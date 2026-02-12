import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';
import 'package:ai_anti_fraud_detection_system_frontend/pages/NetworkTest/index.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _smsCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _isLoading = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  
  // 登录方式：0=账号密码, 1=手机号验证码
  int _loginMode = 0;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _accountController.dispose();
    _passwordController.dispose();
    _smsCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// 验证账号格式（手机号或用户名）
  String? _validateAccount(String? value) {
    if (value == null || value.isEmpty) {
      return _loginMode == 1 ? '请输入手机号' : '请输入手机号或用户名';
    }
    
    if (_loginMode == 1) {
      if (value.length != 11) {
        return '手机号必须是11位';
      }
      if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
        return '手机号格式错误';
      }
    }
    
    return null;
  }

  /// 验证密码
  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入密码';
    }
    if (value.length < 6) {
      return '密码长度至少6位';
    }
    if (value.length > 20) {
      return '密码长度不能超过20位';
    }
    return null;
  }

  /// 验证验证码
  String? _validateSmsCode(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入验证码';
    }
    return null;
  }

  /// 显示错误提示
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  /// 显示成功提示
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
      ),
    );
  }

  /// 处理登录逻辑
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      // 使用 AuthService 登录
      final success = await AuthService().login(
        _accountController.text.trim(),
        _passwordController.text,
      );

      if (success) {
        _showSuccess('登录成功！');
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          // 登录成功后跳转到主页
          Navigator.of(context).pushReplacementNamed('/');
        }
      } else {
        _showError('账号或密码错误');
      }
    } catch (e) {
      _showError('登录失败: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// 发送验证码
  Future<void> _sendSmsCode() async {
    final phone = _accountController.text.trim();
    if (phone.isEmpty) {
      _showError('请先输入手机号');
      return;
    }
    if (phone.length != 11) {
      _showError('手机号必须是11位');
      return;
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(phone)) {
      _showError('手机号格式错误');
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      // TODO: 实现发送验证码功能
      // await AuthService().sendSmsCode(phone);
      _showSuccess('验证码已发送（功能待实现）');
      
      setState(() {
        _countdown = 60;
      });
      
      _startCountdown();
    } catch (e) {
      _showError('发送失败: ${e.toString()}');
    } finally {
      setState(() {
        _isSendingCode = false;
      });
    }
  }

  /// 开始倒计时
  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_countdown > 0 && mounted) {
        setState(() {
          _countdown--;
        });
        _startCountdown();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // 大图标背景（使用 ColorFiltered 去除白色背景）
          Positioned.fill(
            child: Opacity(
              opacity: 0.08,
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  Colors.white,
                  BlendMode.dstOut,
                ),
                child: Image.asset(
                  'lib/assets/登录界面图标.jpg',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          
          // 渐变色装饰圆圈
          _buildGradientDecorations(),
          
          // 主要内容
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(AppTheme.paddingLarge),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildHeader(),
                            SizedBox(height: AppTheme.paddingXLarge),
                            _buildLoginCard(),
                            SizedBox(height: AppTheme.paddingLarge),
                            _buildFooter(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGradientDecorations() {
    return Stack(
      children: [
        // 左上角 - 明黄色（无勾线）
        Positioned(
          top: -60,
          left: -60,
          child: Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.secondary.withOpacity(0.15),
            ),
          ),
        ),
        // 右上角 - 浅桃色（无勾线）
        Positioned(
          top: 100,
          right: -50,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withOpacity(0.2),
            ),
          ),
        ),
        // 左下角 - 珊瑚橙（无勾线）
        Positioned(
          bottom: 120,
          left: -40,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.18),
            ),
          ),
        ),
        // 右下角 - 深橙棕（无勾线）
        Positioned(
          bottom: -80,
          right: -60,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.brown.withOpacity(0.12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // 大Logo图片（原图，无背景）
        Container(
          width: 160,
          height: 160,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            boxShadow: AppTheme.shadowMedium,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            child: Image.asset(
              'lib/assets/登录界面图标.jpg',
              fit: BoxFit.contain,
            ),
          ),
        ),
        SizedBox(height: AppTheme.paddingLarge),
        
        // 欢迎登录标题（无勾线）
        Text(
          '欢迎登录',
          style: TextStyle(
            fontSize: AppTheme.fontSizeTitle,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        border: Border.all(
          color: AppColors.borderDark,
          width: 2.0,
        ),
        boxShadow: AppTheme.shadowMedium,
      ),
      padding: EdgeInsets.all(AppTheme.paddingLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLoginModeTabs(),
          SizedBox(height: AppTheme.paddingLarge),
          
          _buildTextField(
            controller: _accountController,
            label: _loginMode == 0 ? '手机号/用户名' : '手机号',
            hint: _loginMode == 0 ? '请输入手机号或用户名' : '请输入手机号',
            icon: Icons.person_outline,
            validator: _validateAccount,
            keyboardType: _loginMode == 1 ? TextInputType.phone : TextInputType.text,
          ),
          SizedBox(height: AppTheme.paddingMedium),
          
          if (_loginMode == 0)
            _buildTextField(
              controller: _passwordController,
              label: '密码',
              hint: '请输入密码',
              icon: Icons.lock_outline,
              isPassword: true,
              validator: _validatePassword,
            )
          else
            _buildSmsCodeField(),
          
          if (_loginMode == 0) ...[
            SizedBox(height: AppTheme.paddingMedium),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (value) {
                          setState(() {
                            _rememberMe = value ?? false;
                          });
                        },
                        activeColor: AppColors.primary,
                        checkColor: AppColors.textWhite,
                        side: BorderSide(
                          color: AppColors.borderMedium,
                          width: 1.5,
                        ),
                      ),
                    ),
                    SizedBox(width: AppTheme.paddingSmall),
                    Text(
                      '记住我',
                      style: TextStyle(
                        fontSize: AppTheme.fontSizeSmall,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    '忘记密码？',
                    style: TextStyle(
                      fontSize: AppTheme.fontSizeSmall,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          
          SizedBox(height: AppTheme.paddingLarge),
          _buildLoginButton(),
        ],
      ),
    );
  }

  Widget _buildLoginModeTabs() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _loginMode = 0;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: AppTheme.paddingMedium),
              decoration: BoxDecoration(
                color: _loginMode == 0 ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: _loginMode == 0 ? AppColors.borderDark : AppColors.borderMedium,
                  width: 2.0,
                ),
              ),
              child: Text(
                '账号密码',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                  color: _loginMode == 0 ? AppColors.textWhite : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: AppTheme.paddingMedium),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() {
                _loginMode = 1;
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: AppTheme.paddingMedium),
              decoration: BoxDecoration(
                color: _loginMode == 1 ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: _loginMode == 1 ? AppColors.borderDark : AppColors.borderMedium,
                  width: 2.0,
                ),
              ),
              child: Text(
                '验证码登录',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                  color: _loginMode == 1 ? AppColors.textWhite : AppColors.textSecondary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppTheme.paddingSmall),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          keyboardType: keyboardType,
          validator: validator,
          enabled: !_isLoading,
          style: TextStyle(fontSize: AppTheme.fontSizeMedium),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textLight, fontSize: AppTheme.fontSizeSmall),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: AppColors.inputBackground,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderMedium, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderMedium, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppColors.borderDark, width: 2.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppColors.error, width: 2.0),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: AppTheme.paddingMedium,
              vertical: AppTheme.paddingMedium,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmsCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '验证码',
          style: TextStyle(
            fontSize: AppTheme.fontSizeSmall,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: AppTheme.paddingSmall),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _smsCodeController,
                keyboardType: TextInputType.number,
                validator: _validateSmsCode,
                enabled: !_isLoading,
                style: TextStyle(fontSize: AppTheme.fontSizeMedium),
                decoration: InputDecoration(
                  hintText: '请输入验证码',
                  hintStyle: TextStyle(color: AppColors.textLight, fontSize: AppTheme.fontSizeSmall),
                  prefixIcon: Icon(Icons.sms_outlined, color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: AppColors.borderMedium, width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: AppColors.borderMedium, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: AppColors.borderDark, width: 2.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: AppColors.error, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: AppColors.error, width: 2.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppTheme.paddingMedium,
                    vertical: AppTheme.paddingMedium,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppTheme.paddingMedium),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: (_isSendingCode || _countdown > 0 || _isLoading) 
                    ? AppColors.borderLight 
                    : AppColors.secondaryLight,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: (_isSendingCode || _countdown > 0 || _isLoading)
                      ? AppColors.borderMedium
                      : AppColors.borderDark,
                  width: 2.0,
                ),
              ),
              child: ElevatedButton(
                onPressed: (_isSendingCode || _countdown > 0 || _isLoading) ? null : _sendSmsCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: AppColors.textPrimary,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingMedium),
                ),
                child: _isSendingCode
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textPrimary),
                        ),
                      )
                    : Text(
                        _countdown > 0 ? '${_countdown}s' : '获取',
                        style: TextStyle(
                          fontSize: AppTheme.fontSizeSmall,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: _isLoading ? AppColors.borderLight : AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        border: Border.all(
          color: AppColors.borderDark,
          width: 2.0,
        ),
        boxShadow: _isLoading ? [] : AppTheme.shadowMedium,
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textWhite,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textWhite),
                ),
              )
            : Text(
                '登录',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeLarge,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '还没有账户？',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: AppTheme.fontSizeMedium,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/register');
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: AppTheme.paddingSmall),
              ),
              child: Text(
                '立即注册',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: AppTheme.fontSizeMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: AppTheme.paddingSmall),
        // 网络测试按钮
        TextButton.icon(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => NetworkTestPage()),
            );
          },
          icon: Icon(Icons.wifi_find, size: 18, color: AppColors.textSecondary),
          label: Text(
            '网络测试',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: AppTheme.fontSizeSmall,
            ),
          ),
        ),
      ],
    );
  }
}
