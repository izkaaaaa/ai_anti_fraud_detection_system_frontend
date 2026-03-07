import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/PermissionManager.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/RealTimeDetectionService.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:get/get.dart';
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
  double _textConfidence = 0.0;  // ✅ 新增：保存文本检测的实际置信度
  List<String> _textKeywords = [];
  
  // 综合风险等级
  RiskLevel _overallRisk = RiskLevel.safe;
  
  // ✅ 三级防御机制
  int _currentDefenseLevel = 1;  // 当前防御等级（1/2/3）
  
  // 连接状态
  bool _isConnected = false;
  String _statusMessage = '点击开始按钮启动实时监测';
  
  // 实时检测服务
  final RealTimeDetectionService _detectionService = RealTimeDetectionService();
  
  // 真实音频波形数据
  List<double> _realAudioWaveform = List.filled(50, 0.0);
  
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
    
    // 设置检测服务回调
    _setupDetectionServiceCallbacks();
    
    // ✅ 添加前台服务监听
    _initForegroundTask();
  }
  
  /// ✅ 初始化前台服务监听
  void _initForegroundTask() {
    // 监听前台服务的数据
    FlutterForegroundTask.addTaskDataCallback(_onReceiveTaskData);
  }
  
  /// 处理前台服务数据
  void _onReceiveTaskData(dynamic data) {
    print('📨 收到前台服务数据: $data');
    
    if (data == 'stop_requested') {
      // 用户点击了通知栏的"停止监测"按钮
      _stopMonitoring();
    } else if (data == 'notification_pressed') {
      // 用户点击了通知
      // 可以在这里做一些 UI 更新
    }
  }
  
  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _detectionService.dispose();
    // ✅ 移除前台服务监听
    FlutterForegroundTask.removeTaskDataCallback(_onReceiveTaskData);
    super.dispose();
  }
  
  /// 设置检测服务回调
  void _setupDetectionServiceCallbacks() {
    // 检测结果回调（按照接口文档格式）
    _detectionService.onDetectionResult = (result) {
      if (mounted) {
        print('📊 收到检测结果: $result');
        
        setState(() {
          // 按照接口文档格式解析
          final detectionType = result['detection_type'] ?? '';
          final isRisk = result['is_risk'] ?? false;
          final confidence = (result['confidence'] ?? 0.0).toDouble();
          final message = result['message'] ?? '';
          
          // 根据检测类型更新对应的结果
          if (detectionType == '语音' || detectionType == 'audio') {
            _audioConfidence = confidence;
            _audioIsFake = isRisk;
            
            // 显示提示消息
            if (isRisk) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ 音频风险: $message'),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          } else if (detectionType == '视频' || detectionType == 'video') {
            _videoConfidence = confidence;
            _videoIsDeepfake = isRisk;
            
            // 显示提示消息
            if (isRisk) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ 视频风险: $message'),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          } else if (detectionType == '文本' || detectionType == 'text') {
            _textRiskLevel = isRisk ? 'high' : 'safe';
            _textConfidence = confidence;  // ✅ 保存实际置信度
            
            // ✅ 提取关键词
            final keywords = result['keywords'];
            if (keywords != null && keywords is List) {
              _textKeywords = List<String>.from(keywords);
            }
            
            // 显示提示消息
            if (isRisk) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('⚠️ 文本风险: $message${_textKeywords.isNotEmpty ? "\n关键词: ${_textKeywords.join(", ")}" : ""}'),
                  backgroundColor: AppColors.error,
                  duration: Duration(seconds: 3),
                ),
              );
            }
          }
          
          // 计算综合风险等级
          _overallRisk = _calculateOverallRisk();
          
          // 如果是高风险，切换到警告状态
          if (_overallRisk == RiskLevel.high || _overallRisk == RiskLevel.critical) {
            _currentState = DetectionState.warning;
          }
        });
      }
    };
    
    // 控制消息回调（防御升级等）
    _detectionService.onControlMessage = (control) {
      if (mounted) {
        print('🎮 收到控制消息: $control');
        
        final action = control['action'] ?? '';
        
        if (action == 'upgrade_level') {
          final targetLevel = control['target_level'] ?? 1;
          final reason = control['reason'] ?? '';
          final config = control['config'] ?? {};
          
          // ✅ 根据后端文档的 warning_mode 决定显示方式
          final warningMode = config['warning_mode'] ?? 'modal';
          final uiMessage = config['ui_message'] ?? '⚠️ 检测到风险，请提高警惕！';
          
          if (warningMode == 'fullscreen' || config['show_full_screen_warning'] == true) {
            // 全屏警告（Level 3）
            _showFullScreenWarning(uiMessage, targetLevel, reason, config);
          } else if (warningMode == 'modal') {
            // 弹窗警告（Level 2）
            _showModalWarning(uiMessage, targetLevel, reason, config);
          } else if (warningMode == 'toast') {
            // 轻量提示（Level 1）
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(uiMessage),
                backgroundColor: AppColors.warning,
                duration: Duration(seconds: 3),
              ),
            );
          }
          
          // 更新状态为警告
          setState(() {
            _currentState = DetectionState.warning;
          });
        }
      }
    };
    
    // ✅ 防御等级变化回调
    _detectionService.onDefenseLevelChanged = (level) {
      if (mounted) {
        setState(() {
          _currentDefenseLevel = level;
        });
        print('🛡️ UI 防御等级已更新: Level $level');
      }
    };
    
    // ACK 确认回调
    _detectionService.onAckReceived = (msgType, status) {
      // 可以在这里显示发送状态（可选）
      // print('✅ $msgType 已确认: $status');
    };
    
    // 新增：监听真实音频波形数据
    _detectionService.onAudioWaveformUpdate = (waveformData) {
      if (mounted) {
        setState(() {
          _realAudioWaveform = waveformData;
        });
      }
    };
    
    _detectionService.onStatusChange = (message) {
      if (mounted) {
        setState(() {
          _statusMessage = message;
        });
      }
    };
    
    _detectionService.onError = (error) {
      if (mounted) {
        setState(() {
          _currentState = DetectionState.error;
          _statusMessage = error;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('错误: $error'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    };
    
    _detectionService.onConnected = () {
      if (mounted) {
        setState(() {
          _isConnected = true;
        });
      }
    };
    
    _detectionService.onDisconnected = () {
      if (mounted) {
        setState(() {
          _isConnected = false;
          if (_currentState == DetectionState.monitoring) {
            _currentState = DetectionState.error;
            _statusMessage = '连接已断开';
          }
        });
      }
    };
  }
  
  // 开始监测
  Future<void> _startMonitoring() async {
    // 1. 检查权限
    final permissionManager = PermissionManager();
    await permissionManager.checkAllPermissions();
    
    if (!permissionManager.hasMicrophonePermission.value) {
      // 显示权限说明对话框
      final shouldRequest = await _showPermissionRequiredDialog();
      if (!shouldRequest) {
        return;
      }
      
      // 请求麦克风权限
      final granted = await permissionManager.requestMicrophonePermission(context);
      if (!granted) {
        _showPermissionDeniedDialog();
        return;
      }
    }
    
    // 2. 更新状态为准备中
    setState(() {
      _currentState = DetectionState.preparing;
      _statusMessage = '正在准备...';
    });
    
    // 3. 延迟一下，显示准备状态
    await Future.delayed(Duration(milliseconds: 500));
    
    // 4. 更新状态为连接中
    if (mounted) {
      setState(() {
        _currentState = DetectionState.connecting;
        _statusMessage = '正在连接服务器...';
      });
    }
    
    // 5. 启动检测服务
    final success = await _detectionService.startDetection();
    
    if (success) {
      if (mounted) {
        setState(() {
          _currentState = DetectionState.monitoring;
          _statusMessage = '监测中...';
        });
        
        // ✅ 使用 ScaffoldMessenger 替代 Get.snackbar，避免 context 问题
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('实时监测已启动'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else {
      if (mounted) {
        setState(() {
          _currentState = DetectionState.error;
          _statusMessage = '启动失败，请重试';
        });
      }
    }
  }
  
  // 停止监测
  Future<void> _stopMonitoring() async {
    setState(() {
      _currentState = DetectionState.stopping;
      _statusMessage = '正在停止...';
    });
    
    // ✅ 获取最近的截图
    final screenshots = await _detectionService.getRecentScreenshots();
    
    await _detectionService.stopDetection();
    
    if (mounted) {
      setState(() {
        _currentState = DetectionState.idle;
        _isConnected = false;
        _statusMessage = '已停止监测';
        _audioConfidence = 0.0;
        _videoConfidence = 0.0;
        _audioIsFake = false;
        _videoIsDeepfake = false;
        _textRiskLevel = 'safe';
        _textConfidence = 0.0;  // ✅ 重置文本置信度
        _textKeywords = [];
        _overallRisk = RiskLevel.safe;
      });
      
      // ✅ 展示截图
      if (screenshots.isNotEmpty) {
        _showScreenshotsDialog(screenshots);
      }
      
      // ✅ 使用 ScaffoldMessenger 替代 Get.snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('实时监测已停止'),
          backgroundColor: Colors.grey[700],
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
  
  /// 展示截图对话框
  void _showScreenshotsDialog(List<dynamic> screenshots) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.photo_library, color: Colors.blue),
            SizedBox(width: 8),
            Text('监测期间的截图'),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: screenshots.length,
            itemBuilder: (context, index) {
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        '截图 ${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Image.memory(
                      screenshots[index],
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('关闭'),
          ),
        ],
      ),
    );
  }
  
  /// 显示权限必需对话框
  Future<bool> _showPermissionRequiredDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('需要权限'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '实时监测功能需要以下权限：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.mic, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Expanded(
                  child: Text('麦克风权限 - 录制音频进行实时分析'),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '不授予权限将无法使用此功能',
                      style: TextStyle(
                        color: Colors.red[900],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
            child: Text('授予权限'),
          ),
        ],
      ),
    ) ?? false;
  }
  
  /// 显示权限被拒绝对话框
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('权限被拒绝'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('您拒绝了麦克风权限，无法使用实时监测功能。'),
            SizedBox(height: 12),
            Text(
              '您可以在以下位置重新授予权限：',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• 我的 → 权限设置'),
            Text('• 系统设置 → 应用权限'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('知道了'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              PermissionManager().openSettings();
            },
            child: Text('前往设置'),
          ),
        ],
      ),
    );
  }
  
  /// 显示弹窗警告（Level 2）
  void _showModalWarning(String message, int level, String reason, Map<String, dynamic> config) {
    showDialog(
      context: context,
      barrierDismissible: true,  // 允许点击外部关闭
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          side: BorderSide(color: AppColors.warning, width: 3),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: AppColors.warning, size: 32),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                '⚠️ 风险警告',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 防御等级
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.paddingMedium,
                vertical: AppTheme.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppColors.warning.withOpacity(0.3)),
              ),
              child: Text(
                '防御等级: Level $level',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.warning,
                ),
              ),
            ),
            
            SizedBox(height: AppTheme.paddingMedium),
            
            // 警告消息
            Text(
              message,
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
            
            SizedBox(height: AppTheme.paddingSmall),
            
            // 原因
            Text(
              '原因: $reason',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            
            SizedBox(height: AppTheme.paddingMedium),
            
            // 提示信息
            Container(
              padding: EdgeInsets.all(AppTheme.paddingSmall),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '已提高检测频率，已通知家人',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              '继续通话',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _stopMonitoring();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: Colors.white,
            ),
            child: Text('立即挂断'),
          ),
        ],
      ),
    );
  }
  
  /// 显示全屏警告对话框（Level 3）
  void _showFullScreenWarning(String message, int level, String reason, Map<String, dynamic> config) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.error,
                AppColors.error.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.error.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          padding: EdgeInsets.all(AppTheme.paddingLarge * 1.5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 警告图标（带动画）
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.8, end: 1.2),
                duration: Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                builder: (context, double scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.white,
                      size: 80,
                    ),
                  );
                },
              ),
              
              SizedBox(height: AppTheme.paddingLarge),
              
              // 警告标题
              Text(
                '🚨 风险警告',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: AppTheme.paddingMedium),
              
              // 防御等级
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingMedium,
                  vertical: AppTheme.paddingSmall,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  '防御等级: Level $level',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              
              SizedBox(height: AppTheme.paddingLarge),
              
              // 警告消息
              Container(
                padding: EdgeInsets.all(AppTheme.paddingMedium),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: Colors.white,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: AppTheme.paddingSmall),
              
              // 原因
              Text(
                '原因: $reason',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: Colors.white.withOpacity(0.9),
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              
              SizedBox(height: AppTheme.paddingMedium),
              
              // ✅ 额外提示信息
              Container(
                padding: EdgeInsets.all(AppTheme.paddingSmall),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '已通知家人',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
                        SizedBox(width: 8),
                        Text(
                          '正在录音保存证据',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              SizedBox(height: AppTheme.paddingLarge * 1.5),
              
              // 按钮
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // 停止监测
                        _stopMonitoring();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.error,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: Text(
                        '停止监测',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: AppTheme.paddingMedium),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white, width: 2),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                      child: Text(
                        '继续监测',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // 计算综合风险等级
  RiskLevel _calculateOverallRisk() {
    // 严重风险：音频或视频检测到伪造且置信度高
    if (_audioIsFake && _audioConfidence > 0.8) return RiskLevel.critical;
    if (_videoIsDeepfake && _videoConfidence > 0.8) return RiskLevel.critical;
    
    // 高风险：文本检测到高风险
    if (_textRiskLevel == 'high') return RiskLevel.high;
    
    // 中风险：音频或视频检测到伪造但置信度较低，或文本中等风险
    if (_audioIsFake || _videoIsDeepfake) return RiskLevel.medium;
    if (_textRiskLevel == 'medium') return RiskLevel.medium;
    
    // 低风险：有一些可疑迹象
    if (_textRiskLevel == 'low') return RiskLevel.low;
    
    // 安全
    return RiskLevel.safe;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ 使用 WithForegroundTask 包装，以便在前台服务运行时保持 UI 更新
    return WithForegroundTask(
      child: Scaffold(
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
              SizedBox(height: AppTheme.paddingMedium),
              _buildPermissionHint(),
            ],
          ),
        ),
      ),
    );
  }
  
  // 状态卡片
  Widget _buildStatusCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;
    
    // ✅ 根据防御等级显示不同颜色
    Color defenseColor;
    String defenseText;
    
    switch (_currentDefenseLevel) {
      case 1:
        defenseColor = AppColors.success;
        defenseText = 'Level 1 - 正常';
        break;
      case 2:
        defenseColor = AppColors.warning;
        defenseText = 'Level 2 - 警惕';
        break;
      case 3:
        defenseColor = AppColors.error;
        defenseText = 'Level 3 - 危险';
        break;
      default:
        defenseColor = AppColors.textSecondary;
        defenseText = 'Level 1 - 正常';
    }
    
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
        statusColor = defenseColor;  // ✅ 使用防御等级颜色
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
          
          // ✅ 显示防御等级
          if (_currentState == DetectionState.monitoring || _currentState == DetectionState.warning) ...[
            SizedBox(height: AppTheme.paddingMedium),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.paddingMedium,
                vertical: AppTheme.paddingSmall,
              ),
              decoration: BoxDecoration(
                color: defenseColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: defenseColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield, color: defenseColor, size: 20),
                  SizedBox(width: 8),
                  Text(
                    defenseText,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      fontWeight: FontWeight.bold,
                      color: defenseColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  // 音频波形显示
  Widget _buildAudioWaveform() {
    // ✅ 计算当前平均分贝值（用于显示）
    final avgDecibel = _realAudioWaveform.isEmpty 
        ? 0.0 
        : _realAudioWaveform.reduce((a, b) => a + b) / _realAudioWaveform.length * 60;
    
    return Container(
      height: 140,
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
              Spacer(),
              if (_currentState == DetectionState.monitoring)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    border: Border.all(color: AppColors.success.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.volume_up, color: AppColors.success, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '${avgDecibel.toStringAsFixed(1)} dB',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppColors.success,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: AppTheme.paddingSmall),
          Expanded(
            child: _currentState == DetectionState.monitoring
                ? Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                    ),
                    child: CustomPaint(
                      painter: RealWaveformPainter(
                        waveformData: _realAudioWaveform,
                        color: AppColors.primary,
                      ),
                      size: Size.infinite,
                    ),
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.mic_off,
                          color: AppColors.textLight,
                          size: 32,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '未监测',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeSmall,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
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
            confidence: _textConfidence,  // ✅ 使用实际置信度
            isSafe: _textRiskLevel == 'safe',
            keywords: _textKeywords,  // ✅ 传递关键词
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
    List<String>? keywords,  // ✅ 新增关键词参数
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
      child: Column(
        children: [
          Row(
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
          
          // ✅ 显示关键词（如果有）
          if (keywords != null && keywords.isNotEmpty) ...[
            SizedBox(height: AppTheme.paddingSmall),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppTheme.paddingSmall),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: color.withOpacity(0.2)),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  Icon(Icons.warning_amber, color: color, size: 14),
                  Text(
                    '关键词:',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  ...keywords.map((keyword) => Container(
                    padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      keyword,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: color,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )),
                ],
              ),
            ),
          ],
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
  
  // 权限提示
  Widget _buildPermissionHint() {
    return Container(
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '权限说明',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[900],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '实时监测需要麦克风和摄像头权限。如未授权，点击开始时会提示授权。',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: Colors.blue[800],
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // 跳转到权限设置页面
              Navigator.pushNamed(context, '/permission-settings');
            },
            child: Text(
              '查看',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// 真实音频波形绘制器
class RealWaveformPainter extends CustomPainter {
  final List<double> waveformData;
  final Color color;
  
  RealWaveformPainter({required this.waveformData, required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.fill
      ..strokeCap = StrokeCap.round;
    
    final barWidth = size.width / waveformData.length;
    final centerY = size.height / 2;
    
    for (int i = 0; i < waveformData.length; i++) {
      final x = i * barWidth;
      final normalizedValue = waveformData[i];
      
      // ✅ 增强显示效果：
      // 1. 使用平方根函数压缩高值，放大低值
      // 2. 乘以更大的系数
      // 3. 设置最小高度，确保有基础显示
      final enhancedValue = math.sqrt(normalizedValue) * 1.5;
      final barHeight = math.max(enhancedValue * size.height * 0.9, 4.0);
      
      // 从中心向上下绘制
      final topY = centerY - barHeight / 2;
      final bottomY = centerY + barHeight / 2;
      
      // ✅ 使用渐变色增强视觉效果
      final gradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color,
          color.withOpacity(0.3),
        ],
      );
      
      final rect = Rect.fromLTRB(x, topY, x + barWidth - 1, bottomY);
      final gradientPaint = Paint()
        ..shader = gradient.createShader(rect)
        ..style = PaintingStyle.fill;
      
      // 绘制圆角矩形
      final rrect = RRect.fromRectAndRadius(
        rect,
        Radius.circular(2),
      );
      canvas.drawRRect(rrect, gradientPaint);
    }
  }
  
  @override
  bool shouldRepaint(RealWaveformPainter oldDelegate) {
    return oldDelegate.waveformData != waveformData;
  }
}

// 旧的波形绘制器（已废弃，保留以防需要）
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
