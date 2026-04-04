# 平台检测（通话环境识别）接口文档

> 编写目标：供前端（移动端 App）开发人员集成使用。
>
> 最新版本：2026-04-03

---

## 一、系统概述

通话环境识别是系统的核心功能之一。系统通过识别用户当前所在的通话平台（微信 / QQ / 电话 / 视频通话等），**自动调整多模态检测策略**，确定该用哪些模态（语音 / 视频 / 文本）来检测诈骗，以及各模态的融合权重。

整个流程分为三个阶段：

```
阶段 1：环境识别
  前端上报平台  →  后端更新融合引擎  →  计算出新的检测权重

阶段 2：推送确认
  后端通过 WebSocket 推送 `environment_detected` 消息给前端

阶段 3：前端切换
  前端收到消息后，根据 weights 切换音视频采集策略
```

---

## 二、WebSocket 连接

### 2.1 连接地址

```
ws://{{host}}/api/detection/ws/{{user_id}}/{{call_id}}?token={{jwt_token}}
```

| 参数 | 说明 |
|------|------|
| host | 后端服务地址，如 `http://localhost:8000` |
| user_id | 当前登录用户的 ID（整数） |
| call_id | 当前通话的 ID（整数），由 `POST /api/call-records/start` 返回 |
| token | JWT 访问令牌（Query 参数，非 Header） |

> ⚠️ **重要**：`user_id` 和 `call_id` 是路径参数，`token` 是 Query 参数，顺序不能颠倒。

### 2.2 鉴权方式

前端需在连接 URL 中附带 JWT Token：

