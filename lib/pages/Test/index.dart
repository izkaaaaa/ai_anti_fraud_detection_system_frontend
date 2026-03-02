import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'dart:math';
import 'package:flutter_screen_recording/flutter_screen_recording.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import 'package:ai_anti_fraud_detection_system_frontend/services/baidu_speech_service.dart';

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
    _tabController = TabController(length: 3, vsync: this);
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
                  Tab(icon: Icon(Icons.text_fields), text: '语音转文字'),
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
          SpeechToTextTestTab(),
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
  String? _videoPath;
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;

  Future<void> _startRecording() async {
    try {
      print('🎬 准备开始录屏...');
      
      // 请求存储权限
      final storageStatus = await Permission.storage.request();
      print('🎬 存储权限状态: $storageStatus');
      
      // Android 13+ 不需要存储权限，但需要其他权限
      if (!storageStatus.isGranted && !storageStatus.isPermanentlyDenied) {
        print('⚠️ 存储权限未授予，但继续尝试录屏');
      }

      setState(() {
        _isRecording = true;
        _recordDuration = Duration.zero;
        _statusMessage = '正在录制屏幕...\n请授权屏幕录制权限';
      });

      // 启动计时器
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordDuration = Duration(seconds: _recordDuration.inSeconds + 1);
          });
        }
      });

      // 生成视频文件名
      final videoName = 'screen_record_${DateTime.now().millisecondsSinceEpoch}';
      print('🎬 视频文件名: $videoName');

      // 开始录屏（带音频）
      print('🎬 调用 startRecordScreenAndAudio...');
      bool started = await FlutterScreenRecording.startRecordScreenAndAudio(videoName);
      print('🎬 录屏启动结果: $started');

      if (started) {
        _showSuccess('开始录屏！');
        setState(() {
          _statusMessage = '正在录制屏幕...\n对着屏幕操作试试！';
        });
      } else {
        throw Exception('录屏启动失败');
      }
    } catch (e) {
      print('❌ 开始录屏失败: $e');
      _timer?.cancel();
      setState(() {
        _isRecording = false;
        _statusMessage = '录屏失败: ${e.toString()}';
      });
      _showError('开始录屏失败: ${e.toString()}');
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    try {
      print('🎬 停止录屏...');
      _timer?.cancel();

      // 停止录屏并获取视频路径
      var path = await FlutterScreenRecording.stopRecordScreen;
      print('🎬 视频保存路径: $path');

      setState(() {
        _isRecording = false;
        _videoPath = path?.toString();
        _statusMessage = '录屏完成！\n时长: ${_formatDuration(_recordDuration)}\n点击下方播放按钮查看录屏';
      });

      // 初始化视频播放器
      if (_videoPath != null) {
        await _initVideoPlayer(_videoPath!);
      }

      _showSuccess('录屏完成！视频已保存');
    } catch (e) {
      print('❌ 停止录屏失败: $e');
      setState(() {
        _isRecording = false;
        _statusMessage = '停止录屏失败: ${e.toString()}';
      });
      _showError('停止录屏失败: ${e.toString()}');
    }
  }

  Future<void> _initVideoPlayer(String path) async {
    try {
      print('🎬 初始化视频播放器: $path');
      
      // 释放旧的播放器
      await _videoController?.dispose();
      
      // 创建新的播放器
      _videoController = VideoPlayerController.file(File(path));
      await _videoController!.initialize();
      
      setState(() {});
      
      print('✅ 视频播放器初始化成功');
    } catch (e) {
      print('❌ 视频播放器初始化失败: $e');
      _showError('视频播放器初始化失败');
    }
  }

  Future<void> _playVideo() async {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      _showError('视频未准备好');
      return;
    }

    try {
      await _videoController!.play();
      setState(() {
        _isVideoPlaying = true;
      });
      
      // 监听播放完成
      _videoController!.addListener(() {
        if (_videoController!.value.position >= _videoController!.value.duration) {
          setState(() {
            _isVideoPlaying = false;
          });
        }
      });
    } catch (e) {
      print('❌ 播放视频失败: $e');
      _showError('播放视频失败');
    }
  }

  Future<void> _pauseVideo() async {
    if (_videoController == null) return;

    try {
      await _videoController!.pause();
      setState(() {
        _isVideoPlaying = false;
      });
    } catch (e) {
      print('❌ 暂停视频失败: $e');
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
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
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
          if (_videoPath != null && _videoController != null && _videoController!.value.isInitialized) ...[
            SizedBox(height: AppTheme.paddingMedium),
            _buildVideoPlayer(),
          ],
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

  Widget _buildVideoPlayer() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: AppTheme.shadowMedium,
      ),
      child: Column(
        children: [
          // 视频播放器
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
          
          // 播放控制
          Container(
            padding: EdgeInsets.all(AppTheme.paddingMedium),
            child: Column(
              children: [
                // 进度条
                VideoProgressIndicator(
                  _videoController!,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                    playedColor: AppColors.primary,
                    bufferedColor: AppColors.borderLight,
                    backgroundColor: AppColors.borderMedium,
                  ),
                ),
                SizedBox(height: AppTheme.paddingMedium),
                
                // 播放按钮
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _isVideoPlaying ? _pauseVideo : _playVideo,
                      icon: Icon(
                        _isVideoPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
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

// ==================== 语音转文字测试 Tab ====================
class SpeechToTextTestTab extends StatefulWidget {
  const SpeechToTextTestTab({super.key});

  @override
  State<SpeechToTextTestTab> createState() => _SpeechToTextTestTabState();
}

class _SpeechToTextTestTabState extends State<SpeechToTextTestTab> {
  final BaiduSpeechService _speechService = BaiduSpeechService();
  bool _isInitialized = false;
  bool _isRecognizing = false;
  String _statusMessage = '点击"初始化"开始';
  String _currentText = '';
  final List<RecognitionResult> _resultHistory = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _setupCallbacks();
  }

  @override
  void dispose() {
    _speechService.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupCallbacks() {
    // 临时识别结果（实时显示）
    _speechService.onPartialResult = (text) {
      if (mounted) {
        setState(() {
          _currentText = text;
        });
      }
    };

    // 最终识别结果（添加到历史）
    _speechService.onFinalResult = (text, startTime, endTime) {
      if (mounted) {
        setState(() {
          _resultHistory.add(RecognitionResult(
            text: text,
            startTime: startTime,
            endTime: endTime,
            timestamp: DateTime.now(),
          ));
          _currentText = '';
        });

        // 自动滚动到底部
        Future.delayed(Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    };

    // 状态变化
    _speechService.onStatusChange = (status) {
      if (mounted) {
        setState(() {
          _statusMessage = status;
        });
      }
    };

    // 错误处理
    _speechService.onError = (error) {
      if (mounted) {
        setState(() {
          _statusMessage = '错误: $error';
        });
        _showError(error);
      }
    };

    // 连接成功
    _speechService.onConnected = () {
      if (mounted) {
        _showSuccess('连接成功！');
      }
    };

    // 断开连接
    _speechService.onDisconnected = () {
      if (mounted) {
        setState(() {
          _isRecognizing = false;
        });
      }
    };
  }

  Future<void> _initialize() async {
    setState(() {
      _statusMessage = '正在初始化...';
    });

    final success = await _speechService.initialize();

    if (success) {
      setState(() {
        _isInitialized = true;
        _statusMessage = '初始化成功！点击"开始识别"';
      });
      _showSuccess('初始化成功！');
    } else {
      setState(() {
        _statusMessage = '初始化失败';
      });
    }
  }

  Future<void> _startRecognition() async {
    if (!_isInitialized) {
      _showError('请先初始化');
      return;
    }

    setState(() {
      _statusMessage = '正在连接...';
      _currentText = '';
    });

    final success = await _speechService.startRecognition();

    if (success) {
      setState(() {
        _isRecognizing = true;
      });
    }
  }

  Future<void> _stopRecognition() async {
    setState(() {
      _statusMessage = '正在停止...';
    });

    await _speechService.stopRecognition();

    setState(() {
      _isRecognizing = false;
      _statusMessage = '已停止';
    });
  }

  void _clearHistory() {
    setState(() {
      _resultHistory.clear();
      _currentText = '';
    });
    _showSuccess('已清空历史记录');
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
          _buildStatusCard(),
          SizedBox(height: AppTheme.paddingMedium),
          _buildCurrentTextCard(),
          SizedBox(height: AppTheme.paddingMedium),
          _buildControlButtons(),
          SizedBox(height: AppTheme.paddingMedium),
          _buildHistoryCard(),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    Color statusColor = _isRecognizing 
        ? AppColors.success 
        : _isInitialized 
            ? AppColors.primary 
            : AppColors.textSecondary;

    IconData statusIcon = _isRecognizing 
        ? Icons.mic 
        : _isInitialized 
            ? Icons.check_circle 
            : Icons.info_outline;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: AppTheme.shadowMedium,
      ),
      padding: EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: statusColor,
              boxShadow: _isRecognizing
                  ? [
                      BoxShadow(
                        color: statusColor.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ]
                  : AppTheme.shadowMedium,
            ),
            child: Icon(
              statusIcon,
              size: 40,
              color: Colors.white,
            ),
          ),
          SizedBox(height: AppTheme.paddingMedium),
          Text(
            _isRecognizing ? '识别中...' : _isInitialized ? '就绪' : '未初始化',
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
          SizedBox(height: AppTheme.paddingMedium),
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
                    '使用百度实时语音识别 WebSocket API',
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
    );
  }

  Widget _buildCurrentTextCard() {
    return Container(
      constraints: BoxConstraints(minHeight: 120),
      decoration: BoxDecoration(
        color: _isRecognizing 
            ? AppColors.success.withOpacity(0.1) 
            : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: _isRecognizing ? AppColors.success : AppColors.borderDark,
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
              Icon(
                Icons.text_fields,
                color: _isRecognizing ? AppColors.success : AppColors.textSecondary,
                size: 20,
              ),
              SizedBox(width: AppTheme.paddingSmall),
              Text(
                '实时识别结果',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_isRecognizing) ...[
                SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: AppTheme.paddingMedium),
          Text(
            _currentText.isEmpty ? '等待识别...' : _currentText,
            style: TextStyle(
              fontSize: AppTheme.fontSizeLarge,
              color: _currentText.isEmpty ? AppColors.textLight : AppColors.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButtons() {
    return Column(
      children: [
        if (!_isInitialized)
          _buildButton(
            label: '初始化',
            icon: Icons.power_settings_new,
            color: AppColors.primary,
            onPressed: _initialize,
          )
        else ...[
          _buildButton(
            label: _isRecognizing ? '停止识别' : '开始识别',
            icon: _isRecognizing ? Icons.stop : Icons.mic,
            color: _isRecognizing ? AppColors.error : AppColors.success,
            onPressed: _isRecognizing ? _stopRecognition : _startRecognition,
          ),
          SizedBox(height: AppTheme.paddingSmall),
          Row(
            children: [
              Expanded(
                child: _buildButton(
                  label: '清空历史',
                  icon: Icons.delete_outline,
                  color: AppColors.warning,
                  onPressed: _resultHistory.isEmpty ? () {} : _clearHistory,
                  enabled: _resultHistory.isNotEmpty && !_isRecognizing,
                ),
              ),
            ],
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

  Widget _buildHistoryCard() {
    return Container(
      constraints: BoxConstraints(maxHeight: 400),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(AppTheme.paddingLarge),
            child: Row(
              children: [
                Icon(Icons.history, color: AppColors.primary, size: 20),
                SizedBox(width: AppTheme.paddingSmall),
                Text(
                  '识别历史',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    '${_resultHistory.length} 条',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: AppColors.borderMedium),
          Expanded(
            child: _resultHistory.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.paddingLarge),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat_bubble_outline,
                            size: 48,
                            color: AppColors.textLight,
                          ),
                          SizedBox(height: AppTheme.paddingMedium),
                          Text(
                            '暂无识别记录',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeMedium,
                              color: AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.all(AppTheme.paddingMedium),
                    itemCount: _resultHistory.length,
                    separatorBuilder: (context, index) => SizedBox(height: AppTheme.paddingSmall),
                    itemBuilder: (context, index) {
                      final result = _resultHistory[index];
                      return _buildHistoryItem(result, index);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(RecognitionResult result, int index) {
    final duration = result.endTime - result.startTime;
    final durationText = '${(duration / 1000).toStringAsFixed(1)}s';

    return Container(
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8),
              Text(
                result.timestamp.toString().substring(11, 19),
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppColors.textSecondary,
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  durationText,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            result.text,
            style: TextStyle(
              fontSize: AppTheme.fontSizeMedium,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// 识别结果数据类
class RecognitionResult {
  final String text;
  final int startTime;
  final int endTime;
  final DateTime timestamp;

  RecognitionResult({
    required this.text,
    required this.startTime,
    required this.endTime,
    required this.timestamp,
  });
}
