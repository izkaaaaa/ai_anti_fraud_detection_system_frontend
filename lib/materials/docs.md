# AI Anti-Fraud Detection System API

## Project Overview

An intelligent anti-fraud detection system built with FastAPI, providing real-time multi-modal fraud detection (voice, video, text) for phone/video calls. The system leverages AI models (AASIST, Xception+BiLSTM, BERT) combined with a Large Language Model (DeepSeek) to analyze and report fraud risks. It supports family group management, elder care monitoring, and anti-fraud education.

**Version**: 1.0.0

---

## Technology Stack

| Layer | Technology |
|---|---|
| Web Framework | FastAPI 0.104.1 |
| ASGI Server | uvicorn 0.24.0 |
| Database | MySQL 8.0 + SQLAlchemy 2.0 (async via aiomysql) |
| Cache & Broker | Redis 5.0.1 |
| Object Storage | MinIO |
| Task Queue | Celery 5.3.4 |
| AI — Audio | AASIST (PyTorch), ONNX fallback |
| AI — Video | Xception + BiLSTM (ONNX), Deepfake detection |
| AI — Text | BERT fine-tuned model (PyTorch/ONNX) |
| AI — Analysis | DeepSeek LLM (multi-modal risk reasoning) |
| RAG | ChromaDB + LangChain |
| Authentication | JWT (python-jose), bcrypt |
| Validation | Pydantic 2.5.0 |

---

## Project Structure

```
.
├── main.py                          # FastAPI application entry point
├── requirements.txt                 # Python dependencies
├── alembic.ini                      # Database migration configuration
├── docker-compose.yml               # Docker services (MySQL, Redis, MinIO)
├── Dockerfile                       # Docker image build file
├── setup.bat                        # Windows environment setup script
├── start_celery.bat                 # Celery worker startup script
├── app/
│   ├── api/                         # API route handlers
│   │   ├── users.py                 # User management
│   │   ├── detection.py             # Real-time detection
│   │   ├── tasks.py                 # Async task management
│   │   ├── call_records.py          # Call record management
│   │   ├── family.py                # Family group management
│   │   ├── education.py             # Anti-fraud education
│   │   └── admin.py                 # Admin dashboard & management
│   ├── core/                        # Core utilities & configuration
│   │   ├── config.py                # Application settings
│   │   ├── security.py              # JWT authentication
│   │   ├── redis.py                  # Redis connection
│   │   ├── storage.py                # MinIO storage client
│   │   ├── sms.py                    # SMS service (mock implementation)
│   │   └── email_code.py             # Email verification code
│   ├── db/
│   │   └── database.py               # Async SQLAlchemy setup
│   ├── models/                       # SQLAlchemy ORM models
│   │   ├── user.py                   # User model
│   │   ├── call_record.py            # Call record model
│   │   ├── ai_detection_log.py       # AI detection log
│   │   ├── family_group.py           # Family group, admin, application
│   │   ├── risk_rule.py              # Risk rule model
│   │   ├── blacklist.py              # Phone number blacklist
│   │   ├── user_memory.py            # User long-term memory
│   │   ├── message_log.py            # Alert message log
│   │   ├── chat_message.py           # Chat message
│   │   ├── education.py              # Knowledge items & learning records
│   │   ├── admin.py                  # Admin & system monitor
│   │   └── mdp_decision_event.py     # MDP decision event
│   ├── schemas/                      # Pydantic request/response models
│   │   ├── __init__.py               # Shared schemas
│   │   └── admin.py                  # Admin-specific schemas
│   ├── services/                     # Business logic services
│   │   ├── websocket_manager.py      # WebSocket connection manager
│   │   ├── audio_processor.py        # Audio feature extraction
│   │   ├── video_processor.py        # Video frame processing
│   │   ├── model_service.py          # AI model inference
│   │   ├── llm_service.py            # DeepSeek LLM integration
│   │   ├── risk_fusion_engine.py     # Multi-modal risk fusion
│   │   ├── education_service.py      # Anti-fraud education logic
│   │   ├── memory_service.py         # Short-term memory (Redis)
│   │   ├── long_term_memory_service.py
│   │   ├── vector_db_service.py      # RAG vector database (ChromaDB)
│   │   ├── notification_service.py   # Real-time notifications
│   │   ├── email_service.py          # Email sending
│   │   ├── security_service.py       # Risk rule matching
│   │   ├── image_ocr_service.py      # Image OCR
│   │   └── mdp_defense/              # MDP defense agent
│   │       ├── dynamic_defense_agent.py
│   │       ├── mdp_types.py
│   │       └── reward_builder.py
│   └── tasks/                        # Celery async tasks
│       ├── celery_app.py             # Celery configuration
│       └── detection_tasks.py        # Detection task definitions
├── tests/                            # Unit tests
├── alembic/                          # Database migrations
└── models/                           # AI model files (voice/video/text)
```

---

## API Reference

Interactive documentation is available at:
- Swagger UI: `http://localhost:8000/docs`
- ReDoc: `http://localhost:8000/redoc`

> All API responses follow a unified format. Successful responses include `code: 200` and `message`. Error responses return appropriate HTTP status codes (400, 401, 403, 404, 500) with error details.

---

## Authentication

### JWT Authentication

All protected endpoints require a JWT token in the `Authorization` header:

```
Authorization: Bearer <token>
```

**Token payload:**
```json
{
  "sub": "user_id",
  "phone": "phone_number",
  "exp": "expiry_timestamp"
}
```

- Default expiry: 30 minutes
- Algorithm: HS256

### Login Methods

1. **Email + Password**
2. **Email + Verification Code**
3. **Phone + Password**

### Email Verification Code

Send code: `POST /api/users/send-code` (stores 6-digit code in Redis with 5-minute TTL)

Universal test code: `666666`

---

## System

### GET `/`

System information and status.

**Response:**
```json
{
  "name": "AI Anti-Fraud Detection System",
  "version": "1.0.0",
  "status": "running"
}
```

---

### GET `/health`

Health check endpoint. Checks database and Redis connectivity.

**Response:**
```json
{
  "status": "healthy",
  "database": "connected",
  "redis": "connected",
  "timestamp": "2024-01-01T00:00:00"
}
```

---

## User Management `/api/users`

### POST `/api/users/send-code`

Send email verification code for registration.

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | Yes | Valid email address |

```json
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "code": 200,
  "message": "验证码已发送至邮箱",
  "data": {
    "email": "user@example.com"
  }
}
```

---

### POST `/api/users/send-login-code`

Send email verification code for login.

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | Yes | Valid email address |

**Response:** Same as `/send-code`

---

### POST `/api/users/register`

User registration (requires email verification code).

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| phone | string | Yes | Phone number, 11 digits |
| username | string | Yes | Username, 3-50 characters |
| password | string | Yes | Password, 6-20 characters |
| email_code | string | Yes | Email verification code, 4-6 digits |
| email | string | Yes | Email address |
| name | string | No | Display name |
| role_type | string | No | Role type, default: "青壮年" |
| gender | string | No | Gender |
| profession | string | No | Occupation |
| marital_status | string | No | Marital status |

```json
{
  "phone": "13800138000",
  "username": "john_doe",
  "password": "password123",
  "email_code": "123456",
  "email": "user@example.com",
  "name": "张三",
  "role_type": "老年人",
  "gender": "男",
  "profession": "退休",
  "marital_status": "已婚"
}
```

**Response:**
```json
{
  "code": 201,
  "message": "注册成功",
  "data": {
    "user_id": 1
  }
}
```

---

### POST `/api/users/login`

User login with multiple authentication methods.

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| email | string | Conditional | Email address (required for email/password or email/code login) |
| phone | string | Conditional | Phone number, 11 digits (required for phone/password login) |
| password | string | Conditional | Password, 6-20 characters (required for password-based login) |
| email_code | string | Conditional | Email verification code (required for email code login) |

Login method 1 — Email + Password:
```json
{
  "email": "user@example.com",
  "password": "password123"
}
```

Login method 2 — Email + Verification Code:
```json
{
  "email": "user@example.com",
  "email_code": "123456"
}
```

Login method 3 — Phone + Password:
```json
{
  "phone": "13800138000",
  "password": "password123"
}
```

