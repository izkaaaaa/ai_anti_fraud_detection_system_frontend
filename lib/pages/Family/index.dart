import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/DioRequest.dart';

class FamilyPage extends StatefulWidget {
  const FamilyPage({super.key});

  @override
  State<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends State<FamilyPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _familyInfo;
  List<dynamic> _members = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFamilyInfo();
  }

  Future<void> _loadFamilyInfo() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 重新从服务器获取最新的用户信息
      final userInfo = await AuthService().getCurrentUser();
      
      if (userInfo == null || userInfo['family_id'] == null) {
        setState(() {
          _familyInfo = null;
          _members = [];
          _isLoading = false;
        });
        return;
      }

      // 暂时使用模拟数据，等待后端实现家庭组详情接口
      setState(() {
        _familyInfo = {
          'family_id': userInfo['family_id'],
          'name': '家庭组 ${userInfo['family_id']}',
          'invite_code': '${userInfo['family_id']}',
        };
        _members = [
          {
            'user_id': userInfo['user_id'],
            'username': userInfo['username'],
            'phone': userInfo['phone'],
            'role': 'member',
          }
        ];
        _isLoading = false;
      });
    } catch (e) {
      print('❌ 加载家庭组信息失败: $e');
      setState(() {
        _errorMessage = '加载失败，请稍后重试';
        _isLoading = false;
      });
    }
  }

  Future<void> _createFamily() async {
    final familyIdController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          '创建/加入家庭组',
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
              '输入家庭组ID（如果不存在会自动创建）',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppTheme.paddingSmall),
            TextField(
              controller: familyIdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '例如：100',
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
              if (familyIdController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('请输入家庭组ID'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              try {
                final familyId = int.parse(familyIdController.text.trim());
                await dioRequest.put('/api/users/family/$familyId');
                
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('操作失败: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text('确定', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (result == true) {
      _showSuccess('加入家庭组成功！');
      await _loadFamilyInfo();
    }
  }

  Future<void> _joinFamily() async {
    final familyIdController = TextEditingController();
    
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
              controller: familyIdController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: '例如：100',
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
              if (familyIdController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('请输入家庭组ID'),
                    backgroundColor: AppColors.error,
                  ),
                );
                return;
              }
              
              try {
                final familyId = int.parse(familyIdController.text.trim());
                await dioRequest.put('/api/users/family/$familyId');
                
                Navigator.pop(context, true);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('加入失败: $e'),
                    backgroundColor: AppColors.error,
                  ),
                );
              }
            },
            child: Text('加入', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (result == true) {
      _showSuccess('加入家庭组成功！');
      await _loadFamilyInfo();
    }
  }

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
          '确定要退出当前家庭组吗？',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('确定', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await dioRequest.delete('/api/users/family');
        _showSuccess('已退出家庭组');
        await _loadFamilyInfo();
      } catch (e) {
        _showError('退出失败: $e');
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        title: Text(
          '家庭组',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_familyInfo != null)
            IconButton(
              icon: Icon(Icons.refresh, color: AppColors.primary),
              onPressed: _loadFamilyInfo,
            ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Container(
            color: AppColors.borderMedium,
            height: 1.5,
          ),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _errorMessage != null
              ? _buildErrorView()
              : _familyInfo == null
                  ? _buildNoFamilyView()
                  : _buildFamilyView(),
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
              onPressed: _loadFamilyInfo,
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
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3.0),
              ),
              child: Icon(
                Icons.family_restroom,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: AppTheme.paddingXLarge),
            Text(
              '还没有加入家庭组',
              style: TextStyle(
                fontSize: AppTheme.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: AppTheme.paddingMedium),
            Text(
              '创建或加入家庭组，与家人共享防诈骗保护',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: AppTheme.paddingXLarge),
            
            // 创建家庭组按钮
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppColors.borderDark, width: 2.0),
                boxShadow: AppTheme.shadowMedium,
              ),
              child: ElevatedButton.icon(
                onPressed: _createFamily,
                icon: Icon(Icons.add_circle_outline, size: 24),
                label: Text(
                  '创建/加入家庭组',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeLarge,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.textWhite,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
              ),
            ),
            
            SizedBox(height: AppTheme.paddingSmall),
            
            // 说明文字
            Center(
              child: Text(
                '输入家庭组ID即可加入\n如果家庭组不存在会自动创建',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppColors.textLight,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildFamilyInfoCard(),
          SizedBox(height: AppTheme.paddingMedium),
          _buildMembersSection(),
          SizedBox(height: AppTheme.paddingMedium),
          _buildActionsSection(),
        ],
      ),
    );
  }

  Widget _buildFamilyInfoCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.cardBackground,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: AppTheme.shadowMedium,
      ),
      padding: EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 2.0),
                ),
                child: Icon(
                  Icons.family_restroom,
                  size: 32,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(width: AppTheme.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _familyInfo!['name'] ?? '未命名家庭组',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeXLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${_members.length} 位成员',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeMedium,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppTheme.paddingMedium),
          
          Container(
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppColors.borderLight, width: 1.0),
            ),
            padding: EdgeInsets.all(AppTheme.paddingMedium),
            child: Row(
              children: [
                Icon(Icons.vpn_key, size: 18, color: AppColors.textSecondary),
                SizedBox(width: 8),
                Text(
                  '邀请码',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
                Spacer(),
                Text(
                  _familyInfo!['invite_code'] ?? '无',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 2,
                  ),
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.copy, size: 18, color: AppColors.primary),
                  onPressed: () {
                    // TODO: 复制邀请码到剪贴板
                    _showSuccess('邀请码已复制');
                  },
                  padding: EdgeInsets.zero,
                  constraints: BoxConstraints(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            '成员列表',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(color: AppColors.borderDark, width: 2.0),
            boxShadow: AppTheme.shadowSmall,
          ),
          child: _members.isEmpty
              ? Padding(
                  padding: EdgeInsets.all(AppTheme.paddingLarge),
                  child: Center(
                    child: Text(
                      '暂无成员',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: AppTheme.fontSizeMedium,
                      ),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _members.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: AppColors.borderLight,
                  ),
                  itemBuilder: (context, index) {
                    final member = _members[index];
                    final isCreator = member['role'] == 'creator';
                    
                    return ListTile(
                      leading: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCreator 
                              ? AppColors.secondary.withOpacity(0.2)
                              : AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCreator ? Icons.star : Icons.person,
                          color: isCreator ? AppColors.secondary : AppColors.primary,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        member['username'] ?? '未知用户',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        member['phone'] ?? '',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: isCreator
                          ? Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                                border: Border.all(color: AppColors.secondary),
                              ),
                              child: Text(
                                '创建者',
                                style: TextStyle(
                                  fontSize: AppTheme.fontSizeSmall,
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : null,
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildActionsSection() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: AppTheme.shadowMedium,
      ),
      child: ElevatedButton.icon(
        onPressed: _leaveFamily,
        icon: Icon(Icons.exit_to_app, size: 20),
        label: Text(
          '退出家庭组',
          style: TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textWhite,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      ),
    );
  }
}
