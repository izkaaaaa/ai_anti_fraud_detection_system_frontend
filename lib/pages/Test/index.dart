import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> with SingleTickerProviderStateMixin {
  // Tab 控制器
  late TabController _tabController;
  
  // 使用 AuthService 创建带 Token 的 Dio
  late Dio _dio;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _dio = AuthService().createAuthDio();
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
          '检测测试',
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
                  Tab(text: '视频检测'),
                  Tab(text: '音频检测'),
                  Tab(text: '文本检测'),
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
          VideoTestTab(dio: _dio),
          AudioTestTab(dio: _dio),
          TextTestTab(dio: _dio),
        ],
      ),
    );
  }
}

// ==================== 视频检测 Tab ====================
class VideoTestTab extends StatefulWidget {
  final Dio dio;
  
  const VideoTestTab({super.key, required this.dio});

  @override
  State<VideoTestTab> createState() => _VideoTestTabState();
}

class _VideoTestTabState extends State<VideoTestTab> {
  VideoPlayerController? _videoController;
  int _detectionStatus = 0;
  int _safetyStatus = 0;
  double _videoConfidence = 0.0;
  String _resultMessage = '';
  String? _taskId;
  File? _selectedVideoFile;
  PlatformFile? _selectedPlatformFile;
  int _videoSource = 0;
  String _videoFileName = 'test_video2.mp4';

