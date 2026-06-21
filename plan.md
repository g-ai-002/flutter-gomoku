# 五子棋 — 项目规划

## 长期目标
- 跨 Android + Windows 双平台的五子棋游戏
- 支持人机对弈、双人对弈
- 精美克制的界面，操作与主流棋类 App 一致
- 持续可演进：每个版本可独立交付，可观测、可回滚

## 中期目标
- [ ] 人机对弈（AI 难度分级）
- [ ] 双人本地对弈
- [ ] 悔棋 / 撤销
- [ ] 对局记录与回放
- [ ] 音效与动画
- [ ] 自适应布局（折叠屏/平板/桌面）

## 短期目标
- 持续按 prompt.md 的版本节奏：新功能 → patch 修复 → patch 重构

---

## 版本历史

### v0.1.2 (PATCH)
- **状态**: 已完成 ✅
- **目标**: 重构优化存量代码，提升代码质量和可维护性
- **任务**:
  - [x] 重构：简化服务层单例模式（StorageService, LogService, FileSystemService）
  - [x] 重构：提取设置面板为独立组件
  - [x] 重构：优化 BoardPainter shouldRepaint 性能
  - [x] 测试：补充边界用例测试
  - [x] 代码审查与清理
  - [x] 更新版本号到 0.1.2
  - [x] 更新 README

### v0.1.1 (PATCH)
- **状态**: 已完成 ✅
- **目标**: 修复 CI 测试失败和 lint 警告
- **任务**:
  - [x] 修复测试：无效棋盘大小不生效（StorageService 单例跨测试持久化）
  - [x] 修复测试：白棋获胜（测试逻辑错误，黑棋先连成五子）
  - [x] 修复 lint：game_page.dart 中 4 个 prefer_const_constructors
  - [x] 修复 Android 构建：添加缺失的启动图标资源
  - [x] 更新版本号到 0.1.1
  - [x] 更新 README

### v0.1.0 (MINOR)
- **状态**: 已完成 ✅
- **目标**: 首个版本：五子棋最小可用集
- **任务**:
  - [x] 项目脚手架（pubspec/analysis_options/.gitignore）
  - [x] Android 平台文件（manifest、build.gradle、签名、minSdk=34/targetSdk=36/compileSdk=36）
  - [x] 主题（Material 3 浅/深色、Windows YaHei UI、克制扁平风）
  - [x] 数据模型（StoneColor、GameState、Position、Move）
  - [x] 服务层：日志、文件系统、存储
  - [x] 状态层：GameProvider（落子、胜负判定、悔棋、重置）
  - [x] 界面：棋盘组件、游戏主页面、设置页面
  - [x] 双人本地对弈
  - [x] 单元测试：胜负判定、GameProvider 状态
  - [x] GitHub Actions：lint + 单测 + Android APK + Windows ZIP + tag 自动 release
  - [x] README/plan

---

## 设计原则
- **离线优先**：所有数据本地存储，不联网。
- **克制扁平**：Material 3 风格，灰底白卡，0.5px 细线条。
- **可观测**：所有操作写入日志文件，方便排障。
- **包体克制**：依赖均为成熟稳定的纯 Dart / Flutter 插件。

## 依赖与版本基线
- Flutter: 3.44.1
- provider: 6.1.5+1
- shared_preferences: 2.5.5
- path_provider: 2.1.5
- path: 1.9.1
- window_manager: 0.5.1