**Response:**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "bearer",
  "user": {
    "user_id": 1,
    "phone": "13800138000",
    "email": "user@example.com",
    "username": "john_doe",
    "name": "张三",
    "role_type": "青壮年",
    "family_id": null,
    "is_active": true,
    "created_at": "2024-01-01T00:00:00"
  }
}
```

---

### GET `/api/users/me`

Get current user profile. **Requires JWT authentication.**

**Response:**
```json
{
  "user_id": 1,
  "phone": "13800138000",
  "email": "user@example.com",
  "username": "john_doe",
  "name": "张三",
  "role_type": "青壮年",
  "gender": "男",
  "profession": "工程师",
  "marital_status": "已婚",
  "family_id": null,
  "is_active": true,
  "created_at": "2024-01-01T00:00:00"
}
```

---

### PUT `/api/users/profile`

Update user profile. **Requires JWT authentication.**

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| role_type | string | No | Role type (老人/儿童/学生/青壮年) |
| gender | string | No | Gender |
| profession | string | No | Occupation |
| marital_status | string | No | Marital status |

```json
{
  "role_type": "老年人",
  "gender": "女",
  "profession": "退休",
  "marital_status": "已婚"
}
```

**Response:**
```json
{
  "code": 200,
  "message": "用户画像更新成功",
  "data": {
    "user_id": 1,
    "role_type": "老年人"
  }
}
```

---

### DELETE `/api/users/family`

Unbind from family group. **Requires JWT authentication.**

**Response:**
```json
{
  "code": 200,
  "message": "解绑成功",
  "data": {
    "user_id": 1
  }
}
```

---

### GET `/api/users/{user_id}/security-report`

Generate user security monitoring report. **Optional JWT authentication.**

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | Target user ID |

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| stream | boolean | No | false | Enable SSE streaming output |

**Response (stream=false):**
```json
{
  "user_id": 1,
  "username": "john_doe",
  "report_generated_at": "2024-01-01T00:00:00",
  "report_content": "## 用户安全报告\n\n### 统计概览\n- 总通话数: 10\n...",
  "stats": {
    "total_calls": 10,
    "risk_calls": 2,
    "fake_calls": 1,
    "suspicious_calls": 1,
    "safe_calls": 8,
    "risk_rate": 20.0,
    "daily_trend": [
      {"date": "2024-01-01", "total": 3, "risk": 1}
    ],
    "fraud_type_distribution": [
      {"type": "冒充公检法", "count": 2}
    ]
  }
}
```

**Response (stream=true):** Uses SSE (Server-Sent Events) with chunks of the generated report.

---

### GET `/api/users/guardian`

Get guardian information for the current user. **Requires JWT authentication.**

**Response:**
```json
{
  "code": 200,
  "message": "获取监护人成功",
  "data": {
    "guardians": [
      {
        "user_id": 2,
        "name": "李四",
        "phone": "13800138001",
        "admin_role": "primary"
      }
    ]
  }
}
```

---

## Real-time Detection `/api/detection`

### WS `/api/detection/ws/{user_id}/{call_id}`

WebSocket connection for real-time streaming detection and control.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |
| call_id | integer | Yes | Call ID |

**Query Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| token | string | Yes | JWT authentication token |

---

#### Client → Server Message Types

##### 1. Audio data
```json
{
  "type": "audio",
  "data": "<base64_encoded_audio_data>"
}
```

##### 2. Video frame
```json
{
  "type": "video",
  "data": "<base64_encoded_frame_data>"
}
```

##### 3. Text content
```json
{
  "type": "text",
  "data": "通话内容文本"
}
```
Or:
```json
{
  "type": "text",
  "data": {
    "text": "通话内容文本"
  }
}
```

##### 4. Control command
```json
{
  "type": "control",
  "data": {
    "action": "set_config",
    "fps": 5
  }
}
```

##### 5. Heartbeat
```json
{
  "type": "heartbeat"
}
```

---

#### Server → Client Message Types

> 所有后端推送的消息统一通过 Redis `fraud_alerts` 频道发布，由 FastAPI 主进程转发至 WebSocket。消息外层结构为 `{"user_id": <int>, "payload": {...}}`，其中 `payload` 的 `type` 字段标识消息类型。

##### 1. `ack` — 处理确认

WebSocket 连接处理层收到客户端消息后回送的确认。

```json
{
  "type": "ack",
  "msg_type": "audio",
  "timestamp": "2024-01-01T00:00:00"
}
```

或配置更新确认：
```json
{
  "type": "ack",
  "msg": "Config updated",
  "config": {"fps": 5}
}
```

---

##### 2. `heartbeat_ack` — 心跳响应

收到客户端心跳后的响应。

```json
{
  "type": "heartbeat_ack",
  "timestamp": "2024-01-01T00:00:00"
}
```

---

##### 3. `heartbeat` — 服务端主动心跳

由 `ConnectionManager.heartbeat_check` 定期主动推送，用于保活检测。

```json
{
  "type": "heartbeat",
  "timestamp": "2024-01-01T00:00:00"
}
```

---

##### 4. `level_sync` — 防御等级同步

由 `ConnectionManager.set_defense_level` 调用，推送当前防御等级和配置给前端。

| Field | Type | Description |
|-------|------|-------------|
| type | string | `"level_sync"` |
| level | integer | 当前防御等级：0=待机, 1=正常, 2=预警, 3=最高警戒 |
| config | object | 防御配置（video_fps, warning_mode 等） |
| timestamp | string | ISO 格式时间戳 |

```json
{
  "type": "level_sync",
  "level": 2,
  "config": {
    "video_fps": 15.0,
    "warning_mode": "modal",
    "block_call": false
  },
  "timestamp": "2024-01-01T00:00:00"
}
```

---

##### 5. `detection_result` — 多模态融合检测结果

**最核心的推送消息**。由 Celery 检测任务在多模态融合后生成，包含 LLM 综合分析结果，通过 Redis 推送给前端。

| Field | Type | Description |
|-------|------|-------------|
| overall_score | number | 融合风险评分（0-100） |
| voice_confidence | number | 语音伪造置信度（0-1） |
| video_confidence | number | 视频伪造置信度（0-1） |
| text_confidence | number | 文本欺诈置信度（0-1） |
| is_fraud | boolean | 是否判定为高风险诈骗 |
| advice | string | LLM 给出的个性化防骗建议 |
| keywords | string[] | 检测到的敏感关键词列表 |
| show_risk_popup | boolean | 是否应弹出风险提示 |

```json
{
  "type": "detection_result",
  "data": {
    "overall_score": 85.5,
    "voice_confidence": 0.9234,
    "video_confidence": 0.4567,
    "text_confidence": 0.7823,
    "is_fraud": true,
    "advice": "对方要求转账到安全账户是典型冒充公检法诈骗手法，请立即挂断并报警。",
    "keywords": ["安全账户", "转账", "公安局"],
    "show_risk_popup": true
  }
}
```

---

##### 6. `alert` — 单模态风险预警

由 `NotificationService.handle_detection_result` 推送。当单一模态（语音/视频/文本）检测到异常时触发，同时写入 `MessageLog` 并可能联动监护人。

| Field | Type | Description |
|-------|------|-------------|
| title | string | 预警标题，如 "检测到voice异常风险" |
| message | string | 预警内容描述 |
| risk_level | string | 风险等级：`low` / `medium` / `high` / `critical` |
| confidence | number | 该模态检测置信度 |
| call_id | integer | 关联的通话 ID |
| display_mode | string | 前端展示模式，对应 `get_display_mode(risk_level)` |
| timestamp | string | ISO 格式时间戳 |

```json
{
  "type": "alert",
  "data": {
    "title": "检测到voice异常风险",
    "message": "当前通话环境存在伪造风险，未通过voice安全检测。",
    "risk_level": "high",
    "confidence": 0.92,
    "call_id": 1,
    "timestamp": "2024-01-01T00:00:00",
    "display_mode": "modal"
  }
}
```

**risk_level → display_mode 映射：**

| risk_level | display_mode |
|-----------|---------------|
| low | inline |
| medium | inline |
| high | modal |
| critical | fullscreen |

---

##### 7. `family_alert` — 家人安全预警

由 `NotificationService._notify_family_in_app` 推送给家庭管理员。当被监护用户遭遇风险时，监护人 App 收到实时通知。

| Field | Type | Description |
|-------|------|-------------|
| title | string | 预警标题（如含 emoji） |
| message | string | 预警消息内容 |
| risk_level | string | 风险等级 |
| victim_id | integer | 被监护用户 ID |
| victim_name | string | 被监护用户姓名 |
| victim_phone | string | 被监护用户手机号 |
| call_id | integer | 关联通话 ID |
| family_id | integer | 家庭组 ID |
| display_mode | string | 前端展示模式 |
| action | string | 前端执行动作：`none` / `vibrate`（高危）/ `alarm`（极高危） |
| timestamp | string | ISO 格式时间戳 |

```json
{
  "type": "family_alert",
  "data": {
    "title": "🚨 家人安全预警",
    "message": "您的家人【张三】疑似正在遭遇诈骗。对方声称其账户涉嫌洗钱，要求转账。",
    "risk_level": "critical",
    "victim_id": 2,
    "victim_name": "张三",
    "victim_phone": "13800138000",
    "call_id": 1,
    "family_id": 1,
    "timestamp": "2024-01-01T00:00:00",
    "display_mode": "fullscreen",
    "action": "alarm"
  }
}
```

---

##### 8. `emergency_alert` — 一键紧急报警

用户主动触发紧急报警时，推送给所有家庭管理员。最高优先级，同时触发邮件通知。

| Field | Type | Description |
|-------|------|-------------|
| title | string | 固定 "🚨 紧急报警" |
| message | string | 报警消息内容 |
| victim_id | integer | 报警用户 ID |
| victim_name | string | 报警用户姓名 |
| victim_phone | string | 报警用户手机号 |
| call_id | integer | 关联通话 ID |
| family_id | integer | 家庭组 ID |
| display_mode | string | 固定 `"fullscreen"` |
| action | string | 固定 `"alarm"`（响铃+震动） |
| alert_type | string | 报警类型：`emergency`（紧急）/ `suspicious`（可疑） |
| timestamp | string | ISO 格式时间戳 |

```json
{
  "type": "emergency_alert",
  "data": {
    "title": "🚨 紧急报警",
    "message": "用户 张三 触发了一键报警，可能正在遭遇诈骗！",
    "victim_id": 2,
    "victim_name": "张三",
    "victim_phone": "13800138000",
    "call_id": 1,
    "family_id": 1,
    "timestamp": "2024-01-01T00:00:00",
    "display_mode": "fullscreen",
    "action": "alarm",
    "alert_type": "emergency"
  }
}
```

---

##### 9. `sos_alert` — SOS 求助信号

用户主动发起求助时，推送给家庭监护人。比 `emergency_alert` 优先级稍低，action 为 `vibrate`。

| Field | Type | Description |
|-------|------|-------------|
| title | string | 固定 "紧急求助" |
| message | string | 求助消息内容 |
| victim_id | integer | 求助用户 ID |
| victim_name | string | 求助用户姓名 |
| victim_phone | string | 求助用户手机号 |
| call_id | integer | 关联通话 ID |
| family_id | integer | 家庭组 ID |
| display_mode | string | 固定 `"popup"` |
| action | string | 固定 `"vibrate"`（震动提醒） |
| urgency | string | 紧急程度，如 `"high"` |
| timestamp | string | ISO 格式时间戳 |

```json
{
  "type": "sos_alert",
  "data": {
    "title": "紧急求助",
    "message": "您的家人【张三】正在请求帮助！我正在遭遇可疑通话，请立即联系我！",
    "victim_id": 2,
    "victim_name": "张三",
    "victim_phone": "13800138000",
    "call_id": 1,
    "family_id": 1,
    "timestamp": "2024-01-01T00:00:00",
    "display_mode": "popup",
    "action": "vibrate",
    "urgency": "high"
  }
}
```

---

##### 10. `remote_control` — 远程干预指令

管理员对家庭成员执行远程控制时，推送给被干预用户。前端收到后执行相应动作（挂断通话/弹出警告/返回状态）。

| Field | Type | Description |
|-------|------|-------------|
| action | string | 干预动作：`block_call`（强制挂断）/ `warn`（发送警告）/ `check_status`（检查状态） |
| from_admin_id | integer | 发起干预的管理员 ID |
| from_admin_name | string | 管理员姓名 |
| target_user_id | integer | 被干预用户 ID |
| message | string | 附加消息 |
| control | object | 具体控制参数 |
| control.block_call | boolean | 是否强制挂断 |
| control.warning_mode | string | 警告模式 |
| control.ui_message | string | 界面提示文字 |
| control.request_status | boolean | 是否请求状态反馈（仅 check_status） |
| timestamp | string | ISO 格式时间戳 |

**Example (block_call):**
```json
{
  "type": "remote_control",
  "data": {
    "action": "block_call",
    "from_admin_id": 1,
    "from_admin_name": "张三",
    "target_user_id": 2,
    "message": "",
    "timestamp": "2024-01-01T00:00:00",
    "control": {
      "block_call": true,
      "warning_mode": "fullscreen",
      "ui_message": "监护人 张三 已为您强制挂断此通话"
    }
  }
}
```

**Example (warn):**
```json
{
  "type": "remote_control",
  "data": {
    "action": "warn",
    "from_admin_id": 1,
    "from_admin_name": "张三",
    "target_user_id": 2,
    "message": "当前通话疑似诈骗，请提高警惕！",
    "timestamp": "2024-01-01T00:00:00",
    "control": {
      "block_call": false,
      "warning_mode": "popup",
      "ui_message": "监护人 张三 提醒您注意通话安全"
    }
  }
}
```

---

##### 11. `environment_detected` — 通话环境识别结果

通过 OCR 或平台信息识别到通话环境后推送，告知前端当前应启用哪些检测模态及权重。同时该消息会触发前端切换检测模式和 UI 展示策略。

> **场景切换机制**：这是系统实现"场景自适应检测"的核心接口。不同平台（电话/微信/QQ/视频通话）的检测模态和融合权重完全不同，系统通过此消息通知前端切换采集策略。
>
> **自动识别流程**：OCR 识别图片（如微信名片、通话界面截图）→ `detect_image_task` → 提取 `environment` 字段 → `set_call_environment` → 推送 `environment_detected` → 前端切换检测模式。

| Field | Type | Description |
|-------|------|-------------|
| call_id | integer | 关联通话 ID |
| platform | string | 平台类型：`phone` / `wechat` / `qq` / `video_call` / `other` |
| is_text_chat | boolean | 是否为纯文字聊天 |
| environment_type | string | 环境类型标识，见下方映射 |
| description | string | 环境描述 |
| active_modalities | string[] | 当前启用的检测模态，如 `["voice", "text"]` |
| weights | object | 各模态的融合权重，详见下表 |

```json
{
  "type": "environment_detected",
  "data": {
    "call_id": 1,
    "platform": "wechat",
    "is_text_chat": false,
    "environment_type": "voice_chat",
    "description": "QQ/微信语音聊天场景",
    "active_modalities": ["voice", "text"],
    "weights": {
      "text": 0.72,
      "vision": 0.0,
      "audio": 0.28
    }
  }
}
```

**平台 → 环境类型映射：**

| platform | environment_type | Description |
|----------|----------------|-------------|
| `wechat` | `voice_chat` | 微信（默认语音聊天） |
| `qq` | `voice_chat` | QQ（默认语音聊天） |
| `phone` | `phone_call` | 电话通话 |
| `video_call` | `video_call` | 视频通话 |
| `other` | `unknown` | 未知环境 |

**环境类型 → 融合权重映射：**

| environment_type | text | vision | audio | 说明 |
|-----------------|------|--------|-------|------|
| `text_chat` | 1.00 | 0.00 | 0.00 | 纯文字聊天（QQ/微信文字），仅文本检测 |
| `voice_chat` | 0.72 | 0.00 | 0.28 | 语音聊天，文本主导 + 音频辅助 |
| `phone_call` | 0.65 | 0.00 | 0.35 | 电话通话，文本 + 音频均衡融合 |
| `video_call` | 0.68 | 0.12 | 0.20 | 视频通话，文本主导 + 视频辅助参考 |
| `unknown` | 0.70 | 0.10 | 0.20 | 未知环境，使用默认权重 |

**前端切换逻辑建议：**

| environment_type | 前端操作 |
|-----------------|---------|
| `text_chat` | 关闭麦克风/摄像头采集，仅发送文本 |
| `voice_chat` / `phone_call` | 开启音频采集，关闭视频采集 |
| `video_call` | 开启音频 + 视频双模态采集 |
| `unknown` | 保持默认，待 OCR 识别后自动切换 |

> 实际前端还可通过 **手动调用** `POST /api/call-records/{call_id}/environment` 接口主动上报平台类型，系统会立即重新计算权重并推送 `environment_detected`。

---

##### 12. `control` — 控制指令

由 MDP 决策引擎生成，分为两个子类型，通过 `action` 字段区分。

###### 12.1 `upgrade_level` — 防御等级变化

当检测到风险等级变化时推送，包含完整的防御配置。

| Field | Type | Description |
|-------|------|-------------|
| type | string | 固定 `"control"` |
| action | string | 固定 `"upgrade_level"` |
| target_level | integer | 目标防御等级：1=正常, 2=预警, 3=最高警戒 |
| config | object | 防御配置 |

**config 子字段：**

| Field | Type | Description |
|-------|------|-------------|
| video_fps | number | 视频帧率 |
| ui_message | string | 界面提示文字 |
| warning_mode | string | `inline`（正常）/ `modal`（预警）/ `fullscreen`（最高） |
| block_call | boolean | 是否强制挂断 |

**Example (level=2, 预警态):**
```json
{
  "type": "control",
  "action": "upgrade_level",
  "target_level": 2,
  "config": {
    "video_fps": 15.0,
    "ui_message": "检测到疑似诈骗风险，请提高警惕！",
    "warning_mode": "modal",
    "block_call": false
  }
}
```

**Example (level=3, 最高警戒):**
```json
{
  "type": "control",
  "action": "upgrade_level",
  "target_level": 3,
  "config": {
    "video_fps": 15.0,
    "ui_message": "警告：已确认高危诈骗！建议立即终止通话！",
    "warning_mode": "fullscreen",
    "block_call": true
  }
}
```

###### 12.2 `tts_speak` — 语音播报

当系统判定需要语音播报提醒（尤其是老年人/儿童用户）时，通过前端 TTS 引擎朗读警告内容。

| Field | Type | Description |
|-------|------|-------------|
| type | string | 固定 `"control"` |
| action | string | 固定 `"tts_speak"` |
| target_level | integer | 当前防御等级：1/2/3 |
| tts_priority | string | 播报优先级：`normal` / `high` / `critical` |
| tts_text | string | TTS 朗读文本（中文，应简洁，30 字以内） |
| config | object | 同 upgrade_level 的 config |

**触发条件（全部满足才推送）：**
- 融合分数 ≥ 80 **或** MDP 动作等级 ≥ 2
- LLM 判定需要 TTS（`tts_enabled: true`）
- 用户角色为"老人"或"儿童"
- 同一通话同一等级有 60 秒冷却限制（Redis key: `mdp:published_tts:{call_id}:{target_level}`）

```json
{
  "type": "control",
  "action": "tts_speak",
  "target_level": 2,
  "tts_priority": "high",
  "tts_text": "注意！对方要求转账，这是诈骗！请立即挂断电话！",
  "config": {
    "video_fps": 15.0,
    "ui_message": "检测到高风险通话，已为您开启语音提醒",
    "warning_mode": "modal",
    "block_call": false
  }
}
```

---

##### 13. `error` — 错误消息

收到无效消息格式时回送。

```json
{
  "type": "error",
  "message": "Invalid message format"
}
```

---

#### WebSocket 消息总览表

| type | 来源 | 方向 | 触发场景 |
|------|------|------|---------|
| `ack` | WebSocket handler | 后端→前端 | 收到客户端消息后回送确认 |
| `heartbeat_ack` | WebSocket handler | 后端→前端 | 收到客户端心跳后响应 |
| `heartbeat` | ConnectionManager | 后端→前端 | 定期保活检测（30s 间隔） |
| `level_sync` | ConnectionManager | 后端→前端 | 防御等级变更时同步状态 |
| `detection_result` | detection_tasks (Celery) | 后端→前端 | 多模态融合完成后推送综合结果 |
| `alert` | NotificationService | 后端→前端 | 单模态检测到异常时推送预警 |
| `family_alert` | NotificationService | 后端→前端（监护人） | 被监护人遭遇风险时通知监护人 |
| `emergency_alert` | call_records API | 后端→前端（监护人） | 用户触发一键报警 |
| `sos_alert` | family API | 后端→前端（监护人） | 用户主动发起求助 |
| `remote_control` | family API | 后端→前端（被干预用户） | 管理员执行远程干预 |
| `environment_detected` | detection_tasks (Celery) | 后端→前端 | OCR/平台识别到通话环境 |
| `control` | detection_tasks (Celery) | 后端→前端 | MDP 决策指令：upgrade_level / tts_speak |
| `error` | WebSocket handler | 后端→前端 | 消息格式错误时回送 |

---

### POST `/api/detection/upload/audio`

Upload audio file for detection. **Requires JWT authentication.**

**Request Body (multipart/form-data):**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| file | File | Yes | Audio file |
| call_id | integer | No | Associated call ID |

**Allowed file types:** `audio/mpeg`, `audio/wav`, `audio/x-m4a`, `audio/ogg`, `audio/mp3`

**Response:**
```json
{
  "code": 200,
  "message": "音频上传成功",
  "data": {
    "url": "https://minio:9000/fraud-detection/audio/1/sample.wav",
    "filename": "sample.wav",
    "size": 102400
  }
}
```

---

### POST `/api/detection/upload/video`

Upload video file for detection. **Requires JWT authentication.**

**Request Body (multipart/form-data):**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| file | File | Yes | Video file |
| call_id | integer | No | Associated call ID |

**Allowed file types:** `video/mp4`, `video/x-msvideo`, `video/quicktime`, `video/webm`

**Response:** Same structure as audio upload.

---

### POST `/api/detection/upload/image`

Upload image for OCR analysis. **Requires JWT authentication.**

**Request Body (multipart/form-data):**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| file | File | Yes | Image file (max 10MB) |
| call_id | integer | No | Associated call ID |

**Allowed file types:** `image/jpeg`, `image/png`, `image/jpg`, `image/webp`

**Response:**
```json
{
  "code": 200,
  "message": "图片上传成功，正在进行OCR识别",
  "data": {
    "url": "https://minio:9000/fraud-detection/image/1/sample.jpg",
    "filename": "sample.jpg",
    "size": 51200,
    "task_id": "abc123-def456"
  }
}
```

---

### POST `/api/detection/extract-frames`

Extract key frames from video. **Requires JWT authentication.**

**Request Body (multipart/form-data):**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| file | File | Yes | - | Video file |
| frame_rate | integer | No | 15 | Target frame rate |

**Response:**
```json
{
  "code": 200,
  "message": "成功提取30帧",
  "data": {
    "frame_count": 30,
    "frame_rate": 15,
    "frames": ["<base64_frame_1>", "<base64_frame_2>", ...]
  }
}
```

---

## Async Tasks `/api/tasks`

### POST `/api/tasks/audio/detect`

Submit audio detection task (Celery). **Requires JWT authentication.**

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| audio_base64 | string | Yes | Base64-encoded audio data |
| call_id | integer | Yes | Associated call ID |

```json
{
  "audio_base64": "SUQzBAAAAAAAI1RTU0UAAA...",
  "call_id": 1
}
```

**Response:**
```json
{
  "code": 200,
  "message": "任务已提交",
  "data": {
    "task_id": "abc123-def456",
    "status": "submitted"
  }
}
```

---

### POST `/api/tasks/video/detect`

Submit video detection task (Celery). **Requires JWT authentication.**

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| frame_data | array[string] | Yes | Array of base64-encoded frame data |
| call_id | integer | Yes | Associated call ID |

```json
{
  "frame_data": ["<base64_frame_1>", "<base64_frame_2>"],
  "call_id": 1
}
```

**Response:** Same structure as audio detect.

---

### POST `/api/tasks/text/detect`

Submit text detection task (Celery). **Requires JWT authentication.**

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| text | string | Yes | Text content to analyze |
| call_id | integer | Yes | Associated call ID |

```json
{
  "text": "这里是银行客服，您的账户涉嫌洗钱，请立即转账到安全账户",
  "call_id": 1
}
```

**Response:** Same structure as audio detect.

---

### GET `/api/tasks/status/{task_id}`

Query task status and result.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| task_id | string | Yes | Celery task ID |

**Response:**
```json
{
  "code": 200,
  "message": "查询成功",
  "data": {
    "task_id": "abc123-def456",
    "status": "SUCCESS",
    "result": {
      "overall_score": 85.5,
      "fraud_type": "冒充公检法",
      "confidence": 0.92
    }
  }
}
```

---

## Call Records `/api/call-records`

### GET `/api/call-records/my-records`

Get current user's call records. **Requires JWT authentication.**

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| page | integer | No | 1 | Page number (min: 1) |
| page_size | integer | No | 20 | Items per page (1-100) |
| result_filter | string | No | - | Filter by result: SAFE / SUSPICIOUS / FAKE |
| user_id | integer | No | - | Target user ID (for family admins viewing member records) |

**Response:**
```json
{
  "code": 200,
  "message": "查询成功",
  "data": {
    "records": [
      {
        "call_id": 1,
        "platform": "phone",
        "target_name": "张三",
        "caller_number": "13800138000",
        "start_time": "2024-01-01T10:00:00",
        "end_time": "2024-01-01T10:15:00",
        "duration": 900,
        "detected_result": "safe",
        "audio_url": "https://...",
        "analysis": "通话内容正常，未检测到欺诈风险",
        "advice": "继续保持警惕...",
        "created_at": "2024-01-01T10:00:00"
      }
    ],
    "pagination": {
      "page": 1,
      "page_size": 20,
      "total": 50,
      "total_pages": 3
    }
  }
}
```

---

### POST `/api/call-records/start`

Start a new call session. **Requires JWT authentication.**

**Query Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| platform | string | Yes | Platform: phone / wechat / qq / video_call / other |
| target_identifier | string | Yes | Phone number (for phone) or contact name (for others) |

**Response:**
```json
{
  "call_id": 1,
  "status": "started"
}
```

---

### GET `/api/call-records/record/{call_id}`

Get detailed call record. **Requires JWT authentication.**

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |

**Response:**
```json
{
  "code": 200,
  "message": "查询成功",
  "data": {
    "call_record": {
      "call_id": 1,
      "platform": "phone",
      "target_name": "张三",
      "caller_number": "13800138000",
      "start_time": "2024-01-01T10:00:00",
      "end_time": "2024-01-01T10:15:00",
      "duration": 900,
      "detected_result": "safe",
      "audio_url": "https://...",
      "analysis": "...",
      "advice": "...",
      "created_at": "2024-01-01T10:00:00"
    },
    "detection_log": {
      "overall_score": 15.5,
      "voice_conf": 0.12,
      "video_conf": null,
      "keywords": "正常问候"
    }
  }
}
```

---

### DELETE `/api/call-records/record/{call_id}`

Delete a call record. **Requires JWT authentication.** Only the record owner can delete.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |

**Response:**
```json
{
  "code": 200,
  "message": "删除成功",
  "data": {
    "call_id": 1
  }
}
```

---

### POST `/api/call-records/{call_id}/end`

End a call session and trigger AI post-call summary. **Requires JWT authentication.**

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| audio_url | string | No | Final audio file URL |
| video_url | string | No | Final video file URL |
| cover_image | string | No | Video cover/thumbnail URL |

```json
{
  "audio_url": "https://minio:9000/fraud-detection/audio/1/final.wav",
  "video_url": null,
  "cover_image": "https://minio:9000/fraud-detection/image/1/cover.jpg"
}
```

**Response:**
```json
{
  "code": 200,
  "message": "通话记录归档成功，已交由异步引擎生成AI全局总结",
  "data": {
    "duration": 900
  }
}
```

---

### GET `/api/call-records/family-records`

Get family members' call records. **Requires JWT authentication.**

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| page | integer | No | 1 | Page number |
| page_size | integer | No | 20 | Items per page (1-100) |

**Response:** Same structure as `/my-records`.

---

### GET `/api/call-records/{call_id}/audit-logs`

Get audit logs for a call. **Requires JWT authentication.**

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |

**Response:**
```json
{
  "code": 200,
  "message": "获取审计日志成功",
  "data": {
    "ai_events": [
      {
        "time_offset": 30,
        "overall_score": 85.5,
        "voice_conf": 0.92,
        "video_conf": null,
        "text_conf": 0.78,
        "evidence_url": "https://...",
        "text_content": "检测到敏感关键词：账户涉嫌洗钱"
      }
    ],
    "alert_events": [
      {
        "created_at": "2024-01-01T10:05:00",
        "msg_type": "warning",
        "risk_level": "high",
        "title": "风险预警",
        "content": "检测到疑似冒充公检法诈骗"
      }
    ]
  }
}
```

---

### POST `/api/call-records/{call_id}/report-to-admin`

Report a suspicious call to the admin for fraud case learning. **Requires JWT authentication.**

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |

**Response:**
```json
{
  "code": 200,
  "message": "已成功提交至系统防诈特征库待审核队列"
}
```

---

### GET `/api/call-records/{call_id}/chat-history`

Get chat history for a call. **Requires JWT authentication.**

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |

**Response:**
```json
{
  "code": 200,
  "message": "获取对话历史成功",
  "data": {
    "call_id": 1,
    "message_count": 15,
    "messages": [
      {
        "sequence": 1,
        "speaker": "self",
        "content": "你好",
        "timestamp": "2024-01-01T10:00:00"
      },
      {
        "sequence": 2,
        "speaker": "other",
        "content": "您好，这里是公安局",
        "timestamp": "2024-01-01T10:00:05"
      }
    ],
    "source": "database"
  }
}
```

---

### GET `/api/call-records/{call_id}/detection-timeline`

Get detailed detection timeline for a call. **Requires JWT authentication.**

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |

**Response:**
```json
{
  "code": 200,
  "message": "获取检测时间轴成功",
  "data": {
    "call_id": 1,
    "timeline": [
      {
        "time_offset": 30,
        "timestamp": "2024-01-01T10:00:30",
        "modalities": {
          "text": {"confidence": 0.78, "score": 78.0},
          "voice": {"confidence": 0.92, "score": 92.0},
          "video": {"confidence": null, "score": 0}
        },
        "overall_score": 85.5,
        "fused_risk_level": "high",
        "detected_text": "您的账户涉嫌洗钱...",
        "detected_keywords": "洗钱, 公安局, 转账",
        "match_script": "冒充公检法诈骗",
        "intent": "诈骗",
        "detection_type": "text",
        "model_version": "v1.0.0",
        "evidence_url": "https://...",
        "log_id": 1
      }
    ],
    "statistics": {
      "total_events": 25,
      "max_overall_score": 92.3,
      "avg_text_conf": 0.65,
      "avg_voice_conf": 0.45,
      "avg_video_conf": 0.0,
      "duration_seconds": 900
    }
  }
}
```

---

### GET `/api/call-records/{call_id}/evidence/{log_id}`

Get detailed evidence for a specific detection log. **Requires JWT authentication.**

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |
| log_id | integer | Yes | Detection log ID |

**Response:**
```json
{
  "code": 200,
  "message": "获取证据详情成功",
  "data": {
    "log_id": 1,
    "call_id": 1,
    "time_offset": 30,
    "created_at": "2024-01-01T10:00:30",
    "detection_type": "text",
    "modalities": {
      "text": {
        "confidence": 0.78,
        "detected_text": "您的账户涉嫌洗钱...",
        "detected_keywords": "洗钱, 公安局",
        "match_script": "冒充公检法诈骗",
        "intent": "诈骗"
      },
      "voice": {"confidence": 0.92},
      "video": {"confidence": null}
    },
    "overall_score": 85.5,
    "risk_level": "high",
    "evidence": {
      "snapshot_url": "https://...",
      "ocr_text": null,
      "ocr_dialogue_hash": null
    },
    "technical_details": {
      "algorithm_details": "BERT + DeepSeek fusion",
      "model_version": "v1.0.0"
    }
  }
}
```

---

### GET `/api/call-records/{call_id}/environment`

Get current call environment information. **Requires JWT authentication.**

> **用途**：查询当前通话的环境类型和检测权重配置。前端可在通话开始后调用此接口，确认系统当前使用的检测模态和融合权重。

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |

**Response:**
```json
{
  "code": 200,
  "message": "获取环境信息成功",
  "data": {
    "environment_type": "phone_call",
    "active_modalities": ["voice", "text"],
    "platform": "phone",
    "target_name": "张三",
    "caller_number": "13800138000",
    "description": "电话通话场景",
    "weights": {
      "text": 0.65,
      "vision": 0.0,
      "audio": 0.35
    }
  }
}
```

---

### POST `/api/call-records/{call_id}/environment`

Set / update call environment. **Requires JWT authentication.**

> **用途**：前端主动上报平台类型，触发系统重新计算检测权重并推送 `environment_detected` 消息。用于用户在通话过程中切换平台（如从电话切到微信）或系统未自动识别时手动指定。
>
> **调用时机**：建议在通话开始时（`/start` 之后）立即调用一次，系统会更新融合引擎权重并通过 WebSocket 推送 `environment_detected` 给前端，前端据此切换采集策略。

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| platform | string | Yes | - | Platform: `wechat` / `qq` / `phone` / `video_call` / `other` |
| is_text_chat | boolean | No | false | Whether it is pure text-only chat (微信/QQ 文字模式) |

**platform 有效值与对应的检测模态：**

| platform | 环境类型 | 启用模态 | 融合权重（text/vision/audio） |
|----------|---------|---------|--------------------------|
| `phone` | phone_call | voice + text | 0.65 / 0.0 / 0.35 |
| `wechat` | voice_chat | voice + text | 0.72 / 0.0 / 0.28 |
| `qq` | voice_chat | voice + text | 0.72 / 0.0 / 0.28 |
| `video_call` | video_call | voice + video + text | 0.68 / 0.12 / 0.20 |
| `other` | unknown | 默认权重 | 0.70 / 0.10 / 0.20 |

> **前端注意**：调用此接口后，应监听 WebSocket 的 `environment_detected` 消息，确认权重已切换后再调整音视频采集策略（开启/关闭麦克风/摄像头）。

---

### POST `/api/call-records/{call_id}/emergency-alert`

Trigger emergency alert (one-click alarm). **Requires JWT authentication.**

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |

**Request Body:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| call_id | integer | No | From path | Call ID |
| alert_type | string | No | "emergency" | Alert type: emergency / suspicious |
| message | string | No | Auto-generated | Custom alert message |

```json
{
  "call_id": 1,
  "alert_type": "emergency",
  "message": "我正在遭遇诈骗电话，请立即联系我！"
}
```

**Response:**
```json
{
  "code": 200,
  "message": "紧急报警已发送，已通知 2 位家庭管理员",
  "data": {
    "alert_id": 1,
    "notified_admins": 2,
    "timestamp": "2024-01-01T10:10:00"
  }
}
```

---

## Family Groups `/api/family`

### POST `/api/family/create`

Create a family group. **Requires JWT authentication.**

**Query Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | Yes | Family group name |

**Response:**
```json
{
  "code": 200,
  "message": "家庭组创建成功",
  "data": {
    "family_id": 1,
    "group_name": "张三的家庭"
  }
}
```

---

### GET `/api/family/info`

Get current user's family group information. **Requires JWT authentication.**

**Response:**
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "family_id": 1,
    "group_name": "张三的家庭",
    "created_at": "2024-01-01T00:00:00",
    "my_role": "primary",
    "primary_admin": {
      "user_id": 1,
      "username": "john_doe",
      "phone": "13800138000"
    },
    "statistics": {
      "total_members": 4,
      "primary_admins": 1,
      "secondary_admins": 1,
      "normal_members": 2
    }
  }
}
```

