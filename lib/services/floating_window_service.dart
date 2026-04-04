import 'package:flutter/services.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/index.dart';

/// 悬浮窗服务（Flutter 侧封装）
/// 通过 MethodChannel 驱动原生 FloatingWindowService。
/// 单例，外部统一通过 [FloatingWindowService.instance] 访问。
class FloatingWindowService {
  static const _ch = MethodChannel(
    'com.example.ai_anti_fraud_detection_system_frontend/floating_window',
  );

  FloatingWindowService._();
  static final instance = FloatingWindowService._();

  bool _showing = false;
  bool get isShowing => _showing;

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

  // ── Alert 通知 ─────────────────────────────────────────────

  /// [level]   : "medium" | "high"
  /// [title]   : 通知/弹窗标题
  /// [message] : 通知/弹窗内容
  Future<void> showAlertNotification(String level, String title, String message) async {
    try {
      await _ch.invokeMethod('showAlertNotification', {
        'level': level,
        'title': title,
        'message': message,
      });
      print('✅ [FloatingWindow] Alert 触发: level=$level title=$title');
    } catch (e) {
      print('❌ [FloatingWindow] showAlertNotification: $e');
    }
  }

  /// 关闭全屏预警遮罩（用户确认后由 App 侧调用）
  Future<void> dismissFullScreenWarning() async {
    try {
      await _ch.invokeMethod('dismissFullScreenWarning');
    } catch (e) {
      print('❌ [FloatingWindow] dismissFullScreenWarning: $e');
    }
  }
}
