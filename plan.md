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
