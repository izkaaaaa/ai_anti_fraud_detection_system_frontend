import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// 前台服务任务处理器
/// 
/// 这个类负责处理前台服务的回调，保持 App 在后台运行时继续工作
@pragma('vm:entry-point')
class ForegroundTaskHandler extends TaskHandler {
  // 任务计数器
  int _taskCount = 0;
  
  // 任务启动时间
  DateTime? _startTime;
  
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('🚀 前台服务已启动: $timestamp (启动者: $starter)');
    _startTime = timestamp;
  }
  
  @override
  void onRepeatEvent(DateTime timestamp) {
    // 这个方法会定期被调用（根据 eventAction 设置）
    // 我们不在这里做具体工作，只是保持服务活跃
    _taskCount++;
    
    // 每 10 次打印一次日志，避免日志过多
    if (_taskCount % 10 == 0) {
      print('💓 前台服务心跳: $_taskCount 次');
    }
    
    // 更新通知内容（可选）
    if (_startTime != null) {
      FlutterForegroundTask.updateService(
        notificationText: '监测中... (${_formatDuration(_startTime!)})',
      );
    }
  }
  
  @override
  Future<void> onDestroy(DateTime timestamp, bool isTaskRemoved) async {
    print('🛑 前台服务已停止: $timestamp (任务被移除: $isTaskRemoved)');
    _startTime = null;
    _taskCount = 0;
  }
  
  @override
  void onNotificationButtonPressed(String id) {
    print('🔘 通知按钮被点击: $id');
    
    // 处理通知按钮点击事件
    if (id == 'stop_button') {
      // 用户点击了"停止监测"按钮
      FlutterForegroundTask.stopService();
    }
  }
  
  @override
  void onNotificationPressed() {
    print('🔔 通知被点击');
    
    // 用户点击了通知，打开 App
    FlutterForegroundTask.launchApp('/detection');
  }
  
  /// 格式化持续时间
  String _formatDuration(DateTime startTime) {
    final now = DateTime.now();
    final duration = now.difference(startTime);
    
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}

