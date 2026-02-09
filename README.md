# AI 反欺诈检测系统 - 前端

基于 Flutter 开发的 AI 反欺诈检测系统前端应用，提供直观的用户界面和流畅的交互体验。

## 📋 项目简介

本项目是一个使用 Flutter 框架开发的跨平台反欺诈检测系统前端应用，采用 MVVM 架构模式，支持 Web、iOS、Android 等多个平台。

## 🏗️ 项目结构

```
lib/
├── api/              # 存放请求 - API 接口层
├── assets/           # 存放资源 - 图片、字体等静态资源
├── components/       # 存放公共组件 - 可复用的 UI 组件
├── contants/         # 存放常量文件 - 配置常量、枚举等
├── viewmodels/       # 存放类型文件 - ViewModel 业务逻辑层
├── pages/            # 存放页面 - 应用的各个页面
├── routes/           # 存放路由配置 - 页面路由管理
├── stores/           # 存放全局状态组件 - 状态管理
├── utils/            # 存放工具类 - 通用工具函数
└── main.dart         # 入口 - 应用程序入口文件
```

## 🚀 技术栈

- **框架**: Flutter 3.11+
- **语言**: Dart
- **架构模式**: MVVM (Model-View-ViewModel)
- **状态管理**: Stores (全局状态管理)
- **路由管理**: Routes (统一路由配置)

## 📦 环境要求

- Flutter SDK: ^3.11.0
- Dart SDK: ^3.11.0
- IDE: Android Studio / VS Code / IntelliJ IDEA

## 🔧 安装与运行

### 1. 克隆项目

```bash
git clone <repository-url>
cd ai_anti_fraud_detection_system_frontend
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 运行项目

```bash
# 运行在 Chrome 浏览器
flutter run -d chrome

# 运行在 Android 设备
flutter run -d android

# 运行在 iOS 设备
flutter run -d ios
```

### 4. 构建项目

```bash
# 构建 Web 版本
flutter build web

# 构建 Android APK
flutter build apk

# 构建 iOS
flutter build ios
```

## 📂 目录说明

### `/lib/api`
存放所有 API 接口请求相关的代码，包括：
- HTTP 请求封装
- API 接口定义
- 请求拦截器
- 响应处理

### `/lib/assets`
存放静态资源文件，如：
- 图片资源
- 字体文件
- 本地数据文件

### `/lib/components`
存放可复用的公共组件，如：
- 按钮组件
- 输入框组件
- 卡片组件
- 对话框组件

### `/lib/contants`
存放项目常量配置，如：
- API 地址配置
- 颜色常量
- 尺寸常量
- 枚举类型

### `/lib/viewmodels`
存放 ViewModel 层代码，负责：
- 业务逻辑处理
- 数据转换
- 状态管理
- 与 Model 层交互

### `/lib/pages`
存放应用的各个页面，如：
- 登录页面
- 首页
- 检测页面
- 结果展示页面

### `/lib/routes`
存放路由配置，包括：
- 路由表定义
- 路由跳转封装
- 路由守卫

### `/lib/stores`
存放全局状态管理，如：
- 用户状态
- 应用配置状态
- 主题状态

### `/lib/utils`
存放工具类函数，如：
- 日期格式化
- 字符串处理
- 验证工具
- 加密工具

## 🎨 设计规范

### 色彩系统 - Skip Gradient（渐变色系）

本项目采用温暖渐变的配色方案，营造活力、友好的视觉体验。

#### 主色调 - Skip Gradient
- **Primary（主色）**: `#FA8D75` - 珊瑚橙，用于主要按钮、强调元素
- **Primary Light**: `#FFC4A9` - 浅桃色，用于渐变、高亮
- **Primary Dark**: `#BE5944` - 深橙棕，用于深色元素

#### 辅助色
- **Secondary（辅助色）**: `#F3DD4F` - 明黄色，用于次要按钮、提示元素
- **Secondary Light**: `#F9E87A` - 浅黄色
- **Secondary Dark**: `#D4BE2A` - 深黄色

#### 背景色
- **Background**: `#FFFBF5` - 极浅米色背景，温暖柔和
- **Background Light**: `#FFFFFF` - 纯白色，用于卡片、容器

#### 文字颜色
- **Text Primary**: `#2D2D2D` - 主要文字
- **Text Secondary**: `#666666` - 次要文字
- **Text Light**: `#999999` - 辅助文字
- **Text White**: `#FFFFFF` - 白色文字

#### 功能色
- **Success**: `#52C41A` - 成功状态
- **Warning**: `#F3DD4F` - 警告状态（使用辅助色）
- **Error**: `#BE5944` - 错误状态（使用深橙棕）
- **Info**: `#FFC4A9` - 信息提示（使用浅桃色）

#### 设计原则
- **温暖渐变**: 使用 Skip Gradient 色系，营造温暖友好的氛围
- **视觉层次**: 通过颜色深浅和阴影营造空间感
- **简洁明快**: 保持界面清爽，避免过度装饰
- **一致性**: 统一的圆角、间距、字体大小

### 命名规范
- 文件名：使用小写字母和下划线，如 `user_profile_page.dart`
- 类名：使用大驼峰命名，如 `UserProfilePage`
- 变量名：使用小驼峰命名，如 `userName`
- 常量：使用大写字母和下划线，如 `API_BASE_URL`

### 代码规范
- 遵循 Dart 官方代码规范
- 使用 `flutter_lints` 进行代码检查
- 保持代码简洁，单一职责原则
- 添加必要的注释

### 提交规范
- feat: 新功能
- fix: 修复 bug
- docs: 文档更新
- style: 代码格式调整
- refactor: 代码重构
- test: 测试相关
- chore: 构建/工具链相关

## 🤝 贡献指南

1. Fork 本项目
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 提交 Pull Request

## 📄 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件

## 📞 联系方式

如有问题或建议，请通过以下方式联系：

- 提交 Issue
- 发送邮件至：[your-email@example.com]

## 🙏 致谢

感谢所有为本项目做出贡献的开发者！

---

**注意**: 本项目仅供学习和研究使用，请勿用于非法用途。
