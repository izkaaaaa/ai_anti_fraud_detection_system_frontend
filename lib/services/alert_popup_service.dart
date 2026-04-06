import 'dart:async';
import 'package:flutter/material.dart';

/// 预警弹窗服务（App 内弹窗）
///
/// 收到 high / medium / critical 级别的 alert 时，在 App 内显示一个和
/// "AI智能通话检测正在为您保驾护航" 前台通知视觉风格一致的弹窗。
///
/// 单例，通过 [AlertPopupService.instance] 访问。
class AlertPopupService {
  AlertPopupService._();
  static final AlertPopupService instance = AlertPopupService._();

  OverlayEntry? _overlayEntry;
  Timer? _autoDismissTimer;

  /// 颜色常量（与前台通知、前台服务保持一致）
  static const Color _primaryColor = Color(0xFF58A183);
  static const Color _bgColor = Color(0xFFF8FAF9);

  /// 显示预警弹窗
  ///
  /// [level]       : "medium" | "high" | "critical"
  /// [title]       : 弹窗标题
  /// [message]     : 弹窗内容（来自后端 alert.message）
  /// [displayMode] : "toast" | "popup" | "fullscreen"（目前统一用 popup）
  void show({
    required String level,
    required String title,
    required String message,
    String displayMode = 'popup',
  }) {
    _dismiss();

    final overlay = Overlay.of(
      // 使用 navigatorKey 找不到时取根 context
      WidgetsBinding.instance.rootElement!,
    );

    _overlayEntry = OverlayEntry(
      builder: (context) => _AlertPopupWidget(
        level: level,
        title: title,
        message: message,
        onDismiss: _dismiss,
      ),
    );

    overlay.insert(_overlayEntry!);
    print('✅ [AlertPopup] 已显示弹窗: $title ($level)');
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    _autoDismissTimer = null;
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// 关闭弹窗
  void dismiss() => _dismiss();
}

// ============================================================
// 弹窗 Widget（内部实现）
// ============================================================

class _AlertPopupWidget extends StatefulWidget {
  final String level;
  final String title;
  final String message;
  final VoidCallback onDismiss;

  const _AlertPopupWidget({
    required this.level,
    required this.title,
    required this.message,
    required this.onDismiss,
  });

  @override
  State<_AlertPopupWidget> createState() => _AlertPopupWidgetState();
}

class _AlertPopupWidgetState extends State<_AlertPopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();

    // high / critical 5秒后自动消失，medium 4秒
    final seconds = (widget.level == 'high' || widget.level == 'critical') ? 5 : 4;
    Future.delayed(Duration(seconds: seconds), () {
      if (mounted) {
        _dismissWithAnimation();
      }
    });
  }

  Future<void> _dismissWithAnimation() async {
    await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _accentColor {
    switch (widget.level) {
      case 'critical':
        return const Color(0xFFDC2626); // 红色
      case 'high':
        return const Color(0xFFF59E0B); // 橙色
      case 'medium':
        return const Color(0xFF58A183); // 绿色（和中风险渠道颜色一致）
      default:
        return const Color(0xFF58A183);
    }
  }

  Color get _titleColor {
    switch (widget.level) {
      case 'critical':
        return const Color(0xFFDC2626);
      case 'high':
        return const Color(0xFFD97706);
      case 'medium':
        return const Color(0xFF2D4A3E);
      default:
        return const Color(0xFF2D4A3E);
    }
  }

  IconData get _icon {
    switch (widget.level) {
      case 'critical':
        return Icons.gpp_bad_rounded;
      case 'high':
        return Icons.warning_amber_rounded;
      case 'medium':
        return Icons.info_outline_rounded;
      default:
        return Icons.info_outline_rounded;
    }
  }

  String get _levelLabel {
    switch (widget.level) {
      case 'critical':
        return '紧急警告';
      case 'high':
        return '高风险';
      case 'medium':
        return '中风险';
      default:
        return '风险提醒';
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Positioned(
      top: screenSize.height * 0.18,
      left: 20,
      right: 20,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                color: _accentColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _accentColor.withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 顶部装饰条
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                  ),
                  // 内容区域
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 左侧图标
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _icon,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // 右侧文字
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 标题行
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      _levelLabel,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      widget.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.3,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              // 消息内容
                              Text(
                                widget.message,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.92),
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        // 关闭按钮
                        GestureDetector(
                          onTap: _dismissWithAnimation,
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
