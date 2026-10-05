# 技术选型、测试与工程交付

## 1. 默认技术组合

这是绿地项目的建议组合，不是“企业级必须使用”的第三方清单。已有兼容且可维护的实现保留。引入依赖评估维护活跃度、许可证、平台支持、原生最低版本、体积、数据处理与升级成本；通过解析和平台构建后固定版本，不以“最新”代替验证。

| 能力 | 默认 | 取舍 |
| --- | --- | --- |
| 状态与 DI | Riverpod，手写 Provider/Notifier/AsyncNotifier | 已有 Bloc 沿用；生成 provider 按团队需要，不重复 DI |
| 路由 | go_router | 特殊栈使用 Navigator；集中约定嵌套路由/恢复/深链 |
| HTTP | Dio | 简单业务也可用官方 http；页面不依赖客户端 |
| 不可变模型 | Dart 不可变类型；复杂值类可用 Freezed | 不为两个字段必加生成链；传输序列化单独管理 |
| JSON | json_serializable | 结合显式 mapper/校验；API 生成按实际协议选用 |
| UI | 平台和产品匹配的 Material/Cupertino | 统一语义 token；不是全项目屏幕缩放 |
| 国际化 | flutter_localizations、ARB、gen-l10n、intl | 工具参数与导入以固定 SDK 为准 |
| 偏好 | shared_preferences 的现代 API | 非敏感设置；不承载关键数据 |
| 凭据 | flutter_secure_storage 等经平台验收的适配 | 配置访问策略、迁移和多环境隔离 |
| 日志 | logging + 脱敏 sink/观测 adapter | 不默认接入任意外部平台 |
| 质量 | flutter_lints、官方测试工具、边界检查 | 严格程度与兼容版本确认后统一 |

数据库、推送、崩溃平台、内购、Apple 登录、依赖注入生成、Melos 等按实际需求采用；它们有清楚的 feature/adapter 归属，不在空模板里全部预装。各选择的官方资料见 [sources.md](sources.md)。

## 2. SDK、依赖与代码生成

固定 Flutter 稳定版及其自带 Dart，使用 FVM 或现有团队工具，CI 与本地相同；不能混用系统 Dart 与项目 Flutter 内的不同 Dart 版本。版本文件、升级流程和支持平台最低版本可审查。

