import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:timeline_tile/timeline_tile.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';

const _kAccent = Color(0xFF58A183);
const _kBg = Color(0xFFF8FAF9);

// ---- 风险配置 ----
class _RiskConfig {
  final String label;
  final IconData icon;
  final Color color;     // 卡片背景色
  final Color textColor; // 文字色
  final Color bgColor;   // 浅色背景

  const _RiskConfig(this.label, this.icon, this.color, this.textColor, this.bgColor);
}

_RiskConfig _riskConfig(String result) {
  switch (result) {
    case 'safe':
      return const _RiskConfig(
        '安全', Icons.verified_rounded,
        Color(0xFF059669), Colors.white, Color(0xFF58A183),
      );
    case 'suspicious':
      return const _RiskConfig(
        '可疑', Icons.warning_amber_rounded,
        Color(0xFFD97706), Color(0xFF92400E), Color(0xFFFFEDD5),
      );
    case 'fake':
      return const _RiskConfig(
        '危险', Icons.gpp_bad_rounded,
        Color(0xFFDC2626), Color(0xFF7F1D1D), Color(0xFFFEE2E2),
      );
    default:
      return const _RiskConfig(
        '未检测', Icons.help_outline_rounded,
        Color(0xFF9CA3AF), Color(0xFF374151), Color(0xFFF3F4F6),
      );
  }
}


// ==================== 主页面 ====================
class CallRecordsPage extends StatefulWidget {
  const CallRecordsPage({super.key});
  @override
  State<CallRecordsPage> createState() => _CallRecordsPageState();
  }

class _CallRecordsPageState extends State<CallRecordsPage> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: CallRecordsList(isFamily: false)),
    );
  }
}

// ==================== 列表页 ====================
class CallRecordsList extends StatefulWidget {
  final bool isFamily;
  const CallRecordsList({super.key, required this.isFamily});
  @override
  State<CallRecordsList> createState() => _CallRecordsListState();
}

