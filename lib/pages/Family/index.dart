import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/family_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/CallRecords/index.dart';
import 'dart:ui';

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  Map<String, dynamic>? _userInfo;
  bool _isAdmin = false;
  String? _errorMessage;
  late TabController _tabController;

  final FamilyService _familyService = FamilyService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 获取用户信息
      _userInfo = await _authService.getCurrentUser();
      
      // 检查是否是管理员
      if (_userInfo != null && _userInfo!['family_id'] != null) {
        try {
          await _familyService.getApplications();
          _isAdmin = true;
        } catch (e) {
          // 如果返回 403，说明不是管理员
          _isAdmin = false;
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 加载数据失败: $e');
      setState(() {
        _errorMessage = '加载失败，请稍后重试';
        _isLoading = false;
      });
    }
  }

  /// 创建家庭组
  Future<void> _createFamily() async {
    final nameController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          '创建家庭组',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '输入家庭组名称',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppTheme.paddingSmall),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                hintText: '例如：我的家庭',
                hintStyle: TextStyle(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  borderSide: BorderSide(color: AppColors.borderMedium),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  borderSide: BorderSide(color: AppColors.primary, width: 2.0),
                ),
              ),
              style: TextStyle(color: AppColors.textPrimary),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                _showError('请输入家庭组名称');
                return;
              }
              
              try {
                final result = await _familyService.createFamily(nameController.text.trim());
                
                if (result != null) {
                Navigator.pop(context, true);
                  _showSuccess('家庭组创建成功！ID: ${result['family_id']}');
                }
              } catch (e) {
                _showError('创建失败: $e');
              }
            },
            child: Text('创建', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (result == true) {
      await _loadData();
    }
  }

  /// 申请加入家庭组
  Future<void> _joinFamily() async {
    final idController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          '加入家庭组',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '输入家庭组ID',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppTheme.paddingSmall),
            TextField(
              controller: idController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '例如：1',
                hintStyle: TextStyle(color: AppColors.textLight),
                filled: true,
                fillColor: AppColors.inputBackground,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  borderSide: BorderSide(color: AppColors.borderMedium),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  borderSide: BorderSide(color: AppColors.primary, width: 2.0),
                ),
              ),
              style: TextStyle(color: AppColors.textPrimary),
            ),
            SizedBox(height: AppTheme.paddingSmall),
            Container(
              padding: EdgeInsets.all(AppTheme.paddingSmall),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '申请后需等待管理员审批',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: Colors.blue[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              if (idController.text.trim().isEmpty) {
                _showError('请输入家庭组ID');
                return;
              }
              
              try {
                final familyId = int.parse(idController.text.trim());
                final success = await _familyService.applyToJoin(familyId);
                
                if (success) {
                Navigator.pop(context, true);
                  _showSuccess('申请已发送，等待管理员审批');
                }
              } catch (e) {
                _showError('申请失败: $e');
              }
            },
            child: Text('申请', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: _userInfo?['family_id'] != null && _isAdmin
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                '家庭组',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadData,
                ),
              ],
              bottom: PreferredSize(
                preferredSize: Size.fromHeight(50),
                child: TabBar(
                  controller: _tabController,
                  labelColor: Color(0xFF00F5A0),
                  unselectedLabelColor: Colors.white.withOpacity(0.6),
                  indicatorColor: Color(0xFF00F5A0),
                  indicatorWeight: 3,
                  labelStyle: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.w700,
                  ),
                  tabs: [
                    Tab(text: '申请管理'),
                    Tab(text: '成员管理'),
                  ],
                ),
              ),
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: Text(
                '家庭组',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.refresh, color: Colors.white),
                  onPressed: _loadData,
                ),
              ],
            ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A237E),
              Color(0xFF283593),
              Color(0xFF3949AB),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.white))
              : _errorMessage != null
                  ? _buildErrorView()
                  : _userInfo?['family_id'] == null
                      ? _buildNoFamilyView()
                      : _isAdmin
                          ? TabBarView(
                              controller: _tabController,
                              children: [
                                ApplicationsTab(familyService: _familyService),
                                MembersTab(familyService: _familyService),
                              ],
                            )
                          : _buildMemberOnlyView(),
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
            Icon(Icons.error_outline, size: 80, color: Colors.white.withOpacity(0.7)),
            SizedBox(height: AppTheme.paddingLarge),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                color: Colors.white,
              ),
            ),
            SizedBox(height: AppTheme.paddingLarge),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: Icon(Icons.refresh),
              label: Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
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

  Widget _buildNoFamilyView() {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
              ),
              child: Icon(
                Icons.family_restroom,
                size: 80,
                color: Colors.white,
              ),
            ),
            SizedBox(height: AppTheme.paddingXLarge),
            Text(
              '还没有加入家庭组',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            SizedBox(height: AppTheme.paddingMedium),
            Text(
              '创建或加入家庭组\n与家人共享防诈骗保护',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: Colors.white.withOpacity(0.8),
                height: 1.5,
              ),
            ),
            SizedBox(height: AppTheme.paddingXLarge),
            
            // 创建家庭组按钮
            Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: LinearGradient(
                  colors: [Color(0xFF00F5A0), Color(0xFF00D9F5)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFF00F5A0).withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _createFamily,
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_circle_outline, size: 28, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          '创建家庭组',
                  style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: AppTheme.paddingMedium),
            
            // 加入家庭组按钮
            Container(
              width: double.infinity,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _joinFamily,
                  borderRadius: BorderRadius.circular(32),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.group_add, size: 28, color: Colors.white),
                        SizedBox(width: 12),
                        Text(
                          '加入家庭组',
                style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberOnlyView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFamilyInfoCard(),
          SizedBox(height: AppTheme.paddingMedium),
          Container(
            padding: EdgeInsets.all(AppTheme.paddingLarge),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.info_outline, size: 60, color: Colors.white.withOpacity(0.7)),
                SizedBox(height: AppTheme.paddingMedium),
                Text(
                  '您是家庭组成员',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: AppTheme.paddingSmall),
                Text(
                  '只有管理员可以查看申请和成员信息',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFamilyInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(AppTheme.paddingLarge * 1.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                      padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                        color: Color(0xFF00F5A0).withOpacity(0.2),
                  shape: BoxShape.circle,
                        border: Border.all(
                          color: Color(0xFF00F5A0).withOpacity(0.5),
                          width: 2,
                        ),
                ),
                child: Icon(
                  Icons.family_restroom,
                        size: 36,
                        color: Color(0xFF00F5A0),
                ),
              ),
                    SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                            '家庭组 ${_userInfo!['family_id']}',
                      style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                            _isAdmin ? '管理员' : '成员',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                              color: Colors.white.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
                SizedBox(height: AppTheme.paddingLarge),
          
          Container(
                  padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
            ),
                  ),
            child: Row(
              children: [
                      Icon(Icons.vpn_key, size: 20, color: Colors.white.withOpacity(0.7)),
                      SizedBox(width: 12),
                Text(
                        '家庭组ID',
                  style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Spacer(),
                Text(
                        '${_userInfo!['family_id']}',
                  style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF00F5A0),
                    letterSpacing: 2,
                  ),
                ),
                      SizedBox(width: 12),
                IconButton(
                        icon: Icon(Icons.copy, size: 20, color: Color(0xFF00F5A0)),
                  onPressed: () {
                          Clipboard.setData(ClipboardData(text: '${_userInfo!['family_id']}'));
                          _showSuccess('ID已复制');
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
          
          SizedBox(height: AppTheme.paddingMedium),
          
          // 退出家庭组按钮
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _leaveFamily,
              icon: Icon(Icons.exit_to_app, size: 20),
              label: Text('退出家庭组', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.2),
                foregroundColor: Colors.red[300],
                padding: EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.red.withOpacity(0.5), width: 1.5),
                ),
              ),
            ),
          ),
        ],
            ),
          ),
        ),
      ),
    );
  }
  
  /// 退出家庭组
  Future<void> _leaveFamily() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          '退出家庭组',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '确定要退出当前家庭组吗？退出后将无法查看家庭成员的通话记录。',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('退出', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await _familyService.leaveFamily();
        if (success) {
          _showSuccess('已退出家庭组');
          await _loadData(); // 重新加载数据
        }
      } catch (e) {
        _showError('退出失败: $e');
      }
    }
  }

}

