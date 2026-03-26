# AI 反诈检测系统 - 接口总览文档

> 更新日期：2026-03-26  
> Base URL：`http://localhost:8000`  
> 鉴权方式：除特殊说明外，所有接口需在 Header 中携带 `Authorization: Bearer <token>`

---

## 目录

1. [用户管理](#一用户管理)
2. [家庭组管理](#二家庭组管理)
3. [实时检测](#三实时检测)
4. [通话记录](#四通话记录)
5. [教育推荐](#五教育推荐)
6. [任务管理](#六任务管理)
7. [管理后台](#七管理后台)

---

## 一、用户管理

| 方法 | 路径 | 鉴权 | 说明 |
|------|------|------|------|
| POST | `/api/users/send-code` | 否 | 发送验证码（邮箱/短信） |
| POST | `/api/users/register` | 否 | 用户注册 |
| POST | `/api/users/login` | 否 | 用户登录（仅手机号+密码） |
| GET | `/api/users/me` | 是 | 获取当前用户信息 |
| PUT | `/api/users/profile` | 是 | 更新用户画像 |
| DELETE | `/api/users/family` | 是 | 解绑家庭组 |
| GET | `/api/users/{user_id}/security-report` | 是 | 生成个人安全报告 |
| GET | `/api/users/guardian` | 是 | 获取监护人信息 |

### 1. 发送验证码
**POST** `/api/users/send-code`
```json
{ "phone": "17371999302", "email": "xxx@qq.com" }
```
有邮箱优先发邮件，否则发短信。

### 2. 用户注册
**POST** `/api/users/register`
```json
{
  "phone": "17371999302", "password": "123456", "sms_code": "1234",
  "username": "izk", "name": "张三",
  "email": "xxx@qq.com", "role_type": "老人",
  "gender": "男", "profession": "退休", "marital_status": "已婚"
}
```
email/role_type/gender/profession/marital_status 均为可选。

### 3. 用户登录
**POST** `/api/users/login`  
> 只支持手机号+密码，username 不能用于登录。
```json
{ "phone": "17371999302", "password": "123456" }
```
返回：
```json
{
  "access_token": "eyJhbGci...",
  "user": {
    "user_id": 1, "phone": "17371999302", "username": "izk", "name": "张三",
    "email": "xxx@qq.com", "role_type": "老人", "gender": "男",
    "profession": "退休", "marital_status": "已婚", "family_id": 1, "is_admin": false
  }
}
```

### 4. 更新用户画像
**PUT** `/api/users/profile`
```json
{ "role_type": "学生", "gender": "女", "profession": "在校学生", "marital_status": "单身" }
```

### 5. 生成个人安全报告
**GET** `/api/users/{user_id}/security-report?stream=false`

- `stream=false`：返回完整 JSON（含 Markdown 报告 + 统计数据）
- `stream=true`：SSE 流式输出，事件类型：`metadata` → `content`（多次）→ `complete`

统计数据包含：total_calls / risk_calls / fake_calls / risk_rate / daily_trend / fraud_type_distribution

### 6. 获取监护人信息
**GET** `/api/users/guardian`
```json
{ "code": 200, "data": { "guardians": [{ "user_id": 2, "name": "李四", "phone": "138xxxxxxxx", "admin_role": "primary" }] } }
```

---

## 二、家庭组管理

| 方法 | 路径 | 权限 | 说明 |
|------|------|------|------|
| POST | `/api/family/create?name=xxx` | 登录用户 | 创建家庭组（自动成为主管理员） |
| POST | `/api/family/{family_id}/apply` | 登录用户 | 申请加入家庭组 |
| GET | `/api/family/applications` | 管理员 | 获取待审批申请列表 |
| PUT | `/api/family/applications/{app_id}?is_approve=true` | 管理员 | 审批申请 |
| GET | `/api/family/members?family_id=1` | 成员/管理员 | 获取成员列表 |
| PUT | `/api/family/members/{user_id}/admin-role?role=xxx` | 主管理员 | 设置管理员角色 |
| DELETE | `/api/family/members/{user_id}` | 管理员 | 移除成员 |
| POST | `/api/family/leave` | 成员 | 退出家庭组 |
| GET | `/api/family/info` | 成员 | 获取家庭组详情 |
| GET | `/api/family/my-admin-families` | 管理员 | 获取我管理的所有家庭组 |
| POST | `/api/family/sos?call_id=3&message=xxx` | 成员 | 一键求助（推送给所有监护人） |
| POST | `/api/family/remote-intervene?target_user_id=3&action=block_call` | 管理员 | 远程干预被监护人通话 |

### 角色说明
- `primary`：主管理员，可转让、设置他人角色
- `secondary`：副管理员，可审批申请、移除普通成员
- `none`/普通成员：无管理权限

### 待审批列表返回示例
```json
{
  "code": 200,
  "data": {
    "items": [{
      "application_id": 1, "family_id": 1, "family_name": "张家大院",
      "user_id": 3, "username": "wangwu", "phone": "139xxxxxxxx",
      "role_type": "学生", "apply_time": "2026-03-26 10:00:00"
    }]
  }
}
```

### 成员列表返回示例
```json
{
  "code": 200,
  "data": {
    "family_id": 1, "group_name": "张家大院",
    "members": [{
      "user_id": 1, "username": "izk", "name": "张三",
      "phone": "173xxxxxxxx", "role_type": "老人",
      "admin_role": "primary", "is_me": true
    }]
  }
}
```

### 家庭组详情返回示例
```json
{
  "code": 200,
  "data": {
    "family_id": 1, "group_name": "张家大院",
    "my_role": "primary",
    "primary_admin": { "user_id": 1, "username": "izk", "phone": "173xxxxxxxx" },
    "statistics": { "total_members": 5, "primary_admins": 1, "secondary_admins": 1, "normal_members": 3 }
  }
}
```

### SOS 推送给监护人的 WebSocket 消息
```json
{
  "type": "sos_alert",
  "data": {
    "title": "紧急求助", "message": "您的家人【张三】正在请求帮助！",
    "victim_phone": "173xxxxxxxx", "call_id": 3,
    "display_mode": "popup", "action": "vibrate", "urgency": "high"
  }
}
```

### 远程干预推送给被监护人的 WebSocket 消息
```json
{
  "type": "remote_control",
  "data": {
    "action": "block_call", "from_admin_name": "李四",
    "control": { "block_call": true, "warning_mode": "fullscreen", "ui_message": "监护人已为您强制挂断此通话" }
  }
}
```

---

## 三、实时检测

### 1. WebSocket 实时检测（核心接口）
**WS** `/api/detection/ws/{user_id}/{call_id}?token=<JWT>`

> **必须先调用** `POST /api/call-records/start` 获取 call_id，再建立 WebSocket 连接。

#### 前端 → 后端消息

| type | data | 说明 |
|------|------|------|
| `audio` | base64 音频数据 | 音频帧，异步投递 Celery |
| `video` | base64 JPEG 图片 | 视频截图，积攒 10 帧后投递 Celery |
| `text` | 字符串或 `{"text": "..."}` | 语音转写文本，三道防线检测 |
| `heartbeat` | 无 | 心跳保活，每 30 秒一次 |
| `control` | `{"action": "set_config", "fps": 15}` | 配置指令 |

#### 后端 → 前端消息

**ACK 确认**
```json
{ "type": "ack", "msg_type": "audio", "timestamp": "2026-03-26T10:00:00" }
```

**心跳回复**
```json
{ "type": "heartbeat_ack", "timestamp": "2026-03-26T10:00:00" }
```

**防御等级升级指令**
```json
{
  "type": "control", "action": "upgrade_level", "target_level": 2,
  "config": {
    "video_fps": 30.0, "ui_message": "检测到高危AI合成语音，请立即挂断！",
    "warning_mode": "modal", "block_call": true
  }
}
```

**防御等级说明**

| Level | 模式 | 视频帧率 | 触发条件 |
|-------|------|----------|----------|
| 0 | 安全模式 | 5 fps | 无风险 |
| 1 | 警戒模式 | 15 fps | 检测到可疑内容 |
| 2 | 高危模式 | 30 fps | 检测到高危诈骗 |

**检测结果推送（Celery → Redis → WebSocket）**
```json
{
  "type": "detection_result",
  "data": {
    "overall_score": 95, "voice_confidence": 0.98,
    "video_confidence": 0.85, "text_confidence": 0.92,
    "is_fraud": true, "advice": "检测到高危AI合成语音，请立即挂断！",
    "keywords": ["转账", "验证码", "公安局"]
  }
}
```

**环境识别推送**
```json
{
  "type": "environment_detected",
  "data": {
    "call_id": 3, "platform": "wechat", "is_text_chat": false,
    "environment_type": "social_app",
    "active_modalities": ["text", "audio", "video"]
  }
}
```

### 2. 其他检测接口

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/detection/upload/audio` | 上传音频文件到 MinIO（mp3/wav/m4a/ogg） |
| POST | `/api/detection/upload/video` | 上传视频文件到 MinIO（mp4/avi/mov/webm） |
| POST | `/api/detection/upload/image` | 上传图片并触发 OCR 检测（最大 10MB） |
| POST | `/api/detection/extract-frames?frame_rate=1` | 从视频中提取关键帧（返回 base64 数组） |

---

## 四、通话记录

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/call-records/start` | 开始通话（必须先调用，获取 call_id） |
| POST | `/api/call-records/{call_id}/end` | 结束通话，触发 AI 总结 |
| GET | `/api/call-records/my-records` | 获取我的通话记录列表 |
| GET | `/api/call-records/record/{call_id}` | 获取单条通话详情 |
| GET | `/api/call-records/family-records` | 获取家庭组成员通话记录 |
| DELETE | `/api/call-records/record/{call_id}` | 删除通话记录（仅本人） |
| GET | `/api/call-records/{call_id}/audit-logs` | 获取通话审计日志（时间轴） |
| GET | `/api/call-records/{call_id}/detection-timeline` | 获取三模态检测时间轴（折线图数据） |
| GET | `/api/call-records/{call_id}/chat-history` | 获取通话对话历史 |
| GET | `/api/call-records/{call_id}/evidence/{log_id}` | 获取证据详情（截图/OCR/算法详情） |
| GET | `/api/call-records/{call_id}/environment` | 获取通话环境信息 |
| POST | `/api/call-records/{call_id}/environment` | 设置通话环境（触发 WebSocket 推送） |
| POST | `/api/call-records/{call_id}/report-to-admin` | 提交通话给管理员审核（仅家庭组管理员） |
| POST | `/api/call-records/{call_id}/emergency-alert` | 一键报警（推送给所有家庭组管理员） |

### 开始通话
**POST** `/api/call-records/start?platform=PHONE&target_identifier=138xxxxxxxx`

| platform 值 | 说明 |
|-------------|------|
| `PHONE` | 电话，target_identifier 存为 caller_number |
| `WECHAT` | 微信，target_identifier 存为 target_name |
| `QQ` | QQ |
| `OTHER` | 其他 |

返回：`{ "call_id": 3, "status": "started" }`

### 结束通话
**POST** `/api/call-records/{call_id}/end`
```json
{
  "audio_url": "https://minio/.../audio.mp3",
  "video_url": "https://minio/.../video.mp4",
  "cover_image": "https://minio/.../cover.jpg"
}
```
所有字段可选。调用后自动触发 Celery 异步生成 AI 通话总结（写入 analysis 和 advice 字段）。

### 我的通话记录列表
**GET** `/api/call-records/my-records?page=1&page_size=20&result_filter=FAKE`

`result_filter` 可选值：`SAFE` / `SUSPICIOUS` / `FAKE`

记录字段包含：call_id / platform / caller_number / target_name / start_time / end_time / duration / detected_result / audio_url / **analysis** / **advice**

### 检测时间轴
**GET** `/api/call-records/{call_id}/detection-timeline`

返回每个检测点的三模态数据，适合绘制折线图：
```json
{
  "timeline": [{
    "time_offset": 10,
    "modalities": {
      "text": { "confidence": 0.9, "score": 90 },
      "voice": { "confidence": 0.85, "score": 85 },
      "video": { "confidence": 0.7, "score": 70 }
    },
    "overall_score": 88.0,
    "fused_risk_level": "high",
    "detected_keywords": "公安局、转账",
    "match_script": "冒充公检法剧本",
    "intent": "诱导转账"
  }],
  "statistics": { "total_events": 12, "max_overall_score": 95.0, "duration_seconds": 120 }
}
```
`fused_risk_level`：`high`(>=80) / `medium`(>=50) / `low`(<50)

### 一键报警
**POST** `/api/call-records/{call_id}/emergency-alert`
```json
{ "call_id": 3, "alert_type": "emergency", "message": "我正在遭遇诈骗！" }
```
同时触发 WebSocket 全屏推送 + 邮件通知所有家庭组管理员。

---

## 五、教育推荐

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/api/education/recommendations/{user_id}?limit=5` | 基于历史学习记录的个性化推荐 |
| POST | `/api/education/match_cases` | 根据对话内容匹配相似诈骗案例和法律法规 |
| POST | `/api/education/record/{user_id}` | 记录/更新用户学习进度 |
| GET | `/api/education/recommendations/profile/{user_id}` | 基于用户画像（角色类型）推荐 |
| POST | `/api/education/recommendations/realtime` | 实时对话推荐（通话中使用） |
| GET | `/api/education/recommendations/library/{user_id}` | 从案例库+法律库推荐 |

**match_cases 请求体：**
```json
{ "transcript": "您好，我是公安局的，您的账户涉嫌洗钱", "top_k": 3 }
```

**realtime 请求体：**
```json
{ "user_id": 1, "conversation_text": "您好，我是公安局的", "top_k": 3 }
```

**library 请求：** `GET /api/education/recommendations/library/{user_id}?fraud_type=冒充公检法诈骗&limit=5`

---

## 六、任务管理

> 通常通过 WebSocket 自动触发，无需手动调用。

| 方法 | 路径 | 说明 |
|------|------|------|
| POST | `/api/tasks/audio/detect` | 手动提交音频检测任务 |
| POST | `/api/tasks/video/detect` | 手动提交视频检测任务 |
| POST | `/api/tasks/text/detect` | 手动提交文本检测任务 |
| GET | `/api/tasks/status/{task_id}` | 查询 Celery 任务状态 |

**请求体示例：**
```json
// 音频
{ "audio_base64": "<base64>", "call_id": 3 }
// 视频
{ "frame_data": ["<base64帧1>", "<base64帧2>"], "call_id": 3 }
// 文本
{ "text": "您好，我是公安局的", "call_id": 3 }
```

**任务状态返回：**
```json
{ "code": 200, "data": { "task_id": "abc-123", "status": "SUCCESS", "result": { "is_fraud": true, "confidence": 0.95 } } }
```
`status` 值：`PENDING` / `STARTED` / `SUCCESS` / `FAILURE`

---

## 七、管理后台

> 路由前缀 `/admin`，需系统管理员权限。

### 统计数据

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/stats` | 仪表盘统计（总用户/拦截数/今日数据/平均风险分） |
| GET | `/admin/stats/trends?days=7` | 最近 N 天趋势（检测次数/拦截次数/新增用户） |
| GET | `/admin/stats/fraud-types` | 诈骗类型分布统计 |
| GET | `/admin/stats/hourly` | 24小时检测分布 |

**stats 返回示例：**
```json
{
  "total_users": 1000, "total_calls": 5000, "fraud_blocked": 200,
  "blacklist_count": 50, "active_rules": 30,
  "new_users_today": 10, "detections_today": 100, "blocked_today": 5,
  "avg_risk_score": 35.6, "detection_rate": 4.0
}
```

### 风险规则管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/rules` | 获取风险规则列表 |
| POST | `/admin/rules` | 创建风险规则 |
| DELETE | `/admin/rules/{rule_id}` | 删除风险规则 |
| POST | `/admin/test/text_match?text=xxx` | 测试文本是否命中规则 |

### 黑名单管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/blacklist` | 获取黑名单列表 |
| POST | `/admin/blacklist` | 添加黑名单号码 |
| DELETE | `/admin/blacklist/{id}` | 删除黑名单号码 |

### 诈骗案例管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/fraud-cases` | 获取被判定为诈骗的通话记录 |
| POST | `/admin/fraud-cases/{call_id}/learn` | 将案例加入待学习队列 |
| POST | `/admin/fraud-cases/{call_id}/learn-with-edit` | 编辑后加入学习队列 |
| POST | `/admin/cases/upload` | 手动上传案例到待学习队列 |
| GET | `/admin/cases/pending` | 获取待学习案例文件列表 |
| GET | `/admin/cases/learned` | 获取已学习案例文件列表 |
| GET | `/admin/cases/pending/{filename}` | 获取待学习案例详情 |
| DELETE | `/admin/cases/pending/{filename}` | 删除待学习案例文件 |

### 用户管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/users` | 获取用户列表 |
| GET | `/admin/users/{user_id}` | 获取用户详情 |
| PUT | `/admin/users/{user_id}` | 更新用户信息 |
| PATCH | `/admin/users/{user_id}/status` | 启用/禁用用户账号 |
| DELETE | `/admin/users/{user_id}` | 删除用户 |
| GET | `/admin/users/{user_id}/call-stats` | 获取用户通话统计 |

**用户详情包含字段：** user_id / username / name / phone / email / role_type / gender / profession / marital_status / family_id / is_active / is_admin

### 家庭组管理（管理后台）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/family-groups` | 获取所有家庭组列表 |
| GET | `/admin/family-groups/{family_id}/members` | 获取指定家庭组成员 |
| GET | `/admin/family-stats` | 家庭组统计（总数/总成员数/总管理员数） |

### 检测记录（管理后台）

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/detection/recent?limit=20` | 获取最近 AI 检测记录 |
| GET | `/admin/detection/{log_id}/evidence` | 获取检测证据详情 |
| GET | `/admin/call-records/{call_id}/detection-timeline` | 获取通话检测时间轴 |
| GET | `/admin/call-records/{call_id}/chat-history` | 获取通话对话历史 |

### 用户长期记忆管理

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/users/{user_id}/memories` | 获取用户长期记忆列表 |
| POST | `/admin/users/{user_id}/memories` | 手动添加用户长期记忆 |
| DELETE | `/admin/memories/{memory_id}` | 删除指定记忆 |
| GET | `/admin/users/{user_id}/memory-summary` | 获取用户记忆摘要 |
| POST | `/admin/users/{user_id}/refresh-memory-summary` | 刷新用户记忆摘要 |

记忆类型：`fraud_experience`（诈骗经历）/ `alert_response`（告警响应）/ `preference`（偏好）/ `risk_pattern`（风险模式）

### 系统监控

| 方法 | 路径 | 说明 |
|------|------|------|
| GET | `/admin/system/health` | 系统健康状态 |
| GET | `/admin/system/logs` | 管理员操作日志 |

---

## 附录：WebSocket 完整消息类型汇总

### 前端 → 后端

| type | 说明 |
|------|------|
| `audio` | 发送音频帧（base64） |
| `video` | 发送视频截图（base64 JPEG） |
| `text` | 发送语音转写文本 |
| `heartbeat` | 心跳保活 |
| `control` | 配置控制指令 |

### 后端 → 前端

| type | 说明 |
|------|------|
| `ack` | 数据接收确认 |
| `heartbeat_ack` | 心跳回复 |
| `detection_result` | 检测结果（音频/视频/文本） |
| `control` | 防御等级升级指令 |
| `environment_detected` | 环境识别结果 |
| `sos_alert` | 收到被监护人 SOS 求助 |
| `remote_control` | 收到监护人远程干预指令 |
| `emergency_alert` | 收到紧急报警通知 |
| `error` | 消息格式错误 |

---

## 附录：通用返回格式

```json
{
  "code": 200,
  "message": "操作成功",
  "data": { ... }
}
```

常见 code 值：
- `200`：成功
- `201`：创建成功
- `400`：参数错误/业务限制
- `401`：未授权（token 无效）
- `403`：无权限
- `404`：资源不存在
- `500`：服务器内部错误

