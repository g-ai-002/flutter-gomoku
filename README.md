# 五子棋 (Gomoku)

跨 Android + Windows 双平台的五子棋游戏，支持双人本地对弈与人机对弈。

## 功能

- 🎮 双人本地对弈 / 人机对弈
- 🤖 AI 三级难度（简单 / 中等 / 困难）
- 🎨 Material 3 浅色/深色主题
- 📐 多种棋盘大小（9x9 / 13x13 / 15x15 / 19x19）
- ↩️ 悔棋功能
- 📋 对局记录与回放
- 🔊 落子/获胜音效
- ✨ 落子缩放动画
- 🖥️ Windows 窗口自适应
- 📱 Android 手机/折叠屏/平板自适应

## 下载

| 平台 | 下载 |
|------|------|
| Android | [v0.3.3 APK](https://github.com/g-ai-002/flutter-gomoku/releases/tag/v0.3.3) |
| Windows | [v0.3.3 ZIP](https://github.com/g-ai-002/flutter-gomoku/releases/tag/v0.3.3) |

## 开发

```bash
# 安装依赖
flutter pub get

# 运行测试
flutter test

# 运行应用
flutter run
```

## 技术栈

- Flutter 3.44.1
- Provider 状态管理
- Material 3 设计
- SharedPreferences 本地存储
- Minimax + Alpha-Beta 剪枝 AI
- 程序化音效生成（无需外部资源）

## 版本历史

### v0.3.3 (2026-06-22)
- 修复 CI 测试失败：`List.filled(size, null)` 类型推断为 `List<Null>` 导致编译错误

### v0.3.2 (2026-06-22)
- 修复 GameState.copyWith 中 winStart/winEnd 丢失旧值的 bug
- 消除 ReplayPage 与 BoardUtils 的五连检测代码重复
- 提取棋子颜色、棋盘参数等共享常量，消除魔法数字
- 统一服务层单例模式，添加测试重置方法
- 新增 BoardUtils 单元测试

### v0.3.1 (2026-06-22)
- 修复 CI 测试失败：SoundService 在测试环境 binding 未初始化导致 22 个测试失败

### v0.3.0 (2026-06-22)
- 新增对局记录：自动保存每局对局到本地 JSON 文件
- 新增对局列表页：查看历史对局，显示日期/模式/结果/步数
- 新增对局回放：逐步回放，支持前进/后退/自动播放
- 新增音效系统：程序化生成落子音效和获胜音效
- 新增落子动画：棋子缩放弹入效果

### v0.1.0 ~ v0.2.1 (2026-06-21 ~ 2026-06-22)
- 首个版本：双人本地对弈，支持 9x9/13x13/15x15/19x19 棋盘
- 人机对弈模式，支持简单/中等/困难三级 AI 难度
- AI 引擎：简单（随机）、中等（评分策略）、困难（Minimax + Alpha-Beta 剪枝）
- 悔棋、重新开始功能，浅色/深色主题
- Windows + Android 双平台
- 修复 CI 测试失败和 lint 警告
- 重构优化：简化服务层、提取设置面板、优化棋盘重绘
