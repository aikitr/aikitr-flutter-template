# 状态、数据流、网络与安全

## 1. 状态所有权

每种状态明确谁创建、谁更新、谁销毁、如何恢复、是否持久化，以及账号/租户/环境作用域。一个业务事实只有一个权威来源；UI 派生信息不重复存三份可独立修改的数据。

| 状态 | 所有者与生命周期 |
| --- | --- |
| 焦点、输入 controller、动画、局部展开状态 | Widget，销毁时 dispose |
| 页面列表、筛选、提交状态、校验结果 | route/flow 的 ViewModel；按业务参数隔离 |
| 会话、当前账号、租户 | identity，应用级可观察契约 |
| 主题、语言等偏好 | settings Repository；应用展示配置消费 |
| 业务缓存与同步状态 | 对应 feature Repository；不是全局 UI provider |
| HTTP client、技术存储适配 | 装配拥有生命周期，注入使用者 |

默认单向流：用户动作 → ViewModel → Repository/UseCase → 新的不可变状态 → UI。操作失败不回滚掉无关页面数据。

## 2. Riverpod 与已有 Bloc

新项目可用 Riverpod 统一状态与依赖；Bloc/Cubit 等已有可靠方案沿用相同边界。不得只因技能默认选型而迁移整仓，不能同时以 GetIt、静态 singleton、Riverpod 建立三套服务来源。

Riverpod 团队默认：

- Provider 装配只读依赖；Notifier/AsyncNotifier 管理页面/流程状态。简单异步查询可用 FutureProvider；提交、付款、退出等写操作由明确方法触发。
- provider 自行初始化读取逻辑，不在 Widget build/initState 中用额外 `init()` 形成第二初始化路径。业务操作不能随 provider 重建而再次执行。
- 页面用 `watch` 订阅、事件用 `read` 调方法；UI 副作用通过合适的 `listen` 处理。纯计算与副作用分离。
- 按参数隔离实例，声明自动释放/保留的理由；参数具有稳定相等性，不把每次 build 新建的可变集合当 family key。
- dispose 取消请求、订阅与计时器；异步结束后确认仍是有效实例。使用已安装版本支持的 mounted/生命周期 API，不能复制不同 Riverpod 大版本写法。
- provider/依赖声明留在对应模块；由 app/模块 composition 注入 Repository 实现。只为读契约的声明不能 import data。
- 每次测试创建独立 container/scope 并销毁，通过 override 提供 fake，不使用跨测试共享状态。
- 检查固定版本的默认 retry 行为。Riverpod 3 的 provider 计算有自动重试，应显式决定读取重试策略；确定性解析失败、认证/校验失败、会话清理不应被隐式重试，不能在可重试计算内执行写操作。

