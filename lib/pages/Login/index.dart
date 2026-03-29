import 'package:flutter/material.dart';
import 'package:ai_anti_fraud_detection_system_frontend/services/auth_service.dart';
import 'package:ai_anti_fraud_detection_system_frontend/api/auth_api.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _emailCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  bool _isPasswordVisible = false;
  bool _rememberMe = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  
  // 登录方式：0=手机号密码, 1=邮箱密码, 2=邮箱验证码
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
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _emailCodeController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// 验证邮箱格式
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入邮箱';
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
      return '邮箱格式错误';
    }
    return null;
  }

  /// 验证手机号格式
  String? _validatePhone(String? value) {
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

  /// 验证邮箱验证码
  String? _validateEmailCode(String? value) {
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
      bool success = false;
      
      if (_loginMode == 0) {
        // 手机号 + 密码
        success = await AuthService().loginWithPhonePassword(
          _phoneController.text.trim(),
          _passwordController.text,
        );
      } else if (_loginMode == 1) {
        // 邮箱 + 密码
        success = await AuthService().loginWithEmailPassword(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } else {
        // 邮箱 + 验证码
        success = await AuthService().loginWithEmailCode(
          _emailController.text.trim(),
          _emailCodeController.text.trim(),
        );
      }

      if (success) {
        _showSuccess('登录成功！');
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/');
        }
      } else {
        _showError('登录失败，请检查账号和密码/验证码');
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

  /// 发送邮箱验证码
  Future<void> _sendEmailCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      _showError('请先输入邮箱');
      return;
    }
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email)) {
      _showError('邮箱格式错误');
      return;
    }

    setState(() {
      _isSendingCode = true;
    });

    try {
      await sendLoginCodeAPI(email);
      _showSuccess('验证码已发送到邮箱');
      
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
                  color: const Color(0xFF58A183).withOpacity(0.1),
                  child: const Center(
                    child: Icon(Icons.image, size: 50, color: Color(0xFF58A183)),
                  ),
                );
              },
            ),
          ),
          
          // 欢迎语（在图片上方，左对齐，带弹出效果）
          Positioned(
            top: MediaQuery.of(context).padding.top + 30,
            left: 24,
            right: 24,
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
                            offset: const Offset(0, 2),
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
                            offset: const Offset(0, 2),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
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
                            offset: const Offset(0, 1),
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
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: _animationController,
                curve: Curves.easeOutCubic,
              )),
              child: FractionallySizedBox(
                heightFactor: 0.62,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF8FAF9),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
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
                              const SizedBox(height: 12),
                              if (_loginMode == 0 || _loginMode == 1) ...[
                                _buildPhoneField(),
                              ] else ...[
                                _buildAccountField(),
                              ],
                              const SizedBox(height: 10),
                              if (_loginMode == 0 || _loginMode == 1) ...[
                                _buildPasswordField(),
                                const SizedBox(height: 10),
                                _buildRememberMeRow(),
                              ] else ...[
                                _buildEmailCodeField(),
                              ],
                              const SizedBox(height: 10),
                              _buildAgreementRow(),
                              const SizedBox(height: 16),
                              _buildLoginButton(),
                              const SizedBox(height: 10),
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
      controller: _emailController,
      label: '邮箱',
      hint: '请输入邮箱地址',
      icon: Icons.email_outlined,
      validator: _validateEmail,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPhoneField() {
    return _buildTextField(
      controller: _phoneController,
      label: '手机号',
      hint: '请输入11位手机号',
      icon: Icons.phone_outlined,
      validator: _validatePhone,
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
              width: 18,
              height: 18,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
                activeColor: const Color(0xFF58A183),
                checkColor: Colors.white,
                side: const BorderSide(
                  color: Color(0xFFE5E7EB),
                  width: 1.5,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              '记住我',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          child: const Text(
            '忘记密码？',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF58A183),
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
          width: 18,
          height: 18,
          child: Checkbox(
            value: _agreeToTerms,
            onChanged: (value) {
              setState(() {
                _agreeToTerms = value ?? false;
              });
            },
            activeColor: const Color(0xFF58A183),
            checkColor: Colors.white,
            side: const BorderSide(
              color: Color(0xFFE5E7EB),
              width: 1.5,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Text(
                '我已阅读并接受',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/user-agreement');
                },
                child: const Text(
                  '《用户服务协议》',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF58A183),
                    decoration: TextDecoration.underline,
                    decorationColor: Color(0xFF58A183),
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
    const kAccent = Color(0xFF58A183);
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _loginMode = 0),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: _loginMode == 0 ? kAccent : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _loginMode == 0 ? kAccent : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
                boxShadow: _loginMode == 0
                    ? [BoxShadow(color: kAccent.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Text(
                '手机号密码',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _loginMode == 0 ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _loginMode = 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: _loginMode == 1 ? kAccent : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _loginMode == 1 ? kAccent : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
                boxShadow: _loginMode == 1
                    ? [BoxShadow(color: kAccent.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Text(
                '邮箱密码',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _loginMode == 1 ? Colors.white : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _loginMode = 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: _loginMode == 2 ? kAccent : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _loginMode == 2 ? kAccent : const Color(0xFFE5E7EB),
                  width: 1.5,
                ),
                boxShadow: _loginMode == 2
                    ? [BoxShadow(color: kAccent.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))]
                    : [],
              ),
              child: Text(
                '邮箱验证码',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _loginMode == 2 ? Colors.white : const Color(0xFF6B7280),
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
    const kAccent = Color(0xFF58A183);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1923),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: isPassword && !_isPasswordVisible,
          keyboardType: keyboardType,
          validator: validator,
          enabled: !_isLoading,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF0F1923),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            prefixIcon: Icon(icon, color: kAccent, size: 18),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: const Color(0xFF9CA3AF),
                      size: 18,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  )
                : null,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: kAccent, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailCodeField() {
    const kAccent = Color(0xFF58A183);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '邮箱验证码',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F1923),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _emailCodeController,
                keyboardType: TextInputType.number,
                validator: _validateEmailCode,
                enabled: !_isLoading,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF0F1923),
                ),
                decoration: InputDecoration(
                  hintText: '请输入验证码',
                  hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
                  prefixIcon: const Icon(Icons.mail_outline, color: kAccent, size: 18),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: kAccent, width: 1.5),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: (_isSendingCode || _countdown > 0 || _isLoading) ? const Color(0xFFF3F4F6) : kAccent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ElevatedButton(
                onPressed: (_isSendingCode || _countdown > 0 || _isLoading) ? null : _sendEmailCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: (_isSendingCode || _countdown > 0 || _isLoading)
                      ? const Color(0xFF9CA3AF)
                      : Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: _isSendingCode
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9CA3AF)),
                        ),
                      )
                    : Text(
                        _countdown > 0 ? '${_countdown}s' : '获取',
                        style: const TextStyle(
                          fontSize: 12,
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
    const kAccent = Color(0xFF58A183);
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: _isLoading ? const Color(0xFFF3F4F6) : kAccent,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isLoading
            ? []
            : [BoxShadow(color: kAccent.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: _isLoading ? const Color(0xFF9CA3AF) : Colors.white,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF9CA3AF)),
                ),
              )
            : const Text(
                '登录',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          '还没有账户？',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushNamed('/register');
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: const Text(
            '立即注册',
            style: TextStyle(
              color: Color(0xFF58A183),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
