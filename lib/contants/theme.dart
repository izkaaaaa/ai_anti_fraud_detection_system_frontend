// 应用主题颜色配置
import 'package:flutter/material.dart';

/// 绿黑荧光色系 - 赛博朋克风格
class AppColors {
  // 主色调 - 荧光绿系
  static const Color primary = Color(0xFFCDED63);  // #CDED63 荧光黄绿
  static const Color primaryLight = Color(0xFFEFFF86);  // #EFFF86 亮荧光黄
  static const Color primaryDark = Color(0xFF9DC24F);  // #9DC24F 深荧光绿
  
  // 辅助色 - 深绿系
  static const Color secondary = Color(0xFF095943);  // #095943 深墨绿
  static const Color secondaryLight = Color(0xFF0D7A5E);  // 中墨绿
  static const Color secondaryDark = Color(0xFF053D2E);  // 极深墨绿
  
  // 强调色 - 荧光黄系
  static const Color accent = Color(0xFFEFFF86);  // #EFFF86 荧光黄
  static const Color accentLight = Color(0xFFF8FFB3);  // 浅荧光黄
  static const Color accentDark = Color(0xFFCDED63);  // 深荧光黄绿
  
  // 中性绿色
  static const Color green = Color(0xFF9DC24F);  // #9DC24F 中性绿
  static const Color greenLight = Color(0xFFB8D97A);  // 浅中性绿
  static const Color greenDark = Color(0xFF7FA63D);  // 深中性绿
  
  // 背景色 - 深色系
  static const Color background = Color(0xFF25282B);  // #25282B 深灰黑
  static const Color backgroundLight = Color(0xFF2F3337);  // 浅深灰
  static const Color backgroundCard = Color(0xFF1C1E21);  // 极深灰黑
  static const Color backgroundDark = Color(0xFF1A1C1F);  // 最深背景
  
  // 米白色（用于卡片和对比）
  static const Color cream = Color(0xFFF6F6EF);  // #F6F6EF 米白色
  static const Color creamDark = Color(0xFFE8E8E0);  // 深米白
  
  // 文字颜色
  static const Color textPrimary = Color(0xFFF6F6EF);  // 米白色文字
  static const Color textSecondary = Color(0xFFCDED63);  // 荧光绿文字
  static const Color textLight = Color(0xFF9DA3A8);  // 浅灰文字
  static const Color textDark = Color(0xFF25282B);  // 深色文字（用于浅色背景）
  static const Color textGlow = Color(0xFFEFFF86);  // 荧光黄文字
  static const Color textWhite = Color(0xFFF6F6EF);  // 白色文字（兼容旧代码）
  
  // 棕色系（兼容旧代码）
  static const Color brown = Color(0xFF9DC24F);  // 使用中性绿代替
  
  // 边框颜色
  static const Color borderDark = Color(0xFF095943);  // 深墨绿边框
  static const Color borderMedium = Color(0xFF9DC24F);  // 中性绿边框
  static const Color borderLight = Color(0xFFCDED63);  // 荧光绿边框
  static const Color borderGlow = Color(0xFFEFFF86);  // 荧光黄边框
  
  // 功能色
  static const Color success = Color(0xFF9DC24F);  // 成功 - 中性绿
  static const Color warning = Color(0xFFEFFF86);  // 警告 - 荧光黄
  static const Color error = Color(0xFFFF6B6B);  // 错误 - 红色
  static const Color info = Color(0xFFCDED63);  // 信息 - 荧光黄绿
  
  // 卡片和容器
  static const Color cardBackground = Color(0xFF2F3337);
  static const Color inputBackground = Color(0xFF1C1E21);
  
  // 荧光发光效果
  static Color glowGreen = Color(0xFFCDED63).withOpacity(0.3);
  static Color glowYellow = Color(0xFFEFFF86).withOpacity(0.3);
  static Color glowDarkGreen = Color(0xFF095943).withOpacity(0.5);
  
  // 阴影
  static Color shadow = Colors.black.withOpacity(0.4);
  static Color shadowMedium = Colors.black.withOpacity(0.6);
  static Color shadowDark = Colors.black.withOpacity(0.8);
  
  // 荧光阴影
  static Color shadowGlow = Color(0xFFCDED63).withOpacity(0.2);
  static Color shadowGlowYellow = Color(0xFFEFFF86).withOpacity(0.2);
}

// 中老年大字模式字体大小（比标准大 3~5px）
class ElderFontSize {
  static const double small = 14.0;      // 原 12
  static const double medium = 16.0;      // 原 14
  static const double large = 18.0;       // 原 16
  static const double xlarge = 21.0;      // 原 20
  static const double xxlarge = 24.0;     // 原 24
  static const double title = 28.0;       // 原 28

  static double getSmall(double normal) => normal + 2;
  static double getMedium(double normal) => normal + 2;
  static double getLarge(double normal) => normal + 2;
}

/// 应用主题配置
class AppTheme {
  // 圆角
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;
  static const double radiusXLarge = 20.0;
  
  // 边框宽度（荧光勾线）
  static const double borderThin = 1.5;  // 细勾线
  static const double borderMedium = 2.0;  // 中等勾线
  static const double borderThick = 2.5;  // 粗勾线
  static const double borderGlow = 3.0;  // 荧光勾线
  
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
  
  // 普通阴影
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
  
  // 荧光发光效果
  static List<BoxShadow> glowGreen = [
    BoxShadow(
      color: AppColors.glowGreen,
      blurRadius: 20,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: AppColors.primary,
      blurRadius: 40,
      spreadRadius: -10,
    ),
  ];
  
  static List<BoxShadow> glowYellow = [
    BoxShadow(
      color: AppColors.glowYellow,
      blurRadius: 20,
      spreadRadius: 2,
    ),
    BoxShadow(
      color: AppColors.accent,
      blurRadius: 40,
      spreadRadius: -10,
    ),
  ];
  
  static List<BoxShadow> glowDarkGreen = [
    BoxShadow(
      color: AppColors.glowDarkGreen,
      blurRadius: 15,
      spreadRadius: 1,
    ),
  ];
  
  // 荧光渐变
  static LinearGradient gradientGreen = LinearGradient(
    colors: [
      AppColors.primary,
      AppColors.green,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient gradientYellow = LinearGradient(
    colors: [
      AppColors.accent,
      AppColors.primary,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static LinearGradient gradientDark = LinearGradient(
    colors: [
      AppColors.secondary,
      AppColors.background,
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