---

### POST `/api/family/{family_id}/apply`

Apply to join a family group. **Requires JWT authentication.**

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| family_id | integer | Yes | Target family group ID |

**Response:**
```json
{
  "code": 200,
  "message": "申请已发送，等待管理员审批"
}
```

---

### GET `/api/family/applications`

Get pending family applications (admin only). **Requires JWT authentication.**

**Response:**
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "items": [
      {
        "application_id": 1,
        "family_id": 1,
        "family_name": "张三的家庭",
        "user_id": 3,
        "username": "new_user",
        "phone": "13800138003",
        "role_type": "老年人",
        "apply_time": "2024-01-01 10:00:00"
      }
    ]
  }
}
```

---

### GET `/api/family/my-applications`

Get my submitted family applications. **Requires JWT authentication.**

**Response:** Same structure as `/applications` but filtered by current user.

---

### DELETE `/api/family/applications/{app_id}`

Cancel my submitted application. **Requires JWT authentication.**

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| app_id | integer | Yes | Application ID |

**Response:**
```json
{
  "code": 200,
  "message": "申请已取消"
}
```

---

### PUT `/api/family/applications/{app_id}`

Approve or reject a family application (admin only). **Requires JWT authentication.**

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| app_id | integer | Yes | Application ID |

**Query Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| is_approve | boolean | Yes | true = approve, false = reject |

**Response:**
```json
{
  "code": 200,
  "message": "操作成功，已同意"
}
```

---

### GET `/api/family/members`

Get family group members. **Requires JWT authentication.**

**Query Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| family_id | integer | No | Family group ID (uses current user's family if not provided) |

**Response:**
```json
{
  "code": 200,
  "message": "获取成员列表成功",
  "data": {
    "family_id": 1,
    "group_name": "张三的家庭",
    "members": [
      {
        "user_id": 1,
        "username": "john_doe",
        "name": "张三",
        "phone": "13800138000",
        "role_type": "青壮年",
        "admin_role": "primary",
        "is_me": true
      },
      {
        "user_id": 2,
        "username": "jane_doe",
        "name": "李四",
        "phone": "13800138001",
        "role_type": "老年人",
        "admin_role": "secondary",
        "is_me": false
      }
    ]
  }
}
```

---

### PUT `/api/family/members/{user_id}/admin-role`

Set member admin role (primary admin only). **Requires JWT authentication.**

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | Target user ID |

**Query Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| role | string | Yes | Role: none / secondary / primary |

**Response:**
```json
{
  "code": 200,
  "message": "已将 jane_doe 设置为副管理员"
}
```

---

### DELETE `/api/family/members/{user_id}`

Remove a member from the family group (admin only). **Requires JWT authentication.**

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | Target user ID |

**Response:**
```json
{
  "code": 200,
  "message": "已将该成员移出家庭组"
}
```

---

### POST `/api/family/leave`

Leave the current family group. **Requires JWT authentication.**

**Response:**
```json
{
  "code": 200,
  "message": "已退出家庭组"
}
```

---

### GET `/api/family/my-admin-families`

Get families where current user is an admin. **Requires JWT authentication.**

**Response:**
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "items": [
      {
        "family_id": 1,
        "group_name": "张三的家庭",
        "my_role": "primary",
        "member_count": 4,
        "created_at": "2024-01-01T00:00:00"
      }
    ]
  }
}
```

