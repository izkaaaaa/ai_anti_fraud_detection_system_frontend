import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:video_player/video_player.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class DetectionPage extends StatefulWidget {
  const DetectionPage({super.key});

  @override
  State<DetectionPage> createState() => _DetectionPageState();
}

class _DetectionPageState extends State<DetectionPage> {
  // 视频播放器
  VideoPlayerController? _videoController;
  
  // 检测状态：0=未开始, 1=检测中, 2=已完成
  int _detectionStatus = 0;
  
  // 当前安全状态：0=未检测, 1=安全, 2=可疑, 3=危险
  int _safetyStatus = 0;
  
  // 置信度
  double _videoConfidence = 0.0;
  
  // 检测结果信息
  String _resultMessage = '';
  
  // 任务 ID
  String? _taskId;
  
  // 使用 AuthService 创建带 Token 的 Dio
  late Dio _dio;
  
  // 当前选择的视频文件
  File? _selectedVideoFile;
  PlatformFile? _selectedPlatformFile;
  
  // 视频来源：0=默认视频, 1=用户选择的视频
  int _videoSource = 0;
  
  // 视频文件名
  String _videoFileName = 'test_video.mp4';

  @override
  void initState() {
    super.initState();
    _dio = AuthService().createAuthDio();  // 使用带 Token 的 Dio
    _initVideoPlayer();
  }
  
  // 初始化视频播放器
  Future<void> _initVideoPlayer() async {
    try {
      // 从 assets 加载默认视频
      _videoController = VideoPlayerController.asset('lib/assets/test_video.mp4');
      await _videoController!.initialize();
      setState(() {});
    } catch (e) {
      print('视频加载失败: $e');
      _showError('视频加载失败');
    }
  }
  
