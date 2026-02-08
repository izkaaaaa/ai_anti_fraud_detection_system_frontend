import 'package:dio/dio.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/index.dart';
import 'package:ai_anti_fraud_detection_system_frontend/utils/token_manager.dart';

class DioRequest {
  final _dio = Dio();
  
  DioRequest() {
    // 设置基础配置
    _dio.options.baseUrl = GlobalConstants.BASE_URL;
    _dio.options.connectTimeout = Duration(seconds: GlobalConstants.TIME_OUT);
    _dio.options.receiveTimeout = Duration(seconds: GlobalConstants.TIME_OUT);
    _dio.options.sendTimeout = Duration(seconds: GlobalConstants.TIME_OUT);
    _dio.options.headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    // 拦截器
    _addInterceptors();
  }
  
  void _addInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          // 如果有 token，自动添加到请求头
          if (tokenManager.getToken().isNotEmpty) {
            request.headers['Authorization'] = 
                '${tokenManager.getTokenType()} ${tokenManager.getToken()}';
          }
          handler.next(request);
        },
        onResponse: (response, handler) {
          // HTTP 状态码 200-299 都认为是成功
          if (response.statusCode! >= 200 && response.statusCode! < 300) {
            handler.next(response);
          }
        },
        onError: (error, handler) {
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
            errorMessage = '连接超时';
          } else if (error.type == DioExceptionType.receiveTimeout) {
            errorMessage = '响应超时';
          } else if (error.type == DioExceptionType.sendTimeout) {
            errorMessage = '发送超时';
          } else if (error.type == DioExceptionType.connectionError) {
            errorMessage = '网络连接失败';
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
  
  Future<dynamic> post(String url, {Map<String, dynamic>? data}) {
    return _handleResponse(_dio.post(url, data: data));
  }
  
  Future<dynamic> put(String url, {Map<String, dynamic>? data}) {
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

// 单例对象
final dioRequest = DioRequest();