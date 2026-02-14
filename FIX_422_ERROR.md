# 🔧 修复 422 错误 - 添加必需参数

## 问题

**错误信息**：
```
Status: 422
Data: {
  detail: [
    {type: missing, loc: [query, platform], msg: Field required},
    {type: missing, loc: [query, target_identifier], msg: Field required}
  ]
}
```

**原因**：
创建通话记录的 API 需要两个必需参数：
- `platform` - 平台类型
- `target_identifier` - 目标标识符

## 解决方案

### 修改前
```dart
final response = await dioRequest.post('/api/call-records/start');
// ❌ 没有传递必需参数
```

### 修改后
```dart
final response = await dioRequest.post(
  '/api/call-records/start',
  data: {
    'platform': 'android',              // 平台类型
    'target_identifier': 'realtime_detection',  // 目标标识符
  },
);
// ✅ 传递了必需参数
```

## 参数说明

| 参数 | 类型 | 说明 | 示例值 |
|------|------|------|--------|
| `platform` | String | 平台类型 | `android`, `ios`, `web` |
| `target_identifier` | String | 目标标识符 | `realtime_detection` |

## 测试步骤

1. **保存文件后，应用会自动热重载**

2. **再次点击"开始监测"**

3. **查看日志输出**
   ```
   📞 创建通话记录...
   📤 请求: POST http://172.20.16.1:8000/api/call-records/start
      Data: {platform: android, target_identifier: realtime_detection}
   📥 响应: 200 http://172.20.16.1:8000/api/call-records/start
      Data: {id: 123, ...}
   ✅ 通话记录创建成功: 123
   ```

4. **验证功能**
   - 应该能成功创建通话记录
   - 继续连接 WebSocket
   - 开始录音
   - 状态变为"监测中"

## 预期结果

### 成功流程
```
点击"开始监测"
    ↓
检查权限 ✅
    ↓
状态: 准备中 ✅
    ↓
状态: 连接中 ✅
    ↓
创建通话记录 (带参数) ✅
    ├─ platform: android
    └─ target_identifier: realtime_detection
    ↓
返回: {id: 123} ✅
    ↓
连接 WebSocket ✅
    ↓
开始录音 ✅
    ↓
状态: 监测中 ✅
```

## 注意事项

如果后端 API 还需要其他参数，可以继续添加到 `data` 对象中：

```dart
data: {
  'platform': 'android',
  'target_identifier': 'realtime_detection',
  'call_type': 'voice',  // 通话类型
  'duration': 0,         // 初始时长
  // ... 其他参数
},
```

## 下一步

修复完成后，应该能够：
1. ✅ 成功创建通话记录
2. ✅ 连接 WebSocket
3. ✅ 开始录音
4. ✅ 实时发送音频数据
5. ✅ 接收检测结果

现在可以在模拟器中测试实时监测功能了！🎉