  // 选择视频文件
  Future<void> _pickVideoFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty) {
        _selectedPlatformFile = result.files.first;
        
        // 释放旧的视频控制器
        await _videoController?.dispose();
        
        // 根据平台加载视频
        if (result.files.first.path != null) {
          // 移动端：使用文件路径
          _selectedVideoFile = File(result.files.first.path!);
          _videoController = VideoPlayerController.file(_selectedVideoFile!);
        } else if (result.files.first.bytes != null) {
          // Web 端：使用字节数据（需要特殊处理）
          // Web 端暂时使用默认视频预览
          _videoController = VideoPlayerController.asset('lib/assets/test_video.mp4');
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
  
  // 切换回默认视频
  Future<void> _useDefaultVideo() async {
    try {
      await _videoController?.dispose();
      
      _selectedVideoFile = null;
      _selectedPlatformFile = null;
      
      _videoController = VideoPlayerController.asset('lib/assets/test_video.mp4');
      await _videoController!.initialize();
      
      setState(() {
        _videoSource = 0;
        _videoFileName = 'test_video.mp4';
        _detectionStatus = 0;
        _safetyStatus = 0;
        _videoConfidence = 0.0;
        _resultMessage = '';
      });
      
      _showSuccess('已切换到默认视频');
    } catch (e) {
      print('切换视频失败: $e');
      _showError('切换视频失败');
    }
  }
  
  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }
  
  // 开始检测（支持 Web 和移动端）
  Future<void> _startDetection() async {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      _showError('视频未加载');
      return;
    }
    
    setState(() {
      _detectionStatus = 1;  // 检测中
      _resultMessage = '步骤 1/5: 准备视频文件...';
    });
    
    try {
      // ========== 步骤 1: 读取视频文件 ==========
      print('📁 步骤 1: 读取视频文件');
      List<int> bytes;
      
      if (_videoSource == 1 && _selectedPlatformFile != null) {
        // 用户选择的视频
        if (_selectedPlatformFile!.bytes != null) {
          // Web 端：直接使用字节数据
          bytes = _selectedPlatformFile!.bytes!;
          print('✅ 使用用户选择的视频 (Web): ${_videoFileName}');
        } else if (_selectedVideoFile != null) {
          // 移动端：从文件读取
          bytes = await _selectedVideoFile!.readAsBytes();
          print('✅ 使用用户选择的视频 (移动端): ${_videoFileName}');
        } else {
          throw Exception('无法读取视频文件');
        }
      } else {
        // 默认视频
        final ByteData data = await rootBundle.load('lib/assets/test_video.mp4');
        bytes = data.buffer.asUint8List();
        print('✅ 使用默认视频: test_video.mp4');
      }
      
      print('✅ 视频文件大小: ${bytes.length} bytes');
      
      // ========== 步骤 2: 准备上传（Web 和移动端兼容） ==========
      setState(() {
        _resultMessage = '步骤 2/5: 准备上传...';
      });
      print('📝 步骤 2: 准备上传');
      
      // ========== 步骤 3: 上传视频到后端 ==========
      setState(() {
        _resultMessage = '步骤 3/5: 上传视频到服务器...';
      });
      print('📤 步骤 3: 上传视频到后端');
      print('   接口: POST /api/detection/upload/video');
      
      // 创建 MultipartFile
      FormData formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: _videoFileName,
        ),
      });
      
      print('   使用 Token 认证: ${AuthService().accessToken != null}');
      
      final uploadResponse = await _dio.post(
        '/api/detection/upload/video',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      print('✅ 上传成功');
      print('   响应: ${uploadResponse.data}');
      
      // 从响应中获取视频 URL（如果后端返回了）
      final videoUrl = uploadResponse.data['data']?['url'];
      print('   视频 URL: $videoUrl');
      
      // ========== 步骤 4: 提取视频帧（可选，取决于后端实现） ==========
      // 有些后端会在上传时自动提取帧，有些需要单独调用
      // 这里我们假设后端已经自动处理了
      
      // ========== 步骤 5: 提交检测任务 ==========
      setState(() {
        _resultMessage = '步骤 4/5: 提交检测任务...';
      });
      print('🔍 步骤 4: 提交视频检测任务');
      print('   接口: POST /api/tasks/video/detect');
      
      // 注意：这里需要根据你的后端实际接口调整
      // 如果后端需要 frame_data，可能需要先提取帧
      final taskResponse = await _dio.post(
        '/api/tasks/video/detect',
        data: {
          'frame_data': [],  // 这里可能需要实际的帧数据
          'call_id': 1,      // 测试用的 call_id
        },
      );
      
      _taskId = taskResponse.data['data']['task_id'];
      print('✅ 任务已提交');
      print('   任务 ID: $_taskId');
      
      // ========== 步骤 6: 轮询查询任务状态 ==========
      setState(() {
        _resultMessage = '步骤 5/5: 等待检测结果...';
      });
      print('⏳ 步骤 5: 轮询任务状态');
      
      await _pollTaskStatus();
      
    } catch (e) {
      print('❌ 检测失败: $e');
      if (e is DioException) {
        print('   状态码: ${e.response?.statusCode}');
        print('   响应数据: ${e.response?.data}');
      }
      
      setState(() {
        _detectionStatus = 0;
        _resultMessage = '检测失败';
      });
      _showError('检测失败: ${e.toString()}');
    }
  }
  
  // 轮询查询任务状态
  Future<void> _pollTaskStatus() async {
    if (_taskId == null) {
      _showError('任务 ID 为空');
      return;
    }
    
    int maxRetries = 30;  // 最多查询 30 次
    int retryCount = 0;
    
    while (retryCount < maxRetries) {
      try {
        print('🔄 查询任务状态 (第 ${retryCount + 1} 次)');
        print('   接口: GET /api/tasks/status/$_taskId');
        
        final statusResponse = await _dio.get(
          '/api/tasks/status/$_taskId',
        );
        
        final status = statusResponse.data['data']['status'];
        print('   状态: $status');
        
        if (status == 'SUCCESS') {
          // 检测完成
          final result = statusResponse.data['data']['result'];
          final confidence = result['confidence'] ?? 0.0;
          final isFake = result['is_fake'] ?? false;
          
          print('✅ 检测完成');
          print('   置信度: $confidence');
          print('   是否伪造: $isFake');
          
          setState(() {
            _detectionStatus = 2;
            _videoConfidence = confidence;
            
            if (isFake) {
              // 检测到伪造
              if (confidence < 0.4) {
                _safetyStatus = 3;  // 危险
                _resultMessage = '检测完成！检测到 Deepfake 伪造！';
              } else {
                _safetyStatus = 2;  // 可疑
                _resultMessage = '检测完成！视频存在可疑特征。';
              }
            } else {
              // 真实视频
              _safetyStatus = 1;  // 安全
              _resultMessage = '检测完成！视频内容真实可信。';
            }
          });
          
          _showSuccess('检测完成！');
          return;
          
        } else if (status == 'FAILURE') {
          // 检测失败
          print('❌ 任务失败');
          throw Exception('检测任务失败');
          
        } else {
          // PENDING 或 PROCESSING，继续等待
          print('   继续等待...');
          await Future.delayed(Duration(seconds: 2));
          retryCount++;
        }
        
      } catch (e) {
        print('❌ 查询状态失败: $e');
        throw e;
      }
    }
    
    // 超时
    throw Exception('检测超时，请稍后重试');
  }
  
  // 重置检测
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
  
  // 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }
  
  // 显示成功提示
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        title: Text(
          '视频检测测试',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
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
      ),
    );
  }
  
  // 视频源选择器
  Widget _buildVideoSourceSelector() {
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
                  Icon(Icons.play_circle_outline, 
                    color: AppColors.primary, 
                    size: 16
                  ),
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
  
  // 视频源按钮
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
          color: isSelected 
            ? AppColors.primary.withOpacity(0.15) 
            : AppColors.background,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 18,
            ),
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
  
  // 视频播放器
  Widget _buildVideoPlayer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppColors.borderDark,
          width: 2.0,
        ),
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
                    // 播放/暂停按钮
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
              : Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                ),
        ),
      ),
    );
  }
  
  // 状态卡片
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
        border: Border.all(
          color: statusColor,
          width: 2.0,
        ),
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
            ),
          ],
        ],
      ),
    );
  }
  
  // 视频检测卡片
  Widget _buildVideoDetectionCard() {
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
          
          // 进度条
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
  
  // 控制按钮
  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: _detectionStatus == 1 ? AppColors.borderLight : AppColors.primary,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: AppColors.borderDark,
                width: 2.0,
              ),
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
              border: Border.all(
                color: AppColors.borderDark,
                width: 2.0,
              ),
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

