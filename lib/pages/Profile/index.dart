import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    setState(() {
      _isLoading = true;
    });

    final userInfo = await AuthService().getCurrentUser();
    
    setState(() {
      _userInfo = userInfo;
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    // 显示确认对话框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认登出'),
        content: Text('确定要退出登录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('确定', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService().logout();
      
      if (mounted) {
        // 跳转到登录页
        Navigator.of(context).pushReplacementNamed('/login');
      }
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
          '个人中心',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
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
          : SingleChildScrollView(
              padding: EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildUserCard(),
                  SizedBox(height: AppTheme.paddingMedium),
                  _buildMenuList(),
                  SizedBox(height: AppTheme.paddingLarge),
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildUserCard() {
    if (_userInfo == null) {
      return Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppColors.borderDark, width: 2.0),
          boxShadow: AppTheme.shadowMedium,
        ),
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          children: [
            Icon(Icons.person_outline, size: 64, color: AppColors.textLight),
            SizedBox(height: AppTheme.paddingMedium),
            Text(
              '未登录',
              style: TextStyle(
                fontSize: AppTheme.fontSizeXLarge,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
            SizedBox(height: AppTheme.paddingMedium),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textWhite,
              ),
              child: Text('去登录'),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: AppTheme.shadowMedium,
      ),
      padding: EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        children: [
          // 头像
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 2.0),
            ),
            child: Icon(
              Icons.person,
              size: 48,
              color: AppColors.primary,
            ),
          ),
          SizedBox(height: AppTheme.paddingMedium),
          
          // 用户名
          Text(
            _userInfo!['username'] ?? '未知用户',
            style: TextStyle(
              fontSize: AppTheme.fontSizeXLarge,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          
          if (_userInfo!['name'] != null) ...[
            SizedBox(height: AppTheme.paddingSmall),
            Text(
              _userInfo!['name'],
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          
          SizedBox(height: AppTheme.paddingSmall),
          Text(
            _userInfo!['phone'] ?? '',
            style: TextStyle(
              fontSize: AppTheme.fontSizeSmall,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuList() {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.family_restroom,
          title: '家庭组',
          subtitle: _userInfo?['family_id'] != null ? '已加入' : '未加入',
          onTap: () {
            // TODO: 跳转到家庭组页面
          },
        ),
        SizedBox(height: AppTheme.paddingSmall),
        _buildMenuItem(
          icon: Icons.history,
          title: '通话记录',
          subtitle: '查看检测历史',
          onTap: () {
            // TODO: 跳转到通话记录页面
          },
        ),
        SizedBox(height: AppTheme.paddingSmall),
        _buildMenuItem(
          icon: Icons.settings,
          title: '设置',
          subtitle: '账号与安全',
          onTap: () {
            // TODO: 跳转到设置页面
          },
        ),
      ],
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.borderMedium, width: 1.5),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary, size: 24),
        title: Text(
          title,
          style: TextStyle(
            fontSize: AppTheme.fontSizeMedium,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textLight),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    if (_userInfo == null) return SizedBox.shrink();

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: AppColors.error,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.borderDark, width: 2.0),
        boxShadow: AppTheme.shadowMedium,
      ),
      child: ElevatedButton(
        onPressed: _handleLogout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textWhite,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: Text(
          '退出登录',
          style: TextStyle(
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

