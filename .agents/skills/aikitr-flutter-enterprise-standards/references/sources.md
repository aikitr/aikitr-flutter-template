# 官方依据与版本核验

本规范于 **2026-10-04** 核对以下官方文档/包作者文档。只引用支持对应原则或 API 的资料；Feature-first 树、边界矩阵、默认依赖组合、命名后缀和 CI 组织方式是本技能的团队建议，不代表所有企业或 Flutter 官方的唯一标准。

## 架构与 Dart

| 来源 | 采用的依据 |
| --- | --- |
| [Flutter architecture recommendations](https://docs.flutter.dev/app-architecture/recommendations) | UI/数据解耦、MVVM、Repository、DI、不可变模型；domain/UseCase 根据复杂度采用 |
| [Flutter app architecture guide](https://docs.flutter.dev/app-architecture/guide) | View、ViewModel、Repository、service 的职责及依赖 |
| [Effective Dart: Style](https://dart.dev/effective-dart/style) | 文件/类型/成员/常量命名、缩写、导入顺序、formatter |
| [Effective Dart: Design](https://dart.dev/effective-dart/design) | API、类型、可变性及可理解的公共契约 |
| [Dart libraries & imports](https://dart.dev/language/libraries) | library 私有性；目录不是语言访问控制 |
| [implementation_imports lint](https://dart.dev/tools/linter-rules/implementation_imports) | 跨包 src 导入约束，不替代 feature 内部边界校验 |
| [Pub workspaces](https://dart.dev/tools/pub/workspaces) | 多包共享解析、根锁文件与工作区依赖 |

## 界面与平台

| 来源 | 采用的依据 |
| --- | --- |
| [Flutter adaptive design](https://docs.flutter.dev/ui/adaptive-responsive/best-practices) | 按约束与可用空间适配布局 |
| [Flutter accessibility](https://docs.flutter.dev/ui/accessibility) | 语义、屏幕阅读器、对比、点击区域和大字号验证 |
| [Flutter internationalization](https://docs.flutter.dev/ui/internationalization) | ARB、gen-l10n、locale、复数和格式化 |
| [Flutter iOS flavors](https://docs.flutter.dev/deployment/flavors-ios) | Scheme 与构建配置、原生环境身份 |
| [Flutter testing](https://docs.flutter.dev/testing/overview) | unit/widget/integration 分工及原生交互限制 |
| [Flutter obfuscation](https://docs.flutter.dev/deployment/obfuscate) | 混淆无法保护客户端秘密；保留符号以解析堆栈 |

## 组件作者文档

| 来源 | 采用的依据 |
| --- | --- |
| [Riverpod DO/DON'T](https://riverpod.dev/docs/root/do_dont) | 初始化、局部短暂状态和写操作边界 |
| [Riverpod retry](https://riverpod.dev/docs/concepts2/retry) | provider 计算重试的默认行为与配置 |
| [Riverpod cancellation](https://riverpod.dev/docs/how_to/cancel) | 生命周期与请求取消/防抖 |
| [go_router](https://pub.dev/packages/go_router) | 声明路由、重定向、嵌套导航能力 |
| [Dio](https://pub.dev/packages/dio) | 传输、超时、拦截器、取消与适配 |
| [Freezed](https://pub.dev/packages/freezed) | 不可变值模型与代码生成 |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | 现代 async/cache API 及关键数据持久化限制 |
| [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) | 平台安全存储和配置边界 |

## 实施时重新核验

不在通用技能里固定一组很快过期的依赖版本。每个项目固定并验证自身组合；涉及下列变化时检查已安装版本与官方 changelog/文档：

- Flutter/Dart 语言和分析器能力，原生平台最低版本。
- Riverpod 生命周期、自动重试、observer、生成语法；实验功能不能默认为生产承诺。
- Freezed/json_serializable/build_runner/analyzer 的兼容约束。
- gen-l10n 输出路径、导入方式和参数，避免复用旧 synthetic package 示例。
- go_router redirect 与嵌套 Navigator 生命周期；原生路由恢复行为。
- 安全存储访问策略、备份/重装行为、平台迁移；偏好存储的持久化语义。
- Pub workspace 的基础能力、glob/嵌套配置等受 SDK 版本影响的语法。
- Xcode、签名、entitlement、权限、商店隐私要求与 CI runner 可用性。

资料更新可能改变 API，但不能仅因文档示例不同而未经验证删除已有兼容补丁。报告实际版本、验证结果和未确认项；不把“文档已核对”表述成“项目已通过构建”。

## 2026-10-05 扩充依据

以下是本次补充时核验的官方与作者资料。生命周期顺序、缓存预算、事件登记、开关治理、例外截止语义等是本技能的工程约定；平台行为依据下列资料，实施时重新核验版本敏感配置。

| 来源 | 采用的依据 |
| --- | --- |
| [Flutter AppLifecycleState](https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html) | 生命周期通知可能被跳过，突然终止不保证通知 |
| [Android 状态恢复](https://docs.flutter.dev/platform-integration/android/restore-state-android)、[iOS 状态恢复](https://docs.flutter.dev/platform-integration/ios/restore-state-ios) | 系统进程恢复与 Flutter 状态恢复能力，需独立验证 |
| [Apple BackgroundTasks](https://developer.apple.com/documentation/backgroundtasks) | 系统调度的原生后台工作能力与生命周期约束 |
| [SQLite transactions](https://www.sqlite.org/lang_transaction.html) | 数据事务和中断边界；业务兼容协议仍须项目定义 |
| [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices) | build、layout、paint 等性能定位，测量后优化 |
| [Flutter 错误处理](https://docs.flutter.dev/testing/errors)、[PlatformDispatcher.onError](https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/onError.html) | 框架与 root isolate 错误钩子的覆盖范围 |
| [Isolate.addErrorListener](https://api.dart.dev/dart-isolate/Isolate/addErrorListener.html)、[binding zone 检查](https://api.flutter.dev/flutter/foundation/BindingBase/debugZoneErrorsAreFatal.html) | worker isolate 错误监听与 binding/runApp zone 一致性 |
| [Apple 隐私清单](https://developer.apple.com/documentation/bundleresources/describing-data-use-in-privacy-manifests)、[第三方 SDK 要求](https://developer.apple.com/support/third-party-SDK-requirements/) | 对实际归档产物与适用 SDK 核验隐私声明、签名和 required-reason APIs |
| [GitHub 依赖图](https://docs.github.com/en/code-security/how-tos/secure-your-supply-chain/secure-your-dependencies/explore-dependencies)、[Dependency submission](https://docs.github.com/en/rest/dependency-graph/dependency-submission) | 扫描/依赖图存在生态与输入覆盖条件，不能默认 Dart 全覆盖 |
| [analyzer parseString](https://pub.dev/documentation/analyzer/latest/dart_analysis_utilities/parseString.html)、[UriBasedDirective](https://pub.dev/documentation/analyzer/latest/dart_ast_ast/UriBasedDirective-class.html) | Dart AST 指令解析，配合静态分析使用 |
| [checkout v6.0.2](https://github.com/actions/checkout/releases/tag/v6.0.2)、[固定提交](https://github.com/actions/checkout/commit/de0fac2e4500dabe0009e67214ff5f5447ce83dd)、[GitHub runners](https://docs.github.com/en/actions/reference/runners/github-hosted-runners) | CI 样例 action SHA 与 runner 标签依据；标签不锁定整套镜像 |

本次可执行检查资源在 **Flutter 3.47.6 / Dart 3.13.5** 上解析依赖并运行；analyzer 14.4.0 及其他实际解析版本固定在工具 `pubspec.lock`。CI 中的 Flutter revision 是该验证环境的快照，不是永久推荐最新版。采用方应与自己的版本文件对齐。工具本地测试、CI YAML 结构检查不构成 GitHub 执行或 iOS 真机/签名验收。
