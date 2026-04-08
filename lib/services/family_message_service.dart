import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';

/// 消息类型枚举
enum MessageType {
  familyAlert,    // 家人风险预警
  sosAlert,       // SOS 求救信号
  emergencyAlert, // 紧急报警
  remoteControl,  // 远程干预
  system,         // 系统通知
  unknown,        // 未知类型
}

/// 消息实体
class Message {
  final int messageId;
  final MessageType type;
  final String title;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? extraData;

  Message({
    required this.messageId,
    required this.type,
    required this.title,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.extraData,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      messageId: json['message_id'] ?? 0,
      type: _parseMessageType(json['type'] ?? json['message_type']),
      title: json['title'] ?? '新消息',
      content: json['content'] ?? json['message'] ?? '',
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      extraData: json['extra_data'] ?? json,
    );
  }

  static MessageType _parseMessageType(String type) {
    switch (type.toLowerCase()) {
      case 'family_alert':
        return MessageType.familyAlert;
      case 'sos_alert':
        return MessageType.sosAlert;
      case 'emergency_alert':
        return MessageType.emergencyAlert;
      case 'remote_control':
        return MessageType.remoteControl;
      case 'system':
        return MessageType.system;
      default:
        return MessageType.unknown;
    }
  }

  /// 获取消息图标
  IconData get icon {
    switch (type) {
      case MessageType.familyAlert:
        return Icons.family_restroom;
      case MessageType.sosAlert:
        return Icons.emergency;
      case MessageType.emergencyAlert:
        return Icons.warning;
      case MessageType.remoteControl:
        return Icons.settings_remote;
      case MessageType.system:
        return Icons.info;
      case MessageType.unknown:
        return Icons.mail;
    }
  }

  /// 获取消息颜色
  Color get color {
    switch (type) {
      case MessageType.familyAlert:
        return const Color(0xFF58A183); // 绿色
      case MessageType.sosAlert:
        return const Color(0xFFDC2626); // 红色
      case MessageType.emergencyAlert:
        return const Color(0xFFDC2626); // 红色
      case MessageType.remoteControl:
        return const Color(0xFFF59E0B); // 橙色
      case MessageType.system:
        return const Color(0xFF6B7280); // 灰色
      case MessageType.unknown:
        return const Color(0xFF9CA3AF);
    }
  }
}

/// 消息中心服务
///
/// 负责：
/// 1. 拉取离线消息（登录后立即 + 定时轮询）
/// 2. 管理未读消息数量
/// 3. 标记已读
class FamilyMessageService {
  FamilyMessageService._();
  static final FamilyMessageService instance = FamilyMessageService._();

  // 定时器
  Timer? _pollingTimer;

  // 当前状态
  int _unreadCount = 0;
  int? _lastMessageId;

  // 监听器
  final List<VoidCallback> _unreadCountListeners = [];
  final List<void Function(Message)> _messageListeners = [];

  // 是否正在轮询
  bool _isPolling = false;

  /// 获取未读消息数量
  int get unreadCount => _unreadCount;

  /// 是否正在轮询
  bool get isPolling => _isPolling;

  /// 添加未读数量变化监听
  void addUnreadCountListener(VoidCallback listener) {
    _unreadCountListeners.add(listener);
  }

  /// 移除未读数量变化监听
  void removeUnreadCountListener(VoidCallback listener) {
    _unreadCountListeners.remove(listener);
  }

  /// 添加新消息监听
  void addMessageListener(void Function(Message) listener) {
    _messageListeners.add(listener);
  }

  /// 移除新消息监听
  void removeMessageListener(void Function(Message) listener) {
    _messageListeners.remove(listener);
  }

  /// 通知未读数量变化
  void _notifyUnreadCountChanged() {
    for (final listener in _unreadCountListeners) {
      listener();
    }
  }

  /// 通知新消息
  void _notifyNewMessage(Message message) {
    for (final listener in _messageListeners) {
      listener(message);
    }
  }

  /// 加入家庭组后初始化消息服务
  Future<void> initialize() async {
    print('📬 [FamilyMessageService] 初始化...');
    await fetchUnreadCount();
    await fetchMessages(unreadOnly: true);
    startPolling();
  }

  /// 退出家庭组时停止服务
  void dispose() {
    stopPolling();
    _unreadCountListeners.clear();
    _messageListeners.clear();
    _unreadCount = 0;
    _lastMessageId = null;
    print('🛑 [FamilyMessageService] 已停止');
  }

