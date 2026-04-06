# 实时监测 WebSocket 消息格式文档

## 一、连接方式

**WebSocket 地址**

```
ws://<host>/api/detection/ws/{user_id}/{call_id}?token=<JWT>
```

**鉴权方式**：在 Query 参数中传入 JWT Token。

**连接示例**

```
ws://localhost:8000/api/detection/ws/123/456?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

---

## 二、消息分类总览

后端通过 WebSocket 主动推送多种类型的消息，前端按 `type` 字段分发处理。

| type | 含义 | 来源时机 |
|------|------|---------|
| `ack` | 数据的 ACK 确认 | 前端发送 audio/video/text 后 |
| `heartbeat_ack` | 心跳响应 | 前端发送 heartbeat 后 |
| `error` | 错误响应 | 消息格式错误时 |
| `alert` | 诈骗风险预警 | 文本检测到异常时推送 |
| `info` | 无风险通知 | 文本检测通过时推送 |
| `detection_result` | 实时分数 | 音视频/文本实时分推送 |
| `control` | 系统控制指令 | 防御等级变更、TTS 播报、监护人干预等 |
| `level_sync` | 防御等级同步 | 等级变更时推送 |
| `environment_detected` | 环境识别结果 | 截图环境被识别后推送 |

---

## 三、后端 → 前端（后端主动推送）

### 3.1 ACK 确认

前端发送音频/视频/文本数据后，后端回复确认。

```json
{
  "type": "ack",
  "msg_type": "audio",
  "timestamp": "2026-04-05T10:00:00"
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| type | string | 固定为 `"ack"` |
| msg_type | string | 本次确认的数据类型：`audio` / `video` / `text` |
| status | string | video 类型特有：`buffering` / `ready` / `error` |
| timestamp | string | 服务器时间，ISO 格式 |

**video 类型的 ACK** 额外包含 `status` 字段：

```json
{
  "type": "ack",
  "msg_type": "video",
  "status": "ready",
  "timestamp": "2026-04-05T10:00:00"
}
```

---

### 3.2 心跳响应

```json
{
  "type": "heartbeat_ack",
  "timestamp": "2026-04-05T10:00:00"
}
```

---

### 3.3 错误响应

```json
{
  "type": "error",
  "message": "Invalid message format"
}
```

---

### 3.4 诈骗风险预警（alert）

**触发时机**：文本走完融合 + MDP 决策后，检测到风险时推送。

这是最核心的风险预警消息，需要前端认真展示。

```json
{
  "type": "alert",
  "data": {
    "title": "检测到文本异常风险",
    "message": "当前通话环境存在伪造风险，未通过文本安全检测。命中剧本: 冒充公检法 | 融合分: 85.2",
    "risk_level": "high",
    "confidence": 0.852,
    "call_id": 456,
    "timestamp": "2026-04-05T10:30:00",
    "display_mode": "popup"
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| type | string | 固定为 `"alert"` |
| title | string | 预警标题，如"检测到文本异常风险" |
| message | string | 预警详情，包含命中的剧本类型和融合分 |
| risk_level | string | 风险等级：`low` / `medium` / `high` / `critical` |
| confidence | float | 置信度，0-1 |
| call_id | int | 通话 ID |
| timestamp | string | 服务器时间，ISO 格式 |
| display_mode | string | 前端展示模式：`toast` / `popup` / `fullscreen` |

**display_mode 与 risk_level 的对应关系**：

| risk_level | display_mode | 含义 |
|------------|-------------|------|
| `low` | `toast` | 隐式监测，顶部小横幅 |
| `medium` | `popup` | 中度可疑，弹窗警告 |
| `high` | `popup` | 疑似诈骗，弹窗警告 |
| `critical` | `fullscreen` | 极度高危，全屏强制告警 |

---

### 3.5 无风险通知（info）

**触发时机**：文本检测通过，无异常时推送。

```json
{
  "type": "info",
  "data": {
    "title": "文本检测通过",
    "message": "当前通话环境安全，未检测到异常文本特征。",
    "risk_level": "low",
    "confidence": 0.12,
    "call_id": 456,
    "timestamp": "2026-04-05T10:25:00",
    "display_mode": "toast"
  }
}
```

字段结构与 `alert` 完全一致，`risk_level` 通常为 `low`。

---

### 3.6 实时分数（detection_result）

**触发时机**：音频、视频、文本各自检测后实时推送。

此消息用于**分数条展示**，不触发风险弹窗（`show_risk_popup` 通常为 `false`）。

```json
{
  "type": "detection_result",
  "data": {
    "overall_score": 35.6,
    "voice_confidence": 0.3561,
    "video_confidence": 0.0000,
    "text_confidence": 0.0000,
    "is_fraud": false,
    "advice": "",
    "keywords": [],
    "show_risk_popup": false
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| overall_score | float | 综合分数 0-100 |
| voice_confidence | float | 语音伪造置信度 0-1 |
| video_confidence | float | 视频伪造置信度 0-1 |
| text_confidence | float | 文本风险置信度 0-1 |
| is_fraud | bool | 是否判定为诈骗（弹窗以此为准） |
| advice | string | 风险建议文案（高分时才非空） |
| keywords | array | 命中的敏感关键词列表 |
| show_risk_popup | bool | 是否展示风险弹窗；**音视频路径固定为 false** |

> **重要**：音视频只推分数，弹窗仅以文本融合结果为准。当 `show_risk_popup: true` 且 `is_fraud: true` 时，前端应展示与 `alert` 同级的风险弹窗（由后端在同一次推送中通过 `alert`/`info` 消息独立下发）。

---

### 3.7 系统控制指令（control）

**触发时机**：防御等级变更、TTS 语音播报、监护人远程干预等。

```json
{
  "type": "control",
  "action": "upgrade_level",
  "target_level": 2,
  "config": {
    "video_fps": 10,
    "ui_message": "检测到可疑行为，已提升防御等级",
    "warning_mode": "popup",
    "block_call": false
  },
  "timestamp": "2026-04-05T10:30:00"
}
```

#### action 类型说明

| action | 说明 | 额外字段 |
|--------|------|---------|
| `upgrade_level` | 防御等级提升 | `target_level`, `config` |
| `tts_speak` | 语音播报（TTS） | `tts_priority`, `tts_text`, `target_level` |
| `block_call` | 监护人强制挂断 | `ui_message` |
| `warn` | 监护人发送警告 | `ui_message` |
| `check_status` | 监护人查询状态 | 无，需前端主动上报 |
| `set_config` | 前端主动设置配置（响应控制指令） | `fps` 等 |

#### upgrade_level 完整示例

```json
{
  "type": "control",
  "action": "upgrade_level",
  "target_level": 2,
  "config": {
    "video_fps": 10,
    "ui_message": "检测到可疑行为，已提升防御等级",
    "warning_mode": "popup",
    "block_call": false
  },
  "timestamp": "2026-04-05T10:30:00"
}
```

| 字段 | 说明 |
|------|------|
| target_level | 目标防御等级：1=隐式监测, 2=强力干预, 3=强制阻断 |
| config.video_fps | 建议的视频帧率 |
| config.ui_message | 给用户的提示文案 |
| config.warning_mode | 提示模式：`inline` / `popup` / `fullscreen` |
| config.block_call | 是否建议挂断 |

#### tts_speak 完整示例

```json
{
  "type": "control",
  "action": "tts_speak",
  "target_level": 2,
  "tts_priority": "high",
  "tts_text": "检测到疑似诈骗电话，请提高警惕"
}
```

| 字段 | 说明 |
|------|------|
| tts_text | 需要语音播报的文案 |
| tts_priority | 播报优先级：`high` / `normal` / `low` |
| target_level | 触发播报时的防御等级 |

---

### 3.8 防御等级同步（level_sync）

防御等级发生变更时推送（防御等级变更也会同时推送 `control` 指令，两者配合使用）。

```json
{
  "type": "level_sync",
  "level": 2,
  "config": {
    "video_fps": 10,
    "ui_message": "检测到可疑行为，已提升防御等级",
    "warning_mode": "popup",
    "block_call": false
  },
  "timestamp": "2026-04-05T10:30:00"
}
```

| 字段 | 说明 |
|------|------|
| level | 当前防御等级：1 / 2 / 3 |
| config | 同 `control.upgrade_level.config` |
| timestamp | 服务器时间 |

---

### 3.9 环境识别结果（environment_detected）

**触发时机**：前端上传截图后，OCR 环境识别完成时推送。

```json
{
  "type": "environment_detected",
  "data": {
    "call_id": 456,
    "platform": "wechat",
    "is_text_chat": false,
    "environment_type": "voice_chat",
    "description": "语音聊天",
    "active_modalities": ["text", "audio"],
    "weights": {
      "text": 0.3,
      "audio": 0.5,
      "video": 0.2
    }
  }
}
```

| 字段 | 类型 | 说明 |
|------|------|------|
| platform | string | 识别出的平台：`phone` / `wechat` / `qq` / `video_call` / `text_chat` |
| is_text_chat | bool | 是否为纯文字聊天场景 |
| environment_type | string | 环境类型描述 |
| description | string | 环境的中文描述 |
| active_modalities | array | 当前应该启用的检测模态（text/audio/video） |
| weights | object | 各模态的权重配置 |

**平台与建议模态对照**：

| platform | active_modalities | 说明 |
|----------|------------------|------|
| `phone` | `["audio", "text"]` | 电话，启用音频+文本 |
| `wechat` | `["audio", "text"]`（或 `["text"]`） | 微信语音或文字 |
| `qq` | `["audio", "text"]`（或 `["text"]`） | QQ 语音或文字 |
| `video_call` | `["text", "audio", "video"]` | 视频通话，三模态全开 |
| `text_chat` | `["text"]` | 纯文字聊天，专注文本 |

---

## 四、前端 → 后端（前端发送）

### 4.1 发送音频数据

```json
{
  "type": "audio",
  "data": "<base64 编码的音频数据>"
}
```

**后端响应**：ACK 确认。

---

### 4.2 发送视频帧数据

```json
{
  "type": "video",
  "data": "<base64 编码的图片数据>"
}
```

**后端响应**：ACK 确认，`status` 可能为 `buffering`（帧数不足）或 `ready`（已发送给 Celery 检测）。

---

### 4.3 发送文本内容

```json
{
  "type": "text",
  "data": "对方说的内容"
}
```

或（两种格式后端均兼容）：

```json
{
  "type": "text",
  "data": {
    "text": "对方说的内容"
  }
}
```

**后端响应**：ACK 确认。

---

### 4.4 心跳保活

```json
{
  "type": "heartbeat"
}
```

**后端响应**：heartbeat_ack。

> 建议前端每 30 秒发送一次心跳，防止连接断开。

---

### 4.5 控制指令

前端主动发送控制指令（如修改采集配置）：

```json
{
  "type": "control",
  "data": {
    "action": "set_config",
    "fps": 5
  }
}
```

**后端响应**：通过 `connection_manager.handle_command` 处理后返回 ACK。

---

## 五、监护人端特殊消息

监护人（家庭组管理员）收到的预警消息与普通用户不同，使用独立的 `type`。

### 5.1 家人安全预警（family_alert）

用户遭遇诈骗时，推送给所有家庭管理员。

```json
{
  "type": "family_alert",
  "data": {
    "title": "⚠️ 家人安全预警",
    "message": "您的家人【张三】疑似正在遭遇诈骗。当前通话环境存在伪造风险，未通过文本安全检测。命中剧本: 冒充公检法 | 融合分: 85.2",
    "risk_level": "high",
    "victim_id": 123,
    "victim_name": "张三",
    "victim_phone": "138****8888",
    "call_id": 456,
    "family_id": 789,
    "timestamp": "2026-04-05T10:30:00",
    "display_mode": "popup",
    "action": "vibrate"
  }
}
```

| 字段 | 说明 |
|------|------|
| victim_id | 受害者用户 ID |
| victim_name | 受害者姓名/昵称 |
| victim_phone | 受害者手机号（脱敏） |
| action | 前端应执行的动作：`none` / `vibrate` / `alarm` |

**action 与 risk_level 的对应**：

| risk_level | action | 说明 |
|------------|--------|------|
| `high` | `vibrate` | 震动提示 |
| `critical` | `alarm` | 响铃 + 震动 |

---

### 5.2 紧急报警（emergency_alert）

用户触发一键报警时，推送给所有家庭管理员。

```json
{
  "type": "emergency_alert",
  "data": {
    "title": "🚨 紧急报警",
    "message": "用户 张三 触发了一键报警，可能正在遭遇诈骗！",
    "victim_id": 123,
    "victim_name": "张三",
    "victim_phone": "138****8888",
    "call_id": 456,
    "family_id": 789,
    "timestamp": "2026-04-05T10:35:00",
    "display_mode": "fullscreen",
    "action": "alarm",
    "alert_type": "emergency"
  }
}
```

| 字段 | 说明 |
|------|------|
| alert_type | 报警类型：`emergency`（紧急报警）/ `suspicious`（可疑行为） |

---

## 六、前端处理流程建议

### 6.1 消息分发伪代码

```
收到 WebSocket 消息 msg:
  1. 解析 JSON

  2. 判断 msg.type:
     - "ack" / "heartbeat_ack" / "error"  → 无需 UI 操作，记录日志即可
     - "alert"           → 调用 showRiskAlert(msg.data)
     - "info"            → 调用 showInfoNotification(msg.data)
     - "detection_result" → 调用 updateScoreDisplay(msg.data)
     - "control"         → 调用 handleControlCommand(msg)
     - "level_sync"      → 调用 updateDefenseLevel(msg.level, msg.config)
     - "environment_detected" → 调用 applyEnvironmentConfig(msg.data)
     - "family_alert"    → 调用 showFamilyAlert(msg.data)
     - "emergency_alert" → 调用 showEmergencyAlert(msg.data)
```

### 6.2 风险预警展示规则

| display_mode | 展示方式 |
|-------------|---------|
| `toast` | 顶部小横幅，3-5 秒后自动消失 |
| `popup` | 居中弹窗，带操作按钮，用户可选择 |
| `fullscreen` | 全屏遮罩，强制展示，不可关闭，需用户主动操作 |

### 6.3 防御等级与 UI 状态对照

| level | label | warning_mode | 建议 UI |
|-------|-------|-------------|---------|
| 1 | 隐式监测 | `inline` | 分数条低亮，无弹窗 |
| 2 | 强力干预 | `popup` | 弹窗警告，可选操作 |
| 3 | 强制阻断 | `fullscreen` | 全屏告警，挂断按钮 |

---

## 七、完整消息示例汇总

### alert（高风险预警）

```json
{
  "type": "alert",
  "data": {
    "title": "疑似诈骗通话",
    "message": "当前通话疑似诈骗。命中剧本: 冒充公检法 | 融合分: 85.2",
    "risk_level": "high",
    "confidence": 0.852,
    "call_id": 456,
    "timestamp": "2026-04-05T10:30:00",
    "display_mode": "popup"
  }
}
```

### info（安全通知）

```json
{
  "type": "info",
  "data": {
    "title": "文本检测通过",
    "message": "当前通话环境安全，未检测到异常文本特征。",
    "risk_level": "low",
    "confidence": 0.12,
    "call_id": 456,
    "timestamp": "2026-04-05T10:25:00",
    "display_mode": "toast"
  }
}
```

### detection_result（实时分数）

```json
{
  "type": "detection_result",
  "data": {
    "overall_score": 35.6,
    "voice_confidence": 0.3561,
    "video_confidence": 0.0000,
    "text_confidence": 0.0000,
    "is_fraud": false,
    "advice": "",
    "keywords": [],
    "show_risk_popup": false
  }
}
```

### control（防御等级变更）

```json
{
  "type": "control",
  "action": "upgrade_level",
  "target_level": 2,
  "config": {
    "video_fps": 10,
    "ui_message": "检测到可疑行为，已提升防御等级",
    "warning_mode": "popup",
    "block_call": false
  },
  "timestamp": "2026-04-05T10:30:00"
}
```

### family_alert（监护人预警）

```json
{
  "type": "family_alert",
  "data": {
    "title": "⚠️ 家人安全预警",
    "message": "您的家人【张三】疑似正在遭遇诈骗。当前通话疑似诈骗。命中剧本: 冒充公检法 | 融合分: 85.2",
    "risk_level": "high",
    "victim_id": 123,
    "victim_name": "张三",
    "victim_phone": "138****8888",
    "call_id": 456,
    "family_id": 789,
    "timestamp": "2026-04-05T10:30:00",
    "display_mode": "popup",
    "action": "vibrate"
  }
}
```

### emergency_alert（紧急报警）

```json
{
  "type": "emergency_alert",
  "data": {
    "title": "🚨 紧急报警",
    "message": "用户 张三 触发了一键报警，可能正在遭遇诈骗！",
    "victim_id": 123,
    "victim_name": "张三",
    "victim_phone": "138****8888",
    "call_id": 456,
    "family_id": 789,
    "timestamp": "2026-04-05T10:35:00",
    "display_mode": "fullscreen",
    "action": "alarm",
    "alert_type": "emergency"
  }
}
```
