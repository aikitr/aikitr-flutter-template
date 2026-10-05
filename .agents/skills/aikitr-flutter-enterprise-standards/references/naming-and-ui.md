# Dart 命名与界面规范

## 1. 命名基准

Dart 标识符和格式以 [Effective Dart: Style](https://dart.dev/effective-dart/style) 为准。后缀、组件位置和导入策略是本规范的团队默认约定，不是语言强制要求。

| 对象 | 规则 | 示例 |
| --- | --- | --- |
| package、目录、源文件、资源文件 | lowercase_with_underscores | `order_contracts`、`order_detail_page.dart` |
| class、enum、extension、typedef | UpperCamelCase | `OrderDetailPage`、`OrderStatus` |
| 变量、方法、参数、provider、枚举值 | lowerCamelCase | `loadNextPage`、`orderRepositoryProvider`、`pendingPayment` |
| 常量 | lowerCamelCase；沿用已有库约定时可例外 | `pageSize`、`requestTimeout` |
| library 私有声明 | 前缀 `_`，只用于真正私有的声明 | `_mapOrder`、`_OrderCardState` |
| 完整路由页面 | `<feature_or_purpose>_page.dart` | `order_detail_page.dart` |
| ViewModel/Controller | 整个项目选定一种角色命名 | `OrderDetailViewModel` 或 `OrderDetailController` |
| 已有 Bloc/Cubit | 使用其真实角色，不再包一层同义 ViewModel | `OrderDetailBloc`、`OrderDetailState` |
| Repository 契约 | `<business>_repository.dart` | `OrderRepository` |
| Repository 实现 | 说明来源/策略 | `ApiOrderRepository`、`CachedOrderRepository` |
| 传输对象与映射 | `_dto`、`_mapper` | `OrderDto`、`OrderMapper` |
| 明确业务用例 | 动词 + 业务 + UseCase | `SubmitExpenseUseCase` |
| 测试文件 | 被测文件名 + `_test.dart` | `order_mapper_test.dart` |
| 替身 | 明确 fake/mock/stub 身份 | `FakeOrderRepository` |
| 生成文件 | 路径由工具及配置决定；模型/provider 的 part 输出通常与源文件相邻，l10n 使用其单独输出目录 | `order_dto.g.dart`、`order.freezed.dart`、`l10n/generated/app_localizations.dart` |

三个及以上字母的缩写按普通词处理，例如 `HttpClient`、`ApiResponse`、`OrderDto`；两字母缩写按 Effective Dart 规则处理，不机械改写已有公共 API。不要用 `IOrderRepository`、`kPageSize` 或匈牙利前缀表示类型信息。

业务能力模块可用复数（`orders`），模型用单数（`Order`）；采用一种词汇表。布尔值说明语义，如 `canSubmit`、`isRefreshing`；方法表达行为，如 `cancelOrder`，避免 `handleData`、`doAction`。

避免兜底名字 `Utils`、`Manager`、`Helper`、`CommonService`；按职责命名 `MoneyFormatter`、`SessionRepository`。基础类只有真实共性和替换需求时创建，不能为每个 Page、Repository、ViewModel 强制建立 Base 类。

## 2. 文件、导入和 Dart API

- 默认一文件一个主要公开角色，小型私有辅助类型可同文件；不按行数机械拆文件。
- 默认 `lib/` 内使用 `package:<app>/...` 导入；团队已有一致的相对导入策略可保留。无论哪种 URI，都必须规范化后检查分层，不允许 `../` 绕过边界。
- import 分组为 `dart:`、`package:`、相对路径，各组排序，export 单独成组；交给 formatter 和 lint 维护。
- 契约以业务能力组织，不强制 `BaseRepository<T>` 或“万能 CRUD”。参数使用有意义的类型，多个布尔参数改为命名参数或明确的选项类型。
- 异步返回 `Future<T>`，业务订阅返回 `Stream<T>` 并声明初始值、错误及关闭语义。外部输入用 `Object?` 并校验，避免以 `dynamic` 绕过分析器。
- 公共数据不可变，集合不得暴露可变内部引用。使用合适的值相等性；不对包含身份/资源生命周期的对象机械使用深比较。
- 不滥用 `late`、`!`、忽略分析器或空 `catch`；注释记录不变量、业务原因、协议限制，公开契约写 dartdoc。
- `part` 默认只用于合法生成或明确的 library 组织，不用巨大共享 library 跨模块扩张私有访问。

接口设计参考 [Effective Dart: Design](https://dart.dev/effective-dart/design)。具体的 import 风格、文件后缀可在项目 ADR 中统一。

## 3. 页面与组件边界

Page 连接路由参数、页面 ViewModel 和 UI；不得解析 JSON、调 HTTP、访问存储或计算价格。ViewModel 输出可渲染状态和明确操作，不返回 Widget，不保存 BuildContext，也不调用 Navigator。

局部焦点、输入 controller、动画、滚动位置留在 Widget 的生命周期。提交数据和校验规则归页面状态/业务模型；即时格式提示可在 UI，最终业务校验不能只依赖表单。

feature 组件接受强类型数据和回调，如 `OrderSummaryCard(order: ..., onTap: ...)`。shared/ui 控件接受展示信息和交互，不隐式读取订单 provider 或账号会话。需要状态的 feature 容器与纯展示组件分别命名。

默认通用组件清单：

| 能力 | 推荐契约 |
| --- | --- |
| 页面容器 | 统一安全区域、背景与键盘策略；不硬编码业务导航 |
| 提交按钮 | 文案、busy、enabled、callback、语义；防止重复触发 |
| 表单输入 | label、hint、error、输入法/自动填充；正确暴露焦点和语义 |
| Loading/Empty/Error | 明确标题、说明、可选动作；区别空结果与失败 |
| AsyncContent | 首次加载/错误/内容；刷新已有内容不能整页闪白 |
| 分页列表 | 接收列表、加载更多状态和动作；分页协议在 ViewModel |
| 确认弹窗/操作菜单 | 返回明确结果；说明所属 Navigator 与取消行为 |

只包装需要团队设计或交互语义的控件，避免为每个 Flutter 控件创建一层无行为 wrapper。组件展示页覆盖真实状态、亮暗主题、大字号与长文本。

## 4. 主题、布局与无障碍

采用语义 token，例如 `surface`、`textPrimary`、`critical`、`spaceMd`；颜色、间距、字号、圆角、动效集中管理。组件消费主题，不在页面散布魔法值或按“白色等于背景”假设暗色模式。

按父级约束、窗口可用空间和内容布局；用 LayoutBuilder/MediaQuery 解决具体约束。避免整屏等比缩放、仅按设备名称划布局，以及禁用系统字号来消除溢出。大屏采用内容最大宽度与合适分栏，不无限拉伸表单。

处理安全区域、键盘 inset、可滚动表单、横屏、分屏、长文本、RTL 与 text scaling。有限宽度内的 Row 文本使用合适的 Flexible/Expanded；按钮和导航标题不能假定单行固定高度。依据 [Flutter 自适应设计](https://docs.flutter.dev/ui/adaptive-responsive/best-practices)。

必须保留屏幕阅读器可理解的名称、状态和操作；图标按钮有语义标签，不用颜色作为唯一状态提示。保持逻辑阅读/焦点顺序，避免重复 Semantics；装饰图像不参与阅读。

团队默认交互目标至少 48×48 逻辑像素，小图标也有充分点击区域；验证亮暗主题对比、VoiceOver/TalkBack、大字号和减少动态效果。此触控目标是团队基准，具体平台控件与设计系统按实际可访问性验证。参考 [Flutter 无障碍检查清单](https://docs.flutter.dev/ui/accessibility)。

## 5. 国际化

- 用户可见文本通过 ARB + gen-l10n；包含按钮、错误、空状态、语义标签。默认源文件为 `lib/l10n/arb/`，输出为 `lib/l10n/generated/`，UI 可读取，app 只装配 delegates。需要可翻译的完整句子，不拼接词段。
- placeholder 有类型与翻译上下文，复数使用 ICU plural；日期、数值、货币依据用户 locale 格式化。
- domain/data 不依赖 `AppLocalizations`，只暴露错误码、业务值与安全参数；presentation 将其映射成文案。
- generated l10n 输出位置、导入与提交策略在 `l10n.yaml` 和 CI 中一致，以已固定 SDK 的 `flutter gen-l10n --help` 为准，不复制旧版本的废弃参数。
- 用户选择语言与主题后可持久化；“跟随系统”需要独立状态，不把当前系统值误保存成固定选择。

依据 [Flutter 国际化文档](https://docs.flutter.dev/ui/internationalization)。

## 6. 路由与平台交互

路由配置集中声明，业务页面只处理已验证参数。详情 ID 应可由深链/恢复路径获得，不能只靠内存中的 `extra` 对象。复杂实体由 Repository 读取；处理非法 ID、不存在、无权限和加载状态。

导航和弹窗由 UI 适配层执行；定义 go_router 与 Navigator 各自管理的栈、root/shell navigator 和返回结果。重要流程覆盖返回、取消、系统返回手势与恢复。确认结果应先让弹窗关闭，再触发会引起会话重置/路由切换的操作；异步回调使用 context 前检查 mounted。

iOS 遵守安全区域、交互式返回、键盘、系统分享和权限交互；Android 处理系统返回及目标 SDK 要求；Web/桌面处理深链、键盘与窗口变化。默认选择与产品平台一致的 Material/Cupertino 风格；适配语义和行为，不只替换图标。
