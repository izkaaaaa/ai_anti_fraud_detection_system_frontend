### 第一部分：修改通话详情页（展示完整评价与防骗建议）

在上一轮中，我们在 `lib/pages/CallRecords/index.dart` 里的 `CallRecordDetailSheet` 预留了大模型评价的位置。现在后端已经能正式返回 `analysis`（分析）和 `advice`（建议）了，我们需要把这两个字段都渲染出来。

找到 `lib/pages/CallRecords/index.dart` 中大模型评价的那个 `Container`（大约在原代码的中间位置），将其**替换**为以下代码：

Dart

```
          // LLM 最终评价与防骗建议
          if (widget.record['analysis'] != null || widget.record['advice'] != null)
            Container(
              padding: EdgeInsets.all(16), // 使用你的 AppTheme.paddingMedium
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05), // 替换为你的 AppColors
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. 智能评价区块
                  if (widget.record['analysis'] != null && widget.record['analysis'].toString().isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.smart_toy, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('大模型智能评价', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.record['analysis'],
                      style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                    ),
                    SizedBox(height: 16),
                  ],

                  // 2. 防骗建议区块
                  if (widget.record['advice'] != null && widget.record['advice'].toString().isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.security, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text('专属防骗建议', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      widget.record['advice'],
                      style: TextStyle(fontSize: 14, color: Colors.black87, height: 1.5),
                    ),
                  ],
                ],
              ),
            ),
```

------

### 第二部分：家庭组成员列表与退出家庭组功能

你需要在家庭组页面（应该是 `lib/pages/Family/index.dart`）中增加两个核心的 API 调用逻辑，以及对应的 UI 渲染。

#### 1. 增加 API 请求方法

在你的家庭组页面的 `State` 类中，添加以下两个方法来调用后端的接口：

Dart

```
  List<dynamic> _familyMembers = [];
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    _fetchFamilyMembers(); // 页面加载时获取成员列表
  }

  // 接口 1：获取家庭组成员 (GET /api/family/members)
  Future<void> _fetchFamilyMembers() async {
    setState(() => _isLoadingMembers = true);
    try {
      // 假设 dioRequest 是你封装的网络请求工具
      final response = await dioRequest.get('/api/family/members');
      if (response != null && response['data'] != null) {
        setState(() {
          _familyMembers = response['data'];
          _isLoadingMembers = false;
        });
      }
    } catch (e) {
      setState(() => _isLoadingMembers = false);
      // 如果报错“您还未加入任何家庭组”，可以在这里捕获并显示空状态
      print('获取家庭组成员失败: $e');
    }
  }

  // 接口 2：退出家庭组 (POST /api/family/leave)
  Future<void> _leaveFamilyGroup() async {
    // 1. 弹出二次确认框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('退出家庭组'),
        content: Text('您确定要退出当前家庭组吗？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('取消')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text('确定退出', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // 2. 发起请求
    try {
      await dioRequest.post('/api/family/leave');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('已成功退出家庭组')));
      // 退出成功后，刷新页面数据，或者跳转回未加入家庭组的状态页
      setState(() {
        _familyMembers = [];
      });
      // Navigator.pop(context); // 或者返回上一页
    } catch (e) {
      // 如果是组长且组内还有人，后端会报错拦截，这里把后端的报错信息展示给用户
      String errorMsg = '退出失败，请稍后再试';
      if (e is DioError && e.response?.data != null) {
        errorMsg = e.response!.data['detail'] ?? errorMsg;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMsg), backgroundColor: Colors.red));
    }
  }
```

#### 2. 增加对应的 UI 渲染逻辑

在家庭组页面的 `build` 方法中，使用获取到的 `_familyMembers` 渲染列表，并在底部（或右上角）放置一个退出按钮。

Dart

```
// 在你的 build 方法中...

Expanded(
  child: _isLoadingMembers
      ? Center(child: CircularProgressIndicator())
      : _familyMembers.isEmpty
          ? Center(child: Text('暂无成员数据'))
          : ListView.builder(
              itemCount: _familyMembers.length,
              itemBuilder: (context, index) {
                final member = _familyMembers[index];
                final isMe = member['user_id'] == currentUserId; // 如果你有保存当前用户ID的话
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: member['is_admin'] ? Colors.orange : Colors.blue,
                    child: Icon(
                      member['is_admin'] ? Icons.admin_panel_settings : Icons.person, 
                      color: Colors.white
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(member['name'] ?? member['username']),
                      if (isMe) 
                        Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Text('(我)', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                    ],
                  ),
                  subtitle: Text('手机号: ${member['phone']} | 角色: ${member['role_type'] ?? "未知"}'),
                  trailing: member['is_admin'] 
                    ? Chip(label: Text('组长', style: TextStyle(fontSize: 10)), backgroundColor: Colors.orange[100])
                    : null,
                );
              },
            ),
),

// 在页面底部增加退出按钮
Padding(
  padding: const EdgeInsets.all(16.0),
  child: SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _leaveFamilyGroup,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.red[50],
        foregroundColor: Colors.red,
        elevation: 0,
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Text('退出当前家庭组'),
    ),
  ),
)
```