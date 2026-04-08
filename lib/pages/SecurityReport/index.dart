import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/security_report_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/tts_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/report_speech_text.dart';

class SecurityReportPage extends StatefulWidget {
  const SecurityReportPage({super.key});

  @override
  State<SecurityReportPage> createState() => _SecurityReportPageState();
}

class _SecurityReportPageState extends State<SecurityReportPage> {
  final _reportService = SecurityReportService();
  final _authService = AuthService();
  final _ttsService = TtsService();

  bool _isGenerating = false;
  bool _isSpeaking = false;
  Map<String, dynamic>? _reportData;

  Future<void> _generateReport() async {
    setState(() => _isGenerating = true);
    try {
      final userInfo = _authService.userInfo;
      if (userInfo == null) {
        _showSnack('请先登录', true);
        setState(() => _isGenerating = false);
        return;
      }

      final data = await _reportService.generateSecurityReport(
        userInfo['user_id'] as int,
      );

      setState(() {
        _reportData = data;
        _isGenerating = false;
      });

      if (data == null) {
        _showSnack('报告生成失败，请稍后重试', true);
      }
    } catch (e) {
      setState(() => _isGenerating = false);
      _showSnack('生成失败，请稍后重试', true);
    }
  }

  @override
  void initState() {
    super.initState();
    _ttsService.onStateChanged = (state, progress) {
      if (mounted) {
        setState(() => _isSpeaking = state == TtsState.playing);
      }
    };
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  void _showSnack(String text, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(text),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError ? const Color(0xFFD85B5B) : const Color(0xFF58A183),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _reportData?['report_content']?.toString().trim();

    return Scaffold(
      backgroundColor: const Color(0xFFF3F8F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF3F8F5),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.18,
                width: double.infinity,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Image.asset(
                    'lib/UIimages/智能安全报告背景.png',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFD7E7E0)),
                  ),
                  child: Column(
                    children: [
                      // 报告头部：标题 + 朗读按钮
                      if (content != null && content.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 16, right: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _isSpeaking
                                  ? TextButton.icon(
                                      onPressed: () => _ttsService.stop(),
                                      icon: const Icon(Icons.stop_rounded,
                                          size: 20),
                                      label: const Text('停止朗读'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFFD85B5B),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                      ),
                                    )
                                  : TextButton.icon(
                                      onPressed: () => _ttsService.speak(
                                          plainTextForSecurityReportSpeech(
                                            _reportData!['report_content']
                                                .toString(),
                                          )),
                                      icon: const Icon(Icons.volume_up_rounded,
                                          size: 20),
                                      label: const Text('朗读报告'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: const Color(0xFF2E5D50),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 4),
                                      ),
                                    ),
                            ],
                          ),
                        ),
                      // 报告正文
                      Expanded(
                        child: content != null && content.isNotEmpty
                            ? Markdown(
                                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                                data: content,
                                styleSheet: MarkdownStyleSheet(
                                  h1: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF18352D),
                                  ),
                                  h2: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2D7A62),
                                  ),
                                  h3: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3F8E74),
                                  ),
                                  p: const TextStyle(
                                    fontSize: 14.5,
                                    height: 1.7,
                                    color: Color(0xFF33403C),
                                  ),
                                  listBullet: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFF2D7A62),
                                  ),
                                  strong: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF18352D),
                                  ),
                                ),
                              )
                            : const Center(
                                child: Text(
                                  '生成的报告会显示在这里',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF8AA39A),
                                  ),
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isGenerating ? null : _generateReport,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF2E5D50),
                    disabledBackgroundColor: const Color(0xFF8FB3A6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _isGenerating
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          '生成安全报告',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
