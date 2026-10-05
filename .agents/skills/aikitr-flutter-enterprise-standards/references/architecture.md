# 架构、目录与依赖边界

## 1. 规则等级与架构选择

- **必须**：数据与 UI 解耦、依赖无环、业务所有权明确、状态可测试、传输实现不泄漏到页面。以下“不得”也属于必须。
- **默认**：本规范的团队约定，例如 Feature-first、目录名称、MVVM、Repository 契约位置。已有明确且有效的约定可沿用。
- **按需**：UseCase、独立 package、数据库、离线队列、事件总线、代码生成。出现明确的复杂度或复用需求才引入。

UI 与数据分离、MVVM、Repository、依赖注入及有条件采用领域层，依据 [Flutter 架构建议](https://docs.flutter.dev/app-architecture/recommendations)。下述目录和边界矩阵是本规范选择的团队约定，Flutter 并未规定这一套唯一目录。

默认是模块化单体。这里的 `domain` 首先承载纯 Dart 的模型和 Repository 契约；有这个目录不意味着必须实现 DDD、聚合或 UseCase。单一页面的简单模块可将相同职责平铺在 feature 内，保持依赖方向，不生成空层。

## 2. 推荐单应用目录

```text
project/
├── lib/
│   ├── main.dart                      # 薄入口：选择配置后启动
│   ├── main_dev.dart                  # 仅在需要独立环境入口时创建
│   ├── main_staging.dart
│   ├── main_prod.dart
│   ├── app/
│   │   ├── app.dart                   # 根 Widget 与应用级 ProviderScope
│   │   ├── bootstrap.dart             # 初始化、错误边界、启动状态
│   │   ├── config/                    # 类型化的非敏感环境配置
│   │   ├── composition/               # 实现选择、DI、生命周期装配
│   │   ├── routing/                   # 路由树、守卫、深链映射
│   │   └── theme/                     # 主题装配与语义 token 配置
│   ├── l10n/                         # 只读 UI 资源；不属于 app 装配
│   │   ├── arb/                       # app_en.arb、app_zh.arb
│   │   └── generated/                 # gen-l10n 输出，遵循生成策略
│   ├── core/
│   │   ├── errors/                    # 纯 Dart 应用错误基础类型
│   │   ├── network/                   # 传输、取消、超时、拦截器
│   │   ├── storage/                   # 技术存储接口与平台适配
│   │   ├── observability/             # 脱敏日志、指标、报告适配
│   │   └── platform/                  # 系统能力适配、平台差异
│   ├── shared/
│   │   ├── ui/                        # 通用控件、交互与状态视图
│   │   └── value_objects/             # 有复用证据的纯 Dart 值类型
│   └── features/
│       ├── identity/                  # 会话、认证及身份业务
│       ├── orders/
│       │   ├── orders.dart            # 窄的纯 Dart 模型/契约公开入口
│       │   ├── orders_composition.dart # 可选的模块装配入口
│       │   ├── presentation/
│       │   │   ├── pages/             # order_list_page.dart
│       │   │   ├── view_models/       # order_list_view_model.dart
│       │   │   ├── providers/         # 契约依赖声明；使用 Riverpod 时按需
│       │   │   ├── states/            # order_list_state.dart
│       │   │   └── components/        # order_summary_card.dart
│       │   ├── domain/
│       │   │   ├── models/            # order.dart
│       │   │   ├── value_objects/     # order_id.dart，有实际约束才封装
│       │   │   ├── repositories/      # order_repository.dart（契约）
│       │   │   └── ports/             # 消费方拥有的外部业务契约，按需
│       │   ├── data/
│       │   │   ├── dto/               # order_dto.dart
│       │   │   ├── mappers/           # order_mapper.dart
│       │   │   ├── remote/            # order_api.dart
│       │   │   ├── local/             # order_cache.dart，按需
│       │   │   ├── adapters/          # 外部业务契约到本模块端口的适配，按需
│       │   │   └── repositories/      # api_order_repository.dart（实现）
│       │   └── application/           # 仅复杂规则/流程需要时创建
│       │       └── use_cases/
│       ├── payments/
│       └── checkout/                  # 跨订单/支付的结账流程，按需
├── assets/
│   ├── images/
│   ├── icons/
│   └── fonts/
├── test/                              # 镜像 lib 的模块与层次
│   ├── app/
│   ├── core/
│   ├── shared/
│   ├── features/
│   └── support/                       # fake、fixture、测试 harness
├── integration_test/                  # 用户路径与真实插件验证
├── tool/                              # 可复现生成、校验与工程脚本
├── docs/
│   ├── architecture.md
│   └── adr/                           # 有影响的决策及例外记录
├── ios/                               # 只保留支持的平台工程
├── android/
├── pubspec.yaml
├── pubspec.lock                       # 应用提交；workspace 见交付规范
├── analysis_options.yaml
└── l10n.yaml
```

树展示职责位置，不是创建清单。`android/` 等平台、`local/`、`value_objects/`、`ports/` 都只在使用时创建。避免以 `screens/models/services/controllers` 四个全局文件夹承载全部业务。

## 3. 分层职责与依赖矩阵

编译依赖箭头表示 import 方向；运行时通过注入的契约调用实现。Repository 可以协调其所属数据的远程/本地来源，但不得凭具体实现调用其他 Repository；跨数据源业务流程由 application 编排。

| 来源 | 允许依赖 | 不允许依赖 |
| --- | --- | --- |
| `app`、明确命名的 composition 文件 | 所需模块公开入口、模块装配、具体实现、技术设施 | 其他层反向依赖 app；在装配中编写订单/支付规则 |
| `presentation` | 同 feature 的 domain、application；shared/ui、l10n；Flutter、选定状态框架 | data、DTO、Dio、数据库、Keychain、业务 SDK、app |
| `application` | 同 feature 的 domain；纯 Dart 基础类型；批准的外部业务契约 | Widget、BuildContext、具体 data、平台 SDK、导航操作 |
| `domain` | Dart、明确允许的纯 Dart 值类型/错误类型 | presentation、application、data、Flutter、Riverpod/Bloc、HTTP、插件 |
| `data` | 同 feature 的 domain、纯 Dart 基础类型、core 技术适配、传输/数据库库；端口适配所需的已批准外部纯契约 | presentation、application、其他 feature 的实现、app |
| `core` | 更底层的技术能力、适配所需 SDK | features、shared/ui、具体业务实体/规则 |
| `shared/ui` | Flutter、l10n、注入的主题 token、业务中立纯类型 | feature、Repository、业务状态 provider、直接 IO |
| `shared/value_objects` | Dart、必要且稳定的纯 Dart 依赖 | Flutter、IO 实现、app、feature |

主题由 app 安装；shared/ui 从 `Theme.of(context)`、`CupertinoTheme.of(context)` 或传入 token 读取，不能 import `app/theme`。公共主题扩展的定义可放 shared/ui/theme，保持依赖方向。l10n 是 UI 可依赖的只读资源，不能反向 import app/feature；app 仅装配 locale/delegates。

MVVM 的 ViewModel 放 presentation；Riverpod Notifier/AsyncNotifier 或 Bloc/Cubit 承担这个角色。选定一种命名，不创建功能相同的 Controller + ViewModel + Bloc 三层。application 默认保持纯 Dart；状态框架与界面副作用适配留在 presentation。

装配例外只对已列明的路径生效，例如 `app/composition/**` 与 `features/*/*_composition.dart`。普通页面不能改名为 composition 来绕过边界。一个 feature 的页面从内部依赖声明读取契约，其声明不能顺带 import 具体 data；实现由装配入口注入。

Riverpod 文件归属示例：`presentation/providers/order_dependencies.dart` 声明类型为 `OrderRepository` 的依赖；`presentation/view_models/order_list_view_model.dart` 读取契约并管理状态；`orders_composition.dart` 选择 `ApiOrderRepository` 并产生 override，由 app 根 scope 安装。缺少装配应明确失败，不能在契约 provider 内悄悄实例化真实/演示 data。provider 很少时可与 ViewModel 同文件，不强制为每个声明再拆一层。Bloc 对应做构造注入，由同一装配入口创建。

## 4. 模块划分与跨模块协作

按业务能力、规则和负责人划 feature，不按每个 Tab 或 API 端点划模块。identity 拥有会话语义，payments 拥有支付；HTTP、存储封装归 core。core 不能成为业务代码的兜底目录。

默认跨 feature 通过上层流程或消费方端口协作。确需直接共享稳定契约时，仅从对方 `<feature>.dart` 导入模型/接口，并记录无环依赖；公共入口不表示所有 feature 自动互相可见。

消费方端口默认放在消费模块的 `domain/ports/`，对应 adapter 放 `data/adapters/`；application 依赖自己的端口，adapter 实现端口并调用批准的外部公开契约，由 composition 注入。例如 `checkout/domain/ports/payment_port.dart`、`checkout/data/adapters/payments_gateway_adapter.dart`；adapter 可依赖 `payments/payments.dart` 中的纯 Dart `PaymentGateway`，但不能依赖 payments 的 Stripe 实现。简单且稳定的协作也可直接依赖批准的公开契约，不为每次调用建立重复端口。application 不承担依赖注入或适配具体实现的职责。

```text
合法：checkout/application → orders/orders.dart（OrderRepository）
合法：checkout/application → payments/payments.dart（PaymentGateway）
合法：app/composition → payments 的 Stripe 实现 → PaymentGateway
非法：orders/presentation → payments/data/stripe_payment_repository.dart
非法：core/session_service → features/identity
非法：shared/ui → features/orders 的 provider
非法：orders → payments → orders（换成 barrel 导入仍然非法）
```

订单查询保持 `OrderListViewModel → OrderRepository`。结账出现库存确认、付款和失败补偿时，由 checkout 的 UseCase 协调公开契约；不能把 HTTP 请求组合误称为客户端原子事务。跨服务一致性、价格和支付授权须由后端协议保证。

`<feature>.dart` 显式 export 必需的纯 Dart 模型和契约；不导出 dto、mappers、data 实现、页面或所有组件。需要 UI/路由入口时单独声明（例如 `presentation/orders_routes.dart` 或独立 UI 入口），由 app 的路由装配消费；其他 feature 不因此获得对所有页面的依赖权限。若采用根目录 UI barrel，边界配置显式分类它，不能把它与纯契约入口归为一类。

## 5. 何时增加 UseCase、共享目录与 package

| 判断 | 处理 |
| --- | --- |
| 一次读取或保存，没有复用规则 | ViewModel 调用 Repository；不加透传 UseCase |
| 多步骤业务、重复规则、跨 Repository 编排 | 创建有业务名称的 UseCase，例如 `PlaceOrderUseCase` |
| 控件只有一个模块使用 | 留在该 feature 的 presentation/components |
| 至少两个独立消费者，语义稳定且不含业务状态 | 移到 shared；没有复用证据时保留本地 |
| 两个应用、独立团队/发布生命周期、原生插件或稳定 SDK 边界 | 评估独立 package |
| 只是文件数量增多 | 先拆职责；无需立刻建立 monorepo |

多应用目录可采用：

```text
repo/
├── apps/consumer_app/
├── apps/operator_app/
├── packages/design_system/           # Flutter UI
├── packages/order_contracts/         # 纯 Dart；实际共享时创建
├── packages/platform_storage/        # 插件适配；按需
└── pubspec.yaml                      # Pub workspace；SDK 支持时采用
```

package 对外使用 `lib/<package_name>.dart`，内部放 `lib/src/`。跨包不得 import 对方 `lib/src` 或复制相对路径。pure Dart package 不依赖 Flutter；design_system 不依赖业务。以真实复用和 ownership 拆包，不强制每层一个 package。

## 6. 把边界变成可检查规则

Dart 的 `_` 是 **library 私有**，不是文件夹/feature/package 私有；barrel 是组织方式，不是访问控制。依据 [Dart libraries](https://dart.dev/language/libraries)。`implementation_imports` 可以限制跨 package 的 `src` 导入，但不能替代应用内部的分层检查。依据 [该 lint 的说明](https://dart.dev/tools/linter-rules/implementation_imports)。

将依赖矩阵落实为 CI 中的 import/export 校验或兼容的 analyzer lint：解析并规范化 package URI、相对 URI、export、part 与条件导入；不能只搜索字符串，也不能漏掉 barrel 的传递导出。检查包图及 feature 图无环，固定装配例外名单。初始化时可先做人工边界审查，不能在没有检查工具时宣称“CI 已强制”。

技能附带经过测试的单应用 Dart AST 检查工具、默认矩阵和到期例外门禁，见 [落地工具与覆盖限制](enforcement-and-templates.md)。它检查本地 lib 的 feature 图；完整 workspace 包图、外部依赖内部实现与符号级约束需要额外分析，不能以工具通过替代全部架构审查。

公共契约变化由消费者测试或 contract test 验证。有破坏性变更时先加兼容契约/适配、迁移消费者、再删除旧 API。ADR 记录必要的直接跨模块依赖及解除条件。
