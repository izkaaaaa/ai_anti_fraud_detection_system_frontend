import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:dio/dio.dart';

class NetworkTestPage extends StatefulWidget {
  const NetworkTestPage({super.key});

  @override
  State<NetworkTestPage> createState() => _NetworkTestPageState();
}

class _NetworkTestPageState extends State<NetworkTestPage> {
  String _result = '点击按钮测试网络连接';
  bool _isLoading = false;
  Color _resultColor = AppColors.textSecondary;

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _result = '正在测试连接...';
      _resultColor = AppColors.textSecondary;
    });

    try {
      final dio = Dio();
      
      // 测试多个地址
      final testUrls = [
        'http://172.20.16.1:8000/health',
        'http://10.0.2.2:8000/health',
        'http://localhost:8000/health',
      ];

      String successUrl = '';
      String errorMessage = '';

      for (var url in testUrls) {
        try {
          print('🧪 测试: $url');
          final response = await dio.get(
            url,
            options: Options(
              connectTimeout: Duration(seconds: 5),
              receiveTimeout: Duration(seconds: 5),
            ),
          );

          if (response.statusCode == 200) {
            successUrl = url;
            print('✅ 成功: $url');
            print('   响应: ${response.data}');
            break;
          }
        } catch (e) {
          print('❌ 失败: $url');
          print('   错误: $e');
          errorMessage = e.toString();
        }
      }

      if (successUrl.isNotEmpty) {
        setState(() {
          _result = '✅ 连接成功！\n\n可用地址：\n$successUrl\n\n请在代码中使用这个地址';
          _resultColor = AppColors.success;
          _isLoading = false;
        });
      } else {
        setState(() {
          _result = '❌ 所有地址都无法连接\n\n错误信息：\n${errorMessage.substring(0, errorMessage.length > 200 ? 200 : errorMessage.length)}...\n\n请检查：\n1. 后端是否启动\n2. 后端是否用 --host 0.0.0.0 启动\n3. 防火墙是否阻止';
          _resultColor = AppColors.error;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _result = '❌ 测试失败\n\n错误：$e';
        _resultColor = AppColors.error;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '网络测试',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: AppTheme.fontSizeLarge,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1.5),
          child: Container(
            color: AppColors.borderMedium,
            height: 1.5,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(AppTheme.paddingLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 说明卡片
            Container(
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppColors.primary, width: 2.0),
              ),
              padding: EdgeInsets.all(AppTheme.paddingMedium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '测试说明',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeMedium,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '点击下方按钮测试后端连接\n将自动尝试多个地址',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: AppTheme.paddingLarge),
            
            // 测试按钮
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: _isLoading ? AppColors.borderLight : AppColors.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(color: AppColors.borderDark, width: 2.0),
                boxShadow: _isLoading ? [] : AppTheme.shadowMedium,
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _testConnection,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.textWhite,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                ),
                child: _isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            '测试中...',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_find, size: 24),
                          SizedBox(width: 12),
                          Text(
                            '测试后端连接',
                            style: TextStyle(
                              fontSize: AppTheme.fontSizeLarge,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            
            SizedBox(height: AppTheme.paddingLarge),
            
            // 结果显示
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  border: Border.all(color: AppColors.borderDark, width: 2.0),
                ),
                padding: EdgeInsets.all(AppTheme.paddingLarge),
                child: SingleChildScrollView(
                  child: Text(
                    _result,
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeMedium,
                      color: _resultColor,
                      height: 1.6,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