class _CallRecordsListState extends State<CallRecordsList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  bool _isLoading = true;
  List<dynamic> _records = [];
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _resultFilter;   // null / 'safe' / 'suspicious' / 'fake'
  DateTime? _dateFilter;   // 选定日期
  
  final ScrollController _scrollController = ScrollController();

  static const _riskFilters = [
    {'label': '全部',  'value': null},
    {'label': '安全',  'value': 'safe'},
    {'label': '可疑',  'value': 'suspicious'},
    {'label': '危险',  'value': 'fake'},
  ];

  @override
  void initState() {
    super.initState();
    _loadRecords();
    _scrollController.addListener(_onScroll);
  }
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
  
  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _currentPage < _totalPages) _loadMore();
    }
  }

  Future<void> _loadRecords({bool refresh = false}) async {
    if (refresh) setState(() { _currentPage = 1; _records = []; });
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final endpoint = widget.isFamily 
          ? '/api/call-records/family-records'
          : '/api/call-records/my-records';
      final params = <String, dynamic>{
        'page': _currentPage,
        'page_size': 20,
        if (_resultFilter != null) 'result_filter': _resultFilter,
        if (_dateFilter != null)
          'date': '${_dateFilter!.year}-${_dateFilter!.month.toString().padLeft(2,'0')}-${_dateFilter!.day.toString().padLeft(2,'0')}',
      };
      final response = await dioRequest.get(endpoint, params: params);
      if (response != null && response['data'] != null) {
        final records = response['data']['records'] as List;
        final pagination = response['data']['pagination'];
        setState(() {
          if (refresh) { _records = records; } else { _records.addAll(records); }
          _totalPages = pagination['total_pages'] ?? 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() { _errorMessage = '加载失败，请稍后重试'; _isLoading = false; });
    }
  }
  
  Future<void> _loadMore() async {
    setState(() => _currentPage++);
    await _loadRecords();
  }
  
  Future<void> _deleteRecord(int callId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('删除记录', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('确定要删除这条通话记录吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),
              child: const Text('删除', style: TextStyle(color: Color(0xFFDC2626)))),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await dioRequest.delete('/api/call-records/record/$callId');
        _snack('删除成功', AppColors.success);
        _loadRecords(refresh: true);
      } catch (_) {
        _snack('删除失败', AppColors.error);
      }
    }
  }
  
  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  // 日期选择弹窗
  void _showDatePicker() {
    DateTime _focused = _dateFilter ?? DateTime.now();
    DateTime? _selected = _dateFilter;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
              ),
              TableCalendar(
                firstDay: DateTime(2020),
                lastDay: DateTime.now(),
                focusedDay: _focused,
                selectedDayPredicate: (d) => _selected != null && isSameDay(d, _selected!),
                onDaySelected: (sel, foc) => setModal(() { _selected = sel; _focused = foc; }),
                onPageChanged: (foc) => setModal(() => _focused = foc),
                calendarStyle: CalendarStyle(
                  selectedDecoration: const BoxDecoration(color: _kAccent, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(color: _kAccent.withOpacity(0.25), shape: BoxShape.circle),
                  todayTextStyle: const TextStyle(color: _kAccent, fontWeight: FontWeight.bold),
                  selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  weekendTextStyle: const TextStyle(color: Color(0xFFDC2626)),
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _dateFilter = null);
                          Navigator.pop(ctx);
        _loadRecords(refresh: true);
      },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF6B7280),
                          side: const BorderSide(color: Color(0xFFE5E7EB)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('清除'),
        ),
      ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() => _dateFilter = _selected);
                          Navigator.pop(ctx);
                          _loadRecords(refresh: true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kAccent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('确定'),
        ),
                    ),
                  ],
                ),
              ),
            ],
      ),
    );
      },
    );
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        _buildFilterRow(),
        const SizedBox(height: 4),
        Expanded(child: _buildBody()),
      ],
    );
  }

  // 标题（与个人中心"我的"同尺寸：20, w700）
  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        '通话记录',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F1923),
          letterSpacing: 1,
        ),
      ),
    );
    }
    
  // 筛选区：两行，第一行风险类型，第二行日期
  Widget _buildFilterRow() {
    final hasDate = _dateFilter != null;
    final dateLabel = hasDate
        ? '${_dateFilter!.month}月${_dateFilter!.day}日'
        : '按日期筛选';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
      children: [
          // 第一行：风险类型胶囊
          Row(
            children: _riskFilters.map((f) {
              final selected = _resultFilter == f['value'];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _resultFilter = f['value'] as String?);
                    _loadRecords(refresh: true);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected ? _kAccent : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? _kAccent : const Color(0xFFE5E7EB),
                        width: 1.5,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: _kAccent.withOpacity(0.22), blurRadius: 6, offset: const Offset(0, 2))]
                          : [],
                    ),
                    child: Center(
                      child: Text(
                        f['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected ? Colors.white : const Color(0xFF6B7280),
                        ),
            ),
          ),
        ),
                ),
    );
            }).toList(),
          ),
          const SizedBox(height: 8),
          // 第二行：日期筛选
          GestureDetector(
            onTap: _showDatePicker,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
                color: hasDate ? _kAccent : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hasDate ? _kAccent : const Color(0xFFE5E7EB),
                  width: 1.5,
        ),
                boxShadow: hasDate
                    ? [BoxShadow(color: _kAccent.withOpacity(0.22), blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
      ),
      child: Row(
                mainAxisSize: MainAxisSize.min,
        children: [
                  Icon(Icons.calendar_today_rounded, size: 13,
                      color: hasDate ? Colors.white : const Color(0xFF6B7280)),
                  const SizedBox(width: 6),
          Text(
                    dateLabel,
            style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: hasDate ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
                  if (hasDate) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() => _dateFilter = null);
                        _loadRecords(refresh: true);
                      },
                      child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _records.isEmpty) {
      return const Center(child: CircularProgressIndicator(color: _kAccent));
    }

    final bodyChild = _errorMessage != null && _records.isEmpty
        ? _buildRefreshableStateView(_buildErrorView())
        : _records.isEmpty
            ? _buildRefreshableStateView(_buildEmptyView())
            : RefreshIndicator(
                onRefresh: () => _loadRecords(refresh: true),
                color: _kAccent,
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
                  itemCount: _records.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _records.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator(color: _kAccent)),
                      );
                    }
                    return _buildRecordCard(_records[index]);
                  },
                ),
              );

    return bodyChild;
  }

  Widget _buildRefreshableStateView(Widget child) {
    return RefreshIndicator(
      onRefresh: () => _loadRecords(refresh: true),
      color: _kAccent,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
        children: [
          SizedBox(
            height: 420,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecordCard(Map<String, dynamic> record) {
    final callId = record['call_id'];
    final startTime = record['start_time'] ?? '';
    final duration = record['duration'] ?? 0;
    final result = record['detected_result'] ?? 'unknown';
    final cfg = _riskConfig(result);

    // 主标题：安全通话/可疑通话/危险通话/未知通话
    final callTypeLabel = result == 'safe' ? '安全通话'
        : result == 'suspicious' ? '可疑通话'
        : result == 'fake' ? '危险通话'
        : '未知通话';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: FractionallySizedBox(
          widthFactor: 0.9,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showRecordDetail(record),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                decoration: BoxDecoration(
                  color: cfg.bgColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: cfg.color.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(cfg.icon, color: cfg.textColor, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            callTypeLabel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: cfg.textColor,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(Icons.schedule_rounded, size: 11, color: cfg.textColor.withOpacity(0.7)),
                              const SizedBox(width: 3),
                              Text(_formatDateTime(startTime),
                                  style: TextStyle(fontSize: 11, color: cfg.textColor.withOpacity(0.8))),
                              const SizedBox(width: 8),
                              Icon(Icons.timer_outlined, size: 11, color: cfg.textColor.withOpacity(0.7)),
                              const SizedBox(width: 3),
                              Text(_formatDuration(duration),
                                  style: TextStyle(fontSize: 11, color: cfg.textColor.withOpacity(0.8))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _deleteRecord(callId),
                      child: Icon(Icons.delete_outline_rounded, size: 18, color: cfg.textColor.withOpacity(0.5)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  Widget _buildEmptyView() {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_disabled_rounded, size: 32, color: _kAccent),
          ),
          const SizedBox(height: 18),
          const Text('暂无通话记录',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F1923))),
          const SizedBox(height: 6),
          Text('您的通话记录会显示在这里',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500)),
          ],
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          const Icon(Icons.error_outline_rounded, size: 52, color: Color(0xFFDC2626)),
          const SizedBox(height: 14),
          Text(_errorMessage!,
              style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
          const SizedBox(height: 18),
          TextButton.icon(
              onPressed: () => _loadRecords(refresh: true),
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
            style: TextButton.styleFrom(foregroundColor: _kAccent),
            ),
          ],
      ),
    );
  }
  
  void _showRecordDetail(Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CallRecordDetailSheet(record: record, isFamily: widget.isFamily),
    );
  }
  
  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      final now = DateTime.now();
      final diff = now.difference(dt);
      final hm = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
      if (diff.inDays == 0) return '今天 $hm';
      if (diff.inDays == 1) return '昨天 $hm';
      return '${dt.month}/${dt.day} $hm';
    } catch (_) { return dateTime; }
  }
  
  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '$m分$s秒' : '$s秒';
  }
}