  @override
  void initState() {
    super.initState();
    _initVideoPlayer();
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
  
  Future<void> _initVideoPlayer() async {
    try {
      _videoController = VideoPlayerController.asset('lib/assets/test_video2.mp4');
      await _videoController!.initialize();
      setState(() {});
    } catch (e) {
      print('视频加载失败: $e');
    }
  }
  
  Future<void> _pickVideoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        _selectedPlatformFile = result.files.first;
        await _videoController?.dispose();
        
        if (result.files.first.path != null) {
          _selectedVideoFile = File(result.files.first.path!);
          _videoController = VideoPlayerController.file(_selectedVideoFile!);
        } else if (result.files.first.bytes != null) {
          _videoController = VideoPlayerController.asset('lib/assets/test_video2.mp4');
        }
        
        await _videoController!.initialize();
        
        setState(() {
          _videoSource = 1;
          _videoFileName = result.files.first.name;
          _detectionStatus = 0;
          _safetyStatus = 0;
          _videoConfidence = 0.0;
          _resultMessage = '';
        });
        
        _showSuccess('视频已选择：${result.files.first.name}');
      }
    } catch (e) {
      print('选择视频失败: $e');
      _showError('选择视频失败: ${e.toString()}');
    }
  }
  
  Future<void> _useDefaultVideo() async {
    try {
      await _videoController?.dispose();
      _selectedVideoFile = null;
      _selectedPlatformFile = null;
      _videoController = VideoPlayerController.asset('lib/assets/test_video2.mp4');
      await _videoController!.initialize();
      
      setState(() {
        _videoSource = 0;
        _videoFileName = 'test_video2.mp4';
        _detectionStatus = 0;
        _safetyStatus = 0;
        _videoConfidence = 0.0;
        _resultMessage = '';
      });
      
      _showSuccess('已切换到默认视频');
    } catch (e) {
      print('切换视频失败: $e');
    }
  }
  
  Future<void> _startDetection() async {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      _showError('视频未加载');
      return;
    }
    
    setState(() {
      _detectionStatus = 1;
      _resultMessage = '步骤 1/5: 准备视频文件...';
    });
    
    try {
      print('📁 步骤 1: 读取视频文件');
      List<int> bytes;
      
      if (_videoSource == 1 && _selectedPlatformFile != null) {
        if (_selectedPlatformFile!.bytes != null) {
          bytes = _selectedPlatformFile!.bytes!;
          print('✅ 使用用户选择的视频 (Web): $_videoFileName');
        } else if (_selectedVideoFile != null) {
          bytes = await _selectedVideoFile!.readAsBytes();
          print('✅ 使用用户选择的视频 (移动端): $_videoFileName');
        } else {
          throw Exception('无法读取视频文件');
        }
      } else {
        final ByteData data = await rootBundle.load('lib/assets/test_video2.mp4');
        bytes = data.buffer.asUint8List();
        print('✅ 使用默认视频: test_video2.mp4');
      }
      
      print('✅ 视频文件大小: ${bytes.length} bytes');
      
      setState(() {
        _resultMessage = '步骤 2/5: 准备上传...';
      });
      
      setState(() {
        _resultMessage = '步骤 3/5: 上传视频到服务器...';
      });
      print('📤 步骤 3: 上传视频到后端');
      
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: _videoFileName),
      });
      
      final uploadResponse = await widget.dio.post(
        '/api/detection/upload/video',
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      
      print('✅ 上传成功: ${uploadResponse.data}');
      
      setState(() {
        _resultMessage = '步骤 4/5: 提交检测任务...';
      });
      
      final taskResponse = await widget.dio.post(
        '/api/tasks/video/detect',
        data: {
          'frame_data': [],
          'call_id': 1,
        },
      );
      
      _taskId = taskResponse.data['data']['task_id'];
      print('✅ 任务已提交: $_taskId');
      
      setState(() {
        _resultMessage = '步骤 5/5: 等待检测结果...';
      });
      
      await _pollTaskStatus();
      
    } catch (e) {
      print('❌ 检测失败: $e');
      setState(() {
        _detectionStatus = 0;
        _resultMessage = '检测失败';
      });
      _showError('检测失败: ${e.toString()}');
    }
  }
  
  Future<void> _pollTaskStatus() async {
    if (_taskId == null) return;
    
    int maxRetries = 30;
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        final statusResponse = await widget.dio.get('/api/tasks/status/$_taskId');
        final status = statusResponse.data['data']['status'];
        
        if (status == 'SUCCESS') {
          final result = statusResponse.data['data']['result'];
          final confidence = result['confidence'] ?? 0.0;
          final isFake = result['is_fake'] ?? false;
          
          print('✅ 检测完成');
          print('   完整响应: ${statusResponse.data}');
          print('   置信度: $confidence');
          print('   是否伪造: $isFake');
          
          bool isMockResult = confidence == 1.0;
          
          setState(() {
            _detectionStatus = 2;
            _videoConfidence = confidence;
            
            if (isFake) {
              if (confidence < 0.4) {
                _safetyStatus = 3;
                _resultMessage = isMockResult 
                  ? '检测完成！检测到 Deepfake 伪造！\n⚠️ 注意：后端可能使用 Mock 模型'
                  : '检测完成！检测到 Deepfake 伪造！';
              } else {
                _safetyStatus = 2;
                _resultMessage = isMockResult
                  ? '检测完成！视频存在可疑特征。\n⚠️ 注意：后端可能使用 Mock 模型'
                  : '检测完成！视频存在可疑特征。';
              }
            } else {
              _safetyStatus = 1;
              _resultMessage = isMockResult
                ? '检测完成！视频内容真实可信。\n⚠️ 注意：后端可能使用 Mock 模型'
                : '检测完成！视频内容真实可信。';
            }
          });
          
          _showSuccess('检测完成！');
          return;
          
        } else if (status == 'FAILURE') {
          throw Exception('检测任务失败');
        } else {
          await Future.delayed(Duration(seconds: 2));
          retryCount++;
        }
      } catch (e) {
        print('❌ 查询状态失败: $e');
        throw e;
      }
    }
    
    throw Exception('检测超时');
  }
  
  void _resetDetection() {
    setState(() {
      _detectionStatus = 0;
      _safetyStatus = 0;
      _videoConfidence = 0.0;
      _resultMessage = '';
    });
    _videoController?.seekTo(Duration.zero);
    _videoController?.pause();
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
          _buildVideoSourceSelector(),
          SizedBox(height: AppTheme.paddingMedium),
          _buildVideoPlayer(),
          SizedBox(height: AppTheme.paddingMedium),
          _buildStatusCard(),
          SizedBox(height: AppTheme.paddingMedium),
          _buildVideoDetectionCard(),
          SizedBox(height: AppTheme.paddingLarge),
          _buildControlButtons(),
        ],
      ),
    );
  }
  
  Widget _buildVideoSourceSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: AppTheme.shadowSmall,
      ),
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.video_library, color: AppColors.primary, size: 20),
              SizedBox(width: AppTheme.paddingSmall),
              Text(
                '视频来源',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.paddingSmall),
          Row(
            children: [
              Expanded(
                child: _buildSourceButton(
                  label: '默认视频',
                  icon: Icons.video_file,
                  isSelected: _videoSource == 0,
                  onTap: _detectionStatus == 1 ? null : _useDefaultVideo,
                ),
              ),
              SizedBox(width: AppTheme.paddingSmall),
              Expanded(
                child: _buildSourceButton(
                  label: '选择视频',
                  icon: Icons.folder_open,
                  isSelected: _videoSource == 1,
                  onTap: _detectionStatus == 1 ? null : _pickVideoFile,
                ),
              ),
            ],
          ),
          if (_videoFileName.isNotEmpty) ...[
            SizedBox(height: AppTheme.paddingSmall),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppTheme.paddingSmall,
                vertical: AppTheme.paddingSmall / 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
              ),
              child: Row(
                children: [
                  Icon(Icons.play_circle_outline, color: AppColors.primary, size: 16),
                  SizedBox(width: AppTheme.paddingSmall / 2),
                  Expanded(
                    child: Text(
                      _videoFileName,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
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
  
  Widget _buildSourceButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: AppTheme.paddingSmall,
          horizontal: AppTheme.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.15) : AppColors.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary, size: 18),
            SizedBox(width: AppTheme.paddingSmall / 2),
            Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildVideoPlayer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge - 2),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _videoController != null && _videoController!.value.isInitialized
              ? Stack(
                  alignment: Alignment.center,
                  children: [
                    VideoPlayer(_videoController!),
                    if (!_videoController!.value.isPlaying)
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.play_arrow, color: Colors.white, size: 48),
                          onPressed: () {
                            setState(() {
                              _videoController!.play();
                            });
                          },
                        ),
                      ),
                  ],
                )
              : Center(child: CircularProgressIndicator(color: AppColors.primary)),
        ),
      ),
    );
  }
  
  Widget _buildStatusCard() {
    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (_safetyStatus) {
      case 0:
        statusColor = AppColors.textSecondary;
        statusText = '未检测';
        statusIcon = Icons.help_outline;
        break;
      case 1:
        statusColor = AppColors.success;
        statusText = '安全视频';
        statusIcon = Icons.check_circle;
        break;
      case 2:
        statusColor = AppColors.warning;
        statusText = '可疑视频';
        statusIcon = Icons.warning;
        break;
      case 3:
        statusColor = AppColors.error;
        statusText = '危险视频';
        statusIcon = Icons.dangerous;
        break;
      default:
        statusColor = AppColors.textSecondary;
        statusText = '未检测';
        statusIcon = Icons.help_outline;
    }

    return Container(
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
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
            '检测结果：$statusText',
            style: TextStyle(
              fontSize: AppTheme.fontSizeXLarge,
              fontWeight: FontWeight.bold,
              color: statusColor,
            ),
          ),
          if (_videoConfidence > 0) ...[
            SizedBox(height: AppTheme.paddingSmall),
            Text(
              '置信度：${(_videoConfidence * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (_resultMessage.isNotEmpty) ...[
            SizedBox(height: AppTheme.paddingSmall),
            Text(
              _resultMessage,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildVideoDetectionCard() {
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
              Icon(Icons.videocam, color: AppColors.primary, size: 24),
              SizedBox(width: AppTheme.paddingSmall),
              Text(
                '视频分析',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.paddingMedium),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  child: LinearProgressIndicator(
                    value: _videoConfidence,
                    minHeight: 12,
                    backgroundColor: AppColors.borderLight,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _videoConfidence > 0.7 ? AppColors.success : 
                      _videoConfidence > 0.4 ? AppColors.warning : AppColors.error
                    ),
                  ),
                ),
              ),
              SizedBox(width: AppTheme.paddingSmall),
              Text(
                '${(_videoConfidence * 100).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          SizedBox(height: AppTheme.paddingSmall),
          Text(
            _detectionStatus == 1 ? '状态：检测中...' : 
            _detectionStatus == 2 ? '状态：检测完成' : '状态：未检测',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: _detectionStatus == 1 ? AppColors.borderLight : AppColors.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppColors.borderDark, width: 2.0),
              boxShadow: _detectionStatus == 1 ? [] : AppTheme.shadowMedium,
            ),
            child: ElevatedButton(
              onPressed: _detectionStatus == 1 ? null : _startDetection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textWhite,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: _detectionStatus == 1
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                      ),
                    )
                  : Text(
                      '开始检测',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeLarge,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
        SizedBox(width: AppTheme.paddingMedium),
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: _detectionStatus == 0 ? AppColors.borderLight : AppColors.secondaryLight,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppColors.borderDark, width: 2.0),
              boxShadow: _detectionStatus == 0 ? [] : AppTheme.shadowMedium,
            ),
            child: ElevatedButton(
              onPressed: _detectionStatus == 0 ? null : _resetDetection,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: AppColors.textPrimary,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
              ),
              child: Text(
                '重置',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ==================== 音频检测 Tab ====================
class AudioTestTab extends StatefulWidget {
  final Dio dio;
  
  const AudioTestTab({super.key, required this.dio});

  @override
  State<AudioTestTab> createState() => _AudioTestTabState();
}

class _AudioTestTabState extends State<AudioTestTab> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.mic_off, size: 80, color: AppColors.textSecondary),
            SizedBox(height: AppTheme.paddingLarge),
            Text(
              '音频检测功能',
              style: TextStyle(
                fontSize: AppTheme.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.paddingMedium),
            Text(
              '后端暂未提供音频检测接口\n功能开发中...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== 文本检测 Tab ====================
class TextTestTab extends StatefulWidget {
  final Dio dio;
  
  const TextTestTab({super.key, required this.dio});

  @override
  State<TextTestTab> createState() => _TextTestTabState();
}

class _TextTestTabState extends State<TextTestTab> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.text_fields_outlined, size: 80, color: AppColors.textSecondary),
            SizedBox(height: AppTheme.paddingLarge),
            Text(
              '文本检测功能',
              style: TextStyle(
                fontSize: AppTheme.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.paddingMedium),
            Text(
              '后端暂未提供文本检测接口\n功能开发中...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

