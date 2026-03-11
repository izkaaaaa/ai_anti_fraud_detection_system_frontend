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

  Future<void> _loadData({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isAdmin = false;
      _userInfo = null;
    });

    try {
      // 强制从服务器获取最新用户信息
      _userInfo = await _authService.getCurrentUser(forceRefresh: true);
      
      print('🔍 用户信息: family_id=${_userInfo?['family_id']}');
      
      // 检查是否是管理员
      if (_userInfo != null && _userInfo!['family_id'] != null) {
        try {
          await _familyService.getApplications();
          _isAdmin = true;
          print('✅ 用户是管理员');
        } catch (e) {
          _isAdmin = false;
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
                  Navigator.pop(context, createResult);
                }
              } catch (e) {
                print('❌ 创建家庭组失败: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('创建失败: $e'),
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
                          Tab(text: '申请管理'),
                          Tab(text: '成员管理'),
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
                        child: _isAdmin
                            ? TabBarView(
                              controller: _tabController,
                              children: [
                                ApplicationsTab(
                                  familyService: _familyService,
                                  onApplicationProcessed: _loadData, // 审批后刷新
                                ),
                                MembersTab(
                                  familyService: _familyService,
                                  onMemberUpdated: _loadData, // 成员变化后刷新
                                ),
                              ],
                            )
                          : _buildMemberView(), // 普通成员也显示成员列表
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
      ],
    );
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
            onMemberUpdated: _loadData,
          ),
        ),
      ],
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
                            '家庭组 ${_userInfo!['family_id']}',
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
              icon: Icon(Icons.exit_to_app, size: 20),
              label: Text('退出家庭组', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
      }
    } catch (e) {
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
  final VoidCallback? onMemberUpdated; // 成员变化后的回调

  const MembersTab({
    super.key, 
    required this.familyService,
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
      final members = await widget.familyService.getMembers();
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
        builder: (context) => MemberRecordsPage(member: member),
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
          final isAdmin = member['is_admin'] == true;
          return GestureDetector(
            onTap: () => _viewMemberRecords(member),
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
      print('📞 开始加载成员通话记录: userId=$userId');
      
      // 尝试正确的接口路径：/api/family/members/{user_id}/call-records
      final response = await dioRequest.get('/api/family/members/$userId/call-records');
      
      print('📦 通话记录响应: $response');
      
      if (response != null && response['data'] != null) {
        final records = List<Map<String, dynamic>>.from(response['data']);
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



