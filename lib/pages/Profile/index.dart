import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Settings/PermissionSettings.dart';
import 'package:ai_anti_fraud_detection_system_frontend/api/auth_api.dart';

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
        Container(color: Colors.black.withOpacity(0.28)),
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
              borderRadius: BorderRadius.circular(16),
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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

  Widget _line(Color color) => Divider(height: 1, indent: 66, color: color);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: simpleAppBar(context, '关于我们'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.3),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2.5),
              ),
              child: Icon(Icons.shield, size: 60, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            Text('AI 反诈检测系统', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            Text('Version 1.0.0', style: TextStyle(fontSize: 13, color: AppColors.textLight)),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.secondary, width: 1.5),
              ),
              child: Text(
                '基于人工智能技术的反诈骗检测系统，通过视频、音频、文本多维度分析，实时识别诈骗风险，保护您和家人的财产安全。',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.6),
              ),
            ),
            const SizedBox(height: 20),
            _featureRow(Icons.videocam, '视频检测', 'Deepfake 视频识别'),
            const SizedBox(height: 10),
            _featureRow(Icons.mic, '音频检测', 'AI 语音伪造识别'),
            const SizedBox(height: 10),
            _featureRow(Icons.text_fields, '文本检测', '诈骗话术智能分析'),
            const SizedBox(height: 28),
            Text('© 2024 AI Anti-Fraud Detection System\nAll Rights Reserved',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textLight, height: 1.5)),
          ],
        ),
      ),
    );
  }

  Widget _featureRow(IconData icon, String title, String desc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.6), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.5), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              Text(desc, style: TextStyle(color: AppColors.textLight, fontSize: 12)),
            ],
          ),
        ],
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: simpleAppBar(context, '修改个人资料'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 1),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('完善资料可获得更精准的 AI 防骗建议', style: TextStyle(fontSize: 13, color: AppColors.textLight))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.secondary, width: 1.5),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _dropdownField(label: '角色类型', value: _selectedRoleType, items: ['青壮年', '老人', '学生', '其他'], onChanged: (v) => setState(() => _selectedRoleType = v)),
                  const SizedBox(height: 16),
                  _dropdownField(label: '性别', value: _selectedGender, items: ['男', '女', '未知'], onChanged: (v) => setState(() => _selectedGender = v)),
                  const SizedBox(height: 16),
                  _textField(controller: _professionController, label: '职业', hint: '如：工程师、教师、学生等', icon: Icons.work_outline),
                  const SizedBox(height: 16),
                  _dropdownField(label: '婚姻状况', value: _selectedMaritalStatus, items: ['单身', '已婚', '离异'], onChanged: (v) => setState(() => _selectedMaritalStatus = v)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _isLoading ? null : _handleUpdate,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: _isLoading ? AppColors.secondary.withOpacity(0.3) : AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: _isLoading ? [] : [BoxShadow(color: AppColors.primary.withOpacity(0.35), blurRadius: 14, spreadRadius: 1)],
                ),
                child: Center(
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('保存', style: TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField({required TextEditingController controller, required String label, required String hint, required IconData icon}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          enabled: !_isLoading,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textLight, fontSize: 13),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.secondary, width: 1.5)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.secondary, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: AppColors.primary, width: 2)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ],
    );
  }

  Widget _dropdownField({required String label, required String? value, required List<String> items, required Function(String?) onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.secondary, width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text('请选择$label', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
              isExpanded: true,
              icon: Icon(Icons.arrow_drop_down, color: AppColors.primary),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
              dropdownColor: AppColors.cardBackground,
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: _isLoading ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }
} 