// ==================== 详情弹窗 ====================

class AuditEvent {
  final int timeValue;
  final String timeDisplay;
  final String type;
  final String title;
  final String description;
  final String? evidenceUrl;
  final int? logId;

  AuditEvent({
    required this.timeValue,
    required this.timeDisplay,
    required this.type,
    required this.title,
    required this.description,
    this.evidenceUrl,
    this.logId,
  });
}

class _TimelinePoint {
  final int timeOffset;
  final double voiceScore;
  final double videoScore;
  final double textScore;
  final double overallScore;
  final String riskLevel;
  final String keywords;
  final int? logId;

  _TimelinePoint({
    required this.timeOffset,
    required this.voiceScore,
    required this.videoScore,
    required this.textScore,
    required this.overallScore,
    required this.riskLevel,
    required this.keywords,
    this.logId,
  });
}

class _ChatMessage {
  final String role;
  final String content;
  final String? timestamp;
  final String? messageType;

  _ChatMessage({
    required this.role,
    required this.content,
    this.timestamp,
    this.messageType,
  });
}

class CallRecordDetailSheet extends StatefulWidget {
  final Map<String, dynamic> record;
  final bool isFamily;

  const CallRecordDetailSheet({
    super.key,
    required this.record,
    this.isFamily = false,
  });