---

### POST `/api/family/sos`

Send SOS alert to family guardians. **Requires JWT authentication.**

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| call_id | integer | Yes | - | Current call ID |
| message | string | No | "我正在遭遇可疑通话，请立即联系我！" | SOS message |

**Response:**
```json
{
  "code": 200,
  "message": "求助信号已发送给 2 位监护人",
  "data": {
    "notified_count": 2,
    "call_id": 1,
    "timestamp": "2024-01-01T10:05:00"
  }
}
```

---

### POST `/api/family/remote-intervene`

Remote intervention on a family member's call (admin only). **Requires JWT authentication.**

**Query Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| target_user_id | integer | Yes | Target user ID to intervene |
| action | string | Yes | Action: block_call / warn / check_status |
| message | string | No | Additional message |

**Response:**
```json
{
  "code": 200,
  "message": "干预指令已发送给 李四",
  "data": {
    "action": "warn",
    "target_user_id": 2,
    "target_user_name": "李四",
    "timestamp": "2024-01-01T10:10:00"
  }
}
```

---

## Anti-Fraud Education `/api/education`

### GET `/api/education/recommendations/{user_id}`

Get personalized anti-fraud education recommendations.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| limit | integer | No | 5 | Number of recommendations |

**Response:**
```json
[
  {
    "id": 1,
    "title": "防范冒充公检法诈骗",
    "content_type": "video",
    "url": "/api/education/videos/prevent_fraud.mp4",
    "fraud_type": "冒充公检法"
  }
]
```

