import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Settings/PermissionSettings.dart';
import 'package:ai_anti_fraud_detection_system_frontend/api/auth_api.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Test/index.dart';

// 根据用户信息选择头像资源
String _getAvatarAsset(Map<String, dynamic>? userInfo) {
  if (userInfo == null) return 'lib/UIimages/头像/未知性别.png';
  final role = userInfo['role_type'] ?? '';
  final gender = userInfo['gender'] ?? '';
  if (role == '老人') {
    if (gender == '女') return 'lib/UIimages/头像/老人女.png';
    if (gender == '男') return 'lib/UIimages/头像/老人男.png';
  } else if (role == '学生') {
    if (gender == '女') return 'lib/UIimages/头像/学生女.png';
    if (gender == '男') return 'lib/UIimages/头像/学生男.png';
  } else if (role == '青壮年') {
    if (gender == '女') return 'lib/UIimages/头像/青壮年女.png';
    if (gender == '男') return 'lib/UIimages/头像/青壮年男.png';
  }
  if (gender == '女') return 'lib/UIimages/头像/未知年龄女.png';
  if (gender == '男') return 'lib/UIimages/头像/未知年龄男.png';
  return 'lib/UIimages/头像/未知性别.png';
}

AppBar simpleAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: AppColors.cardBackground,
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.bold,
      ),
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(color: AppColors.secondary.withOpacity(0.4), height: 1),
    ),
  );
}

// ========================================================
// ProfilePage
// ========================================================

class ProfilePage extends StatefulWidget {
  final void Function(int)? onSwitchTab;
  const ProfilePage({super.key, this.onSwitchTab});

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
    setState(() => _isLoading = true);
    if (!AuthService().isLoggedIn) {
      setState(() { _userInfo = null; _isLoading = false; });
      return;
    }
    final userInfo = await AuthService().getCurrentUser();
    setState(() { _userInfo = userInfo; _isLoading = false; });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('确认退出', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Text('确定要退出登录吗？', style: TextStyle(color: AppColors.textLight)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('取消', style: TextStyle(color: AppColors.textLight))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('确定', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm == true) {
      await AuthService().logout();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
    return Scaffold(
      backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    final isLoggedIn = _userInfo != null && _userInfo!.containsKey('username');
    final screenHeight = MediaQuery.of(context).size.height;
    // 上半占40%，下半卡片上移2%（轻微叠压）
    final headerHeight = screenHeight * 0.40;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF9),
      body: Stack(
        children: [
          // 上半部分背景
          Positioned(
            top: 0, left: 0, right: 0,
            height: headerHeight,
            child: _buildHeader(isLoggedIn),
        ),
          // 下半部分卡片（轻微上移2%）
          Positioned(
            top: headerHeight - screenHeight * 0.02,
            left: 0, right: 0, bottom: 0,
          child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAF9),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: _buildBody(isLoggedIn, screenHeight),
            ),
              ),
        ],
            ),
    );
  }

  Widget _buildHeader(bool isLoggedIn) {
    final avatarAsset = _getAvatarAsset(_userInfo);
    final username = _userInfo?['username'] ?? '未登录';
    final phone = _userInfo?['phone'] ?? '未绑定手机号';

    return Stack(
      fit: StackFit.expand,
      children: [
        // 背景图
        Image.asset('lib/UIimages/个人中心背景.png', fit: BoxFit.cover),
        // 轻微暗色遮罩
        Container(color: Colors.black.withOpacity(0.10)),
        // 内容
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                const SizedBox(height: 4),
                // 顶栏
                Row(
                  children: [
                    const Text(
                      '我的',
              style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
              ),
            ),
                    const Spacer(),
                    if (isLoggedIn) ..._buildHeaderActions(),
          ],
        ),
                const SizedBox(height: 100),
                // 头像左置 + 右侧文字
                GestureDetector(
                  onTap: isLoggedIn ? null : () => Navigator.of(context).pushNamed('/login'),
                  child: Row(
            children: [
              Container(
                      width: 68,
                      height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.85), width: 2),
                ),
                      child: ClipOval(
                        child: isLoggedIn
                            ? Image.asset(avatarAsset, fit: BoxFit.cover)
                            : Icon(Icons.person, size: 36, color: Colors.white),
                ),
              ),
                    const SizedBox(width: 14),
                    Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                          username,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                        const SizedBox(height: 4),
                      Text(
                          phone,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13,
                        ),
                      ),
                  ],
              ),
            ],
          ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildHeaderActions() {
    return [
      IconButton(
        icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PermissionSettingsPage()),
        ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 20,
      ),
      const SizedBox(width: 12),
      IconButton(
        icon: const Icon(Icons.edit_outlined, color: Colors.white, size: 22),
        onPressed: () async {
          if (_userInfo == null) return;
          await Navigator.push(
                  context,
                  MaterialPageRoute(
              builder: (_) => EditProfilePage(
                      userInfo: _userInfo!,
                      onProfileUpdated: _loadUserInfo,
                    ),
                  ),
                );
              },
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 20,
      ),
    ];
                }

  Widget _buildBody(bool isLoggedIn, double screenHeight) {
    const textSub = Color(0xFF6B7280);
    const divColor = Color(0xFFE5E7EB);
    const deepGreen = Color(0xFF095943);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
      child: Column(
      children: [
          // 菜单卡片
        Container(
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.zero,
                topRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 2)),
              ],
          ),
          child: Column(
              children: [
                _item(icon: Icons.analytics_outlined, label: '安全报告', iconColor: deepGreen,
                  onTap: () => Navigator.pushNamed(context, '/security-report')),
                _line(divColor),
                _item(
                  icon: Icons.family_restroom, label: '家庭组', iconColor: deepGreen,
                  trailing: _userInfo?['family_id'] != null
                      ? _chip('已加入', deepGreen)
                      : _chip('未加入', textSub),
                  onTap: () => widget.onSwitchTab?.call(3),
                ),
                _line(divColor),
                _item(icon: Icons.info_outline, label: '关于我们', iconColor: deepGreen,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutPage()))),
                _line(divColor),
                _item(
                  icon: Icons.phone_outlined, label: '通话记录', iconColor: deepGreen,
                  onTap: () => widget.onSwitchTab?.call(0),
                ),
                _line(divColor),
                _item(icon: Icons.build_outlined, label: '设备测试', iconColor: deepGreen,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TestPage()))),
                _line(divColor),
                _item(icon: Icons.help_outline, label: '帮助中心', iconColor: deepGreen,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpCenterPage()))),
                    ],
                  ),
          ),
          const Spacer(),
          // 退出登录按钮
          if (isLoggedIn)
            GestureDetector(
              onTap: _handleLogout,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                margin: const EdgeInsets.only(bottom: 42),
                decoration: BoxDecoration(
                                color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.6), width: 1.5),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFFFF6B6B).withOpacity(0.08), blurRadius: 10),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: AppColors.error, size: 19),
                    const SizedBox(width: 8),
                    Text('退出登录', style: TextStyle(color: AppColors.error, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                  ],
                ),
                      ),
                    ),
                  ],
      ),
    );
  }

  Widget _item({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color iconColor,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        child: Row(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 15, fontWeight: FontWeight.w500)),
            const Spacer(),
            if (trailing != null) ...[trailing, const SizedBox(width: 6)],
            const Icon(Icons.chevron_right, color: Color(0xFFD1D5DB), size: 18),
          ],
        ),
      ),
    );
  }

  Widget _line(Color color) => Divider(height: 1, indent: 72, color: color);

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
              ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}

