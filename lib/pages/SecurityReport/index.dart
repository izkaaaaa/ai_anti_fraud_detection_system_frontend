import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/security_report_service.dart';
import 'dart:ui';

class SecurityReportPage extends StatefulWidget {
  const SecurityReportPage({super.key});

  @override
  State<SecurityReportPage> createState() => _SecurityReportPageState();
}

class _SecurityReportPageState extends State<SecurityReportPage> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _isGenerating = false;
  Map<String, dynamic>? _reportData;
  String? _errorMessage;

  final SecurityReportService _reportService = SecurityReportService();
  final AuthService _authService = AuthService();
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// 生成安全报告
  Future<void> _generateReport() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
    });

    try {
      final userInfo = _authService.userInfo;
      
      if (userInfo == null) {
        _showError('请先登录');
        setState(() {
          _isGenerating = false;
        });
        return;
      }

      final userId = userInfo['user_id'] as int;
      final reportData = await _reportService.generateSecurityReport(userId);

      if (reportData != null) {
        setState(() {
          _reportData = reportData;
          _isGenerating = false;
        });
        _showSuccess('报告生成成功！');
      } else {
        setState(() {
          _errorMessage = '报告生成失败，请稍后重试';
          _isGenerating = false;
        });
      }
    } catch (e) {
      print('❌ 生成报告失败: $e');
      setState(() {
        _errorMessage = '生成失败: $e';
        _isGenerating = false;
      });
      _showError('生成失败，请检查网络连接');
    }
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          '安全报告',
          style: TextStyle(
            color: Colors.white,
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF6A1B9A),
              Color(0xFF8E24AA),
              Color(0xFFAB47BC),
            ],
          ),
        ),
        child: SafeArea(
          child: _reportData == null
              ? _buildEmptyView()
              : _buildReportView(),
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _scaleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    padding: EdgeInsets.all(50),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.2),
                          blurRadius: 30,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.analytics_outlined,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                );
              },
            ),
            
            SizedBox(height: AppTheme.paddingXLarge),
            
            Text(
              '智能安全报告',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            
            SizedBox(height: AppTheme.paddingMedium),
            
            Text(
              'AI 分析您的通话记录\n生成个性化防诈骗建议',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: Colors.white.withOpacity(0.8),
                height: 1.6,
              ),
            ),
            
            SizedBox(height: AppTheme.paddingXLarge),
            
            // 功能介绍卡片
            Container(
              padding: EdgeInsets.all(AppTheme.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  _buildFeatureItem(
                    Icons.shield_outlined,
                    '综合安全评级',
                    '基于近期通话数据的风险评估',
                  ),
                  SizedBox(height: 16),
                  _buildFeatureItem(
                    Icons.warning_amber_outlined,
                    '薄弱点分析',
                    '识别您容易上当的诈骗类型',
                  ),
                  SizedBox(height: 16),
                  _buildFeatureItem(
                    Icons.lightbulb_outline,
                    '专属防骗建议',
                    '根据您的角色定制防范措施',
                  ),
                ],
              ),
            ),
            
            SizedBox(height: AppTheme.paddingXLarge),
            
            // 生成报告按钮
            Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF00F5A0).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isGenerating ? null : _generateReport,
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isGenerating)
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 3,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        else
                          Icon(Icons.auto_awesome, size: 28, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          _isGenerating ? '生成中...' : '生成报告',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            if (_isGenerating) ...[
              SizedBox(height: AppTheme.paddingMedium),
              Text(
                'AI 正在分析您的数据，请稍候...',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
            
            if (_errorMessage != null) ...[
              SizedBox(height: AppTheme.paddingMedium),
              Container(
                padding: EdgeInsets.all(AppTheme.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red[300], size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReportView() {
    return Column(
      children: [
        // 顶部信息栏
        Container(
          margin: EdgeInsets.all(AppTheme.paddingMedium),
          padding: EdgeInsets.all(AppTheme.paddingMedium),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xFF00F5A0).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.person, color: Color(0xFF00F5A0), size: 24),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _reportData!['username'] ?? '未知用户',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '生成时间: ${_reportData!['report_generated_at'] ?? ''}',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.white),
                    onPressed: _generateReport,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Markdown 报告内容
        Expanded(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
            padding: EdgeInsets.all(AppTheme.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Markdown(
              data: _reportData!['report_content'] ?? '# 报告内容为空',
              styleSheet: MarkdownStyleSheet(
                h1: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF6A1B9A),
                ),
                h2: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF8E24AA),
                ),
                h3: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFAB47BC),
                ),
                p: TextStyle(
                  fontSize: 15,
                  color: Colors.black87,
                  height: 1.6,
                ),
                listBullet: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF6A1B9A),
                ),
                strong: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6A1B9A),
                ),
                em: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.black54,
                ),
                blockquote: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
                code: TextStyle(
                  fontSize: 14,
                  fontFamily: 'monospace',
                  backgroundColor: Colors.grey[200],
                ),
              ),
            ),
          ),
        ),
        
        SizedBox(height: AppTheme.paddingMedium),
      ],
    );
  }
}



