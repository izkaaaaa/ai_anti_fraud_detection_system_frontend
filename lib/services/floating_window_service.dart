import 'package:flutter/services.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/local_notification_service.dart';

/// 悬浮窗服务（Flutter 侧封装）
///
/// 通过 MethodChannel 驱动原生 FloatingWindowService。
/// 单例，外部统一通过 [FloatingWindowService.instance] 访问。
///
/// Alert 通知：后端发送 alert 消息时，根据 level 调用 LocalNotificationService 发送系统通知
class FloatingWindowService {
  static const _ch = MethodChannel(
    'com.example.ai_anti_fraud_detection_system_frontend/floating_window',
  );

  FloatingWindowService._();
  static final instance = FloatingWindowService._();

  bool _showing = false;
  bool get isShowing => _showing;

  /// 本地通知服务（用于 alert 通知）
  final LocalNotificationService _notificationService = LocalNotificationService();

  // ── 权限 ──────────────────────────────────────────────────────

  Future<bool> hasPermission() async {
    try {
      return await _ch.invokeMethod<bool>('hasPermission') ?? false;
    } catch (e) {
      print('❌ [FloatingWindow] hasPermission: $e');
      return false;
    }
  }

  Future<void> requestPermission() async {
    try {
      await _ch.invokeMethod('requestPermission');
    } catch (e) {
      print('❌ [FloatingWindow] requestPermission: $e');
    }
  }

  // ── 显示 / 隐藏 ───────────────────────────────────────────────

  /// 显示悬浮窗。无权限时自动跳转系统设置，返回 false。
  Future<bool> show() async {
    try {
      if (!await hasPermission()) {
        print('⚠️ [FloatingWindow] 无悬浮窗权限，跳转设置');
        await requestPermission();
        return false;
      }
      await _ch.invokeMethod('show');
      _showing = true;
      print('✅ [FloatingWindow] 已显示');
      return true;
    } catch (e) {
      print('❌ [FloatingWindow] show: $e');
      return false;
    }
  }

  Future<void> hide() async {
    try {
      await _ch.invokeMethod('hide');
      _showing = false;
      print('✅ [FloatingWindow] 已隐藏');
    } catch (e) {
      print('❌ [FloatingWindow] hide: $e');
    }
  }

  // ── 风险等级更新 ──────────────────────────────────────────────

  /// [riskLevel] : "safe" | "suspicious" | "danger"
  /// [confidence]: 0.0 ~ 1.0
  Future<void> updateRiskLevel(String riskLevel, double confidence) async {
    if (!_showing) return;
    try {
      await _ch.invokeMethod('updateRiskLevel', {
        'risk_level': riskLevel,
        'confidence': confidence,
      });
    } catch (e) {
      print('❌ [FloatingWindow] updateRiskLevel: $e');
    }
  }

  // ── 平台场景更新 ─────────────────────────────────────────────

  /// 更新悬浮窗显示的平台场景（来自后端 environment_detected）
  /// [scene]: 后端返回的 description 字段，如"语音聊天"、"电话通话"等
  Future<void> updateScene(String scene) async {
    if (!_showing) return;
    try {
      await _ch.invokeMethod('updateScene', {
        'scene': scene,
      });
      print('✅ [FloatingWindow] 场景更新: $scene');
    } catch (e) {
      print('❌ [FloatingWindow] updateScene: $e');
    }
  }

  // ── Alert 通知（改为系统通知）────────────────────────────

  /// [level]   : "medium" | "high"
  /// [title]   : 通知标题
  /// [message] : 通知内容
  ///
  /// ✅ 已移除全屏遮罩弹窗，改为根据 level 发送系统通知
  /// - "medium" → showMediumRiskAlert（中风险警告）
  /// - "high" → showHighRiskAlert（高风险警告）
  Future<void> showAlertNotification(String level, String title, String message) async {
    try {
      // 确保通知服务已初始化
      await _notificationService.initialize();

      // 根据 level 选择对应的通知方法
      if (level == 'high') {
        await _notificationService.showHighRiskAlert(
          title: title,
          message: message,
          payload: 'alert_high',
        );
        print('✅ [FloatingWindow] 高风险通知已发送: $title');
      } else if (level == 'medium') {
        await _notificationService.showMediumRiskAlert(
          title: title,
          message: message,
          payload: 'alert_medium',
        );
        print('✅ [FloatingWindow] 中风险通知已发送: $title');
      } else {
        // low 级别只记录日志
        print('ℹ️ [FloatingWindow] 低风险预警（不发送通知）: $title');
      }
    } catch (e) {
      print('❌ [FloatingWindow] showAlertNotification: $e');
    }
  }

  /// 关闭全屏预警遮罩（已废弃，保留接口兼容性）
  Future<void> dismissFullScreenWarning() async {
    // ✅ 全屏遮罩已移除，此方法不再需要
    print('ℹ️ [FloatingWindow] dismissFullScreenWarning: 全屏遮罩已移除，无需关闭');
  }
}