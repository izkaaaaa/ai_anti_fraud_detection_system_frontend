import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'dart:math' as math;

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

// 监测状态枚举
enum DetectionState {
  idle,        // 空闲
  preparing,   // 准备中
  connecting,  // 连接中
  monitoring,  // 监测中
  warning,     // 警告中
  stopping,    // 停止中
  error,       // 错误
}

// 风险等级枚举
enum RiskLevel {
  safe,      // 安全
  low,       // 低风险
  medium,    // 中风险
  high,      // 高风险
  critical,  // 严重风险
}

class _DetectionPageState extends State<DetectionPage> with TickerProviderStateMixin {
  // 当前状态
  DetectionState _currentState = DetectionState.idle;
  
  // 检测结果
  double _audioConfidence = 0.0;
  bool _audioIsFake = false;
  double _videoConfidence = 0.0;
  bool _videoIsDeepfake = false;
  String _textRiskLevel = 'safe';
  List<String> _textKeywords = [];
  
  // 综合风险等级
  RiskLevel _overallRisk = RiskLevel.safe;
  
  // 连接状态
  bool _isConnected = false;
  String _statusMessage = '点击开始按钮启动实时监测';
  
  // 动画控制器
  late AnimationController _pulseController;
  late AnimationController _waveController;
  late Animation<double> _pulseAnimation;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化脉冲动画（用于监测中的指示器）
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    // 初始化波形动画
    _waveController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }
  
  // 开始监测
  void _startMonitoring() {
    setState(() {
      _currentState = DetectionState.preparing;
      _statusMessage = '正在准备...';
    });
    
    // TODO: 实际的启动逻辑
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _currentState = DetectionState.connecting;
          _statusMessage = '正在连接服务器...';
        });
      }
    });
    
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _currentState = DetectionState.monitoring;
          _isConnected = true;
          _statusMessage = '监测中...';
        });
        
        // 模拟接收检测结果
        _simulateDetectionResults();
      }
    });
  }
  
  // 停止监测
  void _stopMonitoring() {
    setState(() {
      _currentState = DetectionState.stopping;
      _statusMessage = '正在停止...';
    });
    
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _currentState = DetectionState.idle;
          _isConnected = false;
          _statusMessage = '已停止监测';
          _audioConfidence = 0.0;
          _videoConfidence = 0.0;
          _overallRisk = RiskLevel.safe;
        });
      }
    });
  }
  
  // 模拟检测结果（用于演示）
  void _simulateDetectionResults() {
    if (_currentState != DetectionState.monitoring) return;
    
    Future.delayed(Duration(seconds: 3), () {
      if (_currentState == DetectionState.monitoring && mounted) {
        setState(() {
          _audioConfidence = 0.85 + math.Random().nextDouble() * 0.1;
          _audioIsFake = false;
          _videoConfidence = 0.90 + math.Random().nextDouble() * 0.05;
          _videoIsDeepfake = false;
          _textRiskLevel = 'safe';
          _overallRisk = RiskLevel.safe;
        });
        _simulateDetectionResults();
      }
    });
  }
  
  // 计算综合风险等级
  RiskLevel _calculateOverallRisk() {
    if (_audioIsFake && _audioConfidence > 0.8) return RiskLevel.critical;
    if (_videoIsDeepfake && _videoConfidence > 0.8) return RiskLevel.critical;
    if (_textRiskLevel == 'high') return RiskLevel.high;
    if (_audioIsFake || _videoIsDeepfake) return RiskLevel.medium;
    if (_textRiskLevel == 'medium') return RiskLevel.medium;
    return RiskLevel.safe;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        title: Text(
          '实时监测',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isConnected)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: 8),
                  Text(
                    '已连接',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Container(
            color: AppColors.borderMedium,
            height: 1.5,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatusCard(),
            SizedBox(height: AppTheme.paddingMedium),
            _buildAudioWaveform(),
            SizedBox(height: AppTheme.paddingMedium),
            _buildDetectionResults(),
            SizedBox(height: AppTheme.paddingMedium),
            if (_overallRisk == RiskLevel.high || _overallRisk == RiskLevel.critical)
              _buildRiskWarning(),
            if (_overallRisk == RiskLevel.high || _overallRisk == RiskLevel.critical)
              SizedBox(height: AppTheme.paddingMedium),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }
  
  // 状态卡片
  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    switch (_currentState) {
      case DetectionState.idle:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.radio_button_unchecked;
        statusText = '未启动';
        break;
      case DetectionState.preparing:
        statusColor = AppColors.warning;
        statusIcon = Icons.hourglass_empty;
        statusText = '准备中';
        break;
      case DetectionState.connecting:
        statusColor = AppColors.warning;
        statusIcon = Icons.sync;
        statusText = '连接中';
        break;
      case DetectionState.monitoring:
        statusColor = AppColors.success;
        statusIcon = Icons.radio_button_checked;
        statusText = '监测中';
        break;
      case DetectionState.warning:
        statusColor = AppColors.error;
        statusIcon = Icons.warning;
        statusText = '警告';
        break;
      case DetectionState.stopping:
        statusColor = AppColors.textSecondary;
        statusIcon = Icons.stop_circle;
        statusText = '停止中';
        break;
      case DetectionState.error:
        statusColor = AppColors.error;
        statusIcon = Icons.error;
        statusText = '错误';
        break;
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            AppColors.cardBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: statusColor, width: 2.0),
        boxShadow: AppTheme.shadowMedium,
      ),
      padding: EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        children: [
          Icon(statusIcon, color: statusColor, size: 48),
          SizedBox(height: AppTheme.paddingMedium),
          Text(
            statusText,
            style: TextStyle(
              fontSize: AppTheme.fontSizeXLarge,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          SizedBox(height: AppTheme.paddingSmall),
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  // 音频波形显示
  Widget _buildAudioWaveform() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: AppTheme.shadowSmall,
      ),
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.graphic_eq, color: AppColors.primary, size: 20),
              SizedBox(width: AppTheme.paddingSmall),
              Text(
                '音频监测',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.paddingSmall),
          Expanded(
            child: _currentState == DetectionState.monitoring
                ? AnimatedBuilder(
                    animation: _waveController,
                    builder: (context, child) {
                      return CustomPaint(
                        painter: WaveformPainter(
                          progress: _waveController.value,
                          color: AppColors.primary,
                        ),
                        size: Size.infinite,
                      );
                    },
                  )
                : Center(
                    child: Text(
                      '未监测',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppColors.textLight,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  // 检测结果显示
  Widget _buildDetectionResults() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: AppTheme.shadowSmall,
      ),
      padding: EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '检测结果',
            style: TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: AppTheme.paddingMedium),
          
          // 音频检测
          _buildResultItem(
            icon: Icons.mic,
            label: '音频检测',
            confidence: _audioConfidence,
            isSafe: !_audioIsFake,
          ),
          
          SizedBox(height: AppTheme.paddingSmall),
          
          // 视频检测
          _buildResultItem(
            icon: Icons.videocam,
            label: '视频检测',
            confidence: _videoConfidence,
            isSafe: !_videoIsDeepfake,
          ),
          
          SizedBox(height: AppTheme.paddingSmall),
          
          // 文本检测
          _buildResultItem(
            icon: Icons.text_fields,
            label: '文本检测',
            confidence: _textRiskLevel == 'safe' ? 0.95 : 0.5,
            isSafe: _textRiskLevel == 'safe',
          ),
        ],
      ),
    );
  }
  
  // 单个检测结果项
  Widget _buildResultItem({
    required IconData icon,
    required String label,
    required double confidence,
    required bool isSafe,
  }) {
    final color = isSafe ? AppColors.success : AppColors.error;
    final statusText = isSafe ? '安全' : '风险';
    
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(width: AppTheme.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        child: LinearProgressIndicator(
                          value: confidence,
                          minHeight: 6,
                          backgroundColor: AppColors.borderLight,
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                    ),
                    SizedBox(width: AppTheme.paddingSmall),
                    Text(
                      '${(confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: AppTheme.paddingMedium),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // 风险警告
  Widget _buildRiskWarning() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: AppTheme.shadowMedium,
      ),
      padding: EdgeInsets.all(AppTheme.paddingLarge),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.white, size: 32),
          SizedBox(width: AppTheme.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '⚠️ 风险警告',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '检测到可疑内容，请提高警惕！',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // 控制按钮
  Widget _buildControlButtons() {
    final isMonitoring = _currentState == DetectionState.monitoring;
    final isProcessing = _currentState == DetectionState.preparing ||
                        _currentState == DetectionState.connecting ||
                        _currentState == DetectionState.stopping;
    
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isMonitoring ? AppColors.error : AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: isProcessing ? [] : AppTheme.shadowMedium,
      ),
      child: ElevatedButton.icon(
        onPressed: isProcessing
            ? null
            : isMonitoring
                ? _stopMonitoring
                : _startMonitoring,
        icon: isProcessing
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(
                isMonitoring ? Icons.stop : Icons.play_arrow,
                size: 28,
              ),
        label: Text(
          isProcessing
              ? '处理中...'
              : isMonitoring
                  ? '停止监测'
                  : '开始监测',
          style: TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      ),
    );
  }
}

// 波形绘制器
class WaveformPainter extends CustomPainter {
  final double progress;
  final Color color;
  
  WaveformPainter({required this.progress, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    final path = Path();
    final waveCount = 3;
    final amplitude = size.height / 4;
    
    for (int i = 0; i < size.width.toInt(); i++) {
      final x = i.toDouble();
      final y = size.height / 2 +
          math.sin((i / size.width * waveCount * 2 * math.pi) + (progress * 2 * math.pi)) *
              amplitude *
              (0.5 + math.Random(i).nextDouble() * 0.5);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
