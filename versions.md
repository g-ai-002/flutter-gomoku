# 开源软件版本清单

> 本文件由脚本 `.build/query_all_versions.py` 自动生成，数据来源：Flutter 依赖为
> [pub.dev API](https://pub.dev/api/packages/)，Android 构建链为
> [Google Maven](https://dl.google.com/dl/android/maven2/) /
> [Maven Central](https://repo1.maven.org/maven2/) /
> [Gradle 版本服务](https://services.gradle.org/versions/all)。
>
> **列说明**：
> - **当前版本**：Flutter 依赖取自 `pubspec.yaml`；构建链取自 `android/` 下的
>   Gradle 配置
> - **MAJOR 最新版本**：最新大版本线的最新稳定版
>   （跨大版本升级，可能含破坏式变更）
> - **MINOR 最新版本**：当前大版本线内的最新稳定版（同大版本升级，通常向后兼容）
> - **PATCH 最新版本**：当前大版本.中版本线内的最新补丁版（仅 bug 修复）
>
> 标注 `(已是最新)` 表示当前版本已是该版本线最新。预发布版
> （alpha / beta / rc / dev / milestone）不计入最新版本。
>
> 刷新方式：运行 `python .build/query_all_versions.py` 重新生成

## 项目基础信息

| 项目                                      | 版本                               |
|-------------------------------------------|------------------------------------|
| 应用版本 (`pubspec.yaml`)                 | 0.5.0                              |
| 应用内版本号 (`lib/utils/constants.dart`) | 0.5.0                              |
| Flutter SDK（CI 固定版本）                | 3.47.7                             |
| Dart SDK 约束                             | >=3.13.5 <4.0.0                    |
| compileSdk / targetSdk                    | 37.2 / 37                          |
| minSdk                                    | 35                                 |
| NDK                                       | 30.0.16248370                      |
| Java (source/target)                      | 21                                 |
| 目标平台                                  | Android (arm64-v8a)、Windows (x64) |

发布产物：Android APK（`android-arm64`）、Windows ZIP（`windows-x86_64`）与 Web ZIP
（`web`），由 GitHub Actions 与 Gitea Actions 双流水线构建。

> Web 端自 2026-10-27 起纳入构建：GitHub 侧额外发布到 gh-pages 多版本站点
> <https://g-ai-002.github.io/flutter-gomoku/>，Gitea 侧只产出 `-web.zip` 并附到
> Release。

---

## 1. Flutter 运行时依赖

| 组件                                      | 当前版本  | MAJOR 最新版本       | MINOR 最新版本       | PATCH 最新版本       | 引用文件       | 说明                    | 类型         |
|-------------------------------------------|-----------|----------------------|----------------------|----------------------|----------------|-------------------------|--------------|
| Flame (`flame`)                           | `1.38.2`  | `1.38.2` (已是最新)  | `1.38.2` (已是最新)  | `1.38.2` (已是最新)  | `pubspec.yaml` | 游戏引擎                | dependencies |
| Provider (`provider`)                     | `6.1.5+1` | `6.1.5+1` (已是最新) | `6.1.5+1` (已是最新) | `6.1.5+1` (已是最新) | `pubspec.yaml` | 状态管理                | dependencies |
| Shared Preferences (`shared_preferences`) | `2.5.6`   | `2.5.6` (已是最新)   | `2.5.6` (已是最新)   | `2.5.6` (已是最新)   | `pubspec.yaml` | 键值本地存储            | dependencies |
| Path Provider (`path_provider`)           | `2.1.6`   | `2.1.6` (已是最新)   | `2.1.6` (已是最新)   | `2.1.6` (已是最新)   | `pubspec.yaml` | 平台目录定位            | dependencies |
| Path (`path`)                             | `1.9.1`   | `1.9.1` (已是最新)   | `1.9.1` (已是最新)   | `1.9.1` (已是最新)   | `pubspec.yaml` | 路径处理                | dependencies |
| Window Manager (`window_manager`)         | `0.5.2`   | `0.5.2` (已是最新)   | `0.5.2` (已是最新)   | `0.5.2` (已是最新)   | `pubspec.yaml` | 桌面窗口管理（Windows） | dependencies |

## 2. Flutter 开发依赖

| 组件                            | 当前版本 | MAJOR 最新版本     | MINOR 最新版本     | PATCH 最新版本     | 引用文件       | 说明             | 类型             |
|---------------------------------|----------|--------------------|--------------------|--------------------|----------------|------------------|------------------|
| Flutter Lints (`flutter_lints`) | `6.0.0`  | `6.0.0` (已是最新) | `6.0.0` (已是最新) | `6.0.0` (已是最新) | `pubspec.yaml` | 官方 lint 规则集 | dev_dependencies |

## 3. Android 构建链

| 组件                  | 当前版本 | MAJOR 最新版本      | MINOR 最新版本      | PATCH 最新版本      | 引用文件                                           | 说明                  |
|-----------------------|----------|---------------------|---------------------|---------------------|----------------------------------------------------|-----------------------|
| Gradle                | `9.8.2`  | `9.8.2` (已是最新)  | `9.8.2` (已是最新)  | `9.8.2` (已是最新)  | `android/gradle/wrapper/gradle-wrapper.properties` | Gradle Wrapper 分发包 |
| Android Gradle Plugin | `9.4.1`  | `9.4.1` (已是最新)  | `9.4.1` (已是最新)  | `9.4.1` (已是最新)  | `android/settings.gradle`                          | Android 构建插件      |
| Kotlin Gradle Plugin  | `2.4.21` | `2.4.21` (已是最新) | `2.4.21` (已是最新) | `2.4.21` (已是最新) | `android/settings.gradle`                          | Kotlin 编译插件       |
| Kotlin Stdlib         | `2.4.21` | `2.4.21` (已是最新) | `2.4.21` (已是最新) | `2.4.21` (已是最新) | `android/app/build.gradle`                         | Kotlin 标准库         |
| Desugar JDK Libs      | `2.1.5`  | `2.1.5` (已是最新)  | `2.1.5` (已是最新)  | `2.1.5` (已是最新)  | `android/app/build.gradle`                         | Java 8+ API 脱糖支持  |

## 4. CI 与外部工具

| 组件                            | 当前版本 | 引用文件                                                     | 说明                     |
|---------------------------------|----------|--------------------------------------------------------------|--------------------------|
| actions/checkout                | `v6`     | `.github/workflows/build.yml` / `.gitea/workflows/build.yml` | 检出仓库代码             |
| subosito/flutter-action         | `v2`     | `.github/workflows/build.yml`                                | 安装指定版本 Flutter SDK |
| actions/setup-java              | `v5`     | `.github/workflows/build.yml`                                | 安装 JDK（Temurin）      |
| actions/upload-artifact         | `v7`     | `.github/workflows/build.yml`                                | 上传构建产物（GitHub）   |
| actions/download-artifact       | `v8`     | `.github/workflows/build.yml`                                | 下载构建产物（GitHub）   |
| softprops/action-gh-release     | `v3`     | `.github/workflows/build.yml`                                | 创建 GitHub Release      |
| actions/gitea-upload-artifact   | `v4`     | `.gitea/workflows/build.yml`                                 | 上传构建产物（Gitea）    |
| actions/gitea-download-artifact | `v8`     | `.gitea/workflows/build.yml`                                 | 下载构建产物（Gitea）    |

---

## 如何刷新本文档

运行脚本重新查询 pub.dev / Google Maven / Maven Central / Gradle 版本服务并生成：

```bash
python .build/query_all_versions.py
```

也可以直接访问对应元数据：

- Flutter 依赖：`https://pub.dev/api/packages/<package>`
- Android Gradle Plugin / desugar_jdk_libs：[Google Maven](https://dl.google.com/dl/android/maven2/) 的 `maven-metadata.xml`
- Kotlin：[Maven Central](https://repo1.maven.org/maven2/) 的 `maven-metadata.xml`
- Gradle：`https://services.gradle.org/versions/all`

---

## 本轮任务记录（2026-10-27）

- 平台：目标平台新增 Web（浏览器），发布产物新增 `-web.zip`；本轮不涉及 Flutter
  依赖版本变化，`pubspec.yaml` 与 `lib/utils/constants.dart` 的版本号保持 `0.4.1`
- 平台适配：`log_service`、`file_system_service`、`game_record_service`、
  `logging_init`、`window_setup` 改为条件导入（`*_io.dart` / `*_web.dart`），
  `lib/` 下除 `*_io.dart` 外不再直接 `import 'dart:io'`
- 站点：GitHub Actions 新增 build-web，tag 发布到 `v<version>/`、其余发布到
  `debug/`，并生成版本索引页与 `versions.json`；Gitea Actions 只产出 `-web.zip`
- 渲染：棋盘静态层（棋盘底、网格线、星位、外边框）烘焙为 `ui.Picture` 缓存
- 主循环：对局结束遮罩出现后暂停，重开 / 悔棋 / 回放时恢复
