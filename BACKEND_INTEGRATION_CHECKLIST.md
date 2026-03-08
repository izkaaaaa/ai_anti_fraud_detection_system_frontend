# 后端接口对接 - 功能验证清单

## ✅ 已完成的功能

### 1. 通话记录详情页 - LLM 智能评价

**文件**: `lib/pages/CallRecords/index.dart`

**修改内容**:
- ✅ 同时显示 `analysis` (智能评价) 和 `advice` (防骗建议)
- ✅ 两个区块分开展示，样式清晰
- ✅ 使用不同图标区分（智能机器人 vs 安全盾牌）
- ✅ 使用不同颜色（蓝色 vs 绿色）

**测试步骤**:
1. 打开通话记录页面
2. 点击任意一条记录查看详情
3. 检查是否显示"大模型智能评价"区块（如果有 `analysis` 字段）
4. 检查是否显示"专属防骗建议"区块（如果有 `advice` 字段）

**预期结果**:
```
┌─────────────────────────────────┐
│ 🤖 大模型智能评价                │
│ 这是一个典型的诈骗电话...        │
├─────────────────────────────────┤
│ 🛡️ 专属防骗建议                 │
│ 建议立即挂断，不要透露...        │
└─────────────────────────────────┘
```

---

### 2. 家庭组成员列表

**文件**: `lib/pages/Family/index.dart`

**接口**: `GET /api/family/members`

**实现位置**: `MembersTab._loadMembers()`

**功能**:
- ✅ 获取家庭组所有成员
- ✅ 显示成员姓名、手机号
- ✅ 标识管理员（绿色边框 + 管理员徽章）
- ✅ 支持下拉刷新
- ✅ 点击成员查看其通话记录

**测试步骤**:
1. 登录管理员账号
2. 进入家庭组页面
3. 切换到"成员管理"标签
4. 查看成员列表

**预期结果**:
```
┌─────────────────────────────────┐
│ 👤 张三 [管理员]                 │
│    13800138000                   │
├─────────────────────────────────┤
│ 👤 李四                          │
│    13900139000                   │
└─────────────────────────────────┘
```

---

### 3. 退出家庭组

**文件**: `lib/pages/Family/index.dart`

**接口**: `POST /api/family/leave`

**实现位置**: `_FamilyPageState._leaveFamily()`

**功能**:
- ✅ 显示退出按钮（红色警告样式）
- ✅ 二次确认对话框
- ✅ 调用退出接口
- ✅ 退出成功后刷新页面
- ✅ 错误处理（如组长且组内还有人）

**测试步骤**:
1. 进入家庭组页面
2. 点击"退出家庭组"按钮
3. 确认退出
4. 检查是否成功退出

**预期结果**:
- 显示确认对话框："确定要退出当前家庭组吗？"
- 退出成功：显示"已退出家庭组"，页面切换到未加入状态
- 退出失败（组长）：显示错误信息"您是组长，请先转让组长权限"

---

### 4. 查看成员通话记录

**文件**: `lib/pages/Family/index.dart`

**接口**: `GET /api/call-records/member/{user_id}/records`

**实现位置**: `MemberRecordsPage._loadRecords()`

**功能**:
- ✅ 点击成员卡片跳转到记录页面
- ✅ 显示该成员的所有通话记录
- ✅ 支持下拉刷新
- ✅ 点击记录查看详情
- ✅ 详情页显示"提交审查"按钮

**测试步骤**:
1. 在成员列表中点击任意成员
2. 查看该成员的通话记录
3. 点击任意记录查看详情
4. 检查是否有"提交审查"按钮

**预期结果**:
- 显示成员姓名作为标题
- 列表显示该成员的所有通话记录
- 详情页右上角有"提交审查"按钮

---

### 5. 提交审查（新型诈骗案例）

**文件**: `lib/pages/CallRecords/index.dart`

**接口**: `POST /api/call-records/{call_id}/report-to-admin`

**实现位置**: `_CallRecordDetailSheetState._reportToAdmin()`

**功能**:
- ✅ 仅在家庭记录详情页显示
- ✅ 二次确认对话框
- ✅ 提交到系统防诈中心
- ✅ 成功提示

**测试步骤**:
1. 查看家庭成员的通话记录详情
2. 点击"提交审查"按钮
3. 确认提交
4. 检查提示信息