```
ws://localhost:8000/api/detection/ws/1/123?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

后端在 WebSocket 连接建立时验证 Token，验证失败则拒绝连接。

### 2.3 离线消息说明

**后端不保存离线消息。**

如果用户在推送 `environment_detected` 时不在线（WebSocket 未连接），该消息会被丢弃。因此前端必须**先建立 WebSocket 连接，再上报环境**，确保能收到后端的确认推送。

---

## 三、REST API 接口

### 3.1 查询当前环境

**GET** `/api/call-records/{call_id}/environment`

查询当前通话使用的环境类型和检测权重配置。

**请求头**

| 参数 | 值 | 说明 |
|------|----|------|
| Authorization | Bearer {token} | JWT 认证令牌 |

**路径参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| call_id | integer | 是 | 通话 ID |

**响应示例（200）**

```json
{
  "code": 200,
  "message": "获取环境信息成功",
  "data": {
    "environment_type": "voice_chat",
    "description": "语音聊天",
    "weights": {
      "text": 0.72,
      "vision": 0.0,
      "audio": 0.28
    },
    "active_modalities": ["text", "audio"],
    "platform": "wechat",
    "target_name": "张三",
    "caller_number": "13800138000"
  }
}
```

**响应字段说明**

| 字段 | 类型 | 说明 |
|------|------|------|
| environment_type | string | 环境类型标识，见"环境类型对照表" |
| description | string | 中文描述 |
| weights | object | 三模态融合权重（text / vision / audio） |
| active_modalities | string[] | 当前启用的检测模态 |
| platform | string | 平台原始值（wechat / qq / phone / video_call / other） |
| target_name | string | 被叫方姓名（如有） |
| caller_number | string | 主叫号码（如有） |

**未设置过环境时的默认值**

如果从未调用过 `POST /environment`，`environment_type` 会返回 `"unknown"`，权重为默认值：

```json
{
  "environment_type": "unknown",
  "description": "未知环境",
  "weights": { "text": 0.70, "vision": 0.10, "audio": 0.20 },
  "active_modalities": ["text", "audio", "vision"]
}
```

---

### 3.2 上报 / 设置环境

**POST** `/api/call-records/{call_id}/environment`

前端主动上报当前通话的平台类型，触发后端更新检测权重并推送 WebSocket 确认消息。

**请求头**

| 参数 | 值 | 说明 |
|------|----|------|
| Authorization | Bearer {token} | JWT 认证令牌 |

**路径参数**

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| call_id | integer | 是 | 通话 ID |

**Query 参数**

| 参数 | 类型 | 必填 | 默认值 | 说明 |
|------|------|------|--------|------|
| platform | string | 是 | - | 平台类型 |
| is_text_chat | boolean | 否 | false | 是否为纯文字聊天（微信/QQ 文字模式） |

**platform 有效值**

| 值 | 含义 | 环境类型 |
|----|------|---------|
| `phone` | 手机电话 | phone_call |
| `wechat` | 微信 | voice_chat（默认） |
| `qq` | QQ | voice_chat（默认） |
| `video_call` | 视频通话 | video_call |
| `other` | 其他平台 | unknown |

**调用示例**

```
POST /api/call-records/123/environment?platform=wechat&is_text_chat=false
```

**响应示例（200）**

```json
{
  "code": 200,
  "message": "环境设置成功",
  "data": {
    "environment_type": "voice_chat",
    "description": "语音聊天",
    "weights": { "text": 0.72, "vision": 0.0, "audio": 0.28 },
    "active_modalities": ["text", "audio"]
  }
}
```

**Side Effect（副作用）**

调用成功后，后端会立即通过 WebSocket 推送一条 `environment_detected` 消息给当前用户（见"四、WebSocket 推送"）。前端应监听该消息，确认权重已切换。

---

## 四、WebSocket 推送

### 4.1 推送触发时机

| 触发来源 | 推送者 | 说明 |
|---------|--------|------|
| `POST /environment` | `call_records.py` | 前端主动上报后立即推送 |
| `detect_image_task`（OCR） | `detection_tasks.py` | OCR 识别出平台信息后自动推送 |
| `POST /call-records/start` | `call_records.py` | 通话开始时可能推送 |

### 4.2 推送消息结构

```json
{
  "type": "environment_detected",
  "data": {
    "call_id": 123,
    "platform": "wechat",
    "is_text_chat": false,
    "environment_type": "voice_chat",
    "description": "语音聊天",
    "active_modalities": ["text", "audio"],
    "weights": {
      "text": 0.72,
      "vision": 0.0,
      "audio": 0.28
    }
  }
}
```

**字段说明**

| 字段 | 类型 | 说明 |
|------|------|------|
| type | string | 固定值 `"environment_detected"` |
| data.call_id | integer | 关联的通话 ID |
| data.platform | string | 原始平台值 |
| data.is_text_chat | boolean | 是否纯文字聊天 |
| data.environment_type | string | 环境类型标识，见"环境类型对照表" |
| data.description | string | 中文描述 |
| data.active_modalities | string[] | 当前应启用的检测模态 |
| data.weights | object | 各模态在融合评分中的权重（0.0 ~ 1.0） |

---

## 五、环境类型对照表

### 5.1 平台 → 环境类型映射

| platform 参数值 | 环境类型 | 中文描述 |
|----------------|---------|---------|
| `phone` | phone_call | 电话通话 |
| `wechat` | voice_chat | 语音聊天（微信默认） |
| `qq` | voice_chat | 语音聊天（QQ 默认） |
| `video_call` | video_call | 视频通话 |
| `other` | unknown | 未知环境 |

> 如果 `is_text_chat=true`，无论 platform 为何值，环境类型均强制为 `text_chat`。

### 5.2 环境类型 → 融合权重

权重表示各模态在最终风险评分中的贡献比例。

| 环境类型 | description | text（文本） | vision（视频） | audio（音频） | 含义 |
|---------|-------------|-------------|--------------|-------------|------|
| `text_chat` | 文字聊天 | **1.00** | 0.00 | 0.00 | 纯文字聊天，仅文本检测 |
| `voice_chat` | 语音聊天 | **0.72** | 0.00 | **0.28** | 微信/QQ 语音，文本为主音频为辅 |
| `phone_call` | 电话通话 | **0.65** | 0.00 | **0.35** | 电话通话，文本音频均衡 |
| `video_call` | 视频通话 | **0.68** | **0.12** | **0.20** | 视频通话，文本主导、视频辅助 |
| `unknown` | 未知环境 | 0.70 | 0.10 | 0.20 | 默认权重（保守策略） |

### 5.3 环境类型 → 前端采集策略

| 环境类型 | 前端操作 |
|---------|---------|
| `text_chat` | 关闭麦克风采集，关闭摄像头采集，**仅发送文本** |
| `voice_chat` / `phone_call` | 开启麦克风采集，**关闭摄像头**，发送音频 + 文本 |
| `video_call` | 开启麦克风 + 摄像头，发送音频 + 视频帧 + 文本 |
| `unknown` | 使用默认策略（音视频均开启），等待 OCR 自动识别后更新 |

---

## 六、前端集成流程

### 6.1 推荐接入步骤

**Step 1：建立 WebSocket 连接**

在用户进入通话界面后，立即建立 WebSocket 连接：

```javascript
const ws = new WebSocket(
  `ws://localhost:8000/api/detection/ws/${userId}/${callId}?token=${token}`
);

