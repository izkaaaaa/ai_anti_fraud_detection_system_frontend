import 'package:dio/dio.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';

class DioRequest {
  final _dio = Dio();
  
  DioRequest() {
    // 使用 GlobalConstants 中的配置，自动根据设备模式切换
    final baseUrl = GlobalConstants.BASE_URL;
    
    // 设置基础配置
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = Duration(seconds: GlobalConstants.TIME_OUT);
    _dio.options.receiveTimeout = Duration(seconds: GlobalConstants.TIME_OUT);
    _dio.options.sendTimeout = Duration(seconds: GlobalConstants.TIME_OUT);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // 打印配置信息（调试用）
    print('');
    print('='.padRight(60, '='));
    print('🌐 DioRequest 初始化');
    print('   BASE_URL: $baseUrl');
    print('   TIMEOUT: ${GlobalConstants.TIME_OUT}s');
    print('   如果看到这行，说明已经重启成功！');
    print('='.padRight(60, '='));
    print('');

    // 拦截器
    _addInterceptors();
  }
  
  void _addInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          // 如果有 token，自动添加到请求头
          final token = AuthService().getToken();
          if (token.isNotEmpty) {
            final tokenType = AuthService().getTokenType();
            request.headers['Authorization'] = '$tokenType $token';
            print('🔑 已添加 Token: $tokenType ${token.substring(0, token.length > 20 ? 20 : token.length)}...');
          } else {
            print('⚠️ 警告: Token 为空，未添加 Authorization 头');
          }
          
          // 打印请求信息
          print('📤 请求: ${request.method} ${request.uri}');
          print('   Headers: ${request.headers}');
          if (request.data != null) {
            print('   Data: ${request.data}');
          }
          
          handler.next(request);
        },
        onResponse: (response, handler) {
          // 打印响应信息
          print('📥 响应: ${response.statusCode} ${response.requestOptions.uri}');
          print('   Data: ${response.data}');
          
          // HTTP 状态码 200-299 都认为是成功
          if (response.statusCode! >= 200 && response.statusCode! < 300) {
            handler.next(response);
          }
        },
        onError: (error, handler) {
          // 打印错误信息
          print('❌ 错误: ${error.requestOptions.uri}');
          print('   Type: ${error.type}');
          print('   Message: ${error.message}');
          if (error.response != null) {
            print('   Status: ${error.response?.statusCode}');
            print('   Data: ${error.response?.data}');
          }
          
          // 处理错误响应
          String errorMessage = '请求失败';
          
          if (error.response != null) {
            final data = error.response?.data;
            if (data is Map<String, dynamic>) {
              // 尝试从响应中提取错误信息
              errorMessage = data['msg'] ?? 
                            data['message'] ?? 
                            data['detail'] ?? 
                            '请求失败';
            }
          } else if (error.type == DioExceptionType.connectionTimeout) {
            errorMessage = '连接超时，请检查网络';
          } else if (error.type == DioExceptionType.receiveTimeout) {
            errorMessage = '响应超时，请检查网络';
          } else if (error.type == DioExceptionType.sendTimeout) {
            errorMessage = '发送超时，请检查网络';
          } else if (error.type == DioExceptionType.connectionError) {
            errorMessage = '网络连接失败，请检查后端服务是否启动';
          }
          
          handler.reject(
            DioException(
              requestOptions: error.requestOptions,
              message: errorMessage,
              response: error.response,
              type: error.type,
            ),
          );
        }
      ),
    );
  }

  Future<dynamic> get(String url, {Map<String, dynamic>? params}) {
    return _handleResponse(_dio.get(url, queryParameters: params));
  }
  
  Future<dynamic> post(String url, {dynamic data, Map<String, dynamic>? params}) {
    return _handleResponse(_dio.post(url, data: data, queryParameters: params));
  }
  
  Future<dynamic> put(String url, {dynamic data}) {
    return _handleResponse(_dio.put(url, data: data));
  }
  
  Future<dynamic> delete(String url, {Map<String, dynamic>? params}) {
    return _handleResponse(_dio.delete(url, queryParameters: params));
  }

  // 处理返回结果的函数
  Future<dynamic> _handleResponse(Future<Response<dynamic>> task) async {
    try {
      Response<dynamic> res = await task;
      
      // 直接返回响应数据
      // 因为我们的 API 返回的是标准 HTTP 状态码，不是业务状态码
      return res.data;
    } catch (e) {
      rethrow;
    }
  }
}

// 单例对象（延迟初始化）
DioRequest? _dioRequestInstance;
DioRequest get dioRequest {
  _dioRequestInstance ??= DioRequest();
  return _dioRequestInstance!;
}