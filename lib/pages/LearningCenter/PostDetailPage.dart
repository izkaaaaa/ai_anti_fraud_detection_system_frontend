import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';

/// 将视频 URL/ID 映射为本地 assets 路径
/// 本地视频存放在 lib/UIimages/edu_video/ 目录下，文件名为 1.mp4 ~ 10.mp4
String? _mapToLocalVideoAsset(String? url) {
  if (url == null || url.isEmpty) return null;
  // 优先通过 video_id（若有） 取本地文件
  // 如果 url 本身形如 "1.mp4" / "1" / "/api/.../1.mp4"，则直接映射
  final numMatch = RegExp(r'(\d+)(?:\.mp4)?($|\?)').firstMatch(url);
  if (numMatch != null) {
    final idx = int.tryParse(numMatch.group(1) ?? '');
    if (idx != null && idx >= 1 && idx <= 10) {
      return 'lib/UIimages/edu_video/$idx.mp4';
    }
  }
  return null;
}

class PostDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  final String source;

  const PostDetailPage({
    super.key,
    required this.data,
    required this.source,
  });

  factory PostDetailPage.fromRoute(BuildContext context) {
    final raw = ModalRoute.of(context)?.settings.arguments;
    final args = (raw is Map<String, dynamic>) ? raw : <String, dynamic>{};
    return PostDetailPage(
      data: (args['data'] as Map<String, dynamic>?) ?? {},
      source: (args['source'] as String?) ?? 'recommendation',
    );
  }

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;
  bool _videoError = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _maybeInitVideo();
  }

  void _maybeInitVideo() {
    if (widget.source != 'recommendation') return;
    final type = widget.data['type']?.toString() ?? '';
    if (type != 'video') return;

    // 尝试从 video_url / url / video_id 中解析本地 assets 路径
    final url = widget.data['video_url']?.toString() ??
        widget.data['url']?.toString() ??
        widget.data['video_id']?.toString() ??
        '';
    if (url.isEmpty) return;

    final localAsset = _mapToLocalVideoAsset(url);
    if (localAsset != null) {
      // 优先使用本地视频
      _videoCtrl = VideoPlayerController.asset(localAsset)
        ..initialize().then((_) {
          if (mounted) {
            _videoCtrl?.seekTo(Duration.zero);
            _videoCtrl?.pause();
            setState(() => _videoReady = true);
          }
        }).catchError((_) {
          if (mounted) setState(() => _videoError = true);
        });
    } else {
      // 兜底网络视频
      _videoCtrl = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (mounted) {
            _videoCtrl?.seekTo(Duration.zero);
            _videoCtrl?.pause();
            setState(() => _videoReady = true);
          }
        }).catchError((_) {
          if (mounted) setState(() => _videoError = true);
        });
    }
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _videoCtrl?.dispose();
    super.dispose();
  }

  String get _type => widget.data['type']?.toString() ?? '';

  String get _title {
    final t = widget.data['title']?.toString();
    if (t != null && t.isNotEmpty) return t;
    final c = widget.data['content']?.toString();
    if (c != null && c.isNotEmpty) {
      return c.length > 20 ? c.substring(0, 20) : c;
    }
    return '未知标题';
  }

  String get _body {
    switch (widget.source) {
      case 'case':
        return widget.data['content']?.toString() ??
            widget.data['description']?.toString() ??
            '暂无详细内容';
      case 'law':
        return widget.data['content']?.toString() ?? '暂无详细内容';
      default:
        return widget.data['content']?.toString() ??
            widget.data['description']?.toString() ??
            '暂无详细内容';
    }
  }

  String get _fraudType => widget.data['fraud_type']?.toString() ?? '';

  bool get _isVideo =>
      widget.source == 'recommendation' && _type == 'video';

  String? get _videoUrl {
    if (!_isVideo) return null;
    return widget.data['video_url']?.toString() ??
        widget.data['url']?.toString();
  }

  Color get _accentColor {
    if (widget.source == 'case' || _type == 'case') {
      return const Color(0xFF3B82F6);
    }
    if (widget.source == 'law') return const Color(0xFF10B981);
    if (_type == 'video') return const Color(0xFF10B981);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Column(
        children: [
          // 内容区域，独立滚动
          Expanded(
            child: SingleChildScrollView(
              child: SafeArea(
                top: false,
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 顶部留白（状态栏高度）
                    SizedBox(height: MediaQuery.of(context).padding.top),

                    // 导航栏
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 8, 16, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.arrow_back, color: Color(0xFF0F1923)),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getSourceLabel(),
                            style: TextStyle(
                              fontSize: 13,
                              color: _accentColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (_fraudType.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _accentColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _fraudType,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: _accentColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // 标题
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Text(
                        _title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F1923),
                          height: 1.3,
                        ),
                      ),
                    ),

                    // 分隔线
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: Container(
                        height: 1,
                        color: const Color(0xFFE5E7EB),
                      ),
                    ),

                    // 视频播放器
                    if (_isVideo && _videoUrl != null && _videoUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: _buildVideo(),
                      ),

                    // 正文
                    Padding(
                      padding: EdgeInsets.fromLTRB(20, _isVideo ? 20 : 24, 20, 40),
                      child: Text(
                        _body,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF374151),
                          height: 1.9,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getSourceLabel() {
    if (widget.source == 'case') return '案例库';
    if (widget.source == 'law') return '法律库';
    if (_type == 'video') return '防骗视频';
    if (_type == 'case') return '诈骗案例';
    return '防骗提示';
  }

  Widget _buildVideo() {
    if (_videoError) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.videocam_off, color: Color(0xFF9CA3AF), size: 40),
              SizedBox(height: 8),
              Text('视频加载失败', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 14)),
            ],
          ),
        ),
      );
    }

    if (!_videoReady || _videoCtrl == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF58A183))),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: _videoCtrl!.value.aspectRatio,
            child: VideoPlayer(_videoCtrl!),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            GestureDetector(
              onTap: () {
                setState(() {
                  _videoCtrl!.value.isPlaying ? _videoCtrl!.pause() : _videoCtrl!.play();
                });
              },
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _accentColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _videoCtrl!.value.isPlaying ? Icons.pause : Icons.play_arrow,
                  color: _accentColor,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: VideoProgressIndicator(
                _videoCtrl!,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: _accentColor,
                  bufferedColor: const Color(0xFFE5E7EB),
                  backgroundColor: const Color(0xFFF3F4F6),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              _formatDuration(_videoCtrl!.value.duration),
              style: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