ws.onopen = () => {
  console.log('WebSocket 连接已建立');
  // 连接建立后，立即上报环境
  setEnvironment(callId, platform, isTextChat);
};

ws.onmessage = (event) => {
  const msg = JSON.parse(event.data);
  if (msg.type === 'environment_detected') {
    handleEnvironmentDetected(msg.data);
  }
  // ... 其他 type 处理
};

ws.onerror = (err) => console.error('WebSocket 错误:', err);
ws.onclose = () => console.log('WebSocket 连接已关闭');
```

**Step 2：上报环境**

```javascript
async function setEnvironment(callId, platform, isTextChat) {
  const resp = await fetch(
    `http://localhost:8000/api/call-records/${callId}/environment?platform=${platform}&is_text_chat=${isTextChat}`,
    {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${token}` }
    }
  );
  const result = await resp.json();
  return result.data; // 立即可用的环境信息
}
```

**Step 3：处理 WebSocket 推送**

```javascript
function handleEnvironmentDetected(data) {
  const { environment_type, weights, active_modalities, description } = data;

  // 3.1 更新本地 UI 显示（平台标签）
  setPlatformLabel(description);

  // 3.2 切换音视频采集策略
  if (environment_type === 'text_chat') {
    stopAudioCapture();
    stopVideoCapture();
    console.log('切换为文字聊天模式');
  } else if (environment_type === 'voice_chat' || environment_type === 'phone_call') {
    startAudioCapture();   // 开启麦克风
    stopVideoCapture();     // 关闭摄像头
    console.log('切换为语音聊天模式');
  } else if (environment_type === 'video_call') {
    startAudioCapture();
    startVideoCapture();    // 开启摄像头
    console.log('切换为视频通话模式');
  } else {
    // unknown：使用默认策略
    startAudioCapture();
    startVideoCapture();
    console.log('未知环境，使用默认策略');
  }
}
```

**Step 4：显示平台检测结果**

```javascript
function setPlatformLabel(description) {
  // 无论检测到什么都显示结果；未检测到（unknown）显示"默认检测"
  const label = description === '未知环境' ? '默认检测' : description;
  document.getElementById('platform-label').textContent = `当前模式：${label}`;
}
```

### 6.2 完整状态流

```
[通话开始]
    │
    ▼
[建立 WebSocket 连接] ────► ws.onopen 回调
    │                              │
    │                              ▼
    │                     [POST /environment]
    │                              │
    │                              ▼
    │               ┌──────────────────────────┐
    │               │  后端更新融合引擎权重       │
    │               │  Redis 发布 fraud_alerts  │
    │               └──────────┬───────────────┘
    │                          │
    │                          ▼
    │               [redis_listener 接收消息]
    │                          │
    │                          ▼
    │               [WebSocket 推送 environment_detected]
    │                          │
    │                          ▼
    └───────────► [前端 ws.onmessage 接收]
                           │
                           ▼
                  [handleEnvironmentDetected]
                           │
              ┌────────────┼────────────┐
              ▼            ▼            ▼
         [更新 UI 标签] [切换采集策略] [更新权重配置]
```

---

## 七、错误处理

| 场景 | HTTP 状态码 | 返回内容 | 前端处理方式 |
|------|------------|---------|------------|
| 通话记录不存在 | 404 | `{"detail": "通话记录不存在"}` | 检查 call_id 是否正确 |
| 未认证 / Token 无效 | 401 | `{"detail": "无效的认证凭据"}` | 重新登录获取 Token |
| platform 参数无效 | 200（但无效） | 后端自动映射为 `unknown` | 前端收到 unknown 后按默认策略处理 |
| WebSocket 推送失败（用户不在线） | N/A | 消息丢弃，无返回 | 前端应监听 ws.onclose，断线后重新连接 |

---

## 八、注意事项

1. **先后顺序**：必须先建立 WebSocket 连接，再调用 `POST /environment`。否则后端推送时用户不在线，消息丢失。

2. **未检测到平台时**：后端默认返回 `unknown`，权重为 `{text: 0.70, vision: 0.10, audio: 0.20}`。前端应显示"默认检测"，并按默认策略开启音视频采集。

3. **同一通话多次上报**：`POST /environment` 可以多次调用，后端会以最后一次为准覆盖权重，不会报错。

4. **is_text_chat 优先于 platform**：当 `is_text_chat=true` 时，无论 platform 传什么值，环境类型都会被强制设为 `text_chat`。

5. **weights 中的 vision / audio**：字段名为 `vision`（视频）和 `audio`（音频），不是 `video` 和 `voice`，前端引用时注意区分。
