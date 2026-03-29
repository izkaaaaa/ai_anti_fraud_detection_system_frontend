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
  Map<String, dynamic>? _familyInfo;
  bool _isAdmin = false;
  String _myAdminRole = 'none';
  String? _errorMessage;
  late TabController _tabController;

  final FamilyService _familyService = FamilyService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isAdmin = false;
      _myAdminRole = 'none';
      _userInfo = null;
      _familyInfo = null;
    });

    try {
      // 强制从服务器获取最新用户信息
      _userInfo = await _authService.getCurrentUser(forceRefresh: true);
      
      print('🔍 用户信息: family_id=${_userInfo?['family_id']}');
      
      // 检查是否加入了家庭组（可能有多个）
      if (_userInfo != null && _userInfo!['family_id'] != null) {

        // 获取家庭组详情（group_name、统计数据）
        try {
          _familyInfo = await _familyService.getFamilyInfo();
          final role = _familyInfo?['my_role']?.toString().toLowerCase() ?? 'none';
          _myAdminRole = role;
          _isAdmin = role == 'primary' || role == 'secondary';
        } catch (_) {
          _familyInfo = null;
        }

        try {
          await _familyService.getApplications();
          _isAdmin = true;
          if (_myAdminRole == 'none') {
            _myAdminRole = 'secondary';
          }
          print('✅ 用户是管理员');
        } catch (e) {
          print('ℹ️ 用户是普通成员');
        }
      } else {
        print('ℹ️ 用户未加入家庭组');
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
    // 先检查是否有待审批的申请
    print('🔍 检查是否有待审批申请...');
    final pendingApps = await _familyService.getPendingApplications();
    print('📊 待审批申请数量: ${pendingApps.length}');
    
    if (pendingApps.isNotEmpty && mounted) {
      print('⛔ 用户有待审批申请，阻止创建家庭组');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('您有待审批的家庭组申请，请先处理后再创建新家庭组'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFA9BCBD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text(
          '创建家庭组',
          style: TextStyle(
            color: Color(0xFF0F1923),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '家庭组名称',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF2D4A3E),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(color: Color(0xFF0F1923), fontSize: 15),
              decoration: InputDecoration(
                hintText: '例如：我的家庭',
                hintStyle: const TextStyle(color: Color(0xFF7A9A9B), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFBFCFD0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF58A183), width: 1.5),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D4A3E)),
            child: const Text('取消', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请输入家庭组名称'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              try {
                print('📤 正在创建家庭组: ${nameController.text.trim()}');
                final createResult = await _familyService.createFamily(nameController.text.trim());
                
                if (createResult != null) {
                  print('✅ 家庭组创建成功: $createResult');
                  if (mounted) {
                    Navigator.pop(context, createResult);
                  }
                } else {
                  print('❌ 创建家庭组返回空结果');
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('创建失败：服务器返回异常'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                }
              } catch (e) {
                print('❌ 创建家庭组失败: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('创建失败: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58A183),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('创建', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    // 创建成功后立即刷新并跳转到家庭组页面
    if (result != null && mounted) {
      print('🎉 开始刷新页面，跳转到家庭组管理');
      _showSuccess('家庭组创建成功！正在进入...');
      
      // 等待一小段时间让后端完全处理完
      await Future.delayed(Duration(milliseconds: 300));
      
      // 强制刷新数据
      await _loadData(forceRefresh: true);
      
      print('✅ 页面刷新完成，family_id=${_userInfo?['family_id']}, isAdmin=$_isAdmin');
    }
  }

  /// 申请加入家庭组
  Future<void> _joinFamily() async {
    // 先检查是否有待审批的申请
    print('🔍 检查是否有待审批申请...');
    final pendingApps = await _familyService.getPendingApplications();
    print('📊 待审批申请数量: ${pendingApps.length}');
    
    if (pendingApps.isNotEmpty && mounted) {
      print('⛔ 用户有待审批申请，阻止申请其他家庭组');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('您有待审批的家庭组申请，请先处理后再申请其他家庭组'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final idController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFA9BCBD),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text(
          '加入家庭组',
          style: TextStyle(
            color: Color(0xFF0F1923),
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '家庭组ID',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFF2D4A3E),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: idController,
              autofocus: true,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Color(0xFF0F1923), fontSize: 15),
              decoration: InputDecoration(
                hintText: '例如：1',
                hintStyle: const TextStyle(color: Color(0xFF7A9A9B), fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFBFCFD0),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: Color(0xFF58A183), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF58A183).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF58A183).withOpacity(0.4), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xFF2D4A3E), size: 15),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '申请后需等待管理员审批',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF2D4A3E),
                        fontWeight: FontWeight.w600,
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
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D4A3E)),
            child: const Text('取消', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (idController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请输入家庭组ID'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              try {
                final familyId = int.parse(idController.text.trim());
                final success = await _familyService.applyToJoin(familyId);
                if (success) {
                  Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('该家庭组不存在或已被删除'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('申请失败: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF58A183),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('申请', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    
    // 申请发送成功后显示提示，但不跳转（需要等管理员审批）
    if (result == true) {
      if (mounted) {
        _showSuccess('申请已发送，请等待管理员审批');
        await _loadData(forceRefresh: true);
      }
    }
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
      appBar: _userInfo?['family_id'] != null
          ? AppBar(
              backgroundColor: const Color(0xFFF8FAF9),
              elevation: 0,
              title: const Text(
                '家庭组',
                style: TextStyle(
                  color: Color(0xFF0F1923),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF0F1923)),
                  onPressed: _loadData,
                ),
              ],
              bottom: _isAdmin
                  ? PreferredSize(
                      preferredSize: Size.fromHeight(50),
                      child: TabBar(
                        controller: _tabController,
                        labelColor: Color(0xFF2D4A3E),
                        unselectedLabelColor: Color(0xFF2D4A3E).withOpacity(0.45),
                        indicatorColor: Color(0xFF58A183),
                        indicatorWeight: 3,
                        labelStyle: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.w700,
                        ),
                        tabs: [
                          Tab(text: '我的家庭组'),
                          Tab(text: '成员管理'),
                          Tab(text: '申请管理'),
                        ],
                      ),
                    )
                  : null,
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                '家庭组',
                style: TextStyle(
                  color: Color(0xFF0F1923),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh, color: Color(0xFF0F1923)),
                  onPressed: _loadData,
                ),
              ],
            ),
      body: _isLoading
          ? Container(
              color: const Color(0xFFF8FAF9),
              child: const Center(child: CircularProgressIndicator(color: Color(0xFF58A183))),
            )
              : _errorMessage != null
              ? Container(
                  color: const Color(0xFFF8FAF9),
                  child: SafeArea(child: _buildErrorView()),
                )
                  : _userInfo?['family_id'] == null
                      ? _buildNoFamilyView()
                  : Container(
                      color: const Color(0xFFF8FAF9),
                      child: SafeArea(
                        child: Column(
                          children: [
                            // 待审批申请提示条
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _familyService.getPendingApplications(),
                              builder: (context, snapshot) {
                                final applications = snapshot.data ?? [];
                                if (applications.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return Container(
                                  color: const Color(0xFFFEF3C7),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.info_rounded, color: Color(0xFFD97706), size: 20),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          '您有 ${applications.length} 个待审批的家庭组申请',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF92400E),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => _showPendingApplicationsDialog(applications),
                                        child: const Text(
                                          '查看',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFFD97706),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            Expanded(
                              child: _isAdmin
                                ? TabBarView(
                                    controller: _tabController,
                                    children: [
                                      // 第一个标签页：我的家庭组
                                      SingleChildScrollView(
                                        padding: const EdgeInsets.all(16),
                                        child: Column(
                                          children: [
                                            _buildFamilyInfoCard(),
                                          ],
                                        ),
                                      ),
                                      // 第二个标签页：成员管理
                                      MembersTab(
                                        familyService: _familyService,
                                        familyId: _userInfo!['family_id'] as int,
                                        myAdminRole: _myAdminRole,
                                        currentUserId: _userInfo?['user_id'] as int?,
                                        onMemberUpdated: _loadData,
                                      ),
                                      // 第三个标签页：申请管理
                                      ApplicationsTab(
                                        familyService: _familyService,
                                        onApplicationProcessed: _loadData,
                                      ),
                                    ],
                                  )
                                : _buildMemberView(), // 普通成员也显示成员列表
                            ),
                          ],
                        ),
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
            const Icon(Icons.error_outline, size: 80, color: Color(0xFF58A183)),
            SizedBox(height: AppTheme.paddingLarge),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF0F1923),
              ),
            ),
            SizedBox(height: AppTheme.paddingLarge),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('重试'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58A183),
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
    final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
          children: [
        // 背景图铺满
        Positioned.fill(
          child: Image.asset(
            'lib/UIimages/家庭组背景.png',
            fit: BoxFit.cover,
          ),
        ),

        // 内容区域：限定在画面上 35%（上移15%）
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: screenHeight * 0.35,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 主标题
                const Text(
                  '家庭守护',
              style: TextStyle(
                    fontSize: 38,
                fontWeight: FontWeight.w900,
                    color: Color(0xFF0F1923),
                    letterSpacing: 3,
                    height: 1.1,
              ),
            ),
                const SizedBox(height: 6),
                const Text(
                  '创建或加入家庭组，与家人共享防诈骗保护',
              style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF2D4A3E),
                    height: 1.6,
                    letterSpacing: 0.4,
              ),
            ),
                const SizedBox(height: 24),
                // 两个按钮并列
                Row(
                  children: [
                    // 创建家庭组按钮（#58A183）
                    Expanded(
                      child: GestureDetector(
                        onTap: _createFamily,
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
              decoration: BoxDecoration(
                            color: const Color(0xFF58A183),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF095943),
                              width: 1.0,
                            ),
                          ),
                          child: const Text(
                          '创建家庭组',
                  style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                    ),
                  ),
                ),
                    const SizedBox(width: 12),
                    // 加入家庭组按钮（#d2e4d6）
                    Expanded(
                      child: GestureDetector(
                  onTap: _joinFamily,
                  child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: const Color(0xFFD2E4D6),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFF095943),
                              width: 1.0,
                            ),
                          ),
                          child: const Text(
                          '加入家庭组',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1C3A2F),
                            letterSpacing: 1,
                          ),
                        ),
                    ),
                  ),
                ),
                  ],
            ),
          ],
        ),
      ),
        ),
        // 待审批申请列表
        Positioned(
          top: screenHeight * 0.35,
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildPendingApplicationsList(),
        ),
      ],
    );
  }

  /// 构建待审批申请列表
  Widget _buildPendingApplicationsList() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _familyService.getPendingApplications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF58A183)));
        }

        final applications = snapshot.data ?? [];
        
        if (applications.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          color: const Color(0xFFF8FAF9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Text(
                  '待审批申请 (${applications.length})',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F1923),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: applications.length,
                  itemBuilder: (context, index) {
                    final app = applications[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '家庭组 ${app['family_id'] ?? '未知'}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF0F1923),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  app['apply_time'] ?? '申请中',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _cancelApplication(app['application_id'], app['family_id']),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '取消申请',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// 显示待审批申请对话框
  Future<void> _showPendingApplicationsDialog(List<Map<String, dynamic>> applications) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFA9BCBD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text(
          '待审批申请',
          style: TextStyle(
            color: Color(0xFF0F1923),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: applications.length,
            itemBuilder: (context, index) {
              final app = applications[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '家庭组 ${app['family_id'] ?? '未知'}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F1923),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            app['apply_time'] ?? '申请中',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2D4A3E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _cancelApplication(app['application_id'], app['family_id']);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '取消',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D4A3E)),
            child: const Text('关闭', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// 取消申请
  Future<void> _cancelApplication(int appId, int familyId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFA9BCBD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text(
          '取消申请',
          style: TextStyle(
            color: Color(0xFF0F1923),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          '确认取消对家庭组 $familyId 的申请吗？',
          style: const TextStyle(
            color: Color(0xFF2D4A3E),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D4A3E)),
            child: const Text('保留', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('取消申请', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        print('📤 正在取消申请: appId=$appId');
        final success = await _familyService.cancelApplication(appId);
        if (success && mounted) {
          print('✅ 申请已取消');
          _showSuccess('申请已取消');
          await _loadData(forceRefresh: true);
        }
      } catch (e) {
        print('❌ 取消申请失败: $e');
        if (mounted) {
          _showError('取消失败: $e');
        }
      }
    }
  }

  Widget _buildMemberView() {
    return Column(
      children: [
        // 家庭信息卡片
        Padding(
          padding: EdgeInsets.all(AppTheme.paddingMedium),
          child: _buildFamilyInfoCard(),
        ),
        
        // 成员列表
        Expanded(
          child: MembersTab(
            familyService: _familyService,
            familyId: _userInfo!['family_id'] as int,
            myAdminRole: _myAdminRole,
            currentUserId: _userInfo?['user_id'] as int?,
            onMemberUpdated: _loadData,
          ),
        ),
      ],
    );
  }

  Widget _buildFamilyInfoCardSimple() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF58A183).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
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
                        color: const Color(0xFF58A183).withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF58A183).withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.family_restroom,
                        size: 36,
                        color: Color(0xFF2D4A3E),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _familyInfo?['group_name']?.toString().isNotEmpty == true
                                ? _familyInfo!['group_name'].toString()
                                : '家庭组 ${_userInfo!['family_id']}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F1923),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isAdmin ? '管理员' : '成员',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF58A183),
                              fontWeight: FontWeight.w600,
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
                    color: const Color(0xFF58A183).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF58A183).withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key, size: 20, color: Color(0xFF58A183)),
                      const SizedBox(width: 12),
                      const Text(
                        '家庭组ID',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D4A3E),
                          fontWeight: FontWeight.w600,
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF58A183).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
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
                        color: const Color(0xFF58A183).withOpacity(0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF58A183).withOpacity(0.4),
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.family_restroom,
                        size: 36,
                        color: Color(0xFF2D4A3E),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _familyInfo?['group_name']?.toString().isNotEmpty == true
                                ? _familyInfo!['group_name'].toString()
                                : '家庭组 ${_userInfo!['family_id']}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F1923),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isAdmin ? '管理员' : '成员',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF58A183),
                              fontWeight: FontWeight.w600,
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
                    color: const Color(0xFF58A183).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF58A183).withOpacity(0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.vpn_key, size: 20, color: Color(0xFF58A183)),
                      const SizedBox(width: 12),
                      const Text(
                        '家庭组ID',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF2D4A3E),
                          fontWeight: FontWeight.w600,
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
                    icon: const Icon(Icons.exit_to_app, size: 18),
                    label: const Text('退出家庭组', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3E5E5),
                      foregroundColor: const Color(0xFF8B5A5A),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
        backgroundColor: const Color(0xFFA9BCBD),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: const Text(
          '退出家庭组',
          style: TextStyle(
            color: Color(0xFF0F1923),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          '退出后将无法查看家庭成员的通话记录。',
          style: TextStyle(
            color: Color(0xFF2D4A3E),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFF2D4A3E)),
            child: const Text('取消', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('退出', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        print('📤 正在退出家庭组...');
        final success = await _familyService.leaveFamily();
        if (success && mounted) {
          print('✅ 退出家庭组成功');
          _showSuccess('已退出家庭组');
          
          // 等待一小段时间让后端完全处理完
          await Future.delayed(Duration(milliseconds: 300));
          
          // 强制刷新数据，回到"未加入家庭组"页面
          await _loadData(forceRefresh: true);
          
          print('✅ 页面刷新完成，已回到未加入家庭组页面');
        }
      } catch (e) {
        print('❌ 退出家庭组失败: $e');
        if (mounted) {
          _showError('退出失败: $e');
        }
      }
    }
  }

}

// ==================== 申请管理标签页 ====================
class ApplicationsTab extends StatefulWidget {
  final FamilyService familyService;
  final VoidCallback? onApplicationProcessed; // 审批后的回调

  const ApplicationsTab({
    super.key, 
    required this.familyService,
    this.onApplicationProcessed,
  });

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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isApprove ? '已同意申请' : '已拒绝申请'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        
        // 刷新申请列表
        await _loadApplications();
        
        // 通知父组件刷新（如果同意了申请，成员列表会变化）
        if (isApprove) {
          widget.onApplicationProcessed?.call();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isApprove ? '同意申请失败' : '拒绝申请失败'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ 审批申请失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF58A183)));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            Text(_errorMessage!, style: const TextStyle(color: Color(0xFF6B7280))),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadApplications,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58A183),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    if (_applications.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_rounded, size: 56, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text(
              '暂无待审批申请',
              style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadApplications,
      color: const Color(0xFF58A183),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: _applications.length,
        itemBuilder: (context, index) {
          final app = _applications[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
            ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                // 头像占位
                    Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F0EE),
                        shape: BoxShape.circle,
                      ),
                  child: const Icon(Icons.person_rounded, color: Color(0xFF58A183), size: 22),
                    ),
                const SizedBox(width: 12),
                // 用户信息
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            app['phone'] ?? '未知用户',
                        style: const TextStyle(
                          fontSize: 14,
                              fontWeight: FontWeight.w700,
                          color: Color(0xFF0F1923),
                            ),
                          ),
                      const SizedBox(height: 2),
                          Text(
                            app['apply_time'] ?? '',
                        style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    ),
                // 操作按钮
                GestureDetector(
                  onTap: () => _reviewApplication(app['application_id'], false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(8),
                        ),
                    child: const Text('拒绝',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFDC2626))),
                      ),
                    ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => _reviewApplication(app['application_id'], true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F0EE),
                      borderRadius: BorderRadius.circular(8),
                        ),
                    child: const Text('同意',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF58A183))),
                    ),
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
  final int familyId;
  final String myAdminRole;
  final int? currentUserId;
  final VoidCallback? onMemberUpdated; // 成员变化后的回调

  const MembersTab({
    super.key, 
    required this.familyService,
    required this.familyId,
    required this.myAdminRole,
    this.currentUserId,
    this.onMemberUpdated,
  });

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
      print('🔄 MembersTab: 开始加载成员列表');
      final members = await widget.familyService.getMembers(familyId: widget.familyId);
      print('✅ MembersTab: 成员列表加载成功，共 ${members.length} 个成员');
      setState(() {
        _members = members;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ MembersTab: 加载成员列表失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
        _isLoading = false;
      });
    }
  }

  void _viewMemberRecords(Map<String, dynamic> member) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemberRecordsPage(
          member: member,
          familyId: widget.familyId,
          familyService: widget.familyService,
          myAdminRole: widget.myAdminRole,
        ),
      ),
    );
  }

  bool _canManageMember(Map<String, dynamic> member) {
    final myRole = widget.myAdminRole;
    if (myRole != 'primary' && myRole != 'secondary') return false;

    final memberUserId = member['user_id'] as int?;
    if (widget.currentUserId != null && memberUserId == widget.currentUserId) {
      return false;
    }

    final memberRole = (member['admin_role']?.toString().toLowerCase() ?? 'none');
    if (myRole == 'primary') {
      return memberRole != 'primary';
    }

    // secondary 只能管理普通成员
    return memberRole == 'none' || memberRole.isEmpty;
  }

  Future<void> _setMemberRole(Map<String, dynamic> member, String targetRole) async {
    final userId = member['user_id'] as int?;
    if (userId == null) return;

    final roleName = targetRole == 'none' ? '普通成员' : '副管理员';
    try {
      final ok = await widget.familyService.setAdminRole(userId: userId, role: targetRole);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已设置为$roleName'), backgroundColor: AppColors.success),
        );
        await _loadMembers();
        widget.onMemberUpdated?.call();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('设置角色失败: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _removeMember(Map<String, dynamic> member) async {
    final userId = member['user_id'] as int?;
    if (userId == null) return;

    final name = member['name'] ?? member['phone'] ?? '该成员';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('移除成员'),
        content: Text('确认将 $name 移出家庭组吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('取消')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            child: const Text('移除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final ok = await widget.familyService.removeMember(userId);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('成员已移除'), backgroundColor: AppColors.success),
        );
        await _loadMembers();
        widget.onMemberUpdated?.call();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('移除失败: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _showMemberActions(Map<String, dynamic> member) async {
    final canManage = _canManageMember(member);
    if (!canManage) {
      _viewMemberRecords(member);
      return;
    }

    final role = member['admin_role']?.toString().toLowerCase() ?? 'none';
    final myRole = widget.myAdminRole;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.history_rounded),
                title: const Text('查看通话记录'),
                onTap: () {
                  Navigator.pop(context);
                  _viewMemberRecords(member);
                },
              ),
              if (myRole == 'primary' && role == 'none')
                ListTile(
                  leading: const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFF58A183)),
                  title: const Text('设为副管理员'),
                  onTap: () {
                    Navigator.pop(context);
                    _setMemberRole(member, 'secondary');
                  },
                ),
              if (myRole == 'primary' && role == 'secondary')
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded, color: Color(0xFF58A183)),
                  title: const Text('降级为普通成员'),
                  onTap: () {
                    Navigator.pop(context);
                    _setMemberRole(member, 'none');
                  },
                ),
              if (role == 'none')
                ListTile(
                  leading: const Icon(Icons.person_remove_alt_1_rounded, color: Color(0xFFDC2626)),
                  title: const Text('移除成员'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeMember(member);
                  },
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF58A183)));
    }

    if (_errorMessage != null) {
      return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            const Icon(Icons.error_outline, size: 48, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            Text(_errorMessage!, textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
            const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadMembers,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('重试'),
                style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF58A183),
                  foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
        ),
      );
    }

    if (_members.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline_rounded, size: 56, color: Color(0xFFCBD5E1)),
            SizedBox(height: 12),
            Text('暂无成员', style: TextStyle(fontSize: 15, color: Color(0xFF9CA3AF))),
            SizedBox(height: 4),
            Text('邀请家人加入家庭组', style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMembers,
      color: const Color(0xFF58A183),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: _members.length,
        itemBuilder: (context, index) {
          final member = _members[index];
          final memberRole = member['admin_role']?.toString().toLowerCase() ?? 'none';
          final isAdmin = memberRole == 'primary' || memberRole == 'secondary';
          return GestureDetector(
            onTap: () => _showMemberActions(member),
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
            ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
                  child: Row(
                    children: [
                      Container(
                    width: 40,
                    height: 40,
                        decoration: BoxDecoration(
                      color: isAdmin ? const Color(0xFFE8F0EE) : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                      isAdmin ? Icons.shield_rounded : Icons.person_rounded,
                      color: isAdmin ? const Color(0xFF58A183) : const Color(0xFF9CA3AF),
                      size: 22,
                        ),
                      ),
                  const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  member['name'] ?? member['phone'] ?? '未知',
                              style: const TextStyle(
                                fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                color: Color(0xFF0F1923),
                                  ),
                                ),
                                if (isAdmin) ...[
                              const SizedBox(width: 6),
                                  Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                  color: const Color(0xFFE8F0EE),
                                  borderRadius: BorderRadius.circular(6),
                                    ),
                                child: const Text(
                                      '管理员',
                                      style: TextStyle(
                                        fontSize: 10,
                                    color: Color(0xFF58A183),
                                    fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                        const SizedBox(height: 2),
                            Text(
                              member['phone'] ?? '',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                            ),
                          ],
                        ),
                      ),
                  const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 20),
                    ],
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
  final int familyId;
  final FamilyService familyService;
  final String myAdminRole;

  const MemberRecordsPage({
    super.key,
    required this.member,
    required this.familyId,
    required this.familyService,
    required this.myAdminRole,
  });

  @override
  State<MemberRecordsPage> createState() => _MemberRecordsPageState();
}

