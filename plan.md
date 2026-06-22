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

### v0.3.1 (PATCH)
- **状态**: 已完成 ✅
- **目标**: 修复 CI 测试失败（SoundService 在测试环境 binding 未初始化）
- **任务**:
  - [x] 修复 SoundService：捕获 binding 未初始化异常，静默处理
  - [x] 更新版本号到 0.3.1
  - [x] 更新 README

### v0.3.0 (MINOR)
- **状态**: 已完成 ✅
- **目标**: 对局记录与回放、音效与动画
- **任务**:
  - [x] 对局记录：自动保存每局对局到本地 JSON 文件
  - [x] 对局列表页：查看历史对局，显示日期/模式/结果/步数
  - [x] 对局回放：逐步回放对局，支持前进/后退/自动播放
  - [x] 音效系统：落子音效、获胜音效（程序化生成，无需外部资源）
  - [x] 落子动画：棋子缩放弹入效果
  - [x] 获胜动画：五连棋子高亮闪烁
  - [x] 测试：对局记录/回放/音效单元测试
  - [x] 更新版本号到 0.3.0
  - [x] 更新 README

### v0.2.1 (PATCH)
- **状态**: 已完成 ✅
- **目标**: 重构优化存量代码，提升代码质量和可维护性
- **任务**:
  - [x] 提取共享五连检测逻辑到 utils/ 模块
  - [x] 将 GameMode 枚举移至 models/ 目录
  - [x] 修复主题切换不实时生效
  - [x] AI 引擎魔法数字常量化
  - [x] 提取 _BoardPainter 为独立文件
  - [x] 拆分 _buildStatusBar 为独立 Widget
  - [x] 优化 undo() 性能
  - [x] 日志轮转机制
  - [x] 更新版本号到 0.2.1
  - [x] 更新 README

### v0.2.0 (MINOR)
- **状态**: 已完成 ✅
- **目标**: 人机对弈，AI 难度分级
- **任务**:
  - [x] AI 引擎：简单（随机）、中等（评分策略）、困难（Minimax + Alpha-Beta）
  - [x] 游戏模式：双人对弈 / 人机对弈切换
  - [x] AI 难度选择：简单 / 中等 / 困难
  - [x] AI 自动落子（异步，不阻塞 UI）
  - [x] 设置面板增加模式与难度选项
  - [x] 持久化 AI 设置
  - [x] 测试：AI 引擎单元测试、GameProvider AI 模式测试
  - [x] 更新版本号到 0.2.0
  - [x] 更新 README

### v0.1.3 (PATCH)
- **状态**: 已完成 ✅
- **目标**: 修复 CI 流水线报错（lint 警告 + 测试失败）
- **任务**:
  - [x] 修复：GameState 缺少 isGameOver getter 导致测试编译失败
  - [x] 修复：game_page.dart prefer_const_constructors lint 警告
  - [x] 更新版本号到 0.1.3
  - [x] 更新 README

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