---

### GET `/api/education/recommendations/profile/{user_id}`

Get profile-based personalized recommendations.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| limit | integer | No | 5 | Number of recommendations |
| page | integer | No | 1 | Page number |

**Response:**
```json
{
  "code": 200,
  "message": "获取个性化推荐成功",
  "data": {
    "cases": [
      {
        "id": "case_1",
        "title": "冒充银行客服诈骗案例",
        "content": "案例详情...",
        "fraud_type": "冒充客服",
        "risk_level": "高危",
        "similarity": 0.92
      }
    ],
    "slogans": [
      {
        "id": "slogan_1",
        "content": "公检法不会通过电话办案！",
        "fraud_type": "冒充公检法"
      }
    ],
    "videos": [
      {
        "id": "video_1",
        "title": "如何识别诈骗电话",
        "url": "/api/education/videos/identify_fraud.mp4",
        "fraud_type": "通用",
        "description": "教你识别常见诈骗手法"
      }
    ],
    "vulnerability_analysis": "根据您的角色特点，您需要重点防范...",
    "recommended_types": ["冒充公检法", "网络购物诈骗"]
  }
}
```

---

### GET `/api/education/recommendations/library/{user_id}`

Get recommendations from case and law library.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| fraud_type | string | No | - | Specific fraud type filter |
| limit | integer | No | 5 | Number of recommendations |