// ========================================================
// HelpCenterPage
// ========================================================

class HelpCenterPage extends StatelessWidget {
  const HelpCenterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: simpleAppBar(context, '帮助中心'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.help_outline, size: 72, color: AppColors.primary),
              const SizedBox(height: 20),
              Text('帮助中心', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 12),
              Text(
                '功能开发中...\n\n将包含：\n• 常见问题\n• 使用教程\n• 联系客服\n• 意见反馈',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ========================================================
// AboutPage
// ========================================================

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const _bg      = Color(0xFFF8FAF9);
  static const _white   = Colors.white;
  static const _accent  = Color(0xFF58A183);
  static const _accentD = Color(0xFF0F1923);
  static const _textMid = Color(0xFF374151);
  static const _textLt  = Color(0xFF6B7280);
  static const _border  = Color(0xFFE5E7EB);
  static const _tagBg   = Color(0xFFE9F2EC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: simpleAppBar(context, '关于我们'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 28),

            // 图标
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _tagBg,
                shape: BoxShape.circle,
                border: Border.all(color: _accent, width: 2),
              ),
              child: const Icon(Icons.shield, size: 44, color: _accent),
            ),
            const SizedBox(height: 18),

            // 标题
            const Text(
              'AI 反诈检测系统',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: _accentD,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Version 1.0.0',
              style: TextStyle(fontSize: 13, color: _textLt),
            ),
            const SizedBox(height: 24),

