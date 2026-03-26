from pathlib import Path

path = Path(r"E:/wangtiao/ai_anti_fraud_detection_system_frontend/lib/pages/CallRecords/index.dart")
text = path.read_text(encoding="utf-8")
marker = "// ==================== 详情弹窗 ===================="
head = text.split(marker)[0]

new_tail = '''// ==================== 详情弹窗 ====================

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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(children: [
            _detailRow('通话时长', '${widget.record['duration'] ?? 0} 秒'),
            _detailRowWidget(
              '检测结果',
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: cfg.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cfg.color.withOpacity(0.35)),
                ),
                child: Text(cfg.label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: cfg.color)),
              ),
            ),
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
        ],
      ),
    );
  }

  Widget _buildTimelineTab() {
    if (_isLoadingTimeline) return const Center(child: CircularProgressIndicator(color: _kAccent));
    if (_timelineError != null) return Center(child: Text(_timelineError!, style: const TextStyle(color: Color(0xFFDC2626))));
    if (_timelinePoints.isEmpty) return _emptyHint(Icons.show_chart_rounded, '暂无检测数据');

    List<FlSpot> spots(double Function(_TimelinePoint p) getter) {
      return _timelinePoints.map((p) => FlSpot(p.timeOffset.toDouble(), getter(p))).toList();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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
          ..._timelinePoints.map((p) {
            final color = p.riskLevel == 'high'
                ? const Color(0xFFDC2626)
                : p.riskLevel == 'medium'
                    ? const Color(0xFFD97706)
                    : const Color(0xFF059669);

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: color.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Center(
                      child: Text('${p.timeOffset}s', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          _scoreChip('语', p.voiceScore, const Color(0xFF3B82F6)),
                          const SizedBox(width: 4),
                          _scoreChip('视', p.videoScore, const Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          _scoreChip('文', p.textScore, const Color(0xFFF59E0B)),
                          const SizedBox(width: 4),
                          _scoreChip('综', p.overallScore, const Color(0xFFDC2626)),
                        ]),
                        if (p.keywords.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('关键词: ${p.keywords}', style: const TextStyle(fontSize: 11, color: Color(0xFF6B7280))),
                        ],
                      ],
                    ),
                  ),
                  if (p.logId != null)
                    GestureDetector(
                      onTap: () => _showEvidenceDetail(p.logId!),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.image_search_rounded, size: 18, color: _kAccent),
                      ),
                    ),
                ],
              ),
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

  Widget _scoreChip(String label, double score, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
        child: Text('$label ${score.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700)),
      );

  LineChartBarData _lineBar(List<FlSpot> spots, Color color, {bool dotted = false}) => LineChartBarData(
        spots: spots,
        isCurved: true,
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

  Widget _detailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))),
            Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0F1923)))),
          ],
        ),
      );

  Widget _detailRowWidget(String label, Widget w) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(width: 72, child: Text(label, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)))),
            w,
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
'''

path.write_text(head + new_tail, encoding="utf-8")
print("rewritten")

