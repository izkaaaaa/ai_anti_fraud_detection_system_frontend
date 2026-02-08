// 登录相关的数据模型

/// 登录请求模型
class LoginRequest {
  final String phone;
  final String password;

  LoginRequest({
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

/// 用户信息模型
class User {
  final String phone;
  final String username;
  final String name;
  final int userId;
  final int familyId;
  final bool isActive;
  final String createdAt;

  User({
    required this.phone,
    required this.username,
    required this.name,
    required this.userId,
    required this.familyId,
    required this.isActive,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      phone: json['phone'] ?? '',
      username: json['username'] ?? '',
      name: json['name'] ?? '',
      userId: json['user_id'] ?? 0,
      familyId: json['family_id'] ?? 0,
      isActive: json['is_active'] ?? false,
      createdAt: json['created_at'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'username': username,
      'name': name,
      'user_id': userId,
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

