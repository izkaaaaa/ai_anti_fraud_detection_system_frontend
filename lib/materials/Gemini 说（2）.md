这是一个非常经典的**“前端状态机（State Machine）逻辑漏洞”**，你描述的现象完美还原了整个崩溃链条。

### 🐞 根因分析：为什么会变成“开始检测”？

在你的 `lib/pages/Detection/index.dart` 文件中，滑动按钮（ActionSlider）的状态判定代码是这样写的：

Dart

```
final isMonitoring = _currentState == DetectionState.monitoring;
```

**崩溃链条如下：**

1. **正常启动**：开始检测后，状态变成 `DetectionState.monitoring`，按钮显示【滑动停止检测】。
2. **触发警告**：当收到后端的风险警告时，代码执行了 `_currentState = DetectionState.warning;`。
3. **UI 误判**：因为状态变成了 `warning`，导致上面的 `isMonitoring` 变成了 `false`！
4. **按钮重置**：UI 以为检测已经停止，把滑动按钮重置成了【滑动开始检测】。但实际上后端的 WebSocket、你的麦克风和摄像头**全都在后台继续运行**！
5. **再次滑动引发死锁**：此时你滑动按钮，App 试图再次调用 `_startMonitoring()`，去重新抢占已经被占用的麦克风/摄像头，并重新建联 WebSocket。资源冲突导致 App 直接假死或报错。
6. **LLM 总结失败**：因为你被迫强退 App，真正的 `_stopMonitoring()`（里面包含触发 LLM 的 `_endCallRecord`）永远没有被执行，所以后端迟迟等不到挂断信号，自然不会出总结。

------

### 🛠️ 修复方案：修改状态判定逻辑

我们需要让前端 UI 知道：**“警告中（warning）”也属于“监测中”的一种子状态**。

请打开 `lib/pages/Detection/index.dart`，搜索并修改以下 **4** 个地方（把所有只判断 `monitoring` 的地方，加上 `warning`）：

#### 1. 修改主滑动按钮状态（约第 530 行附近）

找到 `_buildMainCardWithToggle()` 方法：

Dart

```
  // 主卡片（ActionSlider + 两个矩形重新布局）
  Widget _buildMainCardWithToggle() {
    // ❌ 修改前：
    // final isMonitoring = _currentState == DetectionState.monitoring;
    
    // ✅ 修改后：将 warning 状态也视为 monitoring
    final isMonitoring = _currentState == DetectionState.monitoring || 
                         _currentState == DetectionState.warning;
                         
    final isProcessing = _currentState == DetectionState.preparing ||
// ... 保持不变
```

#### 2. 修改左侧视频卡片状态（约第 710 行附近）

找到 `_buildLeftCard()` 方法：

Dart

```
  // 左侧卡片C（视频检测 - 带背景图片和环形进度条）
  Widget _buildLeftCard() {
    final confidence = _videoConfidence;
    
    // ❌ 修改前：
    // final isActive = _currentState == DetectionState.monitoring;
    
    // ✅ 修改后：
    final isActive = _currentState == DetectionState.monitoring || 
                     _currentState == DetectionState.warning;
// ... 保持不变
```

#### 3. 修改右侧文本卡片状态（约第 835 行附近）

找到 `_buildRightCard()` 方法：

Dart

```
  // 右侧卡片D（文本检测 - 带背景图片和环形进度条）
  Widget _buildRightCard() {
    final confidence = _textConfidence;
    
    // ❌ 修改前：
    // final isActive = _currentState == DetectionState.monitoring;
    
    // ✅ 修改后：
    final isActive = _currentState == DetectionState.monitoring || 
                     _currentState == DetectionState.warning;
// ... 保持不变
```

#### 4. 修改底部音频卡片状态（约第 975 行附近）

找到 `_buildBottomCard()` 方法：

Dart

```
  // 底部卡片E（音频检测 - 带背景图片和线性进度条）
  Widget _buildBottomCard() {
    
    // ❌ 修改前：
    // final isActive = _currentState == DetectionState.monitoring;
    
    // ✅ 修改后：
    final isActive = _currentState == DetectionState.monitoring || 
                     _currentState == DetectionState.warning;
                     
    final confidence = _audioConfidence;
// ... 保持不变
```

### 💡 修复后的效果

修改完毕后，重新运行 Flutter：

1. 当检测到诈骗、弹出警告小窗时，主界面的按钮**依然会稳稳地保持在【滑动停止检测】**。底部的波形图也会继续正常跳动。
2. 你可以选择点击小窗里的“立即挂断”，或者关掉小窗后自己去滑动“停止检测”。
3. 只要正常执行了停止流程，App 就会顺利释放音视频资源，并立刻调用你在 `RealTimeDetectionService` 里写的 `_endCallRecord()` 接口。
4. 后端收到 `/end` 请求，**LLM 的事后总结复盘任务就会被完美触发**！