**预期结果**:
- 显示确认对话框："确定将该通话作为新型诈骗案例提交..."
- 提交成功：显示"已成功提交至系统防诈中心待审核队列"

---

## 🔧 技术实现细节

### 1. FamilyService 新增方法

```dart
// lib/services/family_service.dart

/// 获取家庭组成员列表
Future<List<Map<String, dynamic>>> getMembers() async {
  final response = await dioRequest.get('/api/family/members');
  if (response != null && response['code'] == 200) {
    return (response['data'] as List).cast<Map<String, dynamic>>();
  }
  return [];
}

/// 退出家庭组
Future<bool> leaveFamily() async {
  final response = await dioRequest.post('/api/family/leave');
  return response != null && response['code'] == 200;
}
```

### 2. 通话记录详情页修改

```dart
// lib/pages/CallRecords/index.dart

// LLM 最终评价与防骗建议
if (widget.record['analysis'] != null || widget.record['advice'] != null)
  Container(
    child: Column(
      children: [
        // 1. 智能评价区块
        if (widget.record['analysis'] != null) ...[
          Row(children: [
            Icon(Icons.smart_toy, color: AppColors.primary),
            Text('大模型智能评价'),
          ]),
          Text(widget.record['analysis']),
        ],
        
        // 2. 防骗建议区块
        if (widget.record['advice'] != null) ...[
          Row(children: [
            Icon(Icons.security, color: AppColors.success),
            Text('专属防骗建议'),
          ]),
          Text(widget.record['advice']),
        ],
      ],
    ),
  ),
```

---

## 📊 后端接口要求

### 1. GET /api/family/members

**响应格式**:
```json
{
  "code": 200,
  "data": [
    {
      "user_id": 1,
      "name": "张三",
      "phone": "13800138000",
      "is_admin": true,
      "role_type": "admin"
    },
    {
      "user_id": 2,
      "name": "李四",
      "phone": "13900139000",
      "is_admin": false,
      "role_type": "member"
    }
  ]
}
```

### 2. POST /api/family/leave

**响应格式**:
```json
{
  "code": 200,
  "message": "已成功退出家庭组"
}
```

**错误响应**（组长且组内还有人）:
```json
{
  "code": 400,
  "detail": "您是组长，请先转让组长权限或等待所有成员退出"
}
```

### 3. GET /api/call-records/member/{user_id}/records

**响应格式**:
```json
{
  "code": 200,
  "data": [
    {
      "call_id": 1,
      "caller_number": "13800138000",
      "start_time": "2026-03-08 10:30:00",
      "duration": 120,
      "detected_result": "safe",
      "analysis": "这是一个正常的通话...",
      "advice": "无需担心，继续保持警惕即可"
    }
  ]
}
```

### 4. POST /api/call-records/{call_id}/report-to-admin

**响应格式**:
```json
{
  "code": 200,
  "message": "已成功提交至系统防诈中心待审核队列"
}
```

---

## ✅ 验证清单

- [ ] 通话记录详情显示 LLM 智能评价
- [ ] 通话记录详情显示防骗建议
- [ ] 家庭组成员列表正常显示
- [ ] 管理员标识正确显示
- [ ] 退出家庭组功能正常
- [ ] 组长退出时显示错误提示
- [ ] 点击成员可查看其通话记录
- [ ] 家庭记录详情显示"提交审查"按钮
- [ ] 提交审查功能正常工作
- [ ] 下拉刷新功能正常

---

## 🐛 可能的问题

1. **成员列表为空**
   - 检查后端是否返回了正确的数据格式
   - 检查 `is_admin` 字段是否存在

2. **退出失败**
   - 检查是否是组长且组内还有其他成员
   - 检查后端错误信息是否正确返回

3. **LLM 评价不显示**
   - 检查后端是否返回了 `analysis` 和 `advice` 字段
   - 检查字段是否为空字符串

4. **提交审查按钮不显示**
   - 检查 `isFamily` 参数是否正确传递
   - 检查是否在家庭记录详情页

---

## 📝 总结

所有功能已按照文档要求完成实现：

1. ✅ 通话记录详情页同时显示智能评价和防骗建议
2. ✅ 家庭组成员列表展示
3. ✅ 退出家庭组功能
4. ✅ 查看成员通话记录
5. ✅ 提交审查功能

代码已通过静态分析，可以直接运行测试！