            // 简介卡片
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border, width: 1),
              ),
              child: const Text(
                '基于人工智能技术的反诈骗检测系统，通过视频、音频、文本多维度分析，实时识别诈骗风险，保护您和家人的财产安全。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _textMid, height: 1.7),
              ),
            ),
            const SizedBox(height: 16),

            // 视频检测
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: _tagBg, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.videocam, color: _accent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('视频检测', style: TextStyle(color: _accentD, fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('Deepfake 视频识别', style: TextStyle(color: _textLt, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 音频检测
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: _tagBg, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.mic, color: _accent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('音频检测', style: TextStyle(color: _accentD, fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('AI 语音伪造识别', style: TextStyle(color: _textLt, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 文本检测
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: _white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _border, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(color: _tagBg, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.text_fields, color: _accent, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('文本检测', style: TextStyle(color: _accentD, fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(height: 2),
                      Text('诈骗话术智能分析', style: TextStyle(color: _textLt, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // 版权声明
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _tagBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accent.withOpacity(0.3), width: 1),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.photo_camera_outlined, color: _accent, size: 16),
                      SizedBox(width: 6),
                      Text(
                        '素材来源',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: _accentD,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '检测页背景插画素材由 Storyset 提供',
                    style: TextStyle(fontSize: 13, color: _textMid, height: 1.5),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Online illustrations by Storyset',
                    style: TextStyle(fontSize: 12, color: _textLt, height: 1.5),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'https://storyset.com/online',
                    style: TextStyle(fontSize: 12, color: _accent, height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 底部版权
            const Text(
              '© 2024 AI Anti-Fraud Detection System',
              style: TextStyle(fontSize: 12, color: _textLt),
            ),
            const SizedBox(height: 4),
            const Text(
              'All Rights Reserved',
              style: TextStyle(fontSize: 12, color: _textLt),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ========================================================
// EditProfilePage
// ========================================================

class EditProfilePage extends StatefulWidget {
  final Map<String, dynamic> userInfo;
  final VoidCallback onProfileUpdated;

  const EditProfilePage({super.key, required this.userInfo, required this.onProfileUpdated});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _professionController = TextEditingController();
  String? _selectedRoleType;
  String? _selectedGender;
  String? _selectedMaritalStatus;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRoleType = widget.userInfo['role_type'];
    _selectedGender = widget.userInfo['gender'];
    _professionController.text = widget.userInfo['profession'] ?? '';
    _selectedMaritalStatus = widget.userInfo['marital_status'];
  }

  @override
  void dispose() {
    _professionController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    setState(() => _isLoading = true);
    try {
      await updateUserProfileAPI(
        roleType: _selectedRoleType,
        gender: _selectedGender,
        profession: _professionController.text.trim().isEmpty ? null : _professionController.text.trim(),
        maritalStatus: _selectedMaritalStatus,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('资料更新成功'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
        widget.onProfileUpdated();
        await Future.delayed(const Duration(milliseconds: 400));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('更新失败: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // =============================================
  // 配色（参考通话记录页：白绿色系）
  // =============================================
  static const Color _bg       = Color(0xFFF8FAF9);  // 浅灰绿背景
  static const Color _white    = Colors.white;
  static const Color _accent   = Color(0xFF58A183);  // 主绿（与通话记录一致）
  static const Color _accentDark = Color(0xFF059669); // 深绿文字/强调
  static const Color _textDark = Color(0xFF0F1923);  // 深色文字
  static const Color _textGray = Color(0xFF6B7280);  // 灰色文字
  static const Color _border   = Color(0xFFE5E7EB);  // 浅灰边框
  static const Color _tagBg    = Color(0xFFE9F2EC);  // 浅绿标签背景

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _accent,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('修改个人资料', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 角色类型
            _fieldLabel('角色类型'),
            const SizedBox(height: 6),
            _dropdownField(
              value: _selectedRoleType,
              items: const ['青壮年', '老人', '学生', '其他'],
              onChanged: (v) => setState(() => _selectedRoleType = v),
              hint: '请选择角色类型',
            ),
            const SizedBox(height: 20),

            // 性别
            _fieldLabel('性别'),
            const SizedBox(height: 6),
            _dropdownField(
              value: _selectedGender,
              items: const ['男', '女', '未知'],
              onChanged: (v) => setState(() => _selectedGender = v),
              hint: '请选择性别',
            ),
            const SizedBox(height: 20),

            // 职业
            _fieldLabel('职业'),
            const SizedBox(height: 6),
            _textField(
              controller: _professionController,
              hint: '如：工程师、教师、学生等',
              icon: Icons.work_outline,
            ),
            const SizedBox(height: 20),

            // 婚姻状况
            _fieldLabel('婚姻状况'),
            const SizedBox(height: 6),
            _dropdownField(
              value: _selectedMaritalStatus,
              items: const ['单身', '已婚', '离异'],
              onChanged: (v) => setState(() => _selectedMaritalStatus = v),
              hint: '请选择婚姻状况',
            ),
            const SizedBox(height: 36),

            // 保存按钮
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleUpdate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _tagBg,
                  disabledForegroundColor: _textGray,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 1,
                  shadowColor: _accent.withOpacity(0.3),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Text(
                        '保存',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textDark),
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
  }) {
    return TextFormField(
      controller: controller,
      enabled: !_isLoading,
      style: const TextStyle(color: _textDark, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _textGray, fontSize: 13),
        prefixIcon: Icon(icon, color: _accent, size: 18),
        filled: true,
        fillColor: _white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }

  Widget _dropdownField({
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required String hint,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border, width: 1.5),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: _textGray, fontSize: 13)),
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, color: _accent),
          style: const TextStyle(color: _textDark, fontSize: 14),
          dropdownColor: _white,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: _isLoading ? null : onChanged,
        ),
      ),
    );
  }
}