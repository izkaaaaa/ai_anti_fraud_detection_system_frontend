import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Detection/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/CallRecords/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Family/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Profile/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/LearningCenter/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/PermissionManager.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 2;
  final PermissionManager _permissionManager = PermissionManager();
  bool _hasRequestedPermissions = false;
  final GlobalKey<ConvexAppBarState> _barKey = GlobalKey<ConvexAppBarState>();

  bool get isElderMode => AuthService().isElderMode;

  void _switchTab(int index) {
    setState(() => _currentIndex = index);
    _barKey.currentState?.animateTo(index);
  }

  List<Widget> get _pages => [
    CallRecordsPage(),
    LearningCenterPage(),
    DetectionPage(),
    FamilyPage(),
    ProfilePage(onSwitchTab: _switchTab),
  ];

  @override
  void initState() {
    super.initState();
    _checkAndRequestPermissions();
  }

  /// 检查并请求权限（仅首次启动）
  Future<void> _checkAndRequestPermissions() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('is_first_launch') ?? true;

    if (isFirstLaunch && !_hasRequestedPermissions) {
      _hasRequestedPermissions = true;

      // 延迟一下，等待页面完全加载
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        await _permissionManager.requestPermissionsOnFirstLaunch(context);
        await prefs.setBool('is_first_launch', false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ 使用 IndexedStack 保持所有页面存活，切换 tab 时不销毁 Widget
      // 这样 DetectionPage 切换到其他 tab 时不会被 dispose，检测服务不会中断
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: ConvexAppBar(
        key: _barKey,
        style: TabStyle.reactCircle,
        items: [
          TabItem(icon: Icons.history, title: '通话记录'),
          TabItem(icon: Icons.school_outlined, title: '学习中心'),
          TabItem(icon: Icons.radar, title: '实时监测'),
          TabItem(icon: Icons.family_restroom, title: '家庭组'),
          TabItem(icon: Icons.person_outline, title: '我的'),
        ],
        initialActiveIndex: _currentIndex,
        onTap: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // 墨绿色系配色
        backgroundColor: Color(0xFF1B553E),
        activeColor: Colors.white, // 激活时的图标和文字颜色
        color: Color(0xFF6EE7B7).withOpacity(0.6), // 未激活时的图标和文字颜色（浅绿色半透明）
        gradient: LinearGradient(
          colors: [
            Color(0xFF1B553E),
            Color(0xFF164A35),
          ],
        ),
        height: isElderMode ? 72 : 60,
        top: -20,
        curveSize: 80,
        elevation: 8,
      ),
    );
  }
}
