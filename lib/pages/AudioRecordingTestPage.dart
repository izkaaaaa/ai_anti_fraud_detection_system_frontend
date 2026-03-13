import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/AudioRecordingService.dart';

/// 音频录制 POC 测试页面
class AudioRecordingTestPage extends StatefulWidget {
  @override
  State<AudioRecordingTestPage> createState() => _AudioRecordingTestPageState();
}

class _AudioRecordingTestPageState extends State<AudioRecordingTestPage> {
  final AudioRecordingServiceDart _audioService = AudioRecordingServiceDart();
  
  bool _isRecording = false;
  String _audioSource = 'UNKNOWN';
  String _status = '未启动';
  String _error = '';
  int _audioDataCount = 0;
  int _totalAudioBytes = 0;
  List<String> _logs = [];
  
  @override
  void initState() {
    super.initState();
    _setupCallbacks();
  }
  
  /// 设置回调
  void _setupCallbacks() {
    _audioService.onAudioDataReceived = (audioBytes) {
      setState(() {
        _audioDataCount++;
        _totalAudioBytes += audioBytes.length;
        _addLog('🎤 收到音频数据: ${audioBytes.length} bytes (总计: $_totalAudioBytes bytes)');
      });
    };
    
    _audioService.onStatusChanged = (status) {
      setState(() {
        _status = status;
        _addLog('📊 状态: $status');
      });
    };
    
    _audioService.onError = (error) {
      setState(() {
        _error = error;
        _addLog('❌ 错误: $error');
      });
    };
  }
  
  /// 添加日志
  void _addLog(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().split('.')[0]}] $message');
      if (_logs.length > 50) {
        _logs.removeAt(0);
      }
    });
  }
  
  /// 启动录制
  Future<void> _startRecording() async {
    try {
      _addLog('🎤 启动音频录制...');
      final started = await _audioService.startRecording();
      
      if (started) {
        setState(() {
          _isRecording = true;
          _audioDataCount = 0;
          _totalAudioBytes = 0;
          _error = '';
        });
        
        // 获取音频源
        final source = await _audioService.getCurrentAudioSource();
        setState(() {
          _audioSource = source;
        });
        
        _addLog('✅ 音频录制已启动');
        _addLog('🎤 使用音频源: $_audioSource');
        
        if (source == 'VOICE_COMMUNICATION') {
          _addLog('✅ 使用 VOICE_COMMUNICATION - 可以与微信/QQ 共享麦克风');
        } else if (source == 'MIC') {
          _addLog('⚠️ 已降级到 MIC - 只能录本地声音，需要打开免提');
        } else if (source == 'VOICE_RECOGNITION') {
          _addLog('⚠️ 已降级到 VOICE_RECOGNITION');
        }
      } else {
        _addLog('❌ 启动失败');
      }
    } catch (e) {
      _addLog('❌ 异常: $e');
    }
  }
  
  /// 停止录制
  Future<void> _stopRecording() async {
    try {
      _addLog('🎤 停止音频录制...');
      final stopped = await _audioService.stopRecording();
      
      if (stopped) {
        setState(() {
          _isRecording = false;
        });
        _addLog('✅ 音频录制已停止');
        _addLog('📊 总共收到 $_audioDataCount 个音频帧，共 $_totalAudioBytes bytes');
      } else {
        _addLog('❌ 停止失败');
      }
    } catch (e) {
      _addLog('❌ 异常: $e');
    }
  }
  
  /// 清空日志
  void _clearLogs() {
    setState(() {
      _logs.clear();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🎤 音频录制 POC 测试'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          // 状态卡片
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.grey[100],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '录制状态: ${_isRecording ? "🔴 录制中" : "⚫ 已停止"}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _isRecording ? Colors.red : Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '音频源: $_audioSource',
                          style: TextStyle(fontSize: 14),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '状态: $_status',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '音频帧数: $_audioDataCount',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '总字节数: $_totalAudioBytes',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_error.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '错误: $_error',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          
          // 控制按钮
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: _isRecording ? null : _startRecording,
                  icon: Icon(Icons.mic),
                  label: Text('启动录制'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : null,
                  icon: Icon(Icons.stop),
                  label: Text('停止录制'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    disabledBackgroundColor: Colors.grey,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _clearLogs,
                  icon: Icon(Icons.delete),
                  label: Text('清空日志'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          
          // 日志显示
          Expanded(
            child: Container(
              margin: EdgeInsets.all(16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
                color: Colors.black87,
              ),
              child: ListView.builder(
                reverse: true,
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final logIndex = _logs.length - 1 - index;
                  return Text(
                    _logs[logIndex],
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontFamily: 'Courier',
                    ),
                  );
                },
              ),
            ),
          ),
          
          // 测试说明
          Container(
            padding: EdgeInsets.all(16),
            color: Colors.blue[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '📝 测试说明:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                SizedBox(height: 8),
                Text(
                  '1. 点击"启动录制"开始录音\n'
                  '2. 打开微信/QQ 进行通话\n'
                  '3. 观察日志中的音频源和数据\n'
                  '4. 如果看到"收到音频数据"，说明成功\n'
                  '5. 点击"停止录制"结束测试',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

