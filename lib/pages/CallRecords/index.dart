import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';

class CallRecordsPage extends StatefulWidget {
  const CallRecordsPage({super.key});

  @override
  State<CallRecordsPage> createState() => _CallRecordsPageState();
}

class _CallRecordsPageState extends State<CallRecordsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
          '通话记录',
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
                  Tab(text: '我的记录'),
                  Tab(text: '家庭记录'),
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
          CallRecordsList(isFamily: false),
          CallRecordsList(isFamily: true),
        ],
      ),
    );
  }
}

// ==================== 通话记录列表 ====================
class CallRecordsList extends StatefulWidget {
  final bool isFamily;
  
  const CallRecordsList({super.key, required this.isFamily});

  @override
  State<CallRecordsList> createState() => _CallRecordsListState();
}

class _CallRecordsListState extends State<CallRecordsList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  
  bool _isLoading = true;
  List<dynamic> _records = [];
  String? _errorMessage;
  int _currentPage = 1;
  int _totalPages = 1;
  String? _resultFilter;
  
  final ScrollController _scrollController = ScrollController();

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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _currentPage < _totalPages) {
        _loadMoreRecords();
      }
    }
  }

  Future<void> _loadRecords({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _records = [];
      });
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final endpoint = widget.isFamily 
          ? '/api/call-records/family-records'
          : '/api/call-records/my-records';
      
      final params = {
        'page': _currentPage,
        'page_size': 20,
        if (_resultFilter != null) 'result_filter': _resultFilter,
      };
      
      final response = await dioRequest.get(endpoint, params: params);
      
      if (response != null && response['data'] != null) {
        final records = response['data']['records'] as List;
        final pagination = response['data']['pagination'];
        
        setState(() {
          if (refresh) {
            _records = records;
          } else {
            _records.addAll(records);
          }
          _totalPages = pagination['total_pages'] ?? 1;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 加载通话记录失败: $e');
      setState(() {
        _errorMessage = '加载失败，请稍后重试';
        _isLoading = false;
      });
    }
  }
  
  Future<void> _loadMoreRecords() async {
    setState(() {
      _currentPage++;
    });
    await _loadRecords();
  }
  
  Future<void> _deleteRecord(int callId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          '删除记录',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '确定要删除这条通话记录吗？',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('删除', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await dioRequest.delete('/api/call-records/record/$callId');
        _showSuccess('删除成功');
        _loadRecords(refresh: true);
      } catch (e) {
        _showError('删除失败: $e');
      }
    }
  }
  
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          '筛选记录',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFilterOption('全部', null),
            _buildFilterOption('安全', 'safe'),
            _buildFilterOption('可疑', 'suspicious'),
            _buildFilterOption('危险', 'fake'),
          ],
        ),
      ),
    );
  }
  
  Widget _buildFilterOption(String label, String? value) {
    final isSelected = _resultFilter == value;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: isSelected ? Icon(Icons.check, color: AppColors.primary) : null,
      onTap: () {
        setState(() {
          _resultFilter = value;
        });
        Navigator.pop(context);
        _loadRecords(refresh: true);
      },
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    if (_isLoading && _records.isEmpty) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    
    if (_errorMessage != null && _records.isEmpty) {
      return _buildErrorView();
    }
    
    if (_records.isEmpty) {
      return _buildEmptyView();
    }
    
    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _loadRecords(refresh: true),
            color: AppColors.primary,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(AppTheme.paddingMedium),
              itemCount: _records.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _records.length) {
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.paddingMedium),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ),
                  );
                }
                return _buildRecordCard(_records[index]);
              },
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFilterBar() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppTheme.paddingMedium,
        vertical: AppTheme.paddingSmall,
      ),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        border: Border(
          bottom: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, size: 18, color: AppColors.textSecondary),
          SizedBox(width: AppTheme.paddingSmall),
          Text(
            _resultFilter == null ? '全部记录' :
            _resultFilter == 'safe' ? '安全记录' :
            _resultFilter == 'suspicious' ? '可疑记录' : '危险记录',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppColors.textSecondary,
            ),
          ),
          Spacer(),
          TextButton(
            onPressed: _showFilterDialog,
            child: Text(
              '筛选',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecordCard(Map<String, dynamic> record) {
    final callId = record['call_id'];
    final callerNumber = record['caller_number'] ?? '未知号码';
    final startTime = record['start_time'] ?? '';
    final duration = record['duration'] ?? 0;
    final result = record['detected_result'] ?? 'unknown';
    
    Color resultColor;
    IconData resultIcon;
    String resultText;
    
    switch (result) {
      case 'safe':
        resultColor = AppColors.success;
        resultIcon = Icons.check_circle;
        resultText = '安全';
        break;
      case 'suspicious':
        resultColor = AppColors.warning;
        resultIcon = Icons.warning;
        resultText = '可疑';
        break;
      case 'fake':
        resultColor = AppColors.error;
        resultIcon = Icons.dangerous;
        resultText = '危险';
        break;
      default:
        resultColor = AppColors.textSecondary;
        resultIcon = Icons.help_outline;
        resultText = '未检测';
    }
    
    return Container(
      margin: EdgeInsets.only(bottom: AppTheme.paddingMedium),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: AppTheme.shadowSmall,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // TODO: 跳转到详情页
            _showRecordDetail(record);
          },
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          child: Padding(
            padding: EdgeInsets.all(AppTheme.paddingMedium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: resultColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(resultIcon, color: resultColor, size: 20),
                    ),
                    SizedBox(width: AppTheme.paddingMedium),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            callerNumber,
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _formatDateTime(startTime),
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeSmall,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: resultColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                        border: Border.all(color: resultColor),
                      ),
                      child: Text(
                        resultText,
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: resultColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: AppTheme.paddingSmall),
                Divider(height: 1, color: AppColors.borderLight),
                SizedBox(height: AppTheme.paddingSmall),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 4),
                    Text(
                      '通话时长: ${_formatDuration(duration)}',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                      onPressed: () => _deleteRecord(callId),
                      padding: EdgeInsets.zero,
                      constraints: BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_disabled, size: 80, color: AppColors.textSecondary),
            SizedBox(height: AppTheme.paddingLarge),
            Text(
              widget.isFamily ? '暂无家庭通话记录' : '暂无通话记录',
              style: TextStyle(
                fontSize: AppTheme.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.paddingMedium),
            Text(
              widget.isFamily 
                  ? '家庭成员的通话记录会显示在这里'
                  : '您的通话记录会显示在这里',
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
  
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 80, color: AppColors.error),
            SizedBox(height: AppTheme.paddingLarge),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppTheme.paddingLarge),
            ElevatedButton.icon(
              onPressed: () => _loadRecords(refresh: true),
              icon: Icon(Icons.refresh),
              label: Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
                padding: EdgeInsets.symmetric(
                  horizontal: AppTheme.paddingLarge,
                  vertical: AppTheme.paddingMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
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
  
  String _formatDateTime(String dateTime) {
    try {
      final dt = DateTime.parse(dateTime);
      final now = DateTime.now();
      final diff = now.difference(dt);
      
      if (diff.inDays == 0) {
        return '今天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return '昨天 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dt.month}-${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      }
    } catch (e) {
      return dateTime;
    }
  }
  
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes}分${secs}秒';
  }
}

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
