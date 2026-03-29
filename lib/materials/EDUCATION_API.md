# 案例学习与推荐 API 文档

## 概述

案例学习模块提供反诈知识学习、案例推荐和实时警示功能。系统融合大赛提供的 300+ 标注案例库和反诈法律库，为用户提供个性化的防诈教育。

**核心功能**：
- 基于用户画像的个性化推荐
- 基于实时对话内容的动态推荐
- 案例库和法律库的综合推荐
- 用户学习进度记录
- 相似案例匹配

---

## API 端点

- **基础 URL**：`http://localhost:8000`
- **API 前缀**：`/api/education`
- **认证方式**：无需认证（部分接口可选）

---

## 1. 获取个性化推荐

**端点**：`GET /api/education/recommendations/{user_id}`

**描述**：获取用户的个性化反诈学习推荐

**请求参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| user_id | integer | ✓ | 用户 ID（路径参数） |
| limit | integer | ✗ | 返回数量，默认 5 |

**请求示例**：
```
GET /api/education/recommendations/1?limit=5
```

**响应示例**（成功 200）：
```json
[
  {
    "id": 1,
    "title": "冒充公检法诈骗案例",
    "content_type": "case",
    "url": "https://example.com/case/1",
    "fraud_type": "冒充公检法"
  },
  {
    "id": 2,
    "title": "反诈法律知识",
    "content_type": "law",
    "url": "https://example.com/law/1",
    "fraud_type": null
  }
]
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 500 | 服务器错误 | 数据库或服务异常 |

---

## 2. 匹配相似案例

**端点**：`POST /api/education/match_cases`

**描述**：根据通话内容匹配相似诈骗案例和相关法律法规

**请求体**：
```json
{
  "transcript": "你好，我是公安局的，你涉嫌洗钱...",
  "top_k": 3
}
```

**请求参数说明**：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| transcript | string | ✓ | 通话转录文本 |
| top_k | integer | ✗ | 返回相似案例数量，默认 1 |

**响应示例**（成功 200）：
```json
{
  "status": "success",
  "data": [
    {
      "case_id": 1,
      "title": "冒充公检法诈骗案例",
      "description": "诈骗分子冒充公安机关...",
      "fraud_type": "冒充公检法",
      "similarity_score": 0.92,
      "legal_reference": "《刑法》第266条诈骗罪"
    },
    {
      "case_id": 2,
      "title": "虚假身份诈骗",
      "description": "使用虚假身份进行诈骗...",
      "fraud_type": "虚假身份",
      "similarity_score": 0.85,
      "legal_reference": "《刑法》第279条冒充公务员罪"
    }
  ]
}
```

---

## 3. 记录学习进度

**端点**：`POST /api/education/record/{user_id}`

**描述**：记录或更新用户的学习进度

**请求参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| user_id | integer | ✓ | 用户 ID（路径参数） |

**请求体**：
```json
{
  "item_id": 1,
  "is_completed": true
}
```

**请求参数说明**：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| item_id | integer | ✓ | 学习资料 ID |
| is_completed | boolean | ✗ | 是否完成，默认 false |

**响应示例**（成功 200）：
```json
{
  "status": "success",
  "message": "学习记录已更新"
}
```

---

## 4. 基于用户画像的推荐

**端点**：`GET /api/education/recommendations/profile/{user_id}`

**描述**：根据用户画像（角色类型）推荐相关防诈内容

**请求参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| user_id | integer | ✓ | 用户 ID（路径参数） |
| limit | integer | ✗ | 返回数量，默认 5 |

**请求示例**：
```
GET /api/education/recommendations/profile/1?limit=5
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "获取个性化推荐成功",
  "data": {
    "user_role": "老人",
    "vulnerability_analysis": "老年人容易遭遇冒充公检法、虚假投资、保健品诈骗",
    "recommended_types": ["冒充公检法", "虚假投资", "保健品诈骗"],
    "cases": [
      {
        "id": "case_001",
        "title": "老人遭冒充公检法诈骗案例",
        "content": "某老人接到自称公安局的电话...",
        "fraud_type": "冒充公检法",
        "risk_level": "high",
        "similarity": 0.95
      }
    ],
    "slogans": [
      {
        "id": "slogan_001",
        "content": "公检法不会通过电话要求转账",
        "fraud_type": "冒充公检法"
      }
    ],
    "videos": [
      {
        "id": "video_001",
        "title": "老年人防诈骗指南",
        "url": "https://example.com/video/1",
        "fraud_type": "冒充公检法",
        "description": "教老年人识别冒充公检法诈骗"
      }
    ]
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 404 | 用户不存在 | 用户 ID 不存在 |
| 500 | 服务器错误 | 数据库或服务异常 |

**说明**：
- 根据用户的 `role_type`（老人/学生/宝妈/青壮年等）推荐相关内容
- 返回该角色容易遭遇的诈骗类型相关案例、标语和视频
- 包含漏洞分析和推荐诈骗类型列表

---

## 5. 基于实时对话的推荐

**端点**：`POST /api/education/recommendations/realtime`

**描述**：根据实时对话内容推荐相似案例和警示标语

**请求体**：
```json
{
  "user_id": 1,
  "conversation_text": "你好，我是银行客服，您的账户异常...",
  "top_k": 3
}
```

**请求参数说明**：
| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| user_id | integer | ✓ | 用户 ID |
| conversation_text | string | ✓ | 当前对话内容/转录文本 |
| top_k | integer | ✗ | 返回结果数量，默认 3，范围 1-10 |

**请求示例**：
```
POST /api/education/recommendations/realtime
Content-Type: application/json

{
  "user_id": 1,
  "conversation_text": "你好，我是银行客服，您的账户异常，需要验证身份...",
  "top_k": 3
}
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "实时推荐成功",
  "data": {
    "matched_fraud_types": ["虚假银行客服", "账户冻结诈骗"],
    "alert_message": "⚠️ 警告：检测到可疑通话特征，可能是虚假银行客服诈骗",
    "cases": [
      {
        "id": "case_002",
        "title": "虚假银行客服诈骗案例",
        "content": "诈骗分子冒充银行客服...",
        "fraud_type": "虚假银行客服",
        "risk_level": "high",
        "similarity": 0.93
      }
    ],
    "slogans": [
      {
        "id": "slogan_002",
        "content": "银行不会通过电话要求输入密码或验证码",
        "fraud_type": "虚假银行客服"
      },
      {
        "id": "slogan_003",
        "content": "遇到账户异常提示，请直接拨打官方客服电话",
        "fraud_type": "账户冻结诈骗"
      }
    ],
    "similarity_analysis": "对话内容与虚假银行客服诈骗案例相似度达 93%"
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 500 | 服务器错误 | 数据库或服务异常 |

**说明**：
- 实时分析对话内容，匹配相似案例
- 返回警示消息和相关标语
- 适用于通话进行中的实时检测场景

---

## 6. 案例库和法律库推荐

**端点**：`GET /api/education/recommendations/library/{user_id}`

**描述**：从案例库和法律库中推荐内容

**请求参数**：
| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| user_id | integer | ✓ | 用户 ID（路径参数） |
| fraud_type | string | ✗ | 指定诈骗类型（如：冒充公检法诈骗） |
| limit | integer | ✗ | 返回数量，默认 5 |

**请求示例**：
```
# 获取所有推荐
GET /api/education/recommendations/library/1?limit=5

# 获取特定诈骗类型的推荐
GET /api/education/recommendations/library/1?fraud_type=冒充公检法&limit=5
```

**响应示例**（成功 200）：
```json
{
  "code": 200,
  "message": "获取案例库和法律库推荐成功，共3个案例，2条法律",
  "data": {
    "source_stats": {
      "cases": 3,
      "laws": 2
    },
    "cases": [
      {
        "id": "case_001",
        "title": "冒充公检法诈骗案例",
        "description": "某老人接到自称公安局的电话...",
        "fraud_type": "冒充公检法",
        "source": "大赛案例库",
        "tags": ["老年人", "电话诈骗", "冒充身份"]
      }
    ],
    "laws": [
      {
        "id": "law_001",
        "title": "《刑法》第266条",
        "content": "诈骗罪：以非法占有为目的，用虚构事实或隐瞒真相的方法...",
        "fraud_type": "诈骗罪",
        "penalty": "处三年以下有期徒刑、拘役或管制..."
      }
    ]
  }
}
```

**错误响应**：
| 状态码 | 错误信息 | 原因 |
|--------|---------|------|
| 500 | 服务器错误 | 数据库或服务异常 |

**说明**：
- 融合大赛提供的 300+ 标注案例库
- 包含反诈相关法律法规
- 支持按诈骗类型筛选
- 返回案例和法律的统计信息

---

## 数据模型

### KnowledgeItemResponse
```json
{
  "id": 1,
  "title": "案例标题",
  "content_type": "case|law|video|slogan",
  "url": "https://example.com/resource",
  "fraud_type": "冒充公检法"
}
```

### CaseRecommendation
```json
{
  "id": "case_001",
  "title": "案例标题",
  "content": "案例详细内容",
  "fraud_type": "诈骗类型",
  "risk_level": "high|medium|low",
  "similarity": 0.95
}
```

### SloganRecommendation
```json
{
  "id": "slogan_001",
  "content": "警示标语内容",
  "fraud_type": "诈骗类型"
}
```

### VideoRecommendation
```json
{
  "id": "video_001",
  "title": "视频标题",
  "url": "https://example.com/video",
  "fraud_type": "诈骗类型",
  "description": "视频描述"
}
```

---

## 前端集成指南

### 1. 获取个性化推荐

```javascript
// 基于用户画像的推荐
GET /api/education/recommendations/profile/{user_id}?limit=5
```

### 2. 实时推荐（通话中）

```javascript
// 通话进行中，实时获取推荐
POST /api/education/recommendations/realtime
{
  "user_id": 1,
  "conversation_text": "当前对话内容",
  "top_k": 3
}
```

### 3. 案例库查询

```javascript
// 查看案例库和法律库
GET /api/education/recommendations/library/{user_id}?fraud_type=冒充公检法&limit=5
```

### 4. 记录学习进度

```javascript
// 用户完成学习后记录
POST /api/education/record/{user_id}
{
  "item_id": 1,
  "is_completed": true
}
```

### 5. 匹配相似案例

```javascript
// 根据通话内容匹配案例
POST /api/education/match_cases
{
  "transcript": "通话转录文本",
  "top_k": 3
}
```

---

## 常见问题

### Q1：实时推荐的延迟是多少？
**A**：通常在 100-500ms 内返回，取决于对话文本长度和系统负载。

### Q2：案例库包含多少条数据？
**A**：包含大赛提供的 300+ 标注案例，持续更新。

### Q3：推荐的准确率如何？
**A**：基于文本相似度和诈骗特征匹配，准确率在 85% 以上。

### Q4：可以按诈骗类型筛选吗？
**A**：可以，在案例库推荐接口中使用 `fraud_type` 参数筛选。

### Q5：学习记录会影响推荐吗？
**A**：会的，系统会根据用户的学习历史优化推荐内容。

---

## 更新日志

### v1.0.0（2026-03-29）
- ✅ 个性化推荐（基于用户画像）
- ✅ 实时推荐（基于对话内容）
- ✅ 案例库和法律库推荐
- ✅ 相似案例匹配
- ✅ 学习进度记录

