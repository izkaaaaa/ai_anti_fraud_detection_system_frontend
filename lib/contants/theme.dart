// 应用主题颜色配置
import 'package:flutter/material.dart';

/// Skip Gradient - 渐变色系
class AppColors {
  // 主色调 - Skip Gradient 色系
  static const Color primary = Color(0xFFFA8D75);  // #FA8D75 珊瑚橙
  static const Color primaryLight = Color(0xFFFFC4A9);  // #FFC4A9 浅桃色
  static const Color primaryDark = Color(0xFFBE5944);  // #BE5944 深橙棕
  
  // 辅助色 - 黄色系
  static const Color secondary = Color(0xFFF3DD4F);  // #F3DD4F 明黄色
  static const Color secondaryLight = Color(0xFFF9E87A);
  static const Color secondaryDark = Color(0xFFD4BE2A);
  
  // 强调色
  static const Color accent = Color(0xFFFA8D75);
  static const Color accentLight = Color(0xFFFFC4A9);
  
  // 背景色 - 浅色
  static const Color background = Color(0xFFFFFBF5);
  static const Color backgroundLight = Color(0xFFFFFFFF);
  
  // 文字颜色
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color textWhite = Color(0xFFFFFFFF);
  
  // 功能色
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFF3DD4F);
  static const Color error = Color(0xFFBE5944);
  static const Color info = Color(0xFFFFC4A9);
  
  // 边框和分割线
  static const Color border = Color(0xFFE8E8E8);
  static const Color divider = Color(0xFFF0F0F0);
  
  // 卡片和容器
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFFFFBF5);
  
  // 阴影
  static Color shadow = Colors.black.withOpacity(0.08);
  static Color shadowDark = Colors.black.withOpacity(0.15);
}

/// 应用主题配置
class AppTheme {
  // 圆角
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 24.0;
  
  // 边框宽度
  static const double borderThin = 1.0;
  static const double borderMedium = 1.5;
  static const double borderThick = 2.0;
  
  // 间距
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;
  
  // 字体大小
  static const double fontSizeSmall = 12.0;
  static const double fontSizeMedium = 14.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeXLarge = 20.0;
  static const double fontSizeXXLarge = 24.0;
  static const double fontSizeTitle = 28.0;
  
  // 阴影
  static List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: AppColors.shadow,
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: AppColors.shadowDark,
      blurRadius: 24,
      offset: const Offset(0, 8),
    ),
  ];
}

