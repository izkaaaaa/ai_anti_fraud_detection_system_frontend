import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Detection/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/CallRecords/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Family/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Profile/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Test/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/PermissionManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 2; // 默认显示实时监测页面
  final PermissionManager _permissionManager = PermissionManager();
  bool _hasRequestedPermissions = false;

  final List<Widget> _pages = [
    CallRecordsPage(),
    TestPage(),
    DetectionPage(),
    FamilyPage(),
    ProfilePage(),
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
      body: _pages[_currentIndex],
      bottomNavigationBar: ConvexAppBar(
        style: TabStyle.reactCircle,
        items: [
          TabItem(icon: Icons.history, title: '通话记录'),
          TabItem(icon: Icons.science_outlined, title: '测试'),
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
        backgroundColor: Color(0xFF064E3B), // 墨绿色背景
        activeColor: Colors.white, // 激活时的图标和文字颜色
        color: Color(0xFF6EE7B7).withOpacity(0.6), // 未激活时的图标和文字颜色（浅绿色半透明）
        gradient: LinearGradient(
          colors: [
            Color(0xFF059669), // 深绿色
            Color(0xFF047857), // 墨绿色
          ],
        ),
        height: 60,
        top: -20,
        curveSize: 80,
        elevation: 8,
      ),
    );
  }
}