class _MemberRecordsPageState extends State<MemberRecordsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _records = [];
  String? _errorMessage;

  bool get _canRemoteIntervene =>
      widget.myAdminRole == 'primary' || widget.myAdminRole == 'secondary';

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _sendSosForRecord(Map<String, dynamic> record) async {
    final callId = _toInt(record['call_id']);
    if (callId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('当前记录缺少 call_id，无法发起求助'), backgroundColor: AppColors.error),
      );
      return;
    }

    final controller = TextEditingController(text: '检测到风险通话，请尽快联系我');
    final message = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('发送紧急求助'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(hintText: '请输入求助信息'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          ElevatedButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('发送')),
        ],
      ),
    );

    if (message == null || message.isEmpty) return;

    try {
      final ok = await widget.familyService.sendSos(callId: callId, message: message);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '求助已发送给家庭监护人' : '求助发送失败'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送求助失败: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _remoteIntervene() async {
    final targetUserId = _toInt(widget.member['user_id']);
    if (targetUserId == null) return;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.call_end_rounded, color: Color(0xFFDC2626)),
              title: const Text('强制挂断通话'),
              onTap: () => Navigator.pop(context, 'block_call'),
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber_rounded, color: Color(0xFFF59E0B)),
              title: const Text('仅发送警告提示'),
              onTap: () => Navigator.pop(context, 'warn_only'),
            ),
          ],
        ),
      ),
    );

    if (action == null) return;

    try {
      final ok = await widget.familyService.remoteIntervene(
        targetUserId: targetUserId,
        action: action,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? '远程干预指令已发送' : '远程干预失败'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('远程干预失败: $e'), backgroundColor: AppColors.error),
      );
    }
  }

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
      print('📞 开始加载成员通话记录: userId=$userId, familyId=${widget.familyId}');
      
      final response = await dioRequest.get(
        '/api/call-records/family-records',
        params: {
          'family_id': widget.familyId,
          'target_user_id': userId,
          'page': 1,
          'page_size': 50,
        },
      );
      
      print('📦 通话记录响应: $response');
      
      if (response != null && response['data'] != null) {
        final data = response['data'];
        final recordsRaw = data is Map<String, dynamic> ? (data['records'] as List? ?? []) : (data as List? ?? []);
        final records = recordsRaw.cast<Map<String, dynamic>>();
        print('✅ 通话记录加载成功，共 ${records.length} 条记录');
        setState(() {
          _records = records;
          _isLoading = false;
        });
      } else {
        print('⚠️ 响应格式不正确');
        setState(() {
          _records = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ 加载通话记录失败: $e');
      setState(() {
        _errorMessage = '加载失败: $e';
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

  static const Color _accent = Color(0xFF58A183);
  static const Color _bg = Color(0xFFF8FAF9);

  Map<String, dynamic> _riskMeta(String result) {
    switch (result) {
      case 'safe':
        return {
          'label': '安全',
          'icon': Icons.verified_rounded,
          'color': const Color(0xFF059669),
          'title': '安全通话',
        };
      case 'suspicious':
        return {
          'label': '可疑',
          'icon': Icons.warning_amber_rounded,
          'color': const Color(0xFFD97706),
          'title': '可疑通话',
        };
      case 'fake':
        return {
          'label': '危险',
          'icon': Icons.gpp_bad_rounded,
          'color': const Color(0xFFDC2626),
          'title': '危险通话',
        };
      default:
        return {
          'label': '未检测',
          'icon': Icons.help_outline_rounded,
          'color': const Color(0xFF9CA3AF),
          'title': '未知通话',
        };
    }
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return m > 0 ? '$m分$s秒' : '$s秒';
  }

  @override
  Widget build(BuildContext context) {
    final memberName = widget.member['name'] ?? widget.member['phone'] ?? '成员';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Text(
          '$memberName 的通话记录',
          style: const TextStyle(
            color: Color(0xFF0F1923),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        actions: [
          if (_canRemoteIntervene)
            IconButton(
              onPressed: _remoteIntervene,
              tooltip: '远程干预',
              icon: const Icon(Icons.gpp_maybe_rounded, color: Color(0xFFDC2626)),
            ),
          IconButton(
            onPressed: _loadRecords,
            tooltip: '刷新',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F1923)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _errorMessage != null
              ? _buildErrorView()
              : _records.isEmpty
                  ? _buildEmptyView()
                  : RefreshIndicator(
                      onRefresh: _loadRecords,
                      color: _accent,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
                        itemCount: _records.length,
                        itemBuilder: (context, index) => _buildRecordCard(_records[index]),
                      ),
                    ),
    );
  }

  Widget _buildRecordCard(Map<String, dynamic> record) {
    final result = record['detected_result'] ?? 'unknown';
    final risk = _riskMeta(result);
    final color = risk['color'] as Color;
    final icon = risk['icon'] as IconData;
    final title = risk['title'] as String;
    final label = risk['label'] as String;
    final startTime = record['start_time']?.toString() ?? '';
    final duration = _toInt(record['duration']) ?? 0;

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
              child: Ink(
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withOpacity(0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  child: Row(
                    children: [
                      Icon(icon, color: Colors.white.withOpacity(0.92), size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                Icon(Icons.schedule_rounded, size: 11, color: Colors.white.withOpacity(0.7)),
                                const SizedBox(width: 3),
                                Text(
                                  _formatDateTime(startTime),
                                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.timer_outlined, size: 11, color: Colors.white.withOpacity(0.7)),
                                const SizedBox(width: 3),
                                Text(
                                  _formatDuration(duration),
                                  style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.8)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.white.withOpacity(0.35)),
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => _sendSosForRecord(record),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEE2E2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFFFCA5A5)),
                              ),
                              child: const Text(
                                'SOS求助',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFB91C1C),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone_disabled_rounded, size: 32, color: _accent),
          ),
          const SizedBox(height: 18),
          const Text(
            '暂无通话记录',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F1923)),
          ),
          const SizedBox(height: 6),
          Text(
            '该成员的通话记录会显示在这里',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
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
          Text(
            _errorMessage!,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 18),
          TextButton.icon(
            onPressed: _loadRecords,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('重试'),
            style: TextButton.styleFrom(foregroundColor: _accent),
          ),
        ],
      ),
    );
  }
}