  @override
  State<CallRecordDetailSheet> createState() => _CallRecordDetailSheetState();
}

class _CallRecordDetailSheetState extends State<CallRecordDetailSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoadingLogs = true;
  List<AuditEvent> _auditEvents = [];
  String? _logsError;

  bool _isLoadingTimeline = true;
  List<_TimelinePoint> _timelinePoints = [];
  String? _timelineError;

  bool _isLoadingChat = true;
  List<_ChatMessage> _chatMessages = [];
  String? _chatError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAuditLogs();
    _fetchTimeline();
    _fetchChatHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAuditLogs() async {
    try {
      final callId = widget.record['call_id'];
      final response = await dioRequest.get('/api/call-records/$callId/audit-logs');
      if (response != null && response['data'] != null) {
        final data = response['data'];
        final List<AuditEvent> events = [];

        for (final ai in (data['ai_events'] ?? [])) {
          final score = (ai['overall_score'] ?? 0).toDouble();
          if (score > 50) {
            events.add(
              AuditEvent(
                timeValue: ai['time_offset'] ?? 0,
                timeDisplay: '通话第 ${ai['time_offset']} 秒',
                type: 'ai_scan',
                title: '多模态AI扫描点',
                description: '综合风险评分: ${score.toStringAsFixed(1)}',
                evidenceUrl: ai['evidence_url'],
                logId: ai['log_id'],
              ),
            );
          }
        }

        for (final alert in (data['alert_events'] ?? [])) {
          int timeVal = 999999;
          String displayTime = '系统警报';
          if (alert['created_at'] != null) {
            final dt = DateTime.tryParse(alert['created_at']);
            if (dt != null) {
              timeVal = dt.millisecondsSinceEpoch ~/ 1000;
              displayTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
            }
          }
          events.add(
            AuditEvent(
              timeValue: timeVal,
              timeDisplay: displayTime,
              type: 'alert',
              title: alert['title'] ?? '触发警报',
              description: alert['content'] ?? '',
            ),
          );
        }

        events.sort((a, b) => a.timeValue.compareTo(b.timeValue));
        if (mounted) {
          setState(() {
            _auditEvents = events;
            _isLoadingLogs = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingLogs = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _logsError = '无法加载审计日志';
          _isLoadingLogs = false;
        });
      }
    }
  }

  Future<void> _fetchTimeline() async {
    try {
      final callId = widget.record['call_id'];
      final response = await dioRequest.get('/api/call-records/$callId/detection-timeline');
      if (response != null && response['data'] != null) {
        final timeline = (response['data']['timeline'] as List?) ?? [];
        final points = timeline.map((item) {
          final modalities = (item['modalities'] as Map<String, dynamic>?) ?? {};
          return _TimelinePoint(
            timeOffset: item['time_offset'] ?? 0,
            voiceScore: ((modalities['voice']?['score'] ?? 0)).toDouble(),
            videoScore: ((modalities['video']?['score'] ?? 0)).toDouble(),
            textScore: ((modalities['text']?['score'] ?? 0)).toDouble(),
            overallScore: (item['overall_score'] ?? 0).toDouble(),
            riskLevel: item['fused_risk_level'] ?? 'low',
            keywords: item['detected_keywords']?.toString() ?? '',
            logId: item['log_id'],
          );
        }).toList();

        if (mounted) {
          setState(() {
            _timelinePoints = points;
            _isLoadingTimeline = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingTimeline = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _timelineError = '无法加载检测时间轴';
          _isLoadingTimeline = false;
        });
      }
    }
  }

  Future<void> _fetchChatHistory() async {
    try {
      final callId = widget.record['call_id'];
      final response = await dioRequest.get('/api/call-records/$callId/chat-history');
      if (response != null && response['data'] != null) {
        final data = response['data'];
        final messages = (data['messages'] as List?) ?? (data as List? ?? []);
        final parsed = messages
            .map(
              (m) => _ChatMessage(
                role: m['role'] ?? 'user',
                content: m['content'] ?? '',
                timestamp: m['timestamp'],
                messageType: m['message_type'],
              ),
            )
            .toList();

        if (mounted) {
          setState(() {
            _chatMessages = parsed;
            _isLoadingChat = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingChat = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _chatError = '无法加载对话历史';
          _isLoadingChat = false;
        });
      }
    }
  }

  void _showEvidenceDetail(int logId) {
    final callId = widget.record['call_id'];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EvidenceDetailSheet(callId: callId, logId: logId),
    );
  }

  Future<void> _reportToAdmin() async {
    final callId = widget.record['call_id'];
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('提交审查', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('确定将该通话提交给系统防诈中心吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('提交', style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await dioRequest.post('/api/call-records/$callId/report-to-admin');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已成功提交'), backgroundColor: Color(0xFF059669)),
          );
        }
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('提交失败'), backgroundColor: Color(0xFFDC2626)),
          );
        }
      }
    }
  }

  Future<void> _emergencyAlert() async {
    final callId = widget.record['call_id'];
    final messageController = TextEditingController(text: '我正在遭遇诈骗，请立即帮助！');
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('一键报警', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFDC2626))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '这将向所有家庭组管理员发送紧急报警通知',
              style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 12),
            const Text(
              '报警信息',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F1923)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: '输入报警信息...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            child: const Text('发送报警'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        print('🚨 发送一键报警: callId=$callId');
        await dioRequest.post(
          '/api/call-records/$callId/emergency-alert',
          params: {
            'call_id': callId,
            'alert_type': 'emergency',
            'message': messageController.text.trim(),
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ 报警已发送给所有管理员'),
              backgroundColor: Color(0xFF059669),
            ),
          );
        }
      } catch (e) {
        print('❌ 发送报警失败: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('报警发送失败: $e'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final sheetHeight = MediaQuery.of(context).size.height * 0.92;
    final cfg = _riskConfig(widget.record['detected_result'] ?? 'unknown');

    return Container(
      height: sheetHeight,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAF9),
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 6),
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('通话详情', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Color(0xFF0F1923))),
                const Spacer(),
                if (widget.isFamily)
                  TextButton.icon(
                    onPressed: _reportToAdmin,
                    icon: const Icon(Icons.security, size: 14),
                    label: const Text('提交审查', style: TextStyle(fontSize: 12)),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                  ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: const Color(0xFFE9F2EC), borderRadius: BorderRadius.circular(12)),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(color: _kAccent, borderRadius: BorderRadius.circular(10)),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: const Color(0xFF6B7280),
              labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              padding: const EdgeInsets.all(3),
              tabs: const [
                Tab(text: '概览'),
                Tab(text: '折线图'),
                Tab(text: '对话'),
                Tab(text: '时间轴'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(cfg),
                _buildTimelineTab(),
                _buildChatTab(),
                _buildAuditTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(_RiskConfig cfg) {
    final isHighRisk = widget.record['detected_result'] == 'fake';
    
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(children: [
          _detailRow('通话时长', '${widget.record['duration'] ?? 0} 秒'),
          _detailRow('检测结果', cfg.label, valueColor: cfg.color),
          ]),
          const SizedBox(height: 12),
          _sectionCard(children: [
            Row(children: const [
              Icon(Icons.smart_toy_rounded, color: _kAccent, size: 17),
              SizedBox(width: 6),
              Text('大模型智能评价', style: TextStyle(fontWeight: FontWeight.w700, color: _kAccent, fontSize: 14)),
            ]),
            const SizedBox(height: 8),
            Text(
              widget.record['analysis']?.toString().isNotEmpty == true ? widget.record['analysis'] : '暂无智能评价',
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: widget.record['analysis']?.toString().isNotEmpty == true ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
                fontStyle: widget.record['analysis']?.toString().isNotEmpty == true ? FontStyle.normal : FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            Row(children: const [
              Icon(Icons.shield_rounded, color: Color(0xFF059669), size: 17),
              SizedBox(width: 6),
              Text('专属防骗建议', style: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF059669), fontSize: 14)),
            ]),
            const SizedBox(height: 8),
            Text(
              widget.record['advice']?.toString().isNotEmpty == true ? widget.record['advice'] : '暂无防骗建议',
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: widget.record['advice']?.toString().isNotEmpty == true ? const Color(0xFF374151) : const Color(0xFF9CA3AF),
                fontStyle: widget.record['advice']?.toString().isNotEmpty == true ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ]),
          if (isHighRisk) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: const [
                    Icon(Icons.warning_rounded, color: Color(0xFFDC2626), size: 18),
                    SizedBox(width: 8),
                    Text(
                      '检测到高风险诈骗',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _emergencyAlert,
                      icon: const Icon(Icons.emergency_rounded, size: 16),
                      label: const Text('🚨 一键报警', style: TextStyle(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFDC2626),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 11),
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

  Widget _buildTimelineTab() {
    if (_isLoadingTimeline) return const Center(child: CircularProgressIndicator(color: _kAccent));
    if (_timelineError != null) return Center(child: Text(_timelineError!, style: const TextStyle(color: Color(0xFFDC2626))));
    if (_timelinePoints.isEmpty) return _emptyHint(Icons.show_chart_rounded, '暂无检测数据');

    List<FlSpot> spots(double Function(_TimelinePoint p) getter) {
      final spots = <FlSpot>[];
      final seenX = <double>{};
      for (final p in _timelinePoints) {
        double x = p.timeOffset.toDouble();
        // 如果有重复的 x 值，添加微小偏移避免插值异常
        while (seenX.contains(x)) {
          x += 0.01;
        }
        seenX.add(x);
        spots.add(FlSpot(x, getter(p)));
      }
      return spots;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('三模态风险评分折线图', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF0F1923))),
          const SizedBox(height: 4),
          Row(children: [
            _legend('语音', const Color(0xFF3B82F6)),
            const SizedBox(width: 12),
            _legend('视频', const Color(0xFF10B981)),
            const SizedBox(width: 12),
            _legend('文本', const Color(0xFFF59E0B)),
            const SizedBox(width: 12),
            _legend('综合', const Color(0xFFDC2626)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: 100,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 25,
                  getDrawingHorizontalLine: (_) => FlLine(color: const Color(0xFFE5E7EB), strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 25,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      getTitlesWidget: (v, _) => Text('${v.toInt()}s', style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
                    ),
                  ),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                lineBarsData: [
                  _lineBar(spots((p) => p.voiceScore), const Color(0xFF3B82F6)),
                  _lineBar(spots((p) => p.videoScore), const Color(0xFF10B981)),
                  _lineBar(spots((p) => p.textScore), const Color(0xFFF59E0B)),
                  _lineBar(spots((p) => p.overallScore), const Color(0xFFDC2626), dotted: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ..._timelinePoints.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            final isFirst = i == 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isFirst)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(height: 1, color: const Color(0xFFE5E7EB)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 8, right: 8),
                  child: Row(
                    children: [
                      Text(
                        '${p.timeOffset}s',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                      ),
                      const SizedBox(width: 12),
                      _scoreChip('语音', p.voiceScore, const Color(0xFF3B82F6)),
                      const SizedBox(width: 6),
                      _scoreChip('视频', p.videoScore, const Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      _scoreChip('文本', p.textScore, const Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      _scoreChip('综合', p.overallScore, const Color(0xFFDC2626)),
                      const Spacer(),
                      if (p.logId != null)
                        GestureDetector(
                          onTap: () => _showEvidenceDetail(p.logId!),
                          child: const Icon(Icons.image_search_rounded, size: 16, color: _kAccent),
                        ),
                    ],
                  ),
                ),
                if (p.keywords.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(p.keywords, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
                  ),
                ],
                const SizedBox(height: 10),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    if (_isLoadingChat) return const Center(child: CircularProgressIndicator(color: _kAccent));
    if (_chatError != null) return Center(child: Text(_chatError!, style: const TextStyle(color: Color(0xFFDC2626))));
    if (_chatMessages.isEmpty) return _emptyHint(Icons.chat_bubble_outline_rounded, '暂无对话记录');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _chatMessages.length,
      itemBuilder: (_, i) {
        final msg = _chatMessages[i];
        final isUser = msg.role == 'user';
        final bubbleColor = isUser ? _kAccent : Colors.white;
        final textColor = isUser ? Colors.white : const Color(0xFF374151);

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[_avatar(false), const SizedBox(width: 8)],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isUser ? 16 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 16),
                    ),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6, offset: const Offset(0, 2))],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(msg.content, style: TextStyle(fontSize: 13, color: textColor, height: 1.5)),
                      if (msg.timestamp != null) ...[
                        const SizedBox(height: 4),
                        Text(_fmtTs(msg.timestamp!), style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.55))),
                      ],
                    ],
                  ),
                ),
              ),
              if (isUser) ...[const SizedBox(width: 8), _avatar(true)],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuditTab() {
    if (_isLoadingLogs) return const Center(child: CircularProgressIndicator(color: _kAccent));
    if (_logsError != null) return Center(child: Text(_logsError!, style: const TextStyle(color: Color(0xFFDC2626))));
    if (_auditEvents.isEmpty) return _emptyHint(Icons.check_circle_outline_rounded, '暂无异常记录');

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: _auditEvents.length,
      itemBuilder: (_, i) {
        final e = _auditEvents[i];
        final isAlert = e.type == 'alert';
        final dotColor = isAlert ? const Color(0xFFDC2626) : _kAccent;

        return TimelineTile(
          axis: TimelineAxis.vertical,
          alignment: TimelineAlign.start,
          isFirst: i == 0,
          isLast: i == _auditEvents.length - 1,
          indicatorStyle: IndicatorStyle(
            width: 36,
            height: 36,
            padding: const EdgeInsets.symmetric(vertical: 6),
            indicator: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: dotColor.withOpacity(0.12),
                border: Border.all(color: dotColor, width: 2),
              ),
              child: Icon(isAlert ? Icons.warning_amber_rounded : Icons.radar_rounded, size: 17, color: dotColor),
            ),
          ),
          beforeLineStyle: const LineStyle(color: Color(0xFFE5E7EB), thickness: 2),
          afterLineStyle: const LineStyle(color: Color(0xFFE5E7EB), thickness: 2),
          endChild: Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 14, top: 2),
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isAlert ? const Color(0xFFDC2626).withOpacity(0.25) : _kAccent.withOpacity(0.2),
                  width: 1.2,
                ),
                boxShadow: [BoxShadow(color: dotColor.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          e.title,
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: isAlert ? const Color(0xFFDC2626) : const Color(0xFF0F1923)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: dotColor.withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                        child: Text(e.timeDisplay, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: dotColor)),
                      ),
                    ],
                  ),
                  if (e.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(e.description, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.5)),
                  ],
                  if (e.logId != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: GestureDetector(
                        onTap: () => _showEvidenceDetail(e.logId!),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.image_search_rounded, size: 14, color: _kAccent),
                            SizedBox(width: 4),
                            Text('查看证据', style: TextStyle(fontSize: 12, color: _kAccent, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _legend(String label, Color color) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 3, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        ],
      );

  Widget _scoreChip(String label, double score, Color color) => Text(
        '$label: ${score.toStringAsFixed(0)}',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      );

  LineChartBarData _lineBar(List<FlSpot> spots, Color color, {bool dotted = false}) => LineChartBarData(
        spots: spots,
        isCurved: true,
        curveSmoothness: 0.5,
        color: color,
        barWidth: dotted ? 1.5 : 2,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(show: false),
      );

  Widget _avatar(bool isUser) => Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: isUser ? _kAccent.withOpacity(0.15) : const Color(0xFFE5E7EB),
          shape: BoxShape.circle,
        ),
        child: Icon(isUser ? Icons.person_rounded : Icons.smart_toy_rounded, size: 16, color: isUser ? _kAccent : const Color(0xFF9CA3AF)),
      );

  String _fmtTs(String ts) {
    try {
      final dt = DateTime.parse(ts);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return ts;
    }
  }

  Widget _emptyHint(IconData icon, String text) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Text(text, style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          ],
        ),
      );

  Widget _detailRow(String label, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))),
            Expanded(child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? const Color(0xFF0F1923)))),
          ],
        ),
      );
}

