import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'dart:async';

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> with SingleTickerProviderStateMixin {
  // 监测状态：0=未开始, 1=监测中, 2=已暂停
  int _monitoringStatus = 0;
  
  // 当前风险等级：0=安全, 1=低风险, 2=中风险, 3=高风险
  int _riskLevel = 0;
  
  // 模拟的实时数据
  double _voiceConfidence = 0.0;
  double _videoConfidence = 0.0;
  double _textConfidence = 0.0;
  
  // 监测时长
  Duration _monitoringDuration = Duration.zero;
  Timer? _timer;
  
  // 动画控制器
  late AnimationController _pulseController;
  
  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }
  
  // 开始监测
  void _startMonitoring() {
    setState(() {
      _monitoringStatus = 1;
      _monitoringDuration = Duration.zero;
    });
    
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _monitoringDuration += Duration(seconds: 1);
        // 模拟数据变化
        _voiceConfidence = 0.85 + (timer.tick % 10) * 0.01;
        _videoConfidence = 0.92 + (timer.tick % 8) * 0.005;
        _textConfidence = 0.78 + (timer.tick % 12) * 0.015;
      });
    });
  }
  
  // 暂停监测
  void _pauseMonitoring() {
    setState(() {
      _monitoringStatus = 2;
    });
    _timer?.cancel();
  }
  
  // 停止监测
  void _stopMonitoring() {
    setState(() {
      _monitoringStatus = 0;
      _monitoringDuration = Duration.zero;
      _voiceConfidence = 0.0;
      _videoConfidence = 0.0;
      _textConfidence = 0.0;
      _riskLevel = 0;
    });
    _timer?.cancel();
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
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppColors.textSecondary),
            onPressed: () {
              // TODO: 打开设置
            },
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
            _buildMonitoringStatusCard(),
            SizedBox(height: AppTheme.paddingMedium),
            _buildRealTimeIndicators(),
            SizedBox(height: AppTheme.paddingMedium),
            _buildAnalysisCards(),
            SizedBox(height: AppTheme.paddingLarge),
            _buildControlButtons(),
          ],
        ),
      ),
    );
  }
  
  // 监测状态卡片
  Widget _buildMonitoringStatusCard() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_riskLevel) {
      case 0:
        statusColor = AppColors.success;
        statusText = '安全';
        statusIcon = Icons.shield_outlined;
        break;
      case 1:
        statusColor = Colors.blue;
        statusText = '低风险';
        statusIcon = Icons.info_outline;
        break;
      case 2:
        statusColor = AppColors.warning;
        statusText = '中风险';
        statusIcon = Icons.warning_amber_outlined;
        break;
      case 3:
        statusColor = AppColors.error;
        statusText = '高风险';
        statusIcon = Icons.dangerous_outlined;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = '未监测';
        statusIcon = Icons.shield_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.15),
            statusColor.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: statusColor,
          width: 2.0,
        ),
        boxShadow: AppTheme.shadowMedium,
      ),
      padding: EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        children: [
          // 状态图标（带脉冲动画）
          if (_monitoringStatus == 1)
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor.withOpacity(0.1 + _pulseController.value * 0.2),
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 64),
                );
              },
            )
          else
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: statusColor.withOpacity(0.1),
              ),
              child: Icon(statusIcon, color: statusColor, size: 64),
            ),
          
          SizedBox(height: AppTheme.paddingMedium),
          
          Text(
            statusText,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          
          SizedBox(height: AppTheme.paddingSmall),
          
          if (_monitoringStatus == 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                SizedBox(width: 4),
                Text(
                  _formatDuration(_monitoringDuration),
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            )
          else
            Text(
              _monitoringStatus == 0 ? '点击开始监测' : '监测已暂停',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
  
  // 实时指标
  Widget _buildRealTimeIndicators() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppColors.borderDark,
          width: 2.0,
        ),
        boxShadow: AppTheme.shadowSmall,
      ),
      padding: EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.analytics_outlined, color: AppColors.primary, size: 20),
              SizedBox(width: AppTheme.paddingSmall),
              Text(
                '实时指标',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.paddingMedium),
          
          _buildIndicatorItem(
            icon: Icons.mic,
            label: '语音分析',
            value: _voiceConfidence,
            color: Colors.blue,
          ),
          SizedBox(height: AppTheme.paddingSmall),
          
          _buildIndicatorItem(
            icon: Icons.videocam,
            label: '视频分析',
            value: _videoConfidence,
            color: Colors.purple,
          ),
          SizedBox(height: AppTheme.paddingSmall),
          
          _buildIndicatorItem(
            icon: Icons.text_fields,
            label: '文本分析',
            value: _textConfidence,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
  
  // 单个指标项
  Widget _buildIndicatorItem({
    required IconData icon,
    required String label,
    required double value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
            Spacer(),
            Text(
              '${(value * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: AppColors.borderLight,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
  
  // 分析卡片
  Widget _buildAnalysisCards() {
    return Row(
      children: [
        Expanded(
          child: _buildSmallCard(
            icon: Icons.phone_in_talk,
            label: '通话时长',
            value: _formatDuration(_monitoringDuration),
            color: Colors.green,
          ),
        ),
        SizedBox(width: AppTheme.paddingSmall),
        Expanded(
          child: _buildSmallCard(
            icon: Icons.warning_amber,
            label: '风险事件',
            value: '0',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }
  
  // 小卡片
  Widget _buildSmallCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppColors.borderDark,
          width: 2.0,
        ),
      ),
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: AppTheme.paddingSmall),
          Text(
            value,
            style: TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  // 控制按钮
  Widget _buildControlButtons() {
    if (_monitoringStatus == 0) {
      // 未开始
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: AppColors.borderDark,
            width: 2.0,
          ),
          boxShadow: AppTheme.shadowMedium,
        ),
        child: ElevatedButton(
          onPressed: _startMonitoring,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.textWhite,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, size: 28),
              SizedBox(width: 8),
              Text(
                '开始监测',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // 监测中或已暂停
      return Row(
        children: [
          Expanded(
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: _monitoringStatus == 1 ? AppColors.warning : AppColors.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: AppColors.borderDark,
                  width: 2.0,
                ),
                boxShadow: AppTheme.shadowMedium,
              ),
              child: ElevatedButton(
                onPressed: _monitoringStatus == 1 ? _pauseMonitoring : _startMonitoring,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.textWhite,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_monitoringStatus == 1 ? Icons.pause : Icons.play_arrow, size: 24),
                    SizedBox(width: 8),
                    Text(
                      _monitoringStatus == 1 ? '暂停' : '继续',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(width: AppTheme.paddingSmall),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.error,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppColors.borderDark,
                width: 2.0,
              ),
              boxShadow: AppTheme.shadowMedium,
            ),
            child: ElevatedButton(
              onPressed: _stopMonitoring,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textWhite,
                shadowColor: Colors.transparent,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: Icon(Icons.stop, size: 28),
            ),
          ),
        ],
      );
    }
  }
  
  // 格式化时长
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }
}