**Response:**
```json
{
  "code": 200,
  "message": "获取案例库和法律库推荐成功，共10个案例，5条法律",
  "data": {
    "cases": [...],
    "laws": [...],
    "source_stats": {
      "cases": 10,
      "laws": 5
    }
  }
}
```

---

### POST `/api/education/recommendations/realtime`

Real-time recommendations based on ongoing conversation.

**Request Body:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| user_id | integer | Yes | - | User ID |
| conversation_text | string | Yes | - | Current conversation transcript |
| top_k | integer | No | 3 | Number of recommendations (1-10) |

```json
{
  "user_id": 1,
  "conversation_text": "您好，这里是公安局，您涉嫌一起洗钱案件...",
  "top_k": 3
}
```

**Response:**
```json
{
  "code": 200,
  "message": "实时推荐成功",
  "data": {
    "cases": [...],
    "slogans": [...],
    "similarity_analysis": "当前通话与'冒充公检法诈骗'相似度达92%",
    "alert_message": "警告：检测到疑似冒充公检法诈骗！",
    "matched_fraud_types": ["冒充公检法", "洗钱诈骗"]
  }
}
```

---

### GET `/api/education/videos/{filename}`

Get education video file.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| filename | string | Yes | Video filename |

**Response:** Video file (video/mp4).

---

### POST `/api/education/match_cases`

Match similar fraud cases based on transcript.

**Request Body:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| transcript | string | Yes | - | Call transcript |
| top_k | integer | No | 1 | Number of matches |

```json
{
  "transcript": "这里是银行客服，您的账户存在异常...",
  "top_k": 3
}
```

**Response:**
```json
{
  "status": "success",
  "data": [...]
}
```

---

### POST `/api/education/record/{user_id}`

Record user learning progress.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |

**Request Body:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| item_id | integer | Yes | - | Knowledge item ID |
| is_completed | boolean | No | false | Completion status |

```json
{
  "item_id": 1,
  "is_completed": true
}
```

**Response:**
```json
{
  "status": "success",
  "message": "学习记录已更新"
}
```

---

### GET `/api/education/records/{user_id}`

Get user's learning records.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| limit | integer | No | 20 | Number of records |
| completed_only | boolean | No | false | Filter completed only |

**Response:**
```json
{
  "code": 200,
  "message": "获取学习记录成功",
  "data": {
    "items": [...],
    "total": 10,
    "completed_only": false
  }
}
```

---

## Admin Management `/api/admin`

### GET `/api/admin/stats`

Get dashboard statistics.

**Response:**
```json
{
  "total_users": 100,
  "total_calls": 500,
  "fraud_blocked": 45,
  "blacklist_count": 120,
  "active_rules": 30,
  "new_users_today": 5,
  "detections_today": 20,
  "blocked_today": 3,
  "avg_risk_score": 25.5,
  "system_health": "100%",
  "detection_rate": 9.0
}
```

---

### GET `/api/admin/stats/trends`

Get trend data over N days.

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| days | integer | No | 7 | Number of days (1-30) |

**Response:**
```json
[
  {"date": "01-01", "detections": 20, "blocked": 3, "new_users": 5},
  {"date": "01-02", "detections": 25, "blocked": 2, "new_users": 7}
]
```

---

### GET `/api/admin/stats/fraud-types`

Get fraud type distribution.

**Response:**
```json
[
  {"type": "冒充公检法", "value": 15},
  {"type": "网络购物诈骗", "value": 12},
  {"type": "冒充客服诈骗", "value": 10}
]
```

---

### GET `/api/admin/stats/hourly`

Get 24-hour detection distribution.

**Response:**
```json
{
  "hours": [0, 1, 2, ..., 23],
  "counts": [2, 1, 0, 3, ..., 5]
}
```

---

### POST `/api/admin/test/text_match`

Test text rule matching.

**Query Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| text | string | Yes | Text to test |

**Response:**
```json
{
  "text_length": 50,
  "hit_keywords": ["公安局", "洗钱"],
  "risk_level": 4,
  "action": "alert"
}
```

---

### GET `/api/admin/rules`

Get all risk rules.

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| skip | integer | No | 0 | Offset |
| limit | integer | No | 100 | Limit |

**Response:**
```json
[
  {
    "rule_id": 1,
    "keyword": "公安局",
    "risk_level": 3,
    "action": "alert",
    "description": "冒充公检法关键词",
    "is_active": true,
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
]
```

---

### POST `/api/admin/rules`

Create a new risk rule.

**Request Body:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| keyword | string | Yes | - | Rule keyword |
| risk_level | integer | No | 1 | Risk level (1-5) |
| action | string | No | "alert" | Action: alert / block |
| description | string | No | - | Rule description |
| is_active | boolean | No | true | Whether active |

```json
{
  "keyword": "安全账户",
  "risk_level": 5,
  "action": "block",
  "description": "要求转账到安全账户是典型诈骗",
  "is_active": true
}
```

**Response:** Returns the created rule object.

---

### DELETE `/api/admin/rules/{rule_id}`

Delete a risk rule.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| rule_id | integer | Yes | Rule ID |

**Response:**
```json
{"msg": "Deleted"}
```

---

### GET `/api/admin/blacklist`

Get phone number blacklist.

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| skip | integer | No | 0 | Offset |
| limit | integer | No | 100 | Limit |

**Response:**
```json
[
  {
    "id": 1,
    "number": "13800138000",
    "source": "manual_admin",
    "report_count": 5,
    "risk_level": 5,
    "description": "多次举报的可疑号码",
    "is_active": true,
    "created_at": "2024-01-01T00:00:00",
    "updated_at": "2024-01-01T00:00:00"
  }
]
```

---

### POST `/api/admin/blacklist`

Add a number to blacklist.

**Request Body:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| number | string | Yes | - | Phone number |
| source | string | No | "manual_admin" | Source |
| risk_level | integer | No | 5 | Risk level (1-5) |
| description | string | No | - | Description |
| is_active | boolean | No | true | Whether active |

```json
{
  "number": "13800138000",
  "source": "manual_admin",
  "risk_level": 5,
  "description": "多次举报的可疑号码"
}
```

**Response:** Returns the created blacklist entry.

---

### DELETE `/api/admin/blacklist/{id}`

Remove a number from blacklist.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| id | integer | Yes | Blacklist entry ID |

**Response:**
```json
{"msg": "Deleted"}
```

---

### GET `/api/admin/fraud-cases`

Get fraud case records (detected_result = FAKE).

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| skip | integer | No | 0 | Offset |
| limit | integer | No | 50 | Limit |

**Response:**
```json
[
  {
    "call_id": 1,
    "user_id": 2,
    "target_number": "13800138000",
    "start_time": "2024-01-01T10:00:00",
    "duration": 300,
    "risk_level": "高危",
    "fraud_type": "冒充公检法",
    "details": "[风险评分:92.5] 检测到疑似冒充公检法诈骗"
  }
]
```

---

### POST `/api/admin/fraud-cases/{call_id}/learn`

Add fraud case to pending learning queue.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |

**Response:**
```json
{
  "msg": "成功加入待学习队列",
  "file": "manual_learn_1_20240101120000.json"
}
```

---

### POST `/api/admin/fraud-cases/{call_id}/learn-with-edit`

Edit fraud case and add to learning queue.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| modality | string | No | text / audio / video / image |
| fraud_type | string | Yes | Fraud type |
| risk_level | string | No | 高危 / 中危 / 低危 |
| content | string | No | Case content |
| details | string | No | Additional details |
| tags | array[string] | No | Tags |
| source | string | No | Source |
| uploader | string | No | Uploader |

**Response:**
```json
{
  "msg": "案例编辑成功并加入待学习队列",
  "file": "edited_cases_20240101.json",
  "case_count": 3
}
```

---

### POST `/api/admin/cases/upload`