应用提交 `pubspec.lock`；Pub workspace 使用根级共同解析和根锁文件，不复制每个成员锁文件。使用 workspace 前确认 Dart SDK 支持对应语法，并在干净检出验证，依据 [Pub workspaces](https://dart.dev/tools/pub/workspaces)。可发布 package 的兼容版本测试与应用锁定策略分别管理。

依赖不得长期用无限制范围、未说明的 Git 分支或 dependency_overrides。临时 override 记录原因、上游问题、负责人及移除条件；更新依赖单独审查行为与原生变化，不和业务修改混成不可定位的一次提交。

新模板默认提交模型生成文件，复制后可分析；源码为唯一修改入口。团队也可选择构建时生成，但必须在所有分析/测试/构建前生成，并验证干净检出。不得一部分生成文件随意提交、另一部分依赖开发者缓存。

代码生成固定 generator 与 analyzer 兼容组合。CI 在干净检出后运行生成器，验证已跟踪文件的差异和新产生的未跟踪文件；只看 `git diff` 会漏掉新增输出。生成策略包含 Freezed、JSON、l10n 和采用的路由/provider 生成，不手改结果。

## 3. 环境与平台配置

默认 dev/staging/prod。配置是类型化、不可变的非敏感参数：环境、API 地址、公开开关、日志策略与数据实现选择。Dart 入口与原生 flavor/Scheme 必须映射到相同环境；不能只改 base URL 就声称完成 flavor。

- dev 可显式选择本地 demo/fake；staging/prod 缺少真实实现或必要配置时明确失败，不回退为演示数据。
- app ID、显示名、凭据/缓存 namespace 区分环境；开发和预发布显示环境标记。
- 测试环境不可用 production 数据；stub 与日志开关不会被无意带入生产。
- dev/staging/prod 各自可分析和构建；每个发布目标校验配置、资源及后端连接策略。
- iOS 检查 Scheme、Debug/Profile/Release 配置、xcconfig 包含链、部署目标、entitlement、权限说明、隐私声明和签名；Android 检查 productFlavor/applicationId、manifest 合并、目标 SDK 与权限。

iOS flavor 的平台配置参照 [Flutter iOS flavors](https://docs.flutter.dev/deployment/flavors-ios)。最低 iOS/Android 版本依据产品覆盖和依赖兼容性决定，不能把某个模板最低版本当作通用企业标准。

密钥与证书通过受控的 CI secret store/签名设施使用，不进入 Git 或构建日志。客户端环境参数不提供保密能力，详见 [数据安全规范](state-and-data.md)。

## 4. 测试分层与最低场景

以行为风险安排测试，使用 fakes 和可控时钟/调度器；不要只断言 mock 被调用，也不为每个纯排版 wrapper 建立镜像测试。新增规则/修复并发缺陷时先写能重现的测试，确认失败再修复。

| 层次 | 必要覆盖 |
| --- | --- |
| domain/application | 值约束、计算精度、状态转移、编排失败/补偿、授权相关客户端分支 |
| mapper/Repository/service | JSON 缺失/类型错误/未知值、错误转换、存储失败、缓存失效、取消与重试边界 |
| ViewModel/Bloc | 首次读取、空、失败重试、刷新保留旧内容、分页去重、刷新与加载更多竞争、重复提交 |
| 会话与路由 | 启动恢复、失败状态、退出及删除失败、换账号旧响应、深链保持、非法/无权限/不存在页面 |
| Widget | 关键动作、所有读取/操作状态、语言/主题、大字号、小屏/横屏、语义、键盘与返回 |
| 平台 integration | 核心用户路径、实际持久化/Keychain、重启恢复、原生 adapter 和返回交互 |
| 离线写入（采用时） | 重启续传、同一幂等键、超时已成功、冲突/永久失败、账号切换、迁移失败 |

unit/widget/integration 的作用不同，依据 [Flutter 测试文档](https://docs.flutter.dev/testing/overview)。覆盖率作为盲点信号；阈值由团队基于基线与关键业务风险设定，不用任意“100%”代替场景验证。

异步测试等待确定的状态/事件，设置有界超时，不用固定 sleep 赌时序。不对无限动画/加载状态无条件 pumpAndSettle。处理测试产生的 timer、订阅、container 和 controller，保持测试间隔离。

网络测试默认使用替代传输和 fixture，CI 不依赖公网服务；与后端契约的验证单独运行。Widget harness 注入 fake、主题、l10n 和路由；黄金图只有视觉回归价值时采用并固定字体/尺寸/渲染环境。

原生系统权限弹窗等不属于 integration_test 自动可操作的全部范围；需要具备原生交互能力的方案或明确的设备验收。模拟器 build、模拟器流程和真机关键能力是不同证据。

## 5. CI 门禁

干净检出 → 固定 SDK → 锁定依赖解析 → 按策略生成 → 格式/分析/边界校验 → 单元及 Widget 测试 → 目标平台构建。独立任务可并行，生成与消费它的检查保持依赖顺序。

| 门禁 | 通过条件 |
| --- | --- |
| 格式 | 所有已存在的 Dart 源码目录通过 formatter 无变更检查 |
| 静态分析 | 无 error/warning；团队启用的 info 同样处理；只对明确生成输出排除，不排除手写业务 |
| 架构边界 | import/export/包图符合白名单、无循环；没有实现检查时报告人工审查 |
| 测试 | 适用逻辑与 Widget 场景通过；失败即阻止集成 |
| 生成一致性 | 固定工具重生成与提交/排除策略一致，包含新输出检查 |
| 平台构建 | 支持平台的必要 flavors 构建成功；iOS 在合适 macOS/Xcode runner |
| 发布路径 | 受控环境测试、签名、产物记录；在发布前验证真实配置 |

典型命令（选用项目固定 SDK 的入口，且只传存在的源码目录）：

```sh
flutter --version
flutter doctor -v
flutter pub get
flutter gen-l10n
dart run build_runner build
dart format --output=none --set-exit-if-changed lib test
flutter analyze --fatal-infos
flutter test --coverage
flutter build ios --simulator --flavor dev -t lib/main_dev.dart
```

`gen-l10n`、`build_runner`、`--flavor` 仅在项目已配置对应能力时运行；`tool`、`integration_test` 和 package 源码也纳入适用检查。纯 Dart package 用其对应的 dart analyze/test。命令示例不代表项目已有入口或检查脚本，环境构建应扩展到 staging/prod 与实际平台矩阵。

CI action 与 runner/SDK 版本可复现，外部 action 固定可审查版本或 SHA；PR 检查没有生产签名/部署权限，fork 的不可信代码不能读取 secrets。缓存键包含 SDK、锁文件及原生依赖的相关版本，不能缓存掩盖缺失生成或旧配置。

可复制的边界工具、生成检查、CI 示例及精确例外规则见 [规范门禁与模板](enforcement-and-templates.md)。应用依赖清单、原生传递依赖、许可证与扫描覆盖详见 [隐私与依赖治理](privacy-and-dependencies.md)。

## 6. 发布、性能与可追踪性

每个产物能追溯 commit、应用版本、构建号、环境与签名身份。保存 Dart 符号/dSYM/混淆映射和必要发布记录；只向受控系统上传，日志中不输出私密证书内容。

模拟器不验证生产签名、推送、购买或所有 Keychain 策略；发布前在真实签名/设备组合测试关键能力。权限、隐私及商店要求按实施时的平台官方要求核验。

启动、帧率/卡顿、内存、网络用量与包体的目标由产品设定；使用 profile/release 和代表设备测量，debug 结果不能充当发布性能结论。优化前定位瓶颈，避免默认缓存所有数据或滥用 isolate。

发布后观测关键路径成功率与崩溃，服务端开关可控制已实现的行为；App 回滚受商店和安装限制，不能承诺类似 Web 的瞬时回滚。数据迁移、兼容 API、最小支持版本与紧急处理方案应和发布策略一起设计。

详细验收分别见 [性能预算与测量](performance.md)、[观测与故障处置](observability-and-incidents.md)、[兼容发布与功能开关](release-and-flags.md)。不要把模拟器构建证据用于性能或真实配置启动结论。

## 7. 团队协作、ADR 与增量迁移

模块有 owner，公共接口和边界变更有相关消费者审查。PR 描述问题、最终行为、验证与实际风险；相关修复一并提交，避免生成/锁文件与源码分离。分支、提交、发布命名沿用仓库规则。

ADR 只记录有持续影响的决策：状态框架、分包、缓存/离线、错误协议、跨模块例外、平台最低版本。写明背景、选择、替代方案、后果与重新评估条件，不为每个控件建决策文档。

新增业务纵切步骤：

1. 确定 feature、消费者、契约和必要层次。
2. 定义模型/错误、状态所有者、异步与持久化语义。
3. 注入 Repository，完成一条 UI → 状态 → 数据路径。
4. 覆盖失败、取消、并发和平台相关风险，接入实际门禁。
5. 更新窄的公开入口、边界名单及必要文档。

迁移已有项目先绘制现有依赖图和测试基线，选择一个 feature 加契约/适配，再逐个迁移消费者；不要同时重命名全仓、替换状态管理和改协议。临时桥接有 owner、范围和移除条件，删除旧代码前验证消费者都已切换。

交付分别报告“文档定义”“代码实现”“检查通过”“设备验证”。SDK/Xcode/设备缺失时记录未验证部分和实际阻塞，不用阅读配置替代成功构建，也不擅自安装大型工具链、切换系统开发环境。
