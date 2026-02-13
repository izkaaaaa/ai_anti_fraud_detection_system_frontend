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
      builder: (context) => CallRecordDetailSheet(record: record),
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

// ==================== 通话记录详情 ====================
class CallRecordDetailSheet extends StatelessWidget {
  final Map<String, dynamic> record;
  
  const CallRecordDetailSheet({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusLarge),
          topRight: Radius.circular(AppTheme.radiusLarge),
        ),
      ),
      padding: EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '通话详情',
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
          SizedBox(height: AppTheme.paddingLarge),
          _buildDetailRow('来电号码', record['caller_number'] ?? '未知'),
          _buildDetailRow('开始时间', record['start_time'] ?? ''),
          _buildDetailRow('结束时间', record['end_time'] ?? ''),
          _buildDetailRow('通话时长', '${record['duration'] ?? 0}秒'),
          _buildDetailRow('检测结果', _getResultText(record['detected_result'])),
          if (record['audio_url'] != null) ...[
            SizedBox(height: AppTheme.paddingMedium),
            Text(
              '录音文件',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppTheme.paddingSmall),
            Container(
              padding: EdgeInsets.all(AppTheme.paddingMedium),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Row(
                children: [
                  Icon(Icons.audiotrack, color: AppColors.primary, size: 20),
                  SizedBox(width: AppTheme.paddingSmall),
                  Expanded(
                    child: Text(
                      '录音文件',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(Icons.play_arrow, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ],
          SizedBox(height: AppTheme.paddingLarge),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.paddingMedium),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _getResultText(String? result) {
    switch (result) {
      case 'safe':
        return '✅ 安全';
      case 'suspicious':
        return '⚠️ 可疑';
      case 'fake':
        return '❌ 危险';
      default:
        return '❓ 未检测';
    }
  }
}