Upload a new fraud case.

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| modality | string | Yes | text / audio / video / image |
| fraud_type | string | Yes | Fraud type |
| risk_level | string | Yes | 高危 / 中危 / 低危 |
| content | string | Yes | Case content |
| source | string | No | Source |
| tags | array[string] | No | Tags |
| uploader | string | No | Uploader name |

```json
{
  "modality": "audio",
  "fraud_type": "冒充客服",
  "risk_level": "高危",
  "content": "诈骗案例详细描述...",
  "source": "用户举报",
  "tags": ["冒充客服", "网络诈骗"],
  "uploader": "admin"
}
```

**Response:**
```json
{
  "msg": "案例上传成功",
  "file": "uploaded_cases_20240101.json",
  "case_count": 5,
  "case_id": 4
}
```

---

### GET `/api/admin/cases/pending`

Get pending case files list.

**Response:**
```json
[
  {
    "filename": "uploaded_cases_20240101.json",
    "size": 2048,
    "modified": "2024-01-01T12:00:00",
    "case_count": 5
  }
]
```

---

### GET `/api/admin/cases/pending/{filename}`

Get pending case file details.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| filename | string | Yes | Case filename |

**Response:** JSON array of case objects.

---

### DELETE `/api/admin/cases/pending/{filename}`

Delete a pending case file.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| filename | string | Yes | Case filename |

**Response:**
```json
{"msg": "文件已删除", "filename": "uploaded_cases_20240101.json"}
```

---

### GET `/api/admin/cases/learned`

Get learned case files list.

**Response:** Same structure as `/cases/pending`.

---

### GET `/api/admin/system/logs`

Get system operation logs.

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| skip | integer | No | 0 | Offset |
| limit | integer | No | 50 | Limit |
| action | string | No | - | Filter by action type |

**Response:**
```json
[
  {
    "log_id": 1,
    "admin_id": 1,
    "action": "create_rule",
    "resource": "risk_rule",
    "resource_id": 5,
    "details": "Created rule: 安全账户",
    "ip_address": "192.168.1.1",
    "created_at": "2024-01-01T12:00:00"
  }
]
```

---

### GET `/api/admin/system/health`

Get system health status.

**Response:**
```json
{
  "status": "healthy",
  "pending_cases": 3,
  "learned_cases": 50,
  "timestamp": "2024-01-01T12:00:00"
}
```

---

### GET `/api/admin/detection/recent`

Get recent detection records.

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| limit | integer | No | 20 | Number of records (1-100) |

**Response:**
```json
[
  {
    "log_id": 1,
    "call_id": 1,
    "detection_type": "text",
    "overall_score": 85.5,
    "voice_confidence": 0.92,
    "video_confidence": null,
    "text_confidence": 0.78,
    "created_at": "2024-01-01T10:00:30",
    "caller_number": "13800138000"
  }
]
```

---

### GET `/api/admin/users`

Get user list.

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| skip | integer | No | 0 | Offset |
| limit | integer | No | 100 | Limit |

**Response:**
```json
[
  {
    "user_id": 1,
    "username": "john_doe",
    "name": "张三",
    "phone": "13800138000",
    "email": "user@example.com",
    "role_type": "青壮年",
    "gender": "男",
    "profession": "工程师",
    "marital_status": "已婚",
    "family_id": 1,
    "is_active": true,
    "is_admin": false,
    "created_at": "2024-01-01T00:00:00"
  }
]
```

---

### GET `/api/admin/users/{user_id}`

Get user detail.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |

**Response:** Same structure as user object in `/users`.

---

### PUT `/api/admin/users/{user_id}`

Update user information.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| name | string | No | Display name |
| phone | string | No | Phone number |
| email | string | No | Email |
| role_type | string | No | Role type |
| gender | string | No | Gender |
| profession | string | No | Occupation |
| marital_status | string | No | Marital status |

**Response:**
```json
{"msg": "更新成功"}
```

---

### PATCH `/api/admin/users/{user_id}/status`

Update user active status.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |

**Request Body:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| is_active | boolean | No | Account active status |

**Response:**
```json
{"msg": "状态更新成功", "is_active": false}
```

---

### DELETE `/api/admin/users/{user_id}`

Delete a user.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |

**Response:**
```json
{"msg": "删除成功"}
```

---

### GET `/api/admin/users/{user_id}/call-stats`

Get user call statistics.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |

**Response:**
```json
{
  "total_calls": 50,
  "fraud_calls": 5,
  "suspicious_calls": 8
}
```

---

### GET `/api/admin/users/{user_id}/memories`

Get user's long-term memories.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| memory_type | string | No | - | Filter by type |
| min_importance | integer | No | 1 | Minimum importance (1-5) |
| limit | integer | No | 20 | Number of records (max 100) |

**Response:**
```json
{
  "items": [
    {
      "memory_id": 1,
      "memory_type": "fraud_experience",
      "content": "曾接到冒充公检法诈骗电话...",
      "importance": 5,
      "source_call_id": 1,
      "created_at": "2024-01-01T10:00:00"
    }
  ]
}
```

---

### POST `/api/admin/users/{user_id}/memories`

Add user long-term memory.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| memory_type | string | Yes | - | fraud_experience / alert_response / preference / risk_pattern |
| content | string | Yes | - | Memory content |
| importance | integer | No | 3 | Importance (1-5) |
| source_call_id | integer | No | - | Source call ID |

**Response:**
```json
{
  "code": 200,
  "message": "记忆添加成功",
  "memory_id": 1
}
```

---

### DELETE `/api/admin/memories/{memory_id}`

Delete a long-term memory.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| memory_id | integer | Yes | Memory ID |

**Response:**
```json
{"code": 200, "message": "记忆删除成功"}
```

---

### GET `/api/admin/users/{user_id}/memory-summary`

Get user memory summary.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |

**Response:**
```json
{
  "user_id": 1,
  "summary": "该用户曾多次接到冒充公检法诈骗电话，对冒充客服诈骗也比较敏感...",
  "statistics": {
    "fraud_experience": 3,
    "alert_response": 5,
    "risk_pattern": 2
  }
}
```

---

### POST `/api/admin/users/{user_id}/refresh-memory-summary`

Refresh user memory summary.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| user_id | integer | Yes | User ID |

**Response:**
```json
{
  "code": 200,
  "message": "记忆摘要已刷新",
  "summary": "该用户曾多次接到冒充公检法诈骗电话..."
}
```

---

### GET `/api/admin/family-groups`

Get all family groups.

**Query Parameters:**
| Field | Type | Required | Default | Description |
|-------|------|----------|---------|-------------|
| skip | integer | No | 0 | Offset |
| limit | integer | No | 100 | Limit |

**Response:**
```json
{
  "items": [
    {
      "id": 1,
      "group_name": "张三的家庭",
      "admin_id": 1,
      "primary_admin": {
        "user_id": 1,
        "username": "john_doe",
        "phone": "13800138000"
      },
      "statistics": {
        "total_members": 4,
        "primary_admins": 1,
        "secondary_admins": 1
      },
      "created_at": "2024-01-01T00:00:00"
    }
  ],
  "total": 10
}
```

---

### GET `/api/admin/family-groups/{family_id}/members`

Get family group members.

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| family_id | integer | Yes | Family group ID |

**Response:**
```json
{
  "family_id": 1,
  "group_name": "张三的家庭",
  "members": [
    {
      "user_id": 1,
      "username": "john_doe",
      "name": "张三",
      "phone": "13800138000",
      "email": "user@example.com",
      "role_type": "青壮年",
      "admin_role": "primary",
      "is_active": true
    }
  ]
}
```

---

### GET `/api/admin/family-stats`

Get family group statistics.

**Response:**
```json
{
  "total_families": 10,
  "total_members": 35,
  "total_admins": 12
}
```

---

### GET `/api/admin/call-records/{call_id}/detection-timeline`

Get call detection timeline (admin view).

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |

**Response:** Same structure as user-facing `/call-records/{call_id}/detection-timeline`.

---

### GET `/api/admin/call-records/{call_id}/chat-history`

Get call chat history (admin view).

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| call_id | integer | Yes | Call ID |

**Response:** Same structure as user-facing `/call-records/{call_id}/chat-history`.

---

### GET `/api/admin/detection/{log_id}/evidence`

Get detection evidence (admin view).

**Path Parameters:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| log_id | integer | Yes | Detection log ID |

**Response:** Same structure as user-facing `/call-records/{call_id}/evidence/{log_id}`.

---

## Database Schema

### Tables

#### `users`
| Column | Type | Description |
|--------|------|-------------|
| user_id | INT (PK) | User ID, auto-increment |
| phone | VARCHAR(20) | Phone number, unique, required |
| email | VARCHAR(100) | Email, unique, indexed |
| username | VARCHAR(50) | Username, unique, required |
| name | VARCHAR(50) | Display name |
| password_hash | VARCHAR(255) | Bcrypt hashed password, required |
| family_id | INT (FK) | Family group ID (nullable) |
| role_type | VARCHAR(20) | Role: 青壮年 / 老年人 / 儿童 / 学生 (default: 青壮年) |
| gender | VARCHAR(10) | Gender |
| profession | VARCHAR(50) | Occupation |
| marital_status | VARCHAR(20) | Marital status |
| is_active | BOOL | Account active status (default: true) |
| is_admin | BOOL | Admin flag (default: false) |
| memory_summary | TEXT | LLM-generated memory summary |
| created_at | DATETIME | Creation timestamp |
| updated_at | DATETIME | Last update timestamp |

