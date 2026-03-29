# 家庭组管理 API 文档

## 概述

家庭组是系统的核心功能，用于建立监护人与被监护人之间的关系。支持多管理员、多成员的灵活管理模式。

**核心特性**：
- 一个用户可以作为管理员管理多个家庭组
- 一个用户作为普通成员只能属于一个家庭组
- 支持主管理员、副管理员、普通成员三种角色
- 支持一键求助和远程干预功能

---

## API 端点

- **基础 URL**：`http://localhost:8000`
- **API 前缀**：`/api/family`
- **认证方式**：JWT Bearer Token

---

## 1. 创建家庭组

**端点**：`POST /api/family/create`

**描述**：创建新的家庭组，创建者自动成为主管理员

**请求参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| name | string | ✓ | 家庭组名称 |

**请求示例**：
```
POST /api/family/create?name=我的家庭
Authorization: Bearer {access_token}
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "家庭组创建成功",
  "data": {
    "family_id": 1,
    "group_name": "我的家庭"
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 400 | 您已作为普通成员加入一个家庭组，请先退出 | 用户已是某家庭组的普通成员 |

**说明**：
- 创建者自动成为主管理员
- 如果创建者已是其他家庭组的管理员，可以继续创建新家庭组
- 创建者的 `family_id` 会更新为新创建的家庭组

---

## 2. 申请加入家庭组

**端点**：`POST /api/family/{family_id}/apply`

**描述**：申请加入指定的家庭组，需要管理员审批

**请求参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| family_id | integer | ✓ | 家庭组 ID（路径参数） |

**请求示例**：
```
POST /api/family/1/apply
Authorization: Bearer {access_token}
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "申请已发送，等待管理员审批"
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 404 | 未找到该ID的家庭组 | 家庭组不存在 |
| 400 | 您已加入一个家庭组，请先退出 | 用户已是某家庭组的成员 |
| 400 | 您已提交过申请，请等待管理员审批 | 重复申请 |

---

## 3. 获取待审批列表

**端点**：`GET /api/family/applications`

**描述**：【管理员端】获取所有管理的家庭组的待审批申请列表

**请求示例**：
```
GET /api/family/applications
Authorization: Bearer {access_token}
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "items": [
      {
        "application_id": 1,
        "family_id": 1,
        "family_name": "我的家庭",
        "user_id": 2,
        "username": "john_doe",
        "phone": "13800138000",
        "role_type": "青壮年",
        "apply_time": "2026-03-29 11:30:00"
      }
    ]
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 403 | 您不是任何家庭组的管理员 | 用户无管理权限 |

---

## 4. 审批申请

**端点**：`PUT /api/family/applications/{app_id}`

**描述**：【管理员】同意或拒绝成员加入申请

**请求参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| app_id | integer | ✓ | 申请 ID（路径参数） |
| is_approve | boolean | ✓ | true=同意，false=拒绝 |

**请求示例**：
```
PUT /api/family/applications/1?is_approve=true
Authorization: Bearer {access_token}
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "操作成功，已同意"
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 404 | 申请不存在 | 申请 ID 不存在 |
| 400 | 该申请已处理 | 申请已被审批过 |
| 403 | 无权审批此申请 | 操作者不是该家庭组的管理员 |

---

## 5. 获取家庭成员列表

**端点**：`GET /api/family/members`

**描述**：获取家庭组成员列表

**请求参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| family_id | integer | ✗ | 家庭组 ID，不传则查询当前用户所在家庭组 |

**请求示例**：
```
# 查询当前用户所在家庭组的成员
GET /api/family/members
Authorization: Bearer {access_token}

# 查询指定家庭组的成员
GET /api/family/members?family_id=1
Authorization: Bearer {access_token}
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "获取成员列表成功",
  "data": {
    "family_id": 1,
    "group_name": "我的家庭",
    "members": [
      {
        "user_id": 1,
        "username": "admin_user",
        "name": "张三",
        "phone": "13800138000",
        "role_type": "青壮年",
        "admin_role": "primary",
        "is_me": true
      },
      {
        "user_id": 2,
        "username": "john_doe",
        "name": "李四",
        "phone": "13900139000",
        "role_type": "老人",
        "admin_role": "none",
        "is_me": false
      }
    ]
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 400 | 您还未加入任何家庭组 | 用户未加入家庭组 |
| 403 | 您无权查看该家庭组的成员信息 | 无权限查看 |
| 404 | 家庭组不存在 | 家庭组已被删除 |

**字段说明**：
- `admin_role`：用户在家庭组中的角色
  - `primary`：主管理员
  - `secondary`：副管理员
  - `none`：普通成员
- `is_me`：是否为当前用户

---

## 6. 设置/取消管理员

**端点**：`PUT /api/family/members/{user_id}/admin-role`

**描述**：【主管理员】设置成员的管理员角色

**请求参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| user_id | integer | ✓ | 目标用户 ID（路径参数） |
| role | string | ✓ | 角色：none/secondary/primary |

**请求示例**：
```
PUT /api/family/members/2/admin-role?role=secondary
Authorization: Bearer {access_token}
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "已将 john_doe 设置为副管理员"
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 400 | 您还未加入家庭组 | 操作者未加入家庭组 |
| 403 | 只有主管理员可以设置成员角色 | 操作者不是主管理员 |
| 404 | 该用户不在您的家庭组中 | 目标用户不存在或不在同一家庭组 |
| 400 | 无效的角色值，可选: none/secondary/primary | 角色参数错误 |

