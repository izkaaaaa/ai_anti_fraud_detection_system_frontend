import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Detection/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/CallRecords/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Family/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Profile/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Test/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/PermissionManager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> with SingleTickerProviderStateMixin {
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
  
  // 导航栏图标列表（左边2个，右边2个）
  final List<IconData> _iconList = [
    Icons.history,
    Icons.science_outlined,
    Icons.family_restroom,
    Icons.person_outline,
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _currentIndex = 2; // 跳转到实时监测页（中间）
          });
        },
        backgroundColor: Color(0xFF10B981), // 翠绿色
        child: Icon(
          Icons.radar,
          color: Colors.white,
          size: 28,
        ),
        elevation: 8,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: AnimatedBottomNavigationBar(
        icons: _iconList,
        activeIndex: _currentIndex == 2 ? 0 : (_currentIndex > 2 ? _currentIndex - 1 : _currentIndex),
        gapLocation: GapLocation.center,
        notchSmoothness: NotchSmoothness.verySmoothEdge,
        leftCornerRadius: 32,
        rightCornerRadius: 32,
        onTap: (index) {
          setState(() {
            // 映射索引：0->0(通话记录), 1->1(测试), 2->3(家庭组), 3->4(我的)
            if (index >= 2) {
              _currentIndex = index + 1;
            } else {
              _currentIndex = index;
            }
          });
        },
        // 黑绿色系配色
        backgroundColor: Color(0xFF1F2937), // 深灰黑色
        activeColor: Color(0xFF10B981), // 翠绿色
        inactiveColor: Color(0xFF6B7280), // 中灰色
        splashColor: Color(0xFF10B981).withOpacity(0.3),
        splashSpeedInMilliseconds: 300,
        iconSize: 26,
        height: 60,
        elevation: 8,
      ),
    );
  }
}