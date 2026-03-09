import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';

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
  bool _agreeToTerms = false;
  bool _isLoading = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  
  // 登录方式：0=账号密码, 1=手机号验证码
  int _loginMode = 0;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _textSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _textSlideAnimation = Tween<Offset>(
      begin: Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.7, curve: Curves.easeOutCubic),
      ),
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

  /// 验证账号格式（手机号）
  String? _validateAccount(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入手机号';
    }
    
    if (value.length != 11) {
      return '手机号必须是11位';
    }
    if (!RegExp(r'^[0-9]+$').hasMatch(value)) {
      return '手机号格式错误';
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

    if (!_agreeToTerms) {
      _showError('请先阅读并同意用户服务协议');
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
      body: Stack(
        children: [
          // 背景图片（向上偏移25%，显示下半部分）
          Positioned(
            top: -MediaQuery.of(context).size.height * 0.25,
            left: 0,
            right: 0,
            bottom: 0,
            child: Image.asset(
              'lib/UIimages/登录页背景.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppColors.primary.withOpacity(0.1),
                  child: Center(
                    child: Icon(Icons.image, size: 50, color: AppColors.textSecondary),
                  ),
                );
              },
            ),
          ),
          
          // 欢迎语（在图片上方，左对齐，带弹出效果）
          Positioned(
            top: MediaQuery.of(context).padding.top + 30,
            left: AppTheme.paddingLarge,
            right: AppTheme.paddingLarge,
            child: SlideTransition(
              position: _textSlideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '只愿守护你，',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '每一次安心通话。',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'We only wish to keep you safe in every call.',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.95),
                        letterSpacing: 0.5,
                        height: 1.3,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.3),
                            offset: Offset(0, 1),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // 下半部分：登录表单容器（占55%，带弹出动画）
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOutCubic,
              )),
              child: FractionallySizedBox(
                heightFactor: 0.62,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppTheme.paddingLarge,
                      vertical: AppTheme.paddingMedium,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildLoginModeTabs(),
                              SizedBox(height: 12),
                              _buildAccountField(),
                              SizedBox(height: 10),
                              if (_loginMode == 0) ...[
                                _buildPasswordField(),
                                SizedBox(height: 10),
                                _buildRememberMeRow(),
                              ] else ...[
                                _buildSmsCodeField(),
                              ],
                              SizedBox(height: 10),
                              _buildAgreementRow(),
                              SizedBox(height: 16),
                              _buildLoginButton(),
                              SizedBox(height: 10),
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
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccountField() {
    return _buildTextField(
      controller: _accountController,
      label: '手机号',
      hint: '请输入11位手机号',
      icon: Icons.person_outline,
      validator: _validateAccount,
      keyboardType: TextInputType.phone,
    );
  }

  Widget _buildPasswordField() {
    return _buildTextField(
      controller: _passwordController,
      label: '密码',
      hint: '请输入密码',
      icon: Icons.lock_outline,
      isPassword: true,
      validator: _validatePassword,
    );
  }

  Widget _buildRememberMeRow() {
    return Row(
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
            SizedBox(width: 8),
            Text(
              '记住我',
              style: TextStyle(
                fontSize: 14,
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
              fontSize: 14,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAgreementRow() {
    return Row(
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (value) {
              setState(() {
                _agreeToTerms = value ?? false;
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
        SizedBox(width: 8),
        Flexible(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                '我已阅读并接受',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/user-agreement');
                },
                child: Text(
                  '《用户服务协议》',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.primary.withOpacity(0.8),
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
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
              padding: EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _loginMode == 0 ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: _loginMode == 0 ? AppColors.primary : AppColors.borderMedium,
                  width: 1.5,
                ),
              ),
              child: Text(
                '账号密码',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _loginMode == 0 ? AppColors.textDark : AppColors.textSecondary,
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
              padding: EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _loginMode == 1 ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                border: Border.all(
                  color: _loginMode == 1 ? AppColors.primary : AppColors.borderMedium,
                  width: 1.5,
                ),
              ),
              child: Text(
                '验证码登录',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _loginMode == 1 ? AppColors.textDark : AppColors.textSecondary,
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          keyboardType: keyboardType,
          validator: validator,
          enabled: !_isLoading,
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
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
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppColors.error, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
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
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _smsCodeController,
                keyboardType: TextInputType.number,
                validator: _validateSmsCode,
                enabled: !_isLoading,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
                decoration: InputDecoration(
                  hintText: '请输入验证码',
                  hintStyle: TextStyle(color: AppColors.textLight, fontSize: 14),
                  prefixIcon: Icon(Icons.sms_outlined, color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: AppColors.error, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                    borderSide: BorderSide(color: AppColors.error, width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            SizedBox(width: AppTheme.paddingMedium),
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: (_isSendingCode || _countdown > 0 || _isLoading) 
                    ? AppColors.backgroundCard
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              ),
              child: ElevatedButton(
                onPressed: (_isSendingCode || _countdown > 0 || _isLoading) ? null : _sendSmsCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: (_isSendingCode || _countdown > 0 || _isLoading)
                      ? AppColors.textLight
                      : AppColors.textDark,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _isSendingCode
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.textLight),
                        ),
                      )
                    : Text(
                        _countdown > 0 ? '${_countdown}s' : '获取',
                        style: TextStyle(
                          fontSize: 14,
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
      height: 48,
      decoration: BoxDecoration(
        color: _isLoading ? AppColors.borderLight : AppColors.primary,
        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        boxShadow: _isLoading ? [] : [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.textDark,
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
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.textDark),
                ),
              )
            : Text(
                '登录',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '还没有账户？',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
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
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
