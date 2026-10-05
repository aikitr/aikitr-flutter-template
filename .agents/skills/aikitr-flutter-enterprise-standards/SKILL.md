---
name: aikitr-flutter-enterprise-standards
description: Use when defining or applying enterprise engineering standards for Flutter and Dart apps, including project structure, naming, dependency boundaries, state ownership, lifecycle recovery, persistence migrations, performance, observability, feature flags, privacy, dependency governance, CI gates, architecture reviews, or incremental migrations.
---

# Flutter 企业级工程规范

适用于 Flutter 移动、桌面和 Web 应用的架构设计、功能实现与审查。默认采用 **Feature-first + MVVM + Repository**，按业务复杂度增加 application 编排。企业级要求是可维护、可验证的边界，不是目录或依赖数量。

## 使用流程

1. 确认任务是制定规范、设计、实现、审查还是迁移。制定规范时独立交付文档；该技能本身不授权全仓重构、依赖升级、安装工具或发布。
2. 实际改代码前读取仓库约定、SDK 约束、依赖与锁文件、相邻模块。用户要求优先；明确现状、目标和本次范围。通用规范任务不必绑定当前仓库。
3. 先读 [架构与依赖边界](references/architecture.md)，再按下表读取专题。给出文件归属、状态所有者、公开契约与验证方式后实施。
4. 使用最少有效层次；新项目可采用默认技术组合，已有 Bloc、Riverpod 或其他可靠方案沿用，不为遵守规范同时叠加或全量替换。
5. 区分“必须”“默认”“按需”。例外写明具体规则、范围、理由、负责人、验证方法和到期/移除条件；命名偏好不能冒充运行缺陷。
6. API、工具命令和平台配置以项目固定版本及官方资料为准。只报告实际运行的检查；模拟器构建、设备安装、签名发布分别验收。

## 按任务读取

| 任务 | 专题 |
| --- | --- |
| 目录、分层、跨模块、公共包、UseCase | [architecture.md](references/architecture.md) |
| Dart 命名、组件、布局、国际化、无障碍 | [naming-and-ui.md](references/naming-and-ui.md) |
| Riverpod/Bloc、异步并发、会话、网络、模型、安全、离线 | [state-and-data.md](references/state-and-data.md) |
| 技术选型、环境、代码生成、测试、CI、发布、迁移 | [tooling-and-delivery.md](references/tooling-and-delivery.md) |
| 生命周期、进程恢复、权限、后台任务 | [runtime-lifecycle.md](references/runtime-lifecycle.md) |
| 缓存、数据库迁移、中断与降级、持久化兼容 | [persistence-and-evolution.md](references/persistence-and-evolution.md) |
| 启动、帧、内存、图片、包体、性能预算 | [performance.md](references/performance.md) |
| 事件/指标、isolate 错误、告警、故障处置 | [observability-and-incidents.md](references/observability-and-incidents.md) |
| 兼容窗口、灰度、远程开关、离线默认、停发 | [release-and-flags.md](references/release-and-flags.md) |
| 数据分级、同意/删除、SDK 隐私、依赖/许可证 | [privacy-and-dependencies.md](references/privacy-and-dependencies.md) |
| 边界工具、生成一致性、CI/PR/ADR 模板、到期例外 | [enforcement-and-templates.md](references/enforcement-and-templates.md) |
| 官方依据、版本敏感事项、团队约定的来源 | [sources.md](references/sources.md) |

## 核心约束

- `app` 是装配入口；`core` 只放技术基础能力；`shared` 只放有真实复用需求的业务中立内容；业务归属 `features/<feature>`。
- 依赖指向契约：`presentation → domain`，可经 `application`；`data → domain`。domain 不引入 Flutter、状态框架、网络客户端或平台插件。
- 页面不得访问 DTO、具体 Repository、数据库或 SDK。跨 feature 只使用明确公开的契约或由上层编排；依赖图必须无环。
- 依赖注入在装配入口完成，ViewModel/Controller 不定位全局服务，不持有 BuildContext。简单查询不建立透传 UseCase。
- 状态、缓存、任务都有生命周期和账号／租户／环境作用域；取消与过期响应不作为用户错误，写操作不随 provider 初始化或自动重试执行。
- 关键数据在业务提交边界持久化；不依赖终止通知。恢复和迁移先验证身份/数据版本，未确认写操作查询结果而非盲目重放。
- 使用不可变业务模型；在数据边界处理协议、精度、时区与错误。客户端配置不能保管服务端秘密。
- Dart 命名遵循 Effective Dart；私有性属于 library，目录和 barrel 不能强制隔离。用边界检查补足约束。
- 按风险验证逻辑、界面与真实平台行为；生成代码与锁文件策略必须可复现。
- 性能预算有设备/构建/样本口径，事件和依赖有 owner 与数据处理清单；开关、旧客户端及存储格式按兼容窗口验证。

## 交付要求

规范或方案包含目标目录、职责、允许／禁止依赖、命名示例、状态与数据流、检查门禁及例外规则。实现或迁移报告具体变化、已完成验证、未验证条件；迁移按一个业务纵切推进。审查指出文件位置、违反的规则及实际影响，避免只有原则口号。
