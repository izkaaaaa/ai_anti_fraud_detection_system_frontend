import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

/// 本地通知服务
/// 
/// 用于在App后台时显示系统通知，提醒用户风险警告
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  /// 初始化通知服务
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Android 初始化设置
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      
      // iOS 初始化设置
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      final result = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = result ?? false;
      
      if (_isInitialized) {
        print('✅ 本地通知服务初始化成功');
        
        // ✅ Android 13+ 需要请求通知权限
        await _requestNotificationPermission();
        
        // 创建通知渠道
        await _createNotificationChannels();
      } else {
        print('❌ 本地通知服务初始化失败');
      }

      return _isInitialized;
    } catch (e) {
      print('❌ 初始化本地通知服务失败: $e');
      return false;
    }
  }
  
  /// 请求通知权限（Android 13+）
  Future<void> _requestNotificationPermission() async {
    final androidImplementation = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      final granted = await androidImplementation.requestNotificationsPermission();
      if (granted == true) {
        print('✅ 通知权限已授予');
      } else {
        print('⚠️ 通知权限被拒绝');
      }
    }
  }

  /// 创建通知渠道（Android）
  Future<void> _createNotificationChannels() async {
    // 高风险警告渠道
    const highRiskChannel = AndroidNotificationChannel(
      'high_risk_alert',
      '高风险警告',
      description: '检测到高风险诈骗行为时的紧急通知',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFFFF0000),
    );

    // 中风险警告渠道
    const mediumRiskChannel = AndroidNotificationChannel(
      'medium_risk_alert',
      '中风险警告',
      description: '检测到可疑行为时的警告通知',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // 低风险提示渠道
    const lowRiskChannel = AndroidNotificationChannel(
      'low_risk_alert',
      '低风险提示',
      description: '检测到轻微风险时的提示通知',
      importance: Importance.defaultImportance,
      playSound: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(highRiskChannel);
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(mediumRiskChannel);
    
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(lowRiskChannel);

    print('✅ 通知渠道创建成功');
  }

  /// 通知被点击时的回调
  void _onNotificationTapped(NotificationResponse response) {
    print('🔔 通知被点击: ${response.payload}');
    // 可以在这里处理通知点击事件，比如跳转到特定页面
  }

  /// 显示高风险警告通知（Level 3）
  Future<void> showHighRiskAlert({
    required String title,
    required String message,
    String? payload,
  }) async {
    if (!_isInitialized) {
      print('⚠️ 通知服务未初始化');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'high_risk_alert',
      '高风险警告',
      channelDescription: '检测到高风险诈骗行为时的紧急通知',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      enableLights: true,
      color: const Color(0xFFFF0000),
      ledColor: const Color(0xFFFF0000),
      ledOnMs: 1000,
      ledOffMs: 500,
      fullScreenIntent: true, // 全屏显示
      category: AndroidNotificationCategory.alarm,
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: title,
        summaryText: '⚠️ 紧急警告',
      ),
      actions: const [
        AndroidNotificationAction(
          'stop_call',
          '立即挂断',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          'view_details',
          '查看详情',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.critical,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      details,
      payload: payload,
    );

    print('🚨 已发送高风险警告通知');
  }

  /// 显示中风险警告通知（Level 2）
  Future<void> showMediumRiskAlert({
    required String title,
    required String message,
    String? payload,
  }) async {
    if (!_isInitialized) {
      print('⚠️ 通知服务未初始化');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'medium_risk_alert',
      '中风险警告',
      channelDescription: '检测到可疑行为时的警告通知',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
      color: const Color(0xFFFFA500),
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: title,
        summaryText: '⚠️ 警告',
      ),
      actions: const [
        AndroidNotificationAction(
          'view_details',
          '查看详情',
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      message,
      details,
      payload: payload,
    );

    print('⚠️ 已发送中风险警告通知');
  }

  /// 显示低风险提示通知（Level 1）
  Future<void> showLowRiskAlert({
    required String title,
    required String message,
    String? payload,
  }) async {
    print('🔔 准备发送低风险通知: $title - $message');
    
    if (!_isInitialized) {
      print('⚠️ 通知服务未初始化');
      return;
    }

    final androidDetails = AndroidNotificationDetails(
      'low_risk_alert',
      '低风险提示',
      channelDescription: '检测到轻微风险时的提示通知',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      color: const Color(0xFFFFD700),
      styleInformation: BigTextStyleInformation(
        message,
        contentTitle: title,
      ),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);
    print('🔔 通知ID: $notificationId');

    await _notifications.show(
      notificationId,
      title,
      message,
      details,
      payload: payload,
    );

    print('ℹ️ 已发送低风险提示通知');
  }

  /// 取消所有通知
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    print('🔕 已取消所有通知');
  }

  /// 取消指定通知
  Future<void> cancel(int id) async {
    await _notifications.cancel(id);
  }
}

