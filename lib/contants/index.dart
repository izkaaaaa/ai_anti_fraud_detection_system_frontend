// 定义常量数据，基础地址，超时时间，业务状态，请求地址

// ============================================================
// 🌐 网络地址配置中心
// ============================================================
// 
// 📝 地址说明：
// 
// 1. LOCALHOST (127.0.0.1)
//    - 用途：电脑浏览器访问本机后端
//    - 谁能用：只有电脑自己
// 
// 2. EMULATOR_HOST (10.0.2.2)
//    - 用途：Android 模拟器访问电脑后端
//    - 谁能用：只有 Android 模拟器
//    - 说明：自动映射到电脑的 localhost
// 
// 3. WIFI_IP (192.168.31.155)
//    - 用途：真机通过 WiFi 访问电脑后端
//    - 谁能用：同一 WiFi 下的所有设备
//    - 说明：电脑的局域网 IP（可能会变）
// 
// 4. WSL_IP (172.20.16.1)
//    - 用途：Windows 访问 WSL 中的后端
//    - 谁能用：只有电脑内部（Windows ↔ WSL）
//    - 说明：如果后端运行在 WSL 里才需要
// 
// ⚙️ 使用方法：
// - 模拟器测试：改 CURRENT_MODE = DeviceMode.emulator
// - 真机测试：  改 CURRENT_MODE = DeviceMode.realDevice
// - Web 测试：   改 CURRENT_MODE = DeviceMode.web
// 
// ============================================================

/// 设备模式枚举
enum DeviceMode {
  emulator,    // Android 模拟器
  realDevice,  // 真机（通过 WiFi）
  web,         // Web 浏览器
}

// 全局的常量
class GlobalConstants {
  // ============================================================
  // 🎯 在这里修改当前使用的设备模式
  // ============================================================
  static const DeviceMode CURRENT_MODE = DeviceMode.realDevice;
  
  // ============================================================
  // 📍 所有 IP 地址集中管理（修改这里即可）
  // ============================================================
  static const String LOCALHOST = "localhost";           // 本机地址
  static const String EMULATOR_HOST = "10.0.2.2";       // 模拟器专用
  static const String WIFI_IP = "192.168.31.155";       // 电脑 WiFi IP（真机用）
  static const String WSL_IP = "172.20.16.1";           // WSL 虚拟网卡 IP
  static const int PORT = 8000;                          // 后端端口
  
  // ============================================================
  // 🔧 自动选择 BASE_URL（不需要手动改）
  // ============================================================
  static String get BASE_URL {
    String host;
    
    switch (CURRENT_MODE) {
      case DeviceMode.emulator:
        host = EMULATOR_HOST;
        print('🤖 使用模拟器配置: $EMULATOR_HOST');
        break;
      case DeviceMode.realDevice:
        host = WIFI_IP;
        print('📱 使用真机配置: $WIFI_IP');
        break;
      case DeviceMode.web:
        host = LOCALHOST;
        print('🌐 使用 Web 配置: $LOCALHOST');
        break;
    }
    
    return "http://$host:$PORT";
  }
  
  static const int TIME_OUT = 10; // 超时时间（秒）
  static const String TOKEN_KEY = "auth_token"; // token 键名
}

// 存放请求地址接口的常量
class HttpConstants {
  // 认证相关接口
  static const String LOGIN = "/api/users/login"; // 登录请求地址
  static const String REGISTER = "/api/users/register"; // 注册请求地址
  static const String SEND_SMS_CODE = "/api/users/send-code"; // 发送验证码地址
  static const String USER_PROFILE = "/api/users/profile"; // 用户信息接口地址
  
  // 系统接口
  static const String HEALTH = "/health"; // 健康检查接口
  
  // 实时检测接口
  static const String CREATE_CALL_RECORD = "/api/call-records/start"; // 创建通话记录
  static const String END_CALL_RECORD = "/api/call-records/end"; // 结束通话记录
  
  // WebSocket 接口（需要动态拼接 user_id 和 call_id）
  // 格式: /api/detection/ws/{user_id}/{call_id}?token={jwt_token}
  static String getWebSocketUrl(int userId, String callId, String token) {
    // 将 http:// 替换为 ws://
    final wsBaseUrl = GlobalConstants.BASE_URL.replaceFirst('http://', 'ws://');
    return '$wsBaseUrl/api/detection/ws/$userId/$callId?token=$token';
  }
}