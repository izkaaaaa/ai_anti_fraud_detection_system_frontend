import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Settings/PermissionSettings.dart';

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
    print('📱 ProfilePage: 开始加载用户信息');
    print('📱 ProfilePage: 检查登录状态 - ${AuthService().isLoggedIn}');
    
    setState(() {
      _isLoading = true;
    });

    // 先检查是否已登录
    if (!AuthService().isLoggedIn) {
      print('📱 ProfilePage: 未登录，不获取用户信息');
      setState(() {
        _userInfo = null;
        _isLoading = false;
      });
      return;
    }

    final userInfo = await AuthService().getCurrentUser();
    
    print('📱 ProfilePage: 获取到的用户信息: $userInfo');
    
    setState(() {
      _userInfo = userInfo;
      _isLoading = false;
    });
    
    print('📱 ProfilePage: 页面状态已更新，_userInfo = $_userInfo');
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        title: Text(
          '确认退出',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '确定要退出登录吗？',
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
      await AuthService().logout();
      
      if (mounted) {
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
          '我的',
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
                  _buildUserInfoCard(),
                  SizedBox(height: AppTheme.paddingMedium),
                  _buildMenuSection(),
                  SizedBox(height: AppTheme.paddingLarge),
                  _buildLogoutButton(),
                ],
              ),
            ),
    );
  }

  // 用户信息卡片
  Widget _buildUserInfoCard() {
    // 检查用户信息是否有效（不为 null 且包含必要字段）
    if (_userInfo == null || _userInfo!.isEmpty || !_userInfo!.containsKey('username')) {
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
        children: [
          // 用户名
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
                  Icons.person,
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
                      _userInfo!['username'] ?? '未知用户',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeXLarge,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (_userInfo!['name'] != null) ...[
                      SizedBox(height: 4),
                      Text(
                        _userInfo!['name'],
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          
          SizedBox(height: AppTheme.paddingMedium),
          
          // 用户详细信息
          Container(
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(color: AppColors.borderLight, width: 1.0),
            ),
            padding: EdgeInsets.all(AppTheme.paddingMedium),
            child: Column(
              children: [
                _buildInfoRow(
                  icon: Icons.phone,
                  label: '手机号',
                  value: _userInfo!['phone'] ?? '未绑定',
                ),
                if (_userInfo!['family_id'] != null) ...[
                  Divider(height: 20, color: AppColors.borderLight),
                  _buildInfoRow(
                    icon: Icons.family_restroom,
                    label: '家庭组',
                    value: '已加入',
                    valueColor: AppColors.success,
                  ),
                ],
                Divider(height: 20, color: AppColors.borderLight),
                _buildInfoRow(
                  icon: Icons.calendar_today,
                  label: '注册时间',
                  value: _formatDate(_userInfo!['created_at']),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 信息行
  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.textSecondary),
        SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            color: AppColors.textSecondary,
          ),
        ),
        Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            fontWeight: FontWeight.w600,
            color: valueColor ?? AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  // 菜单区域
  Widget _buildMenuSection() {
    return Column(
      children: [
        // 功能菜单
        _buildMenuGroup(
          title: '功能',
          items: [
            _buildMenuItem(
              icon: Icons.analytics_outlined,
              title: '安全报告',
              subtitle: 'AI 生成个性化防骗建议',
              onTap: () {
                Navigator.pushNamed(context, '/security-report');
              },
              highlight: true,
            ),
            _buildMenuItem(
              icon: Icons.history,
              title: '通话记录',
              subtitle: '查看检测历史',
              onTap: () {
                // 切换到通话记录 Tab
                final mainPageState = context.findAncestorStateOfType<State>();
                if (mainPageState != null && mainPageState.mounted) {
                  // 通过修改父组件的 _currentIndex 来切换 Tab
                  (mainPageState as dynamic).setState(() {
                    (mainPageState as dynamic)._currentIndex = 1;
                  });
                }
              },
            ),
            _buildMenuItem(
              icon: Icons.family_restroom,
              title: '家庭组',
              subtitle: _userInfo?['family_id'] != null ? '已加入' : '未加入',
              onTap: () {
                // 切换到家庭组 Tab
                final mainPageState = context.findAncestorStateOfType<State>();
                if (mainPageState != null && mainPageState.mounted) {
                  (mainPageState as dynamic).setState(() {
                    (mainPageState as dynamic)._currentIndex = 2;
                  });
                }
              },
            ),
          ],
        ),
        
        SizedBox(height: AppTheme.paddingMedium),
        
        // 设置菜单
        _buildMenuGroup(
          title: '设置',
          items: [
            _buildMenuItem(
              icon: Icons.security,
              title: '权限设置',
              subtitle: '管理应用权限',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PermissionSettingsPage()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.settings,
              title: '设置',
              subtitle: '账号与安全',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SettingsPage()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.help_outline,
              title: '帮助中心',
              subtitle: '常见问题',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HelpCenterPage()),
                );
              },
            ),
            _buildMenuItem(
              icon: Icons.info_outline,
              title: '关于我们',
              subtitle: '版本信息',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AboutPage()),
                );
              },
            ),
          ],
        ),
      ],
    );
  }

  // 菜单组
  Widget _buildMenuGroup({
    required String title,
    required List<Widget> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
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
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  // 菜单项
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        child: Container(
          decoration: highlight
              ? BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.secondary.withOpacity(0.1),
                      Colors.transparent,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                )
              : null,
          padding: EdgeInsets.symmetric(
            horizontal: AppTheme.paddingMedium,
            vertical: AppTheme.paddingMedium,
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: highlight
                      ? AppColors.secondary.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                ),
                child: Icon(
                  icon,
                  color: highlight ? AppColors.secondary : AppColors.primary,
                  size: 20,
                ),
              ),
              SizedBox(width: AppTheme.paddingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeMedium,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (highlight) ...[
                          SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'NEW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textLight, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  // 退出登录按钮
  Widget _buildLogoutButton() {
    // 检查用户信息是否有效
    if (_userInfo == null || _userInfo!.isEmpty || !_userInfo!.containsKey('username')) {
      return SizedBox.shrink();
    }

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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20),
            SizedBox(width: 8),
            Text(
              '退出登录',
              style: TextStyle(
                fontSize: AppTheme.fontSizeLarge,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 格式化日期
  String _formatDate(dynamic date) {
    if (date == null) return '未知';
    try {
      final dateTime = DateTime.parse(date.toString());
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '未知';
    }
  }
}

// ==================== 设置页面 ====================
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '设置',
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
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.settings, size: 80, color: AppColors.textSecondary),
              SizedBox(height: AppTheme.paddingLarge),
              Text(
                '设置页面',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppTheme.paddingMedium),
              Text(
                '功能开发中...\n\n将包含：\n• 账号安全\n• 通知设置\n• 隐私设置\n• 清除缓存',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 帮助中心页面 ====================
class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '帮助中心',
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
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppTheme.paddingLarge),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.help_outline, size: 80, color: AppColors.textSecondary),
              SizedBox(height: AppTheme.paddingLarge),
              Text(
                '帮助中心',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeXLarge,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              SizedBox(height: AppTheme.paddingMedium),
              Text(
                '功能开发中...\n\n将包含：\n• 常见问题\n• 使用教程\n• 联系客服\n• 意见反馈',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==================== 关于我们页面 ====================
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '关于我们',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          children: [
            SizedBox(height: AppTheme.paddingLarge),
            
            // Logo
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 3.0),
              ),
              child: Icon(
                Icons.shield,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            
            SizedBox(height: AppTheme.paddingLarge),
            
            // 应用名称
            Text(
              'AI 反诈检测系统',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            
            SizedBox(height: AppTheme.paddingSmall),
            
            // 版本号
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: AppTheme.fontSizeMedium,
                color: AppColors.textSecondary,
              ),
            ),
            
            SizedBox(height: AppTheme.paddingLarge),
            
            // 简介
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppColors.borderDark, width: 2.0),
              ),
              padding: EdgeInsets.all(AppTheme.paddingLarge),
              child: Text(
                '基于人工智能技术的反诈骗检测系统，通过视频、音频、文本多维度分析，实时识别诈骗风险，保护您和家人的财产安全。',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
              ),
            ),
            
            SizedBox(height: AppTheme.paddingLarge),
            
            // 功能特点
            _buildFeatureItem(
              icon: Icons.videocam,
              title: '视频检测',
              description: 'Deepfake 视频识别',
            ),
            SizedBox(height: AppTheme.paddingSmall),
            _buildFeatureItem(
              icon: Icons.mic,
              title: '音频检测',
              description: 'AI 语音伪造识别',
            ),
            SizedBox(height: AppTheme.paddingSmall),
            _buildFeatureItem(
              icon: Icons.text_fields,
              title: '文本检测',
              description: '诈骗话术智能分析',
            ),
            
            SizedBox(height: AppTheme.paddingLarge),
            
            // 版权信息
            Text(
              '© 2024 AI Anti-Fraud Detection System\nAll Rights Reserved',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                color: AppColors.textLight,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(color: AppColors.borderMedium, width: 1.5),
      ),
      padding: EdgeInsets.all(AppTheme.paddingMedium),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          SizedBox(width: AppTheme.paddingMedium),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeMedium,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