class _EvidenceDetailSheet extends StatefulWidget {
  final int callId;
  final int logId;

  const _EvidenceDetailSheet({required this.callId, required this.logId});

  @override
  State<_EvidenceDetailSheet> createState() => _EvidenceDetailSheetState();
}

class _EvidenceDetailSheetState extends State<_EvidenceDetailSheet> {
  bool _loading = true;
  Map<String, dynamic>? _evidence;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final r = await dioRequest.get('/api/call-records/${widget.callId}/evidence/${widget.logId}');
      if (r != null && r['data'] != null) {
        setState(() {
          _evidence = r['data'];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      setState(() {
        _error = '无法加载证据详情';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Text('证据详情', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F1923))),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF6B7280)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _kAccent))
                : _error != null
                    ? Center(child: Text(_error!, style: const TextStyle(color: Color(0xFFDC2626))))
                    : _evidence == null
                        ? const Center(child: Text('暂无证据数据', style: TextStyle(color: Color(0xFF9CA3AF))))
                        : SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_evidence!['screenshot_url'] != null) ...[
                                  const Text('截图证据', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F1923))),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _evidence!['screenshot_url'],
                                      width: double.infinity,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) => Container(
                                        height: 80,
                                        color: const Color(0xFFF3F4F6),
                                        child: const Center(child: Icon(Icons.broken_image_rounded, color: Color(0xFF9CA3AF))),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (_evidence!['ocr_text'] != null) ...[
                                  const Text('OCR 识别文本', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F1923))),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAF9),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: Text(_evidence!['ocr_text'], style: const TextStyle(fontSize: 13, color: Color(0xFF374151), height: 1.6)),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                if (_evidence!['algorithm_details'] != null) ...[
                                  const Text('算法检测详情', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F1923))),
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8FAF9),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0xFFE5E7EB)),
                                    ),
                                    child: Text(
                                      _evidence!['algorithm_details'].toString(),
                                      style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.6),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
