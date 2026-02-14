import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/PermissionManager.dart';

/// 权限设置页面
class PermissionSettingsPage extends StatefulWidget {
  const PermissionSettingsPage({super.key});

  @override
  State<PermissionSettingsPage> createState() => _PermissionSettingsPageState();
}

class _PermissionSettingsPageState extends State<PermissionSettingsPage> {
  final PermissionManager _permissionManager = PermissionManager();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await _permissionManager.checkAllPermissions();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('权限设置'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _checkPermissions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 权限说明卡片
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        const Text(
                          '权限说明',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '为了提供实时反诈监测服务，应用需要以下权限。您可以随时在此页面查看和管理权限状态。',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 权限列表
            const Text(
              '必需权限',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // 麦克风权限
            Obx(() => _buildPermissionCard(
              icon: Icons.mic,
              iconColor: Colors.blue,
              title: '麦克风权限',
              description: '录制通话音频进行实时分析',
              isGranted: _permissionManager.hasMicrophonePermission.value,
              onTap: () => _requestMicrophonePermission(),
            )),
            const SizedBox(height: 12),

            // 录屏权限
            Obx(() => _buildPermissionCard(
              icon: Icons.screen_share,
              iconColor: Colors.green,
              title: '录屏权限',
              description: '捕获屏幕内容进行诈骗检测',
              isGranted: _permissionManager.hasScreenRecordPermission.value,
              onTap: () => _showScreenRecordInfo(),
            )),
            const SizedBox(height: 12),

            // 前台服务权限
            Obx(() => _buildPermissionCard(
              icon: Icons.notifications_active,
              iconColor: Colors.orange,
              title: '前台服务权限',
              description: '保持监测服务持续运行',
              isGranted: _permissionManager.hasForegroundServicePermission.value,
              onTap: () => _showForegroundServiceInfo(),
            )),

            const SizedBox(height: 32),

            // 操作按钮
            ElevatedButton.icon(
              onPressed: _requestAllPermissions,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('一键授权所有权限'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () => _permissionManager.openSettings(),
              icon: const Icon(Icons.settings),
              label: const Text('前往系统设置'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 隐私说明
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.privacy_tip_outlined, 
                        color: Colors.grey[700], 
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '隐私承诺',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• 所有数据仅用于反诈骗检测\n'
                    '• 不会上传或分享您的个人信息\n'
                    '• 您可以随时关闭权限',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建权限卡片
  Widget _buildPermissionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
    required bool isGranted,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isGranted ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: isGranted ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // 图标
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 16),

              // 文字信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),

              // 状态指示器
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: isGranted 
                    ? Colors.green.withOpacity(0.1)
                    : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isGranted ? Icons.check_circle : Icons.warning_amber,
                      color: isGranted ? Colors.green : Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isGranted ? '已授权' : '未授权',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isGranted ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 请求麦克风权限
  Future<void> _requestMicrophonePermission() async {
    final granted = await _permissionManager.requestMicrophonePermission(context);
    if (granted) {
      Get.snackbar(
        '成功',
        '麦克风权限已授予',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
    setState(() {});
  }

  /// 请求所有权限
  Future<void> _requestAllPermissions() async {
    final granted = await _permissionManager.requestAllPermissions(context);
    if (granted) {
      Get.snackbar(
        '成功',
        '所有权限已授予',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 2),
      );
    }
    setState(() {});
  }

  /// 显示录屏权限说明
  void _showScreenRecordInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('录屏权限说明'),
        content: const Text(
          '录屏权限将在您首次启动实时监测时通过系统弹窗请求。\n\n'
          '该权限用于捕获屏幕内容，帮助识别潜在的诈骗信息。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  /// 显示前台服务权限说明
  void _showForegroundServiceInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('前台服务权限说明'),
        content: const Text(
          '前台服务权限在 Android 9 及以上版本自动授予。\n\n'
          '该权限用于保持监测服务在后台持续运行，确保实时保护您的安全。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }
}

