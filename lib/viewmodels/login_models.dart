// 登录相关的数据模型

/// 登录请求模型 - 邮箱 + 验证码
class LoginWithEmailCodeRequest {
  final String email;
  final String emailCode;

  LoginWithEmailCodeRequest({
    required this.email,
    required this.emailCode,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'email_code': emailCode,
    };
  }
}

/// 登录请求模型 - 邮箱 + 密码
class LoginWithEmailPasswordRequest {
  final String email;
  final String password;

  LoginWithEmailPasswordRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
    };
  }
}

/// 登录请求模型 - 手机号 + 密码
class LoginWithPhonePasswordRequest {
  final String phone;
  final String password;

  LoginWithPhonePasswordRequest({
    required this.phone,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'password': password,
    };
  }
}

/// 注册请求模型
class RegisterRequest {
  final String phone;
  final String username;
  final String name;
  final String email;
  final String emailCode;
  final String password;
  final String? roleType;      // 角色类型
  final String? gender;        // 性别
  final String? profession;    // 职业
  final String? maritalStatus; // 婚姻状况

  RegisterRequest({
    required this.phone,
    required this.username,
    required this.name,
    required this.email,
    required this.emailCode,
    required this.password,
    this.roleType,
    this.gender,
    this.profession,
    this.maritalStatus,
  });

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'phone': phone,
      'username': username,
      'name': name,
      'email': email,
      'email_code': emailCode,
      'password': password,
    };
    
    // 只添加非空的可选字段
    if (roleType != null && roleType!.isNotEmpty) {
      map['role_type'] = roleType;
    }
    if (gender != null && gender!.isNotEmpty) {
      map['gender'] = gender;
    }
    if (profession != null && profession!.isNotEmpty) {
      map['profession'] = profession;
    }
    if (maritalStatus != null && maritalStatus!.isNotEmpty) {
      map['marital_status'] = maritalStatus;
    }
    
    return map;
  }
}

/// 注册响应模型
class RegisterResponse {
  final int code;
  final String message;
  final Map<String, dynamic> data;

  RegisterResponse({
    required this.code,
    required this.message,
    required this.data,
  });

  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      code: json['code'] ?? 200,
      message: json['message'] ?? 'success',
      data: json['data'] ?? {},
    );
  }
}

/// 用户信息模型
class User {
  final int userId;
  final String phone;
  final String username;
  final String name;
  final String? roleType;      // 角色类型
  final String? gender;        // 性别
  final String? profession;    // 职业
  final String? maritalStatus; // 婚姻状况
  final int? familyId;
  final bool isActive;
  final String createdAt;

  User({
    required this.userId,
    required this.phone,
    required this.username,
    required this.name,
    this.roleType,
    this.gender,
    this.profession,
    this.maritalStatus,
    this.familyId,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? 0,
      phone: json['phone'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      roleType: json['role_type'],
      gender: json['gender'],
      profession: json['profession'],
      maritalStatus: json['marital_status'],
      familyId: json['family_id'],
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'phone': phone,
      'username': username,
      'name': name,
      'role_type': roleType,
      'gender': gender,
      'profession': profession,
      'marital_status': maritalStatus,
      'family_id': familyId,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }
}

/// 登录响应模型
class LoginResponse {
  final String accessToken;
  final String tokenType;
  final User user;

  LoginResponse({
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['access_token'] ?? '',
      tokenType: json['token_type'] ?? 'bearer',
      user: User.fromJson(json['user'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'access_token': accessToken,
      'token_type': tokenType,
      'user': user.toJson(),
    };
  }
}

