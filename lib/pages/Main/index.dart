import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Detection/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/CallRecords/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Family/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Profile/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/Test/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/PermissionManager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;
  final PermissionManager _permissionManager = PermissionManager();
  bool _hasRequestedPermissions = false;

  final List<Widget> _pages = [
    DetectionPage(),
    CallRecordsPage(),
    FamilyPage(),
    TestPage(),
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.borderMedium,
              width: 1.5,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.cardBackground,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          selectedFontSize: AppTheme.fontSizeSmall,
          unselectedFontSize: AppTheme.fontSizeSmall,
          selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.radar, size: 24),
              activeIcon: Icon(Icons.radar, size: 26),
              label: '实时监测',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history, size: 24),
              activeIcon: Icon(Icons.history, size: 26),
              label: '通话记录',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.family_restroom, size: 24),
              activeIcon: Icon(Icons.family_restroom, size: 26),
              label: '家庭组',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.science_outlined, size: 24),
              activeIcon: Icon(Icons.science, size: 26),
              label: '测试',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline, size: 24),
              activeIcon: Icon(Icons.person, size: 26),
              label: '我的',
            ),
          ],
        ),
      ),
    );
  }
}