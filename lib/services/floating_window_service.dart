import 'package:flutter/services.dart';

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
}




