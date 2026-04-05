# 监护人通知相关接口文档

## 概述

本系统提供完整的监护人通知机制，当检测到用户遭遇诈骗风险时，系统会自动通过多种渠道（WebSocket、邮件）向监护人发送预警通知。同时，用户也可以主动发起求助，监护人也可以远程干预被监护人的通话。

---

## 目录

1. [预警通知机制](#1-预警通知机制)
2. [用户主动求助](#2-用户主动求助)
3. [监护人远程干预](#3-监护人远程干预)
4. [邮件通知服务](#4-邮件通知服务)

---

## 1. 预警通知机制

### 1.1 自动风险预警

当系统检测到通话存在诈骗风险时，自动向家庭组管理员发送预警通知。

**触发条件**: 根据防御等级配置，高风险以上（high/critical）自动触发

**通知方式**:
- WebSocket 实时推送至监护人 App
- 邮件通知（可选）

#### 请求示例

预警通过 WebSocket 推送，无需 HTTP 请求。推送消息格式：

```json
{
  "type": "family_alert",
  "data": {
    "title": "⚠️ 家人安全预警",
    "message": "您的家人【张三】疑似正在遭遇诈骗。当前通话环境存在伪造风险，未通过声音安全检测。",
    "risk_level": "high",
    "victim_id": 123,
    "victim_name": "张三",
    "victim_phone": "138****8888",
    "call_id": 456,
    "family_id": 1,
    "timestamp": "2026-04-05T10:30:00",
    "display_mode": "popup",
    "action": "vibrate"
  }
}
```

#### 响应字段说明

| 字段 | 类型 | 说明 |
|------|------|------|
| type | string | 消息类型：`family_alert` |
| data.title | string | 预警标题 |
| data.message | string | 预警内容 |
| data.risk_level | string | 风险等级：`critical`(极高)、`high`(高)、`medium`(中) |
| data.victim_id | int | 被检测用户ID |
| data.victim_name | string | 被检测用户姓名 |
| data.victim_phone | string | 被检测用户电话 |
| data.call_id | int | 关联通话ID |
| data.display_mode | string | 显示模式：`popup`(弹窗)、`fullscreen`(全屏) |
| data.action | string | 客户端动作：`none`、`vibrate`(震动)、`alarm`(响铃+震动) |

---

## 2. 用户主动求助

### 2.1 一键求助（SOS）

用户主动向家庭组监护人发送求助信号。

**接口信息**

| 项目 | 内容 |
|------|------|
| 方法 | POST |
| 路径 | `/api/family/sos` |
| 认证 | 需要用户登录 |

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| call_id | int | 是 | 当前通话ID |
| message | string | 否 | 求助信息，默认："我正在遭遇可疑通话，请立即联系我！" |

#### 请求示例

```bash
curl -X POST "http://localhost:8000/api/family/sos?call_id=123&message=我正在遭遇可疑通话！" \
  -H "Authorization: Bearer <token>"
```

#### 响应示例

```json
{
  "code": 200,
  "message": "求助信号已发送给 2 位监护人",
  "data": {
    "notified_count": 2,
    "call_id": 123,
    "timestamp": "2026-04-05T10:30:00"
  }
}
```

#### 推送消息格式

监护人收到的 WebSocket 消息：

```json
{
  "type": "sos_alert",
  "data": {
    "title": "紧急求助",
    "message": "您的家人【张三】正在请求帮助！我正在遭遇可疑通话，请立即联系我！",
    "victim_id": 123,
    "victim_name": "张三",
    "victim_phone": "138****8888",
    "call_id": 456,
    "family_id": 1,
    "timestamp": "2026-04-05T10:30:00",
    "display_mode": "popup",
    "action": "vibrate",
    "urgency": "high"
  }
}
```

---

### 2.2 一键报警（紧急求助）

当用户遭遇高风险诈骗时，触发紧急报警。

**接口信息**

| 项目 | 内容 |
|------|------|
| 方法 | POST |
| 路径 | `/api/call-records/{call_id}/emergency-alert` |
| 认证 | 需要用户登录 |

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| call_id | int | 是（路径参数） | 通话ID |
| alert_type | string | 否 | 报警类型：`emergency`(紧急报警)、`suspicious`(可疑行为)，默认 `emergency` |
| message | string | 否 | 附加消息 |

#### 请求示例

```bash
curl -X POST "http://localhost:8000/api/call-records/456/emergency-alert" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "call_id": 456,
    "alert_type": "emergency",
    "message": "对方自称警察，要求我转账！"
  }'
```

#### 响应示例

```json
{
  "code": 200,
  "message": "紧急报警已发送，已通知 2 位家庭管理员",
  "data": {
    "alert_id": 789,
    "notified_admins": 2,
    "timestamp": "2026-04-05T10:30:00"
  }
}
```

#### 错误码

| code | 说明 |
|------|------|
| 400 | 用户未加入家庭组，无法发送报警 |
| 400 | 家庭组没有管理员，无法发送报警 |
| 404 | 通话记录不存在 |

#### 推送消息格式

监护人收到的 WebSocket 消息：

```json
{
  "type": "emergency_alert",
  "data": {
    "title": "🚨 紧急报警",
    "message": "用户张三触发了一键报警，可能正在遭遇诈骗！对方自称警察，要求我转账！",
    "victim_id": 123,
    "victim_name": "张三",
    "victim_phone": "138****8888",
    "call_id": 456,
    "family_id": 1,
    "timestamp": "2026-04-05T10:30:00",
    "display_mode": "fullscreen",
    "action": "alarm",
    "alert_type": "emergency"
  }
}
```

---

## 3. 监护人远程干预

### 3.1 远程控制被监护人

监护人远程控制被监护人的通话状态。

**接口信息**

| 项目 | 内容 |
|------|------|
| 方法 | POST |
| 路径 | `/api/family/remote-intervene` |
| 认证 | 需要用户登录（且为家庭组管理员） |

#### 请求参数

| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| target_user_id | int | 是 | 被干预的用户ID |
| action | string | 是 | 干预动作，见下方说明 |
| message | string | 否 | 附加消息 |

#### 支持的动作

| action | 说明 | 效果 |
|--------|------|------|
| `block_call` | 强制挂断 | 挂断当前通话，显示全屏警告 |
| `warn` | 发送警告 | 向被监护人推送警告消息 |
| `check_status` | 检查状态 | 请求被监护人当前状态 |

#### 请求示例

**强制挂断通话**

```bash
curl -X POST "http://localhost:8000/api/family/remote-intervene?target_user_id=123&action=block_call" \
  -H "Authorization: Bearer <token>"
```

**发送警告**

```bash
curl -X POST "http://localhost:8000/api/family/remote-intervene?target_user_id=123&action=warn&message=请立即挂断此电话，这可能是诈骗！" \
  -H "Authorization: Bearer <token>"
```

**检查状态**

```bash
curl -X POST "http://localhost:8000/api/family/remote-intervene?target_user_id=123&action=check_status" \
  -H "Authorization: Bearer <token>"
```

#### 响应示例

```json
{
  "code": 200,
  "message": "干预指令已发送给 张三",
  "data": {
    "action": "block_call",
    "target_user_id": 123,
    "target_user_name": "张三",
    "timestamp": "2026-04-05T10:30:00"
  }
}
```

#### 权限说明

- 只有家庭组管理员可以执行远程干预
- 管理员与被干预用户必须在同一家庭组
- 主管理员和副管理员都有干预权限

#### 推送消息格式（被监护人收到）

```json
{
  "type": "remote_control",
  "data": {
    "action": "block_call",
    "from_admin_id": 456,
    "from_admin_name": "李四",
    "target_user_id": 123,
    "message": "",
    "timestamp": "2026-04-05T10:30:00",
    "control": {
      "block_call": true,
      "warning_mode": "fullscreen",
      "ui_message": "监护人 李四 已为您强制挂断此通话"
    }
  }
}
```

---

## 4. 邮件通知服务

### 4.1 监护人预警邮件

当检测到高风险时，自动向监护人发送预警邮件。

#### 邮件主题

```
【紧急预警】您的家人遭遇极高风险
```

#### 邮件内容示例

**纯文本版本**

```
尊敬的家庭监护人：

您的家人【张三】当前遭遇极高诈骗风险！

风险详情：当前通话环境存在伪造风险，未通过声音安全检测。

建议措施：
- 立即电话联系家人确认安全
- 提醒家人不要转账或泄露个人信息
- 必要时挂断可疑通话
- 如已受骗，立即报警处理

---
此邮件由 AI 反诈系统自动发送
```

**HTML 版本**：包含彩色预警框、详细建议措施

#### 触发条件

| 风险等级 | 是否发送邮件 |
|----------|-------------|
| critical | 是 |
| high | 是 |
| medium | 否 |
| low | 否 |

#### 发送范围

- 用户所属家庭组的所有管理员
- 仅发送给已配置邮箱的管理员

---

## 5. 消息类型汇总

### WebSocket 消息类型

| type | 发送方向 | 说明 |
|------|---------|------|
| `alert` | 系统→用户 | 检测到风险，告知用户 |
| `family_alert` | 系统→监护人 | 家人遭遇风险，告知监护人 |
| `sos_alert` | 系统→监护人 | 用户主动求助 |
| `emergency_alert` | 系统→监护人 | 用户触发紧急报警 |
| `remote_control` | 系统→用户 | 监护人远程干预指令 |

### 消息显示模式

| display_mode | 说明 |
|--------------|------|
| `popup` | 弹窗提示 |
| `fullscreen` | 全屏警告 |
| `banner` | 顶部横幅 |

### 客户端动作

| action | 说明 |
|--------|------|
| `none` | 无动作 |
| `vibrate` | 手机震动 |
| `alarm` | 响铃 + 震动（最高优先级） |

---

## 6. 错误处理

### 常见错误响应

```json
{
  "code": 400,
  "message": "您未加入任何家庭组，无法使用此功能"
}
```

```json
{
  "code": 403,
  "message": "您不是该家庭组的管理员"
}
```

### 错误码说明

| code | 说明 |
|------|------|
| 400 | 参数错误或业务条件不满足 |
| 403 | 权限不足 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

---

## 7. 使用场景示例

### 场景一：系统自动预警流程

1. 用户正在通话
2. AI 检测到声音伪造风险（风险等级：high）
3. 系统自动调用 `notification_service.handle_detection_result()`
4. 向用户推送预警（WebSocket）
5. 查询用户家庭组，向所有管理员推送预警
6. 管理员收到 WebSocket 消息 + 邮件通知

### 场景二：用户主动求助

1. 用户感觉通话可疑
2. 调用 `POST /api/family/sos`
3. 系统查询用户家庭组管理员
4. 向所有管理员推送 SOS 消息
5. 管理员收到消息后联系用户确认情况

### 场景三：监护人远程干预

1. 管理员收到家人预警
2. 管理员调用 `POST /api/family/remote-intervene`
3. 选择 `block_call` 强制挂断通话
4. 用户收到指令，挂断通话并显示警告

---

## 8. 相关模型

### MessageLog（消息日志）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| user_id | int | 接收用户ID |
| call_id | int | 关联通话ID |
| msg_type | string | 消息类型：`alert`、`info`、`system`、`emergency_alert` |
| risk_level | string | 风险等级：`critical`、`high`、`medium`、`low`、`safe` |
| title | string | 消息标题 |
| content | string | 消息内容 |
| is_read | bool | 是否已读 |
| created_at | datetime | 创建时间 |

### FamilyAdmin（家庭管理员）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | int | 主键 |
| user_id | int | 管理员用户ID |
| family_id | int | 家庭组ID |
| admin_role | string | 管理员角色：`primary`(主)、`secondary`(副) |
