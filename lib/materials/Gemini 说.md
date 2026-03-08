## Gemini 说

为了在 Flutter 前端实现这个功能，我们需要将 `lib/pages/CallRecords/index.dart` 文件中的 `CallRecordDetailSheet` 从无状态组件 (`StatelessWidget`) 改为有状态组件 (`StatefulWidget`)。

这样我们可以在用户点开弹窗时，去请求后端的 `/api/call-records/{call_id}/audit-logs` 接口，并将获取到的**AI多模态扫描记录**（线索）、**告警事件**以及**LLM最终评价**按时间轴渲染出来。同时，我们为其添加一个“上报给系统管理员审查”的按钮供家庭组长使用。

请将 `lib/pages/CallRecords/index.dart` 中最下方的 `CallRecordDetailSheet` 类**替换**为以下代码：

Dart

```
// ==================== 通话记录详情 (包含审计日志与LLM评价) ====================
class CallRecordDetailSheet extends StatefulWidget {
  final Map<String, dynamic> record;
  final bool isFamily; // 传入是否是家庭组记录，用于判断是否显示上报按钮

  const CallRecordDetailSheet({super.key, required this.record, this.isFamily = false});

  @override
  State<CallRecordDetailSheet> createState() => _CallRecordDetailSheetState();
}

class AuditEvent {
  final int timeValue;
  final String timeDisplay;
  final String type;
  final String title;
  final String description;
  final String? evidenceUrl;

  AuditEvent({
    required this.timeValue,
    required this.timeDisplay,
    required this.type,
    required this.title,
    required this.description,
    this.evidenceUrl,
  });
}

class _CallRecordDetailSheetState extends State<CallRecordDetailSheet> {
  bool _isLoadingLogs = true;
  List<AuditEvent> _auditEvents = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAuditLogs();
  }

  // 1. 获取审计日志并合并排序
  Future<void> _fetchAuditLogs() async {
    try {
      final callId = widget.record['call_id'];
      final response = await dioRequest.get('/api/call-records/$callId/audit-logs');
      
      if (response != null && response['data'] != null) {
        final data = response['data'];
        List<AuditEvent> events = [];
        
        // 转换底层 AI 检测日志 (线索)
        for (var ai in data['ai_events'] ?? []) {
          final score = ai['overall_score'] ?? 0;
          if (score > 50) { // 过滤掉无风险的噪音
            events.add(AuditEvent(
              timeValue: ai['time_offset'] ?? 0, // 用偏移量排序
              timeDisplay: '通话第 ${ai['time_offset']} 秒',
              type: 'ai_scan',
              title: '多模态AI扫描点',
              description: '综合风险评分: ${score.toStringAsFixed(1)} (语音: ${(ai['voice_conf'] ?? 0).toStringAsFixed(2)})',
              evidenceUrl: ai['evidence_url'],
            ));
          }
        }
        
        // 转换告警触发日志
        for (var alert in data['alert_events'] ?? []) {
          // 尽量将其转换为时间戳进行排序
          int timeVal = 999999; 
          String displayTime = '系统警报';
          if (alert['created_at'] != null) {
            final dt = DateTime.tryParse(alert['created_at']);
            if (dt != null) {
              timeVal = dt.millisecondsSinceEpoch ~/ 1000;
              displayTime = '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';
            }
          }

          events.add(AuditEvent(
            timeValue: timeVal,
            timeDisplay: displayTime,
            type: 'alert',
            title: alert['title'] ?? '触发警报',
            description: alert['content'] ?? '',
          ));
        }
        
        // 按时间排序
        events.sort((a, b) => a.timeValue.compareTo(b.timeValue));
        
        setState(() {
          _auditEvents = events;
          _isLoadingLogs = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '无法加载审计日志';
        _isLoadingLogs = false;
      });
    }
  }

  // 2. 提交审查请求
  Future<void> _reportToAdmin() async {
    final callId = widget.record['call_id'];
    
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        title: Text('提交审查', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('确定将该通话作为新型诈骗案例提交给系统防诈中心供智能体学习吗？', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('取消')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('提交', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await dioRequest.post('/api/call-records/$callId/report-to-admin');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已成功提交至系统防诈中心待审核队列'), backgroundColor: AppColors.success));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('提交失败: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 设置弹窗高度占据屏幕 85%，以便有足够空间展示滚动日志
    final sheetHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusLarge),
          topRight: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部标题和关闭按钮
          Row(
            children: [
              Text(
                '通话审计详情',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Spacer(),
              IconButton(
                icon: Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          
          // 基本信息区
          Container(
            padding: EdgeInsets.all(AppTheme.paddingMedium),
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            ),
            child: Column(
              children: [
                _buildDetailRow('来电号码', widget.record['caller_number'] ?? '未知'),
                _buildDetailRow('通话时长', '${widget.record['duration'] ?? 0}秒'),
                _buildDetailRow('最终结果', _getResultText(widget.record['detected_result'])),
              ],
            ),
          ),
          
          SizedBox(height: AppTheme.paddingMedium),

          // LLM 最终评价 (从 record 中读取后端 LLM 分析字段，例如 analysis / llm_evaluation)
          if (widget.record['analysis'] != null || widget.record['llm_evaluation'] != null)
            Container(
              padding: EdgeInsets.all(AppTheme.paddingMedium),
              margin: EdgeInsets.only(bottom: AppTheme.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.05),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.smart_toy, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('大模型智能评价', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.record['analysis'] ?? widget.record['llm_evaluation'] ?? '无',
                    style: TextStyle(fontSize: AppTheme.fontSizeSmall, color: AppColors.textPrimary, height: 1.5),
                  ),
                ],
              ),
            ),

          // 审计事件时间轴标题与提交审查按钮
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '警报与线索时间轴',
                style: TextStyle(fontSize: AppTheme.fontSizeLarge, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              // 如果是家庭记录（且当前用户是组长），显示提交按钮
              if (widget.isFamily) 
                ElevatedButton.icon(
                  onPressed: _reportToAdmin,
                  icon: Icon(Icons.security, size: 16),
                  label: Text('提交审查', style: TextStyle(fontSize: AppTheme.fontSizeSmall)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppTheme.paddingSmall),

          // 审计日志列表展示区
          Expanded(
            child: _isLoadingLogs 
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _errorMessage != null
                ? Center(child: Text(_errorMessage!, style: TextStyle(color: AppColors.error)))
                : _auditEvents.isEmpty
                  ? Center(child: Text('暂无异常记录', style: TextStyle(color: AppColors.textSecondary)))
                  : ListView.builder(
                      itemCount: _auditEvents.length,
                      itemBuilder: (context, index) {
                        final event = _auditEvents[index];
                        final isAlert = event.type == 'alert';
                        
                        return Container(
                          margin: EdgeInsets.only(bottom: AppTheme.paddingMedium),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 左侧时间与指示线
                              Column(
                                children: [
                                  Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isAlert ? AppColors.error : AppColors.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  if (index != _auditEvents.length - 1)
                                    Container(
                                      width: 2,
                                      height: event.evidenceUrl != null ? 100 : 50, // 简易时间轴连线高度
                                      color: AppColors.borderMedium,
                                    )
                                ],
                              ),
                              SizedBox(width: AppTheme.paddingMedium),
                              // 右侧内容卡片
                              Expanded(
                                child: Container(
                                  padding: EdgeInsets.all(AppTheme.paddingMedium),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBackground,
                                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                    border: Border.all(
                                      color: isAlert ? AppColors.error.withOpacity(0.5) : AppColors.borderLight,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(event.title, style: TextStyle(fontWeight: FontWeight.bold, color: isAlert ? AppColors.error : AppColors.textPrimary)),
                                          Text(event.timeDisplay, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                        ],
                                      ),
                                      SizedBox(height: 4),
                                      Text(event.description, style: TextStyle(fontSize: AppTheme.fontSizeSmall, color: AppColors.textSecondary)),
                                      
                                      // 如果包含留存的截图证据
                                      if (event.evidenceUrl != null && event.evidenceUrl!.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 8.0),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(4),
                                            child: Image.network(
                                              event.evidenceUrl!,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (c, e, s) => Container(color: Colors.grey[200], width: 100, height: 100, child: Icon(Icons.broken_image)),
                                            ),
                                          ),
                                        )
                                    ],
                                  ),
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(fontSize: AppTheme.fontSizeSmall, color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: AppTheme.fontSizeMedium, color: AppColors.textPrimary, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _getResultText(String? result) {
    switch (result) {
      case 'safe': return '✅ 安全';
      case 'suspicious': return '⚠️ 可疑';
      case 'fake': return '❌ 危险';
      default: return '❓ 未检测';
    }
  }
}
```