#### `call_records`
| Column | Type | Description |
|--------|------|-------------|
| call_id | INT (PK) | Call ID, auto-increment |
| user_id | INT (FK) | Owner user ID |
| caller_number | VARCHAR(20) | Caller's phone number (for PHONE platform) |
| platform | ENUM | PHONE / WECHAT / VIDEO_CALL / QQ / OTHER |
| target_name | VARCHAR(100) | Contact name (for non-PHONE platforms) |
| start_time | DATETIME | Call start time, required |
| end_time | DATETIME | Call end time |
| duration | INT | Duration in seconds (default: 0) |
| analysis | TEXT | AI-generated full analysis |
| advice | TEXT | AI-generated anti-fraud advice |
| detected_result | ENUM | SAFE / SUSPICIOUS / FAKE |
| fraud_type | VARCHAR(50) | Detected fraud type |
| match_script | VARCHAR(100) | Matched fraud script |
| audio_url | VARCHAR(500) | Audio file URL (MinIO) |
| video_url | VARCHAR(500) | Video file URL (MinIO) |
| cover_image | VARCHAR(500) | Video thumbnail URL |
| created_at | DATETIME | Creation timestamp |

#### `ai_detection_logs`
| Column | Type | Description |
|--------|------|-------------|
| log_id | INT (PK) | Log ID, auto-increment |
| call_id | INT (FK) | Associated call ID |
| voice_confidence | FLOAT | Voice deepfake confidence (0-1) |
| video_confidence | FLOAT | Video deepfake confidence (0-1) |
| text_confidence | FLOAT | Text fraud confidence (0-1) |
| overall_score | FLOAT | Fused overall risk score (0-100) |
| detected_text | TEXT | Detected fraudulent text content |
| detected_keywords | TEXT | Extracted sensitive keywords |
| match_script | VARCHAR(100) | Matched fraud script |
| intent | VARCHAR(100) | Detected caller intent |
| evidence_snapshot | VARCHAR(500) | Evidence file URL |
| time_offset | INT | Time offset in seconds from call start |
| algorithm_details | TEXT | Detailed algorithm output |
| model_version | VARCHAR(50) | AI model version used |
| detection_type | VARCHAR(20) | text / audio / video / image |
| image_ocr_text | TEXT | OCR extracted text |
| ocr_dialogue_hash | VARCHAR(64) | Dialogue hash for matching |
| created_at | DATETIME | Detection timestamp |

#### `family_groups`
| Column | Type | Description |
|--------|------|-------------|
| id | INT (PK) | Family group ID, auto-increment |
| group_name | VARCHAR(100) | Group name, required |
| admin_id | INT (FK) | Primary admin user ID |
| created_at | DATETIME | Creation timestamp |

#### `family_admins`
| Column | Type | Description |
|--------|------|-------------|
| id | INT (PK) | Record ID, auto-increment |
| user_id | INT (FK) | Admin user ID |
| family_id | INT (FK) | Family group ID |
| admin_role | VARCHAR(20) | Role: primary / secondary |

#### `family_applications`
| Column | Type | Description |
|--------|------|-------------|
| id | INT (PK) | Application ID, auto-increment |
| family_id | INT (FK) | Target family group ID |
| user_id | INT (FK) | Applicant user ID |
| status | ENUM | PENDING / APPROVED / REJECTED |
| created_at | DATETIME | Application timestamp |

#### `risk_rules`
| Column | Type | Description |
|--------|------|-------------|
| rule_id | INT (PK) | Rule ID, auto-increment |
| keyword | VARCHAR(100) | Match keyword, unique, required |
| action | VARCHAR(20) | Action: alert / block |
| risk_level | INT | Risk level 1-5 (default: 1) |
| is_active | BOOL | Rule active status (default: true) |
| description | VARCHAR(255) | Rule description |
| created_at | DATETIME | Creation timestamp |
| updated_at | DATETIME | Last update timestamp |

#### `number_blacklist`
| Column | Type | Description |
|--------|------|-------------|
| id | INT (PK) | Record ID, auto-increment |
| number | VARCHAR(20) | Phone number, unique, required |
| source | VARCHAR(50) | Report source (default: manual_admin) |
| report_count | INT | Number of reports (default: 1) |
| risk_level | INT | Risk level 1-5 (default: 1) |
| is_active | BOOL | Blacklist status (default: true) |
| description | VARCHAR(255) | Additional notes |
| created_at | DATETIME | Creation timestamp |
| updated_at | DATETIME | Last update timestamp |

#### `user_memories`
| Column | Type | Description |
|--------|------|-------------|
| memory_id | INT (PK) | Memory ID, auto-increment |
| user_id | INT (FK) | User ID |
| memory_type | VARCHAR(30) | Type: fraud_experience / alert_response / preference / risk_pattern |
| content | TEXT | Memory content, required |
| importance | INT | Importance 1-5 (default: 3) |
| source_call_id | INT (FK) | Source call ID (nullable) |
| created_at | DATETIME | Creation timestamp |
| updated_at | DATETIME | Last update timestamp |

#### `knowledge_items`
| Column | Type | Description |
|--------|------|-------------|
| id | INT (PK) | Item ID, auto-increment |
| item_type | VARCHAR(50) | Type: video / article |
| title | VARCHAR(255) | Title, required |
| summary | TEXT | Summary |
| content_url | VARCHAR(500) | Content URL (MinIO) |
| fraud_type | VARCHAR(100) | Related fraud type |
| target_group | VARCHAR(255) | Target audience |
| created_at | DATETIME | Creation timestamp |

#### `user_learning_records`
| Column | Type | Description |
|--------|------|-------------|
| id | INT (PK) | Record ID, auto-increment |
| user_id | INT (FK) | User ID |
| item_id | INT (FK) | Knowledge item ID |
| is_completed | BOOL | Completion status (default: false) |
| learned_at | DATETIME | Learning timestamp (auto-update) |
| created_at | DATETIME | Creation timestamp |

---

## Configuration

All settings in `app/core/config.py` via pydantic-settings:

| Setting | Default Value | Description |
|---------|--------------|-------------|
| DATABASE_URL | mysql+aiomysql://root:...@localhost:3307/ai_fraud_detection | MySQL connection |
| REDIS_URL | redis://localhost:6379/0 | Redis connection |
| MINIO_ENDPOINT | localhost:9000 | MinIO endpoint |
| MINIO_BUCKET_NAME | fraud-detection | MinIO bucket name |
| JWT_SECRET_KEY | dev-jwt-secret-key... | JWT signing key |
| JWT_ALGORITHM | HS256 | JWT algorithm |
| ACCESS_TOKEN_EXPIRE_MINUTES | 30 | JWT expiry |
| VOICE_DETECTION_THRESHOLD | 0.90 | Voice fake threshold |
| VIDEO_DETECTION_THRESHOLD | 0.74 | Video deepfake threshold |
| TEXT_DETECTION_THRESHOLD | 0.80 | Text fraud threshold |
| VIDEO_INPUT_SIZE | (299, 299) | Video model input |
| VIDEO_SEQUENCE_LENGTH | 10 | Frames per batch |
| VIDEO_TARGET_FPS | 15.0 | Target frame rate |
| LLM_MODEL_NAME | deepseek-chat | LLM model name |
| LLM_BASE_URL | https://api.deepikeek.com/v1 | LLM API endpoint |
| CELERY_BROKER_URL | redis://localhost:6379/1 | Celery broker |
| CELERY_RESULT_BACKEND | redis://localhost:6379/2 | Celery result backend |

---

## Deployment

### Docker Compose (Recommended)

```bash
docker-compose up -d
```

Starts: MySQL (port 3307), Redis (port 6379), MinIO (ports 9000/9001)

### Application

```bash
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

### Celery Worker

```bash
celery -A app.tasks.celery_app worker --loglevel=info
```

### Environment Setup (Windows)

```bash
setup.bat
start_celery.bat
```

---

## Key Features

### 1. Multi-modal Fraud Detection
- **Voice**: AASIST deepfake voice detection
- **Video**: Xception + BiLSTM deepfake video detection
- **Text**: BERT-based fraud text classification
- **Image**: OCR text extraction from images
- **Fusion**: Scene-adaptive weighted fusion with temporal smoothing

### 1.1 Scene-Adaptive Detection (Environment-Aware)
The system automatically detects the communication platform and adjusts detection strategies:

| Platform | Environment Type | Active Modalities | Fusion Weights (text/vision/audio) |
|----------|----------------|-------------------|----------------------------------|
| Phone | `phone_call` | voice + text | 0.65 / 0.0 / 0.35 |
| WeChat / QQ | `voice_chat` | voice + text | 0.72 / 0.0 / 0.28 |
| WeChat / QQ (text) | `text_chat` | text only | 1.0 / 0.0 / 0.0 |
| Video Call | `video_call` | voice + video + text | 0.68 / 0.12 / 0.20 |

Detection flow: OCR scan → `set_call_environment` → `environment_detected` (WebSocket) → frontend switches采集策略. Manual override available via `POST /api/call-records/{call_id}/environment`.

### 2. Real-time WebSocket Streaming
- Live fraud probability updates during calls
- Defense level control (normal, elevated, maximum)
- Heartbeat mechanism for connection health

### 3. MDP (Markov Decision Process) Defense Agent
- Dynamic defense strategy selection
- Reward-based action optimization
- Multi-agent coordination

### 4. Family Group Management
- Multi-admin family groups
- Join request workflow (apply → approve/reject)
- SOS emergency alerts
- Remote intervention in family calls
- Family-level call records visibility

### 5. Anti-fraud Education
- Personalized recommendations based on user profile
- Video and article knowledge base
- Learning progress tracking
- Similar case matching (RAG with ChromaDB)

### 6. User Memory System
- Short-term memory (Redis): Recent interaction context
- Long-term memory (SQLAlchemy): Persistent important facts
- Memory summary (LLM-generated): Compressed user profile

### 7. Admin Dashboard
- System statistics and trends
- Risk rule management (CRUD)
- Phone blacklist management
- Fraud case library management
- User and family group management
- System health monitoring
