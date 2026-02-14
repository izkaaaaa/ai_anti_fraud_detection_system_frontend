import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

/// 权限管理器
class PermissionManager {
  // 单例模式
  static final PermissionManager _instance = PermissionManager._internal();
  factory PermissionManager() => _instance;
  PermissionManager._internal();

  // 权限状态
  final RxBool hasMicrophonePermission = false.obs;
  final RxBool hasCameraPermission = false.obs;
  final RxBool hasScreenRecordPermission = false.obs;
  final RxBool hasForegroundServicePermission = false.obs;

  /// 检查所有权限状态
  Future<void> checkAllPermissions() async {
    hasMicrophonePermission.value = await Permission.microphone.isGranted;
    hasCameraPermission.value = await Permission.camera.isGranted;
    
    // 录屏权限在 Android 上通过 MediaProjection API 动态请求，这里标记为已授予
    // 实际使用时需要通过系统弹窗请求
    hasScreenRecordPermission.value = true;
    
    // 前台服务权限在 Android 9+ 自动授予
    hasForegroundServicePermission.value = true;
  }

  /// 请求所有必需权限
  Future<bool> requestAllPermissions(BuildContext context) async {
    // 1. 请求麦克风权限
    final micStatus = await Permission.microphone.request();
    hasMicrophonePermission.value = micStatus.isGranted;

    if (micStatus.isDenied) {
      _showPermissionDeniedDialog(
        context,
        '麦克风权限',
        '实时监测需要使用麦克风录制音频，请在设置中开启麦克风权限。',
      );
      return false;
    }

    if (micStatus.isPermanentlyDenied) {
      _showPermissionPermanentlyDeniedDialog(
        context,
        '麦克风权限',
        '您已永久拒绝麦克风权限，请前往设置手动开启。',
      );
      return false;
    }

    // 2. 请求摄像头权限
    final cameraStatus = await Permission.camera.request();
    hasCameraPermission.value = cameraStatus.isGranted;

    if (cameraStatus.isDenied) {
      _showPermissionDeniedDialog(
        context,
        '摄像头权限',
        '视频检测需要使用摄像头，请在设置中开启摄像头权限。',
      );
      // 不阻断流程，可以只使用音频检测
    }

    // 3. 请求通知权限（Android 13+）
    if (await _shouldRequestNotificationPermission()) {
      await Permission.notification.request();
    }

    // 4. 录屏权限和前台服务权限在实际使用时动态请求
    hasScreenRecordPermission.value = true;
    hasForegroundServicePermission.value = true;

    return hasMicrophonePermission.value;
  }

  /// 请求单个权限
  Future<bool> requestMicrophonePermission(BuildContext context) async {
    final status = await Permission.microphone.request();
    hasMicrophonePermission.value = status.isGranted;

    if (status.isDenied) {
      _showPermissionDeniedDialog(
        context,
        '麦克风权限',
        '实时监测需要使用麦克风录制音频，请在设置中开启麦克风权限。',
      );
      return false;
    }

    if (status.isPermanentlyDenied) {
      _showPermissionPermanentlyDeniedDialog(
        context,
        '麦克风权限',
        '您已永久拒绝麦克风权限，请前往设置手动开启。',
      );
      return false;
    }

    return status.isGranted;
  }

  /// 检查是否需要请求通知权限
  Future<bool> _shouldRequestNotificationPermission() async {
    // Android 13 (API 33) 及以上需要请求通知权限
    return await Permission.notification.isDenied;
  }

  /// 显示权限被拒绝对话框
  void _showPermissionDeniedDialog(
    BuildContext context,
    String permissionName,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('需要$permissionName'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('去设置'),
          ),
        ],
      ),
    );
  }

  /// 显示权限被永久拒绝对话框
  void _showPermissionPermanentlyDeniedDialog(
    BuildContext context,
    String permissionName,
    String message,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('$permissionName已被禁用'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('前往设置'),
          ),
        ],
      ),
    );
  }

  /// 打开应用设置页面
  Future<void> openSettings() async {
    await openAppSettings();
  }

  /// 获取所有权限状态摘要
  Map<String, bool> getPermissionsSummary() {
    return {
      '麦克风权限': hasMicrophonePermission.value,
      '摄像头权限': hasCameraPermission.value,
      '录屏权限': hasScreenRecordPermission.value,
      '前台服务权限': hasForegroundServicePermission.value,
    };
  }

  /// 检查是否所有必需权限都已授予
  bool get hasAllRequiredPermissions {
    return hasMicrophonePermission.value &&
        hasCameraPermission.value &&
        hasScreenRecordPermission.value &&
        hasForegroundServicePermission.value;
  }

  /// 首次启动时请求权限
  Future<bool> requestPermissionsOnFirstLaunch(BuildContext context) async {
    // 显示权限说明对话框
    final shouldRequest = await _showPermissionExplanationDialog(context);
    
    if (!shouldRequest) {
      return false;
    }

    // 请求所有权限
    return await requestAllPermissions(context);
  }

  /// 显示权限说明对话框
  Future<bool> _showPermissionExplanationDialog(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('权限申请'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '为了提供实时反诈监测服务，我们需要以下权限：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.mic, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('麦克风权限：录制通话音频进行实时分析'),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.videocam, color: Colors.purple, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('摄像头权限：采集视频帧进行 Deepfake 检测'),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.screen_share, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('录屏权限：捕获屏幕内容进行诈骗检测'),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('前台服务权限：保持监测服务持续运行'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              '我们承诺不会将您的数据用于其他用途。',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('拒绝'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('同意并继续'),
          ),
        ],
      ),
    ) ?? false;
  }
}