### 修改说明：

1. **从 Stateless 变成 Stateful**：把 `CallRecordDetailSheet` 改为有状态组件，并在 `initState` 中触发 `_fetchAuditLogs()`，这样一点开卡片就会从后端拉取该通话的详细“线索”和“警报”。
2. **警报与线索时间轴合并**：与后端的 `/audit-logs` 接口对接，将在时间轴上渲染底层雷达抓取到的线索（AI 多模态扫描高危点，例如画面、声音异常），以及触发的系统告警（Alert Events）。
3. **大模型智能评价 (LLM Evaluation) 展示**：增加了一个带图标的显眼区块，如果后端返回的 `record` 字典中包含 `analysis` 或 `llm_evaluation` 字段（LLM 分析出的总结），就会在这里直接展示。
4. **家庭组长提交审查**：接收传入的 `isFamily` 参数。如果在“家庭记录”下打开，右上角会出现一个红色的“提交审查”按钮。点击后会调用 `/api/call-records/{call_id}/report-to-admin`，完成闭环。

**注意**：在调用该 `CallRecordDetailSheet` 时，原本 `CallRecordsList` 里面第 310 行左右的代码，记得把 `isFamily` 传递进去：

Dart

```
  void _showRecordDetail(Map<String, dynamic> record) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CallRecordDetailSheet(
        record: record, 
        isFamily: widget.isFamily, // 传入此字段以控制是否显示报告按钮
      ),
    );
  }
```