import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:ai_anti_fraud_detection_system_frontend/api/system_api.dart';
import 'dart:convert';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  _TestPageState createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  String _healthStatus = '';
  bool _isLoading = false;
  bool _hasError = false;

  /// 检查健康状态
  Future<void> _checkHealth() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _healthStatus = '';
    });

    try {
      final result = await healthCheckAPI();
      
      // 格式化 JSON 显示
      const encoder = JsonEncoder.withIndent('  ');
      final prettyJson = encoder.convert(result);
      
      setState(() {
        _healthStatus = prettyJson;
        _isLoading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _hasError = true;
        _healthStatus = '请求失败: ${e.message}';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _healthStatus = '错误: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF11998e),
              const Color(0xFF38ef7d),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // 顶部标题栏
                Row(
                  children: [
                    IconButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      '接口测试',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                
                // 测试卡片
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 标题
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF11998e).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.health_and_safety,
                                  color: Color(0xFF11998e),
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '健康检查',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'GET /health',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          
                          // 测试按钮
                          ElevatedButton(
                            onPressed: _isLoading ? null : _checkHealth,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF11998e),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                              disabledBackgroundColor: Colors.grey[400],
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.play_arrow, size: 24),
                                      SizedBox(width: 8),
                                      Text(
                                        '测试接口',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                          const SizedBox(height: 24),
                          
                          // 响应结果
                          const Text(
                            '响应结果:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          const SizedBox(height: 12),
                          
                          // 结果显示区域
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _hasError 
                                    ? Colors.red[50] 
                                    : const Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _hasError 
                                      ? Colors.red[200]! 
                                      : Colors.grey[200]!,
                                ),
                              ),
                              child: _healthStatus.isEmpty
                                  ? Center(
                                      child: Text(
                                        '点击上方按钮测试接口',
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 14,
                                        ),
                                      ),
                                    )
                                  : SingleChildScrollView(
                                      child: SelectableText(
                                        _healthStatus,
                                        style: TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 14,
                                          color: _hasError 
                                              ? Colors.red[700] 
                                              : const Color(0xFF2D3748),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

