import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:ai_anti_fraud_detection_system_frontend/api/auth_api.dart';
import 'package:ai_anti_fraud_detection_system_frontend/contants/theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _emailCodeController = TextEditingController();
  final TextEditingController _professionController = TextEditingController(); // 新增：职业
  final _formKey = GlobalKey<FormState>();
  
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _isSendingCode = false;
  int _countdown = 0;
  bool _showAdvancedOptions = false; // 新增：是否显示高级选项
  
  // 新增：用户画像字段
  String? _selectedRoleType = '青壮年';
  String? _selectedGender;
  String? _selectedMaritalStatus;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.2, 0.8, curve: Curves.easeOut),
      ),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _emailCodeController.dispose();
    _professionController.dispose();
    _animationController.dispose();
    super.dispose();
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

  /// 验证用户名
  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入用户名';
    }
    if (value.length < 3) {
      return '用户名至少3位';
    }
    return null;
  }

  /// 验证姓名
  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return '请输入姓名';
    }
    if (value.length < 2) {
      return '姓名至少2个字符';
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

  /// 验证确认密码
  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return '请确认密码';
    }
    if (value != _passwordController.text) {
      return '两次密码不一致';
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

  /// 处理注册逻辑
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreeToTerms) {
      _showError('请阅读并同意用户协议和隐私政策');
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
    });

    try {
      final registerResponse = await registerAPI(
        phone: _phoneController.text.trim(),
        username: _usernameController.text.trim(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        emailCode: _emailCodeController.text.trim(),
        password: _passwordController.text,
        roleType: _selectedRoleType,
        gender: _selectedGender,
        profession: _professionController.text.trim().isEmpty ? null : _professionController.text.trim(),
        maritalStatus: _selectedMaritalStatus,
      );

      _showSuccess('注册成功！请登录');
      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      String errorMessage = '注册失败';
      
      if (e.response?.statusCode == 422) {
        errorMessage = '输入信息格式不正确';
      } else if (e.response?.statusCode == 400) {
        final responseData = e.response?.data;
        if (responseData is Map && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        } else {
          errorMessage = '该邮箱或手机号已被注册';
        }
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      
      _showError(errorMessage);
    } catch (e) {
      _showError('注册失败: ${e.toString()}');
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
      await sendRegisterCodeAPI(email);
      _showSuccess('验证码已发送到邮箱');
      
      setState(() {
        _countdown = 60;
      });
      
      _startCountdown();
    } on DioException catch (e) {
      String errorMessage = '发送失败';
      
      if (e.response?.statusCode == 400) {
        errorMessage = '邮箱格式不正确';
      } else if (e.message != null) {
        errorMessage = e.message!;
      }
      
      _showError(errorMessage);
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
      backgroundColor: const Color(0xFFF8FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAF9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F1923)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '注册账户',
          style: TextStyle(
            color: Color(0xFF0F1923),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: AppTheme.paddingLarge,
              vertical: AppTheme.paddingMedium,
            ),
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTextField(
                          controller: _phoneController,
                          label: '手机号',
                          hint: '请输入11位手机号',
                          icon: Icons.phone_outlined,
                          validator: _validatePhone,
                          keyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: AppTheme.paddingSmall),
                        
                        _buildTextField(
                          controller: _usernameController,
                          label: '用户名',
                          hint: '请输入用户名',
                          icon: Icons.person_outline,
                          validator: _validateUsername,
                        ),
                        SizedBox(height: AppTheme.paddingSmall),
                        
                        _buildTextField(
                          controller: _nameController,
                          label: '姓名',
                          hint: '请输入真实姓名',
                          icon: Icons.badge_outlined,
                          validator: _validateName,
                        ),
                        SizedBox(height: AppTheme.paddingSmall),
                        
                        _buildTextField(
                          controller: _emailController,
                          label: '邮箱',
                          hint: '请输入邮箱地址',
                          icon: Icons.email_outlined,
                          validator: _validateEmail,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        SizedBox(height: AppTheme.paddingSmall),
                        
                        _buildTextField(
                          controller: _passwordController,
                          label: '密码',
                          hint: '请输入密码（6-20位）',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isPasswordVisible: _isPasswordVisible,
                          validator: _validatePassword,
                          onTogglePassword: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        SizedBox(height: AppTheme.paddingSmall),
                        
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: '确认密码',
                          hint: '请再次输入密码',
                          icon: Icons.lock_outline,
                          isPassword: true,
                          isPasswordVisible: _isConfirmPasswordVisible,
                          validator: _validateConfirmPassword,
                          onTogglePassword: () {
                            setState(() {
                              _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                        SizedBox(height: AppTheme.paddingSmall),
                        
                        _buildSmsCodeField(),
                        SizedBox(height: AppTheme.paddingSmall),
                        
                        _buildAdvancedOptionsToggle(),
                        if (_showAdvancedOptions) ...[
                          SizedBox(height: AppTheme.paddingSmall),
                          _buildAdvancedOptionsSection(),
                        ],
                        SizedBox(height: AppTheme.paddingSmall),
                        
                        _buildAgreementCheckbox(),
                        SizedBox(height: AppTheme.paddingMedium),
                        
                        _buildRegisterButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    VoidCallback? onTogglePassword,
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
          obscureText: isPassword && !isPasswordVisible,
          keyboardType: keyboardType,
          validator: validator,
          enabled: !_isLoading,
          style: TextStyle(
            fontSize: AppTheme.fontSizeMedium,
            color: AppColors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: AppColors.textLight, fontSize: AppTheme.fontSizeSmall),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      isPasswordVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: AppColors.textLight,
                      size: 20,
                    ),
                    onPressed: onTogglePassword,
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
              borderSide: BorderSide(color: AppColors.primary, width: 1.0),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppColors.error, width: 1.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              borderSide: BorderSide(color: AppColors.error, width: 1.0),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              height: 44,
              decoration: BoxDecoration(
                color: (_isSendingCode || _countdown > 0 || _isLoading) 
                    ? const Color(0xFFF3F4F6)
                    : kAccent,
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

  Widget _buildAgreementCheckbox() {
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        SizedBox(width: AppTheme.paddingSmall),
        Expanded(
          child: Wrap(
            children: [
              Text(
                '我已阅读并同意',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/user-agreement');
                },
                child: Text(
                  '《用户协议》',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
                    color: AppColors.primary.withOpacity(0.8),
                    decoration: TextDecoration.underline,
                    decorationColor: AppColors.primary.withOpacity(0.8),
                  ),
                ),
              ),
              Text(
                '和',
                style: TextStyle(
                  fontSize: AppTheme.fontSizeSmall,
                  color: AppColors.textSecondary,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pushNamed('/user-agreement');
                },
                child: Text(
                  '《隐私政策》',
                  style: TextStyle(
                    fontSize: AppTheme.fontSizeSmall,
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

  // 高级选项切换按钮
  Widget _buildAdvancedOptionsToggle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAdvancedOptions = !_showAdvancedOptions;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.paddingMedium,
          vertical: AppTheme.paddingSmall,
        ),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _showAdvancedOptions ? Icons.expand_less : Icons.expand_more,
              color: AppColors.primary,
              size: 20,
            ),
            SizedBox(width: 8),
            Text(
              _showAdvancedOptions ? '收起完善资料' : '完善资料（选填）',
              style: TextStyle(
                fontSize: AppTheme.fontSizeSmall,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            
          ],
        ),
      ),
    );
  }

  // 高级选项区域
  Widget _buildAdvancedOptionsSection() {
    const kAccent = Color(0xFF58A183);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.info_outline, size: 15, color: kAccent),
              SizedBox(width: 6),
              Text(
                '完善资料可获得更精准的防骗建议',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          _buildDropdownField(
            label: '角色类型',
            value: _selectedRoleType,
            items: ['青壮年', '老人', '学生', '其他'],
            onChanged: (value) {
              setState(() {
                _selectedRoleType = value;
              });
            },
          ),
          const SizedBox(height: 12),
          
          _buildDropdownField(
            label: '性别',
            value: _selectedGender,
            hint: '请选择性别',
            items: ['男', '女', '未知'],
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
          const SizedBox(height: 12),
          
          _buildTextField(
            controller: _professionController,
            label: '职业',
            hint: '如：工程师、教师、学生等',
            icon: Icons.work_outline,
          ),
          const SizedBox(height: 12),
          
          _buildDropdownField(
            label: '婚姻状况',
            value: _selectedMaritalStatus,
            hint: '请选择婚姻状况',
            items: ['单身', '已婚', '离异'],
            onChanged: (value) {
              setState(() {
                _selectedMaritalStatus = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // 下拉选择框
  Widget _buildDropdownField({
    required String label,
    required String? value,
    String? hint,
    required List<String> items,
    required Function(String?) onChanged,
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
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text(
                hint ?? '请选择$label',
                style: const TextStyle(
                  color: Color(0xFF9CA3AF),
                  fontSize: 13,
                ),
              ),
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down, color: kAccent),
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF0F1923),
              ),
              dropdownColor: Colors.white,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item),
                );
              }).toList(),
              onChanged: _isLoading ? null : onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterButton() {
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
        onPressed: _isLoading ? null : _handleRegister,
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
                '注册',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
      ),
    );
  }
}
