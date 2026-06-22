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
| Android | [v0.3.0 APK](https://github.com/g-ai-002/flutter-gomoku/releases/tag/v0.3.0) |
| Windows | [v0.3.0 ZIP](https://github.com/g-ai-002/flutter-gomoku/releases/tag/v0.3.0) |

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

### v0.3.0 (2026-06-22)
- 新增对局记录：自动保存每局对局到本地 JSON 文件
- 新增对局列表页：查看历史对局，显示日期/模式/结果/步数
- 新增对局回放：逐步回放，支持前进/后退/自动播放
- 新增音效系统：程序化生成落子音效和获胜音效
- 新增落子动画：棋子缩放弹入效果

### v0.2.0 ~ v0.2.1 (2026-06-22)
- 人机对弈模式，支持简单/中等/困难三级 AI 难度
- AI 引擎：简单（随机）、中等（评分策略）、困难（Minimax + Alpha-Beta 剪枝）
- 重构优化：提取共享工具类、修复主题切换、优化性能

### v0.1.0 ~ v0.1.3 (2026-06-21 ~ 2026-06-22)
- 首个版本：双人本地对弈，支持 9x9/13x13/15x15/19x19 棋盘
- 悔棋、重新开始功能，浅色/深色主题
- Windows + Android 双平台
- 修复 CI 测试失败和 lint 警告
- 重构优化：简化服务层、提取设置面板、优化棋盘重绘