**规则**：
- 只有主管理员可以设置其他成员的角色
- 一个家庭组只能有一个主管理员
- 设置为主管理员时，当前主管理员会自动降级为副管理员

---

## 7. 移除成员

**端点**：`DELETE /api/family/members/{user_id}`

**描述**：【管理员】将成员移出家庭组

**请求参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| user_id | integer | ✓ | 目标用户 ID（路径参数） |

**请求示例**：
```
DELETE /api/family/members/2
Authorization: Bearer {access_token}
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "已将该成员移出家庭组"
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 400 | 您还未加入家庭组 | 操作者未加入家庭组 |
| 403 | 只有管理员可以移除成员 | 操作者不是管理员 |
| 404 | 该用户不在您的家庭组中 | 目标用户不存在或不在同一家庭组 |
| 400 | 不能移除主管理员 | 不能移除主管理员 |
| 403 | 副管理员不能移除其他副管理员 | 权限限制 |

---

## 8. 退出家庭组

**端点**：`POST /api/family/leave`

**描述**：退出当前所在的家庭组

**请求示例**：
```
POST /api/family/leave
Authorization: Bearer {access_token}
```

**响应示例**（成功 200，普通成员）：
```json
{
  "code": 200,
  "message": "已退出家庭组"
}
```

**响应示例**（成功 200，主管理员且无其他成员）：
```json
{
  "code": 200,
  "message": "家庭组已解散"
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 400 | 您还未加入任何家庭组 | 用户未加入家庭组 |
| 400 | 您是主管理员，家庭组内还有其他成员。请先转让主管理员身份或移除所有成员后再退出 | 主管理员无法直接退出 |

**说明**：
- 普通成员和副管理员可以直接退出
- 主管理员退出时，如果还有其他成员，需要先转让主管理员身份或移除所有成员
- 主管理员是唯一成员时，退出会自动解散家庭组

---

## 9. 获取家庭组详情

**端点**：`GET /api/family/info`

**描述**：获取当前用户所在家庭组的详细信息

**请求示例**：
```
GET /api/family/info
Authorization: Bearer {access_token}
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "family_id": 1,
    "group_name": "我的家庭",
    "created_at": "2026-03-29T10:00:00",
    "my_role": "primary",
    "primary_admin": {
      "user_id": 1,
      "username": "admin_user",
      "phone": "13800138000"
    },
    "statistics": {
      "total_members": 3,
      "primary_admins": 1,
      "secondary_admins": 1,
      "normal_members": 1
    }
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 400 | 您还未加入任何家庭组 | 用户未加入家庭组 |
| 404 | 家庭组不存在 | 家庭组已被删除 |

---

## 10. 获取我管理的家庭组列表

**端点**：`GET /api/family/my-admin-families`

**描述**：获取当前用户作为管理员的所有家庭组

**请求示例**：
```
GET /api/family/my-admin-families
Authorization: Bearer {access_token}
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "items": [
      {
        "family_id": 1,
        "group_name": "我的家庭",
        "my_role": "primary",
        "member_count": 3,
        "created_at": "2026-03-29T10:00:00"
      },
      {
        "family_id": 2,
        "group_name": "公司团队",
        "my_role": "secondary",
        "member_count": 5,
        "created_at": "2026-03-28T15:30:00"
      }
    ]
  }
}
```

**说明**：
- 返回用户作为主管理员或副管理员的所有家庭组
- 包含每个家庭组的成员数量

---

## 11. 一键求助（SOS）

**端点**：`POST /api/family/sos`

**描述**：用户主动向家庭组监护人发送求助信号

**请求参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| call_id | integer | ✓ | 当前通话 ID |
| message | string | ✗ | 求助信息，默认"我正在遭遇可疑通话，请立即联系我！" |

**请求示例**：
```
POST /api/family/sos?call_id=123&message=我需要帮助！
Authorization: Bearer {access_token}
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "求助信号已发送给 2 位监护人",
  "data": {
    "notified_count": 2,
    "call_id": 123,
    "timestamp": "2026-03-29T11:30:00"
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 404 | 用户不存在 | 用户已被删除 |
| 400 | 您未加入任何家庭组，无法使用此功能 | 用户未加入家庭组 |
| 400 | 您的家庭组没有监护人，无法发送求助 | 家庭组无管理员 |

**说明**：
- 求助信号会通过 WebSocket 实时推送给所有监护人
- 监护人端会收到弹窗提示和震动反馈
- 适用于用户察觉到异常但系统尚未告警的场景

---

## 12. 远程干预

**端点**：`POST /api/family/remote-intervene`

**描述**：【监护人】远程控制被监护人的通话

**请求参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| target_user_id | integer | ✓ | 被干预的用户 ID |
| action | string | ✓ | 干预动作：block_call/warn/check_status |
| message | string | ✗ | 附加消息 |

**支持的动作**：
- `block_call`：强制挂断当前通话
- `warn`：向被监护人发送警告消息
- `check_status`：检查被监护人当前状态

**请求示例**：
```
# 强制挂断
POST /api/family/remote-intervene?target_user_id=2&action=block_call

# 发送警告
POST /api/family/remote-intervene?target_user_id=2&action=warn&message=这是一个可疑通话，请立即挂断

# 检查状态
POST /api/family/remote-intervene?target_user_id=2&action=check_status

Authorization: Bearer {access_token}
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "干预指令已发送给 李四",
  "data": {
    "action": "block_call",
    "target_user_id": 2,
    "target_user_name": "李四",
    "timestamp": "2026-03-29T11:30:00"
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 404 | 用户不存在 | 操作者不存在 |
| 404 | 目标用户不存在 | 目标用户不存在 |
| 403 | 您无权干预该用户 | 操作者与目标用户不在同一家庭组 |
| 403 | 您不是该家庭组的管理员 | 操作者不是管理员 |
| 400 | 不支持的操作类型 | 动作参数错误 |
| 500 | 指令发送失败 | 网络或系统错误 |

**说明**：
- 只有管理员可以对同家庭组的成员进行远程干预
- 指令通过 WebSocket 实时推送给目标用户
- 被监护人端会立即执行相应的动作

---

## 前端集成指南

### 1. 创建家庭组流程

```javascript
// 创建家庭组
POST /api/family/create?name=我的家庭
Headers: {
  "Authorization": "Bearer {access_token}"
}

// 响应：获得 family_id
```

### 2. 申请加入家庭组流程

```javascript
// 第一步：申请加入
POST /api/family/{family_id}/apply
Headers: {
  "Authorization": "Bearer {access_token}"
}

// 第二步：等待管理员审批
// 管理员端：获取待审批列表
GET /api/family/applications
Headers: {
  "Authorization": "Bearer {access_token}"
}

// 第三步：管理员审批
PUT /api/family/applications/{app_id}?is_approve=true
Headers: {
  "Authorization": "Bearer {access_token}"
}
```

### 3. 查看家庭成员

```javascript
// 查看当前家庭组的成员
GET /api/family/members
Headers: {
  "Authorization": "Bearer {access_token}"
}

// 或查看指定家庭组的成员
GET /api/family/members?family_id=1
Headers: {
  "Authorization": "Bearer {access_token}"
}
```

### 4. 管理成员角色

```javascript
// 设置为副管理员
PUT /api/family/members/{user_id}/admin-role?role=secondary
Headers: {
  "Authorization": "Bearer {access_token}"
}

// 移除成员
DELETE /api/family/members/{user_id}
Headers: {
  "Authorization": "Bearer {access_token}"
}
```

### 5. 一键求助

```javascript
// 用户发送求助信号
POST /api/family/sos?call_id=123&message=我需要帮助
Headers: {
  "Authorization": "Bearer {access_token}"
}
```

### 6. 远程干预

```javascript
// 监护人强制挂断
POST /api/family/remote-intervene?target_user_id=2&action=block_call
Headers: {
  "Authorization": "Bearer {access_token}"
}

// 监护人发送警告
POST /api/family/remote-intervene?target_user_id=2&action=warn&message=这是可疑通话
Headers: {
  "Authorization": "Bearer {access_token}"
}
```

---

## 常见问题

### Q1：一个用户可以加入多个家庭组吗？
**A**：作为普通成员只能加入一个家庭组，但可以作为管理员管理多个家庭组。

### Q2：主管理员可以直接退出吗？
**A**：不可以。主管理员需要先转让身份给其他成员或移除所有成员后才能退出。

### Q3：副管理员有什么权限？
**A**：副管理员可以审批申请、查看成员、移除普通成员，但不能移除其他副管理员或设置管理员角色。

### Q4：SOS 求助会通知谁？
**A**：会通知该家庭组的所有管理员（主管理员和副管理员）。

### Q5：远程干预是实时的吗？
**A**：是的，通过 WebSocket 实时推送，被监护人端会立即收到指令。

---

## 更新日志

### v1.0.0（2026-03-29）
- ✅ 家庭组创建和管理
- ✅ 成员申请和审批
- ✅ 多角色权限管理
- ✅ 一键求助功能
- ✅ 远程干预功能

