# 五子棋 ⚫

基于 Flutter + Flame 的 15 路五子棋，支持 Android、Windows 与 Web。规则简洁、界面克制，内置三档 AI、可选棋钟、棋谱复盘与三套棋盘皮肤。

## 功能

- 🎯 完整规则：横、竖、斜任意方向五连判胜，长连计胜，满盘判和
- ⚖️ 禁手规则：可选黑棋长连 / 四四 / 三三禁手，棋盘红圈标记禁手点，AI 与提示自动遵守
- 🤖 人机对战：入门 / 普通 / 高手三档（默认高手），本地棋型评估 + Alpha-Beta 搜索，可选执黑或执白
- 💡 走子提示：人机对战中一键请求推荐着法，棋盘高亮 6 秒
- 🧩 残局挑战：十道内置杀局，分入门 / 进阶 / 挑战三档，限手数通关并记录进度
- 📖 开局库：直指 / 斜指六条参考棋谱，棋形缩略图、开局讲解与一键练习
- 🀄 开局提示：人机执黑时 AI 走棋谱应手，提示优先给出开局着法，可在设置中关闭
- 👥 双人同屏对弈，适合面对面手谈
- ⏱️ 限时对局：可选 5 / 10 / 20 分钟棋钟，超时判负，AI 思考计入本方用时
- ↩️ 悔棋、重开、认输，人机对战悔棋同时撤回双方各一手
- 📜 坐标棋谱：A–O 列、1–15 行，实时记录并可随时查看
- ♻️ 复盘回放：终局后逐手回看，支持自动播放、滑杆跳转与点击棋谱定位
- 🗂️ 棋谱库：自动保留最近 20 局回放，支持文本导出与粘贴导入
- ✨ Flame 木纹棋盘、棋子落子动画、落点涟漪、最后一手圆点与胜利连线
- 🎨 三套棋盘皮肤：原木、青玉、墨韵，对局页、复盘页与首页缩略图同步
- 🔔 落子音效与震动反馈：运行时合成落子 / 威胁 / 胜利 / 失利音效，可分别关闭
- 🎵 背景音乐：运行时合成五声音阶循环，可独立关闭，应用进入后台自动暂停
- 📱 响应式布局：手机 / 折叠屏 / 平板 / Windows 窗口自适应，折叠屏展开时首页两列排布
- 🌓 深色模式、简体中文、Windows 优先使用 Microsoft YaHei UI、Web 使用 soup_fonts 思源黑体
- 🧾 日志按天写入用户目录，设置页可直接查看最近日志

## 下载

v0.3.0（最新发布）：[Gitea Release](http://192.168.31.120:3020/GTech/flutter-gomoku/releases/tag/v0.3.0)

| 平台 | 产物 |
| --- | --- |
| Android (arm64) | `flutter-gomoku-0.3.0-android-aarch64.apk` |
| Windows (x64, Win10+) | `flutter-gomoku-0.3.0-windows-x86_64.zip` |
| Web | `flutter-gomoku-0.3.0-web.zip`（解压后起静态服务器） |

| 版本 | 说明 |
| --- | --- |
| v0.3.0 | 新增禁手规则，黑棋长连 / 四四 / 三三禁手与棋盘标记，AI 同步遵守 |
| v0.2.1 | 重构提示、落子反馈与页面操作代码，修复缓存与音频重试问题 |
| v0.2.0 | 新增残局挑战、开局库与开局提示，补齐单人练习路径 |
| v0.1.1 | 重构存量代码，候选点生成约快 3.5 倍，修复 AI 兜底错过成五 |
| v0.1.0 | 首个可玩版本：完整规则、三档 AI、棋谱复盘与三端发布 |

## 开发

```bash
flutter pub get
flutter analyze
flutter test
```

构建产物由 CI 生成：在 GitHub Actions / Gitea Actions 里手动运行 `build` 工作流，选中 `v*` Tag 时按该 Tag 的版本构建 Android / Windows / Web 并发布 Release，运行 `main` 则产出预览产物。音频在运行时合成、Web 字体来自 soup_fonts，仓库不存放字体与音频文件。
本地无需安装 Android SDK 等大型工具链。

## 日志位置

- Windows：`文档/FlutterGomoku/logs/app_yyyyMMdd.log`
- Android：应用外部存储目录下的 `FlutterGomoku/logs/`
- Web：仅保留内存日志，可在设置页查看

导出的棋谱保存在 `<文档>/FlutterGomoku/records/`，导入时可粘贴棋谱文本，或在导入弹窗中直接选取该目录下已导出的文件（Web 端使用剪贴板复制与粘贴）。

## 目录结构

```
lib/
├── flame/          # Flame 棋盘渲染、落子动画与点击/悬停交互
├── game/
│   ├── engine/     # 棋型评估、Alpha-Beta 搜索、五连规则与禁手判定
│   ├── board_state.dart / game_controller.dart
│   ├── hint_session.dart      # 提示加载态与请求竞态
│   ├── match_clock.dart / replay_controller.dart / game_archive.dart
│   ├── opening_book.dart      # 六条开局棋谱与匹配
│   └── puzzle_controller.dart / puzzles.dart  # 残局数据与挑战流程
├── models/         # 对局、着法与棋谱存档模型
├── pages/          # 首页、对局、残局、开局库、设置、棋谱库与复盘
├── providers/      # 用户偏好
├── services/       # 日志、存储、音频、棋谱库、落子反馈与残局进度
├── theme/          # 主题、棋盘皮肤与棋子绘制
└── utils/          # 常量、格式化与平台工具
```
