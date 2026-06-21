# 五子棋 (Gomoku)

跨 Android + Windows 双平台的五子棋游戏，支持双人本地对弈与人机对弈。

## 功能

- 🎮 双人本地对弈 / 人机对弈
- 🤖 AI 三级难度（简单 / 中等 / 困难）
- 🎨 Material 3 浅色/深色主题
- 📐 多种棋盘大小（9x9 / 13x13 / 15x15 / 19x19）
- ↩️ 悔棋功能
- 🖥️ Windows 窗口自适应
- 📱 Android 手机/折叠屏/平板自适应

## 下载

| 平台 | 下载 |
|------|------|
| Android | [v0.2.0 APK](https://github.com/g-ai-002/flutter-gomoku/releases/tag/v0.2.0) |
| Windows | [v0.2.0 ZIP](https://github.com/g-ai-002/flutter-gomoku/releases/tag/v0.2.0) |

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

## 版本历史

### v0.2.0 (2026-06-22)
- 新增人机对弈模式，支持简单/中等/困难三级 AI 难度
- AI 引擎：简单（随机）、中等（评分策略）、困难（Minimax + Alpha-Beta 剪枝）
- 人机模式悔棋自动撤销两步
- 设置面板新增游戏模式和 AI 难度选择

### v0.1.0 ~ v0.1.3 (2026-06-21 ~ 2026-06-22)
- 首个版本：双人本地对弈，支持 9x9/13x13/15x15/19x19 棋盘
- 悔棋、重新开始功能，浅色/深色主题
- Windows + Android 双平台
- 修复 CI 测试失败和 lint 警告
- 重构优化：简化服务层、提取设置面板、优化棋盘重绘