  /// 启动定时轮询
  void startPolling({Duration interval = const Duration(seconds: 20)}) {
    stopPolling();
    _isPolling = true;

    _pollingTimer = Timer.periodic(interval, (_) async {
      await fetchIncremental();
    });

    print('🔄 [FamilyMessageService] 启动轮询，间隔: ${interval.inSeconds}秒');
  }

  /// 停止定时轮询
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _isPolling = false;
  }

  /// 获取未读消息数量
  Future<int> fetchUnreadCount() async {
    try {
      final response = await dioRequest.get('/api/messages/my/unread-count');
      if (response != null && response['data'] != null) {
        _unreadCount = response['data']['unread_count'] ?? 0;
        _notifyUnreadCountChanged();
        return _unreadCount;
      }
    } catch (e) {
      print('❌ [FamilyMessageService] 获取未读数量失败: $e');
    }
    return 0;
  }

  /// 拉取消息列表
  Future<List<Message>> fetchMessages({
    bool unreadOnly = false,
    int? sinceId,
    int limit = 50,
  }) async {
    try {
      final params = <String, dynamic>{
        if (unreadOnly) 'unread_only': true,
        if (sinceId != null) 'since_id': sinceId,
        'limit': limit,
      };

      final response = await dioRequest.get('/api/messages/my', params: params);

      if (response != null && response['data'] != null) {
        final messagesData = response['data']['messages'] as List? ?? [];
        final messages = messagesData
            .map((json) => Message.fromJson(json))
            .toList();

        if (messages.isNotEmpty) {
          final maxId = messages.map((m) => m.messageId).reduce((a, b) => a > b ? a : b);
          if (_lastMessageId == null || maxId > _lastMessageId!) {
            _lastMessageId = maxId;
          }
        }

        if (response['data']['unread_count'] != null) {
          _unreadCount = response['data']['unread_count'];
          _notifyUnreadCountChanged();
        }

        for (final message in messages) {
          _notifyNewMessage(message);
        }

        return messages;
      }
    } catch (e) {
      print('❌ [FamilyMessageService] 拉取消息失败: $e');
    }
    return [];
  }

  /// 增量拉取
  Future<List<Message>> fetchIncremental() async {
    if (_lastMessageId == null) {
      return fetchMessages(unreadOnly: true);
    }
    return fetchMessages(sinceId: _lastMessageId);
  }

  /// 标记单条消息已读
  Future<bool> markAsRead(int messageId) async {
    try {
      await dioRequest.post('/api/messages/$messageId/read');
      if (_unreadCount > 0) {
        _unreadCount--;
        _notifyUnreadCountChanged();
      }
      return true;
    } catch (e) {
      print('❌ [FamilyMessageService] 标记已读失败: $e');
      return false;
    }
  }

  /// 标记全部已读
  Future<bool> markAllAsRead() async {
    try {
      await dioRequest.post('/api/messages/read-all');
      _unreadCount = 0;
      _notifyUnreadCountChanged();
      return true;
    } catch (e) {
      print('❌ [FamilyMessageService] 全部已读失败: $e');
      return false;
    }
  }

  /// 处理 WebSocket 推送的新消息
  void handleWebSocketMessage(Map<String, dynamic> data) {
    final type = data['type']?.toString() ?? '';

    if (['family_alert', 'sos_alert', 'emergency_alert', 'remote_control'].contains(type)) {
      final messageData = data['data'] ?? data;

      final message = Message(
        messageId: messageData['message_id'] ?? DateTime.now().millisecondsSinceEpoch,
        type: _parseWebSocketType(type),
        title: messageData['title'] ?? _getDefaultTitle(type),
        content: messageData['message'] ?? messageData['content'] ?? '',
        isRead: false,
        createdAt: DateTime.now(),
        extraData: messageData,
      );

      _unreadCount++;
      _notifyUnreadCountChanged();
      _notifyNewMessage(message);
    }
  }

  MessageType _parseWebSocketType(String type) {
    switch (type) {
      case 'family_alert':
        return MessageType.familyAlert;
      case 'sos_alert':
        return MessageType.sosAlert;
      case 'emergency_alert':
        return MessageType.emergencyAlert;
      case 'remote_control':
        return MessageType.remoteControl;
      default:
        return MessageType.unknown;
    }
  }

  String _getDefaultTitle(String type) {
    switch (type) {
      case 'family_alert':
        return '家人安全预警';
      case 'sos_alert':
        return '紧急求助';
      case 'emergency_alert':
        return '紧急报警';
      case 'remote_control':
        return '远程干预';
      default:
        return '新消息';
    }
  }
}
