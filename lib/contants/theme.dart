// 应用主题颜色配置
import 'package:flutter/material.dart';

/// Skip Gradient - 渐变色系（深色勾线版本）
class AppColors {
  // 主色调 - Skip Gradient 色系
  static const Color primary = Color(0xFFFA8D75);  // #FA8D75 珊瑚橙
  static const Color primaryLight = Color(0xFFFFB8A3);  // 更浅的珊瑚色
  static const Color primaryDark = Color(0xFFE67A62);  // 深珊瑚橙
  
  // 辅助色 - 黄色系
  static const Color secondary = Color(0xFFF3DD4F);  // #F3DD4F 明黄色
  static const Color secondaryLight = Color(0xFFFFF4C4);  // 浅奶黄
  static const Color secondaryDark = Color(0xFFE8C93D);  // 深金黄
  
  // 强调色 - 桃色系
  static const Color accent = Color(0xFFFFC4A9);  // #FFC4A9 浅桃色
  static const Color accentLight = Color(0xFFFFDFCF);  // 极浅桃色
  static const Color accentDark = Color(0xFFFFAA8F);  // 深桃色
  
  // 棕色系
  static const Color brown = Color(0xFFBE5944);  // #BE5944 深橙棕
  static const Color brownLight = Color(0xFFD47A66);  // 浅橙棕
  static const Color brownDark = Color(0xFFA04A36);  // 深棕色
  
  // 背景色 - 浅色
  static const Color background = Color(0xFFFFFBF5);  // 极浅米色
  static const Color backgroundLight = Color(0xFFFFFFFF);  // 纯白
  static const Color backgroundCard = Color(0xFFFFF9F0);  // 浅奶黄背景
  
  // 文字颜色
  static const Color textPrimary = Color(0xFF2D2D2D);  // 深灰黑
  static const Color textSecondary = Color(0xFF666666);  // 中灰
  static const Color textLight = Color(0xFF999999);  // 浅灰
  static const Color textWhite = Color(0xFFFFFFFF);  // 白色
  
  // 深色勾线
  static const Color borderDark = Color(0xFF3D3D3D);  // 深灰色勾线
  static const Color borderMedium = Color(0xFF666666);  // 中灰色勾线
  static const Color borderLight = Color(0xFFD4D4D4);  // 浅灰色勾线
  
  // 功能色
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFF3DD4F);
  static const Color error = Color(0xFFBE5944);
  static const Color info = Color(0xFFFFC4A9);
  
  // 卡片和容器
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFFFFBF5);
  
  // 阴影
  static Color shadow = Colors.black.withOpacity(0.06);
  static Color shadowMedium = Colors.black.withOpacity(0.10);
  static Color shadowDark = Colors.black.withOpacity(0.15);
}

/// 应用主题配置
class AppTheme {
  // 圆角
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  
  // 边框宽度（深色勾线）
  static const double borderThin = 1.5;  // 细勾线
  static const double borderMedium = 2.0;  // 中等勾线
  static const double borderThick = 2.5;  // 粗勾线
  
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
      color: AppColors.shadowMedium,
      blurRadius: 12,
      offset: const Offset(0, 3),
    ),
  ];
  
  static List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: AppColors.shadowDark,
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];
}