参考 [Riverpod DO/DON'T](https://riverpod.dev/docs/root/do_dont)、[取消请求](https://riverpod.dev/docs/how_to/cancel)、[自动重试](https://riverpod.dev/docs/concepts2/retry)。上述命名和装配位置是团队约定。

Bloc/Cubit 注入相同 Repository 契约，页面采用 builder/listener 分离展示和副作用。事件并发策略按操作定义，不把所有事件默认串行或默认并行；close 后不得继续发布状态。

## 3. 异步状态、分页与并发

首次加载、已有内容刷新、加载更多与提交分别表示；不要用一个 `isLoading` 隐藏整个页面。可用 AsyncValue 表示读取状态，但带旧内容和多种操作时需要明确的页面 state；使用不可变集合和枚举/密封类型表达互斥状态。

| 场景 | 必须定义的策略 |
| --- | --- |
| 搜索/切换筛选 | debounce 与 latest-wins；过期响应不覆盖新条件 |
| 多次提交 | UI 防重复 + 状态层互斥；有副作用时后端幂等 |
| 下拉刷新与加载更多并发 | 刷新增 generation 并重置 cursor；旧分页结果不得合入新列表 |
| 分页 | 按稳定 ID 去重且保持约定顺序；失败不推进 cursor，区分尾页与空首屏 |
| 退出/换账号/租户 | 失效 epoch，取消旧任务、清理对应缓存；晚到结果不得恢复旧数据 |
| 局部乐观更新 | 指明回滚范围与服务端冲突策略；不盲目恢复过期全局快照 |
| 取消请求 | 生命周期正常结果，不弹错误；与真正的 timeout 分开 |

依赖已注入的时钟、调度器或可控 completer 测并发；不可只靠“请求通常很快”。缓存键至少包含环境、账号/租户、查询参数与 schema 版本中实际影响数据的部分。公共匿名缓存只有明确的数据共享语义才免除账号键。

## 4. 会话与启动

启动建模为 initializing、ready、recoverableFailure 等状态；session 区分 unknown/restoring、authenticated、unauthenticated、failure。不能将“存储读失败”当作确定的“未登录”，也不能把反序列化失败悄悄吞掉。

只等待启动必需项；非关键遥测等不阻塞首屏。失败提供重试/恢复策略。路由实例和 navigator key 保持稳定，在恢复完成前进入启动页，避免闪登录或循环重定向；保护深链目标并校验允许的重定向地址。

登录成功后的会话持久化失败必须有一致策略（报告失败或明确限内存会话），不能宣称“已保存”却无法恢复。登出先使内存会话与旧任务失效，再处理本地凭据/缓存删除及按协议的后端撤销；清理失败不得误报成功。必要时设置持久化退出标记阻止重启恢复旧凭据，并给出重试，不能只在内存退出而下次自动登录。

401 由传输适配通知注入的会话失效机制，不在 core import identity。通知应携带请求所属会话版本；旧账号的 401 不能踢出新账号。若后端有刷新协议，处理 single-flight 刷新、等待请求、刷新失败及一次受控回放；不猜测端点和 token 格式，不无限刷新。

进程终止、系统恢复、前后台、权限返回和后台任务的顺序与边界见 [生命周期与恢复](runtime-lifecycle.md)；会话恢复不能依靠最后一次生命周期通知。

路由守卫仅提供客户端体验，服务端必须检查授权。生物识别是本地解锁能力，不代替后端身份验证。

## 5. Repository、模型与协议边界

Repository 是所属业务数据的权威访问接口，协调远程和本地一致性；API service 负责协议，local service 负责存储。定义 refresh/cache policy、分页 cursor、notFound、超时与取消等语义，避免只提供一组与 HTTP 完全同名的泛型 CRUD。

domain 契约使用业务参数与模型，不暴露 Dio Response、CancelToken、SQL row、平台类型或服务器 JSON。需要取消时用框架中立的取消抽象或生命周期 handle；data 适配到传输实现。契约通过构造参数注入，方便 fake。

默认分离 DTO 与 domain model：DTO 匹配协议、版本和可空性，mapper 校验并生成可信业务模型。UI state 表示展示/交互，不代替业务模型。极简单的稳定本地数据可共用不可变模型，但须说明没有传输语义泄漏；不用相同字段作为永久省略边界的理由。

- 金额携带币种和明确的精度，采用整数最小单位或经过选型验证的精确十进制类型；比例/汇率也规定舍入规则。API double 已丢失的精度无法由客户端恢复，不用 `(value * 100).toInt()` 猜测修复。
- 时间区分瞬间、当地日期和时长；瞬间在边界解析且约定时区，UI 本地化。生日/账期这类日期不得随意转 UTC 造成跨日。
- 后端状态字符串映射到有语义的 enum/union，明确 unknown 的展示和可操作性；新增后端值不应导致全列表崩溃或静默映射为成功。
- JSON/值对象错误在 data 边界转换为协议错误；不把原始 JSON、后端内部消息或 SDK 异常交给页面。
- Freezed/json_serializable 解决不可变值与生成问题，不自动验证业务规则；生成文件不手改。

## 6. 网络、错误与重试

网络层统一 base URL、connect/send/receive timeout、请求取消、认证注入、相关请求 ID 与脱敏观测；Dio 是默认选择之一，Repository 仍面向契约。通过可替换传输适配器测 HTTP 与解析行为，参考 [Dio 官方包文档](https://pub.dev/packages/dio)。

团队为 Repository 错误选择一致协议：新项目默认抛出纯 Dart 的类型化 AppException，并由 ViewModel 转成可渲染状态；已有 `Result<T, Failure>` 可沿用，不能同一契约混用返回 null、字符串、Result 与未声明异常。

错误区分 cancelled、timeout、offline/connectivity、unauthorized、forbidden、notFound、validation、conflict、rateLimited、server、invalidPayload、storage。保留安全错误码、字段问题和可重试信息；UI 做本地化。未知编程错误由错误边界报告并显示安全提示，不捕获一切后返回空列表；诊断堆栈不能进入用户文案。

取消不提示；加载更多失败在列表尾部重试，刷新失败保留旧内容；校验错误定位字段；缺失数据区别暂时网络错误。日志中的失败与用户展示的安全文案分开。

重试只有一个明确负责人（provider、Repository 或传输，不能三层叠加）。仅对可恢复且安全的读取或有已确认幂等协议的写入采用有限次数、退避与抖动，尊重 Retry-After。POST 超时可能已在服务端成功；无幂等键、去重和状态查询协议时禁止自动回放。认证、解析、校验错误不机械重试。

## 7. 存储、安全与可观测性

偏好设置用非敏感键值存储，新项目可用 SharedPreferencesAsync；写入完成不等于关键数据具备持久化保证，不能用 shared_preferences 保存凭据、关键交易或待同步队列。参考 [插件限制](https://pub.dev/packages/shared_preferences)。

凭据通过 core/storage 的平台适配进入 Keychain/对应安全存储，由 identity 管理读写语义。应用、环境、账号的命名空间分开；按需求选择备份、设备锁定与访问组策略，并测真实平台行为。参考 [flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage)。不要假定重装必然清除 Keychain，也不要把 Web 的客户端存储当作服务端可信边界。

dart-define、配置文件、assets 和混淆后的客户端二进制都不能保存服务端秘密。秘密操作在服务端完成；可公开的 SDK 标识仍须平台/来源与权限限制。CI secret store 只保护流水线中的签名与部署凭据，注入到 App 的秘密仍会进入产物。参考 [Flutter 混淆的安全限制](https://docs.flutter.dev/deployment/obfuscate)。

默认 HTTPS，不为修复开发请求关闭生产证书验证。证书固定只有明确威胁模型与证书轮换/故障恢复方案时采用。收集最少必要数据，凭据不得进入 URL、分析事件、错误对象或剪贴板。

生产日志采用结构化事件、严重级别、request/trace ID 和采样；禁止记录 authorization、cookie、密码、token、原始用户内容与完整请求/响应。脱敏是默认拒绝未知字段、按允许列表开放，不只把某几个字段替换为星号。测试 URL query、嵌套 map/list、异常和第三方 SDK 日志的泄漏。

记录版本/环境、启动、关键任务失败率及性能指标；崩溃报告由可替换 adapter 提交并保留符号。大 JSON、图片或 CPU 密集操作先测量，再用 isolate/后台任务；任务能力受各平台生命周期限制。

缓存保鲜/驱逐、不可重建数据、迁移中断和降级详见 [持久化与数据演进](persistence-and-evolution.md)；性能测量见 [性能规范](performance.md)。事件契约、isolate 错误链与告警见 [观测与故障处置](observability-and-incidents.md)；SDK 独立采集、同意撤回和数据删除见 [隐私与依赖治理](privacy-and-dependencies.md)。

## 8. 离线提交与扩展能力

只有产品要求离线写入时才引入数据库/outbox。队列需事务性持久化、schema migration、账号隔离、稳定幂等键、attempt/nextRetry 状态、去重和冲突协议。重启不能产生新幂等键而重复提交。

关键操作记录原子落盘成功后才发送，失败不发交易；结果确认与恢复的顺序见 [生命周期规范](runtime-lifecycle.md)。这不是要求所有简单读取/写入都建立数据库队列。

区分 queued、sending、confirmed、needsAttention；本地保存不等于服务端成功。注销/换账号时定义保留、清理或拒绝策略，禁止把旧账号任务作为新账号发送。后台连网通知不是可靠同步保证，启动/恢复也需要受控同步。

数据库、推送、内购、Apple 登录等属于具体业务 feature 的契约及 data/platform adapter；SDK 初始化可在 composition，业务规则不能进入 bootstrap/core。没有真实协议与平台验收时不提前假装“已支持”。
