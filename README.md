# 五子棋 (Gomoku)

跨 Android + Windows 双平台的五子棋游戏，支持双人本地对弈。

## 功能

- 🎮 双人本地对弈
- 🎨 Material 3 浅色/深色主题
- 📐 多种棋盘大小（9x9 / 13x13 / 15x15 / 19x19）
- ↩️ 悔棋功能
- 🖥️ Windows 窗口自适应
- 📱 Android 手机/折叠屏/平板自适应

## 下载

| 平台 | 下载 |
|------|------|
| Android | [v0.1.1 APK](https://github.com/g-ai-002/flutter-gomoku/releases/tag/v0.1.1) |
| Windows | [v0.1.1 ZIP](https://github.com/g-ai-002/flutter-gomoku/releases/tag/v0.1.1) |

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

## 版本历史

### v0.1.1 (2026-06-22)
- 修复 CI 测试失败和 lint 警告

### v0.1.0 (2026-06-21)
- 首个版本：双人本地对弈
- 支持 9x9 / 13x13 / 15x15 / 19x19 棋盘
- 悔棋、重新开始功能
- 浅色/深色主题
- Windows + Android 双平台