// ==================== 申请管理标签页 ====================
class ApplicationsTab extends StatefulWidget {
  final FamilyService familyService;

  const ApplicationsTab({super.key, required this.familyService});

  @override
  State<ApplicationsTab> createState() => _ApplicationsTabState();
}

class _ApplicationsTabState extends State<ApplicationsTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  List<Map<String, dynamic>> _applications = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final apps = await widget.familyService.getApplications();
      setState(() {
        _applications = apps;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败';
        _isLoading = false;
      });
    }
  }

  Future<void> _reviewApplication(int appId, bool isApprove) async {
    try {
      final success = await widget.familyService.reviewApplication(appId, isApprove);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isApprove ? '已同意申请' : '已拒绝申请'),
            backgroundColor: AppColors.success,
          ),
        );
        await _loadApplications();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('操作失败: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.white.withOpacity(0.7)),
            SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.white)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadApplications,
              child: Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_applications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.white.withOpacity(0.5)),
            SizedBox(height: 16),
            Text(
              '暂无待审批申请',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: Color(0xFF00F5A0),
      child: ListView.builder(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        itemCount: _applications.length,
        itemBuilder: (context, index) {
          final app = _applications[index];
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.person, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app['phone'] ?? '未知用户',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeMedium,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            app['apply_time'] ?? '',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeSmall,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _reviewApplication(app['application_id'], false),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('拒绝', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _reviewApplication(app['application_id'], true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00F5A0),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('同意', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==================== 成员管理标签页 ====================
class MembersTab extends StatefulWidget {
  final FamilyService familyService;

  const MembersTab({super.key, required this.familyService});

  @override
  State<MembersTab> createState() => _MembersTabState();
}

class _MembersTabState extends State<MembersTab> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = true;
  List<Map<String, dynamic>> _members = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final members = await widget.familyService.getMembers();
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败';
        _isLoading = false;
      });
    }
  }

  void _viewMemberRecords(Map<String, dynamic> member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberRecordsPage(member: member),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 60, color: Colors.white.withOpacity(0.7)),
            SizedBox(height: 16),
            Text(_errorMessage!, style: TextStyle(color: Colors.white)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMembers,
              child: Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_members.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 80, color: Colors.white.withOpacity(0.5)),
            SizedBox(height: 16),
            Text(
              '暂无成员',
              style: TextStyle(
                fontSize: 18,
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      color: Color(0xFF00F5A0),
      child: ListView.builder(
        padding: EdgeInsets.all(AppTheme.paddingMedium),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          final isAdmin = member['is_admin'] == true;
          
          return Container(
            margin: EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isAdmin ? Color(0xFF00F5A0).withOpacity(0.5) : Colors.white.withOpacity(0.2),
                width: isAdmin ? 2 : 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _viewMemberRecords(member),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isAdmin ? Color(0xFF00F5A0).withOpacity(0.2) : Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAdmin ? Icons.admin_panel_settings : Icons.person,
                          color: isAdmin ? Color(0xFF00F5A0) : Colors.white,
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  member['name'] ?? member['phone'] ?? '未知',
                                  style: TextStyle(
                                    fontSize: AppTheme.fontSizeMedium,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                if (isAdmin) ...[
                                  SizedBox(width: 8),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Color(0xFF00F5A0).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Color(0xFF00F5A0)),
                                    ),
                                    child: Text(
                                      '管理员',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF00F5A0),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 4),
                            Text(
                              member['phone'] ?? '',
                              style: TextStyle(
                                fontSize: AppTheme.fontSizeSmall,
                                color: Colors.white.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ==================== 成员通话记录页面 ====================
class MemberRecordsPage extends StatefulWidget {
  final Map<String, dynamic> member;

  const MemberRecordsPage({super.key, required this.member});

  @override
  State<MemberRecordsPage> createState() => _MemberRecordsPageState();
}

class _MemberRecordsPageState extends State<MemberRecordsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _records = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final userId = widget.member['user_id'];
      final response = await dioRequest.get('/api/call-records/member/$userId/records');
      
      if (response != null && response['data'] != null) {
        setState(() {
          _records = List<Map<String, dynamic>>.from(response['data']);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '加载失败';
        _isLoading = false;
      });
    }
  }

  void _showRecordDetail(Map<String, dynamic> record) {
    // 复用 CallRecords 页面的详情弹窗
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => CallRecordDetailSheet(
        record: record,
        isFamily: true, // 家庭成员记录，显示提交审查按钮
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        title: Text(
          '${widget.member['name'] ?? widget.member['phone']}的通话记录',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: AppColors.error),
                      SizedBox(height: 16),
                      Text(_errorMessage!, style: TextStyle(color: AppColors.textSecondary)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadRecords,
                        child: Text('重试'),
                      ),
                    ],
                  ),
                )
              : _records.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_disabled, size: 80, color: AppColors.textSecondary),
                          SizedBox(height: 16),
                          Text(
                            '暂无通话记录',
                            style: TextStyle(
                              fontSize: 18,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadRecords,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: EdgeInsets.all(AppTheme.paddingMedium),
                        itemCount: _records.length,
                        itemBuilder: (context, index) {
                          final record = _records[index];
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
                            margin: EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: AppColors.cardBackground,
                              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                              border: Border.all(color: AppColors.borderDark, width: 2),
                              boxShadow: AppTheme.shadowSmall,
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _showRecordDetail(record),
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                child: Padding(
                                  padding: EdgeInsets.all(AppTheme.paddingMedium),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: resultColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(resultIcon, color: resultColor, size: 20),
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              record['caller_number'] ?? '未知号码',
                                              style: TextStyle(
                                                fontSize: AppTheme.fontSizeMedium,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              '时长: ${record['duration'] ?? 0}秒',
                                              style: TextStyle(
                                                fontSize: AppTheme.fontSizeSmall,
                                                color: AppColors.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: resultColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
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
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}


