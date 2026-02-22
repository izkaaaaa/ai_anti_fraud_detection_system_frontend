import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:math';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        title: Text(
          '设备测试',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                indicatorColor: AppColors.primary,
                indicatorWeight: 3,
                labelStyle: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                ),
                tabs: [
                  Tab(icon: Icon(Icons.screen_share), text: '录屏测试'),
                  Tab(icon: Icon(Icons.mic), text: '麦克风测试'),
                ],
              ),
              Container(
                color: AppColors.borderMedium,
                height: 1.5,
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ScreenRecordTestTab(),
          MicrophoneTestTab(),
        ],
      ),
    );
  }
}

// ==================== 录屏测试 Tab ====================
class ScreenRecordTestTab extends StatefulWidget {
  const ScreenRecordTestTab({super.key});

  @override
  State<ScreenRecordTestTab> createState() => _ScreenRecordTestTabState();
}

class _ScreenRecordTestTabState extends State<ScreenRecordTestTab> {
  bool _isRecording = false;
  String _statusMessage = '点击"开始录屏"测试屏幕录制功能';
  Duration _recordDuration = Duration.zero;
  Timer? _timer;

  Future<void> _startRecording() async {
    // 请求屏幕录制权限
    // 注意：Android 需要 MediaProjection API，这里只是模拟
    setState(() {
      _isRecording = true;
      _recordDuration = Duration.zero;
      _statusMessage = '正在录制屏幕...\n\n提示：实际录屏需要使用 Android MediaProjection API 或 iOS ReplayKit';
    });

    // 启动计时器
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _recordDuration = Duration(seconds: _recordDuration.inSeconds + 1);
      });
    });

    _showSuccess('开始录屏（模拟）');
  }

  void _stopRecording() {
    _timer?.cancel();
    
    setState(() {
      _isRecording = false;
      _statusMessage = '录屏完成！\n时长: ${_formatDuration(_recordDuration)}\n\n说明：\n• Android 使用 MediaProjection API\n• iOS 使用 ReplayKit\n• 需要用户授权屏幕录制权限';
    });

    _showSuccess('录屏完成（模拟）');
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildScreenPreview(),
          SizedBox(height: AppTheme.paddingMedium),
          _buildStatusCard(),
          SizedBox(height: AppTheme.paddingMedium),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildScreenPreview() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: _isRecording ? AppColors.error : AppColors.borderDark,
          width: 2.0,
        ),
        boxShadow: AppTheme.shadowMedium,
      ),
      padding: EdgeInsets.all(AppTheme.paddingLarge * 2),
      child: Column(
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? AppColors.error : AppColors.primary,
              boxShadow: _isRecording
                  ? [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : AppTheme.shadowMedium,
            ),
            child: Icon(
              _isRecording ? Icons.screen_share : Icons.screen_share_outlined,
              size: 64,
              color: Colors.white,
            ),
          ),
          SizedBox(height: AppTheme.paddingLarge),
          if (_isRecording)
            Column(
              children: [
                Text(
                  _formatDuration(_recordDuration),
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(height: AppTheme.paddingSmall),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fiber_manual_record, color: AppColors.error, size: 12),
                    SizedBox(width: 4),
                    Text(
                      '录制中',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Text(
              '准备就绪',
              style: TextStyle(
                fontSize: AppTheme.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
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
          Row(
            children: [
              Icon(
                Icons.info_outline,
                color: AppColors.primary,
                size: 24,
              ),
              SizedBox(width: AppTheme.paddingSmall),
              Text(
                '状态信息',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.paddingMedium),
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: _isRecording ? AppColors.error : AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: AppTheme.shadowMedium,
      ),
      child: ElevatedButton.icon(
        onPressed: _isRecording ? _stopRecording : _startRecording,
        icon: Icon(_isRecording ? Icons.stop : Icons.fiber_manual_record),
        label: Text(
          _isRecording ? '停止录屏' : '开始录屏',
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

// ==================== 麦克风测试 Tab ====================
class MicrophoneTestTab extends StatefulWidget {
  const MicrophoneTestTab({super.key});

  @override
  State<MicrophoneTestTab> createState() => _MicrophoneTestTabState();
}

class _MicrophoneTestTabState extends State<MicrophoneTestTab> with TickerProviderStateMixin {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;
  bool _isRecording = false;
  bool _isPlaying = false;
  String _statusMessage = '点击"开始录音"测试麦克风';
  String? _audioPath;
  Duration _recordDuration = Duration.zero;
  
  // 声波动画相关
  double _currentDecibel = 0.0;
  StreamSubscription? _recorderSubscription;
  late AnimationController _waveController;
  List<double> _waveHeights = List.generate(20, (index) => 0.0);

  @override
  void initState() {
    super.initState();
    _initRecorder();
    _initPlayer();
    _waveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 100),
    )..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _recorderSubscription?.cancel();
    _recorder?.closeRecorder();
    _player?.closePlayer();
    _waveController.dispose();
    super.dispose();
  }

  Future<void> _initRecorder() async {
    try {
      print('🎤 开始初始化录音器...');
      
      print('🎤 请求麦克风权限...');
      final status = await Permission.microphone.request();
      print('🎤 权限状态: $status');
      
      if (!status.isGranted) {
        print('❌ 麦克风权限被拒绝');
        _showError('需要麦克风权限');
        setState(() {
          _statusMessage = '麦克风权限被拒绝，请在设置中允许';
        });
        return;
      }

      _recorder = FlutterSoundRecorder();
      
      print('🎤 打开录音器...');
      await _recorder!.openRecorder();
      
      // ✅ 设置订阅间隔，确保 onProgress 能正常工作
      await _recorder!.setSubscriptionDuration(Duration(milliseconds: 100));
      
      setState(() {
        _isRecorderInitialized = true;
        _statusMessage = '麦克风已就绪！点击"开始录音"测试';
      });

      print('✅ 录音器初始化成功');
      _showSuccess('麦克风初始化成功！');
    } catch (e) {
      print('❌ 录音器初始化失败: $e');
      print('❌ 错误堆栈: ${StackTrace.current}');
      setState(() {
        _statusMessage = '录音器初始化失败: ${e.toString()}';
      });
      _showError('录音器初始化失败: ${e.toString()}');
    }
  }

  Future<void> _initPlayer() async {
    try {
      _player = FlutterSoundPlayer();
      await _player!.openPlayer();
      
      setState(() {
        _isPlayerInitialized = true;
      });

      print('✅ 播放器初始化成功');
    } catch (e) {
      print('❌ 播放器初始化失败: $e');
    }
  }

  Future<void> _startRecording() async {
    if (!_isRecorderInitialized || _recorder == null) {
      print('❌ 录音器未初始化');
      _showError('录音器未初始化');
      return;
    }

    try {
      print('🎤 准备开始录音...');
      final directory = await getApplicationDocumentsDirectory();
      final path = '${directory.path}/test_audio_${DateTime.now().millisecondsSinceEpoch}.aac';
      print('🎤 音频保存路径: $path');

      setState(() {
        _isRecording = true;
        _audioPath = path;
        _recordDuration = Duration.zero;
        _statusMessage = '正在录音...\n对着麦克风说话试试！';
      });

      // ✅ 先订阅 onProgress 事件（在 startRecorder 之前）
      print('🎤 订阅录音进度监听...');
      _recorderSubscription = _recorder!.onProgress!.listen((event) {
        print('🎤 录音进度: ${event.duration.inSeconds}s, 分贝: ${event.decibels}');
        if (mounted) {
          setState(() {
            _recordDuration = event.duration;
            // 获取分贝值（0-120）
            _currentDecibel = event.decibels ?? 0.0;
            
            // 更新声波高度
            _updateWaveHeights(_currentDecibel);
          });
        }
      });

      print('🎤 启动录音器...');
      await _recorder!.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
        sampleRate: 16000,              // ✅ 设置采样率
        numChannels: 1,                 // ✅ 单声道
        bitRate: 128000,                // ✅ 比特率
      );
      print('✅ 录音器已启动，等待进度事件...');

      _waveController.repeat();
      _showSuccess('开始录音！对着麦克风说话');
    } catch (e) {
      print('❌ 开始录音失败: $e');
      print('❌ 错误堆栈: ${StackTrace.current}');
      setState(() {
        _isRecording = false;
        _statusMessage = '录音失败: ${e.toString()}';
      });
      _showError('开始录音失败: ${e.toString()}');
    }
  }

  void _updateWaveHeights(double decibel) {
    // 将分贝值映射到 0-1 范围
    double normalizedValue = (decibel.clamp(0, 120) / 120).clamp(0.0, 1.0);
    
    // 移动波形
    for (int i = _waveHeights.length - 1; i > 0; i--) {
      _waveHeights[i] = _waveHeights[i - 1];
    }
    
    // 添加新的波形高度（加入随机性使其更自然）
    _waveHeights[0] = normalizedValue + (Random().nextDouble() * 0.1 - 0.05);
  }

  Future<void> _stopRecording() async {
    if (!_isRecording || _recorder == null) {
      return;
    }

    try {
      await _recorder!.stopRecorder();
      _recorderSubscription?.cancel();
      _waveController.stop();

      setState(() {
        _isRecording = false;
        _currentDecibel = 0.0;
        _waveHeights = List.generate(20, (index) => 0.0);
        _statusMessage = '录音完成！\n时长: ${_formatDuration(_recordDuration)}\n路径: $_audioPath';
      });

      _showSuccess('录音完成！可以播放试听');
    } catch (e) {
      print('❌ 停止录音失败: $e');
      _showError('停止录音失败: ${e.toString()}');
    }
  }

  Future<void> _playAudio() async {
    if (_audioPath == null || !_isPlayerInitialized || _player == null) {
      _showError('没有可播放的音频');
      return;
    }

    try {
      await _player!.startPlayer(
        fromURI: _audioPath,
        codec: Codec.aacADTS,
        whenFinished: () {
          setState(() {
            _isPlaying = false;
            _statusMessage = '播放完成';
          });
        },
      );

      setState(() {
        _isPlaying = true;
        _statusMessage = '正在播放录音...';
      });

      _showSuccess('开始播放');
    } catch (e) {
      print('❌ 播放失败: $e');
      _showError('播放失败: ${e.toString()}');
    }
  }

  Future<void> _stopPlaying() async {
    if (!_isPlaying || _player == null) {
      return;
    }

    try {
      await _player!.stopPlayer();

      setState(() {
        _isPlaying = false;
        _statusMessage = '播放已停止';
      });
    } catch (e) {
      print('❌ 停止播放失败: $e');
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWaveformCard(),
          SizedBox(height: AppTheme.paddingMedium),
          _buildStatusCard(),
          SizedBox(height: AppTheme.paddingMedium),
          _buildControlButtons(),
        ],
      ),
    );
  }

  Widget _buildWaveformCard() {
    return Container(
      decoration: BoxDecoration(
        color: _isRecording ? AppColors.error.withOpacity(0.1) : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: _isRecording ? AppColors.error : AppColors.borderDark,
          width: 2.0,
        ),
        boxShadow: AppTheme.shadowMedium,
      ),
      padding: EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        children: [
          // 麦克风图标
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isRecording ? AppColors.error : AppColors.primary,
              boxShadow: _isRecording
                  ? [
                      BoxShadow(
                        color: AppColors.error.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : AppTheme.shadowMedium,
            ),
            child: Icon(
              _isRecording ? Icons.mic : Icons.mic_none,
              size: 40,
              color: Colors.white,
            ),
          ),
          SizedBox(height: AppTheme.paddingLarge),
          
          // 声波显示
          Container(
            height: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(20, (index) {
                double height = _waveHeights[index] * 100;
                return Container(
                  width: 4,
                  height: max(height, 4),
                  margin: EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: _isRecording 
                        ? AppColors.error.withOpacity(0.7 + _waveHeights[index] * 0.3)
                        : AppColors.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          
          SizedBox(height: AppTheme.paddingMedium),
          
          // 时长显示
          if (_isRecording)
            Column(
              children: [
                Text(
                  _formatDuration(_recordDuration),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppColors.error,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                SizedBox(height: AppTheme.paddingSmall),
                Text(
                  '音量: ${_currentDecibel.toStringAsFixed(1)} dB',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            )
          else
            Text(
              '准备就绪',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
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
          Row(
            children: [
              Icon(
                _audioPath != null ? Icons.check_circle : Icons.info_outline,
                color: _audioPath != null ? AppColors.success : AppColors.textSecondary,
                size: 24,
              ),
              SizedBox(width: AppTheme.paddingSmall),
              Text(
                '状态信息',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.paddingMedium),
          Text(
            _statusMessage,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          if (_audioPath != null) ...[
            SizedBox(height: AppTheme.paddingSmall),
            Container(
              padding: EdgeInsets.all(AppTheme.paddingSmall),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: AppColors.success, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '音频文件已保存',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
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

  Widget _buildControlButtons() {
    return Column(
      children: [
        _buildButton(
          label: _isRecording ? '停止录音' : '开始录音',
          icon: _isRecording ? Icons.stop : Icons.fiber_manual_record,
          color: _isRecording ? AppColors.error : AppColors.primary,
          onPressed: _isRecording ? _stopRecording : _startRecording,
          enabled: _isRecorderInitialized && !_isPlaying,
        ),
        if (_audioPath != null) ...[
          SizedBox(height: AppTheme.paddingSmall),
          _buildButton(
            label: _isPlaying ? '停止播放' : '播放录音',
            icon: _isPlaying ? Icons.stop : Icons.play_arrow,
            color: _isPlaying ? AppColors.warning : AppColors.success,
            onPressed: _isPlaying ? _stopPlaying : _playAudio,
            enabled: !_isRecording,
          ),
        ],
      ],
    );
  }

  Widget _buildButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    bool enabled = true,
  }) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: enabled ? color : AppColors.borderLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: enabled ? AppTheme.shadowMedium : [],
      ),
      child: ElevatedButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon),
        label: Text(
          label,
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
