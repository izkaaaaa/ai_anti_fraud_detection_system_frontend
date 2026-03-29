# AI 反诈系统 API 文档

## 概述

本文档详细说明了 AI 反诈系统的所有用户认证和管理接口。系统采用了**邮箱验证码 + 密码**的双重认证机制，支持多种登录方式。

---

## 认证方式

### 1. 邮箱验证码登录（推荐）
- **优点**：无需记忆密码，安全性高
- **流程**：发送验证码 → 输入验证码登录

### 2. 邮箱 + 密码登录
- **优点**：传统方式，用户熟悉
- **流程**：输入邮箱和密码直接登录

### 3. 手机号 + 密码登录
- **优点**：支持手机号登录
- **流程**：输入手机号和密码直接登录

---

## API 端点

### 基础信息
- **基础 URL**：`http://localhost:8000`
- **API 前缀**：`/api/users`
- **认证方式**：JWT Bearer Token

---

## 1. 发送注册验证码

**端点**：`POST /api/users/send-code`

**描述**：发送邮箱验证码用于用户注册

**请求体**：
```json
{
  "email": "user@example.com"
}
```

**请求参数说明**：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | ✓ | 用户邮箱，需要包含 @ 和 . |

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "验证码已发送至邮箱",
  "data": {
    "email": "user@example.com"
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 400 | 邮箱格式不正确 | 邮箱缺少 @ 或 . |
| 500 | 邮箱验证码发送失败，请检查邮箱配置 | 邮件服务配置问题 |

**验证码有效期**：10 分钟

---

## 2. 发送登录验证码

**端点**：`POST /api/users/send-login-code`

**描述**：发送邮箱验证码用于用户登录（验证码登录方式）

**请求体**：
```json
{
  "email": "user@example.com"
}
```

**请求参数说明**：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | ✓ | 用户邮箱 |

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "登录验证码已发送至邮箱",
  "data": {
    "email": "user@example.com"
  }
}
```

**验证码有效期**：10 分钟

---

## 3. 用户注册

**端点**：`POST /api/users/register`

**描述**：使用邮箱验证码进行用户注册（强制使用邮箱验证码）

**请求体**：
```json
{
  "phone": "13800138000",
  "username": "john_doe",
  "name": "张三",
  "email": "user@example.com",
  "email_code": "123456",
  "password": "password123",
  "role_type": "青壮年",
  "gender": "男",
  "profession": "工程师",
  "marital_status": "已婚"
}
```

**请求参数说明**：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| phone | string | ✓ | 手机号，11 位数字 |
| username | string | ✓ | 用户名，3-50 字符 |
| name | string | ✓ | 用户姓名，2-50 字符 |
| email | string | ✓ | 邮箱地址 |
| email_code | string | ✓ | 邮箱验证码，4-6 位 |
| password | string | ✓ | 密码，6-20 字符 |
| role_type | string | ✗ | 角色类型（老人/儿童/学生/青壮年），默认"青壮年" |
| gender | string | ✗ | 性别 |
| profession | string | ✗ | 职业 |
| marital_status | string | ✗ | 婚姻状况 |

**响应示例**（成功 201）：
```json
{
  "code": 201,
  "message": "注册成功",
  "data": {
    "user_id": 1
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 400 | 邮箱为必填项 | 未提供邮箱 |
| 400 | 验证码错误或已过期 | 验证码不正确或已过期 |
| 400 | 该手机号已注册 | 手机号重复 |
| 400 | 该邮箱已注册 | 邮箱重复 |
| 400 | 该用户名已被使用 | 用户名重复 |
| 500 | 注册失败，请稍后重试 | 数据库错误 |

---

## 4. 用户登录

**端点**：`POST /api/users/login`

**描述**：用户登录，支持三种方式

### 方式 1：邮箱 + 验证码登录

**请求体**：
```json
{
  "email": "user@example.com",
  "email_code": "123456"
}
```

### 方式 2：邮箱 + 密码登录

**请求体**：
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

### 方式 3：手机号 + 密码登录

**请求体**：
```json
{
  "phone": "13800138000",
  "password": "password123"
}
```

**请求参数说明**：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| email | string | ✗ | 邮箱（邮箱登录时使用） |
| phone | string | ✗ | 手机号（手机号登录时使用） |
| password | string | ✗ | 密码（密码登录时使用） |
| email_code | string | ✗ | 邮箱验证码（验证码登录时使用） |

**响应示例**（成功 200）：
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "token_type": "bearer",
  "user": {
    "user_id": 1,
    "phone": "13800138000",
    "username": "john_doe",
    "name": "张三",
    "role_type": "青壮年",
    "gender": "男",
    "profession": "工程师",
    "marital_status": "已婚",
    "family_id": null,
    "is_active": true,
    "created_at": "2026-03-26T18:00:00"
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 400 | 登录参数不正确，请提供：邮箱+密码、邮箱+验证码 或 手机号+密码 | 参数组合不正确 |
| 401 | 验证码错误或已过期 | 验证码不正确或已过期 |
| 401 | 账号或密码错误 | 用户不存在或密码错误 |
| 403 | 账号已被禁用 | 用户被禁用 |

**Token 有效期**：30 分钟

---

## 5. 获取当前用户信息

**端点**：`GET /api/users/me`

**描述**：获取当前登录用户的信息

**请求头**：
```
Authorization: Bearer {access_token}
```

**响应示例**（成功 200）：
```json
{
  "user_id": 1,
  "phone": "13800138000",
  "username": "john_doe",
  "name": "张三",
  "role_type": "青壮年",
  "gender": "男",
  "profession": "工程师",
  "marital_status": "已婚",
  "family_id": null,
  "is_active": true,
  "created_at": "2026-03-26T18:00:00"
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 401 | Unauthorized | 未提供 Token 或 Token 无效 |
| 404 | 用户不存在 | 用户已被删除 |

---

## 6. 更新用户画像

**端点**：`PUT /api/users/profile`

**描述**：更新用户的个人画像信息（角色类型、性别、职业、婚姻状况）

**请求头**：
```
Authorization: Bearer {access_token}
```

**请求体**：
```json
{
  "role_type": "老人",
  "gender": "女",
  "profession": "退休",
  "marital_status": "已婚"
}
```

**请求参数说明**：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| role_type | string | ✗ | 角色类型（老人/儿童/学生/青壮年） |
| gender | string | ✗ | 性别 |
| profession | string | ✗ | 职业 |
| marital_status | string | ✗ | 婚姻状况 |

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "用户画像更新成功",
  "data": {
    "user_id": 1,
    "role_type": "老人"
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 401 | Unauthorized | Token 无效或过期 |
| 404 | 用户不存在 | 用户已被删除 |
| 500 | 更新画像失败 | 数据库错误 |

---

## 7. 解绑家庭组

**端点**：`DELETE /api/users/family`

**描述**：解除用户与家庭组的绑定关系

**请求头**：
```
Authorization: Bearer {access_token}
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "解绑成功",
  "data": {
    "user_id": 1
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 401 | Unauthorized | Token 无效或过期 |
| 404 | 用户不存在 | 用户已被删除 |
| 500 | 解绑失败 | 数据库错误 |

---

## 8. 获取监护人信息

**端点**：`GET /api/users/guardian`

**描述**：获取当前用户的监护人信息（通过家庭组管理员表查询）

**请求头**：
```
Authorization: Bearer {access_token}
```

**响应示例**（成功 200，有监护人）：
```json
{
  "code": 200,
  "message": "获取监护人成功",
  "data": {
    "guardians": [
      {
        "user_id": 2,
        "name": "李四",
        "phone": "13900139000",
        "admin_role": "primary"
      },
      {
        "user_id": 3,
        "name": "王五",
        "phone": "13700137000",
        "admin_role": "secondary"
      }
    ]
  }
}
```

**响应示例**（成功 200，未绑定家庭组）：
```json
{
  "code": 200,
  "message": "未绑定家庭组",
  "data": {
    "guardian": null
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 401 | Unauthorized | Token 无效或过期 |

---

## 9. 生成用户安全报告

**端点**：`GET /api/users/{user_id}/security-report`

**描述**：分析用户近期通话记录，生成专属防诈报告

**请求参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| user_id | integer | ✓ | 用户 ID（路径参数） |
| stream | boolean | ✗ | 是否使用流式输出，默认 false |

### 非流式模式（stream=false）

**请求示例**：
```
GET /api/users/1/security-report?stream=false
```

**响应示例**（成功 200）：
```json
{
  "user_id": 1,
  "username": "john_doe",
  "report_generated_at": "2026-03-26T18:30:00",
  "report_content": "# 用户安全监测报告\n\n## 通话统计\n- 总通话数：50\n- 风险通话：5\n...",
  "stats": {
    "total_calls": 50,
    "risk_calls": 5,
    "fake_calls": 2,
    "suspicious_calls": 3,
    "safe_calls": 45,
    "risk_rate": 10.0,
    "daily_trend": [
      {
        "date": "2026-03-20",
        "total": 8,
        "risk": 1
      }
    ],
    "fraud_type_distribution": [
      {
        "type": "冒充公检法",
        "count": 2
      }
    ]
  }
}
```

### 流式模式（stream=true）

**请求示例**：
```
GET /api/users/1/security-report?stream=true
```

**响应格式**：Server-Sent Events (SSE)

**事件流示例**：
```
data: {"type":"metadata","data":{"user_id":1,"username":"john_doe","report_generated_at":"2026-03-26T18:30:00","stats":{...}}}

data: {"type":"content","data":{"chunk":"# 用户安全监测报告\n\n","content":"# 用户安全监测报告\n\n"}}

data: {"type":"content","data":{"chunk":"## 通话统计\n","content":"# 用户安全监测报告\n\n## 通话统计\n"}}

...

data: {"type":"complete","data":{"user_id":1,"username":"john_doe","report_generated_at":"2026-03-26T18:30:00","report_content":"# 用户安全监测报告\n\n...","stats":{...}}}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 404 | 用户不存在 | 用户 ID 不存在 |

---

## 通用响应格式

### 成功响应
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {
    // 具体数据
  }
}
```

### 错误响应
```json
{
  "code": 400,
  "message": "错误描述",
  "data": null
}
```

---

## 状态码说明

| 状态码 | 说明 |
|--------|------|
| 200 | 请求成功 |
| 201 | 资源创建成功 |
| 400 | 请求参数错误 |
| 401 | 未授权（Token 无效或过期） |
| 403 | 禁止访问（账号被禁用） |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

---

## 前端集成指南

### 1. 注册流程

```javascript
// 第一步：发送验证码
POST /api/users/send-code
{
  "email": "user@example.com"
}

// 第二步：用户输入验证码后，提交注册
POST /api/users/register
{
  "phone": "13800138000",
  "username": "john_doe",
  "name": "张三",
  "email": "user@example.com",
  "email_code": "123456",
  "password": "password123",
  "role_type": "青壮年"
}

// 响应：获得 user_id
```

### 2. 登录流程（推荐：验证码登录）

```javascript
// 第一步：发送登录验证码
POST /api/users/send-login-code
{
  "email": "user@example.com"
}

// 第二步：用户输入验证码后，提交登录
POST /api/users/login
{
  "email": "user@example.com",
  "email_code": "123456"
}

// 响应：获得 access_token 和用户信息
```

### 3. 登录流程（备选：密码登录）

```javascript
// 邮箱 + 密码
POST /api/users/login
{
  "email": "user@example.com",
  "password": "password123"
}

// 或手机号 + 密码
POST /api/users/login
{
  "phone": "13800138000",
  "password": "password123"
}

// 响应：获得 access_token 和用户信息
```

### 4. 获取用户信息

```javascript
// 使用 Token 获取当前用户信息
GET /api/users/me
Headers: {
  "Authorization": "Bearer {access_token}"
}
```

### 5. 更新用户画像

```javascript
// 更新用户角色类型等信息
PUT /api/users/profile
Headers: {
  "Authorization": "Bearer {access_token}"
}
{
  "role_type": "老人",
  "gender": "女"
}
```

### 6. 获取监护人信息

```javascript
// 获取当前用户的监护人
GET /api/users/guardian
Headers: {
  "Authorization": "Bearer {access_token}"
}
```

### 7. 生成安全报告

```javascript
// 非流式模式
GET /api/users/{user_id}/security-report?stream=false
Headers: {
  "Authorization": "Bearer {access_token}"
}

// 流式模式（实时显示生成内容）
GET /api/users/{user_id}/security-report?stream=true
Headers: {
  "Authorization": "Bearer {access_token}"
}
// 使用 EventSource 或 fetch 处理 SSE
```

---

## 常见问题

### Q1：验证码有效期是多久？
**A**：验证码有效期为 10 分钟。

### Q2：密码有什么要求？
**A**：密码长度 6-20 字符，建议包含大小写字母、数字和特殊符号。

### Q3：Token 过期了怎么办？
**A**：Token 有效期为 30 分钟，过期后需要重新登录获取新 Token。

### Q4：支持哪些登录方式？
**A**：支持三种方式：
- 邮箱 + 验证码（推荐）
- 邮箱 + 密码
- 手机号 + 密码

### Q5：如何处理流式报告？
**A**：使用 `EventSource` API 或 `fetch` 处理 Server-Sent Events，实时接收报告内容。

---

## 更新日志

### v1.0.0（2026-03-26）
- ✅ 实现邮箱验证码注册
- ✅ 支持多种登录方式
- ✅ 用户画像管理
- ✅ 家庭组绑定/解绑
- ✅ 监护人信息查询
- ✅ 安全报告生成（支持流式输出）

