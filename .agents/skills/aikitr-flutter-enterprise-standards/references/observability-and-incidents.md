# 4. 可观测性与故障处理

## 职责与事件契约

core/observability 定义业务中立的 logger、metric、trace、error-report adapter；feature 定义其事件语义，app/composition 安装具体 sink。业务不直接耦合某个崩溃平台或把日志当作共享状态总线。

事件目录声明 event name/version、触发时点、允许字段/类型、用途、采样、数据分类、owner 和保留期。安全参数按允许列表记录；密码/token、原始表单/响应、支付数据及任意 SDK metadata 不进入事件。新增字段走 [隐私与依赖治理](privacy-and-dependencies.md)。

用户动作、技术失败、预期取消与安全事件分别定义口径；高基数 request/operation ID 可用于受控 trace，不能直接做时间序列 label。账号散列值仍需数据治理，不能默认视作匿名。

## 完整错误路径

| 错误来源 | 采集入口 | 验证要求 |
| --- | --- | --- |
| Flutter build/layout/paint 等回调 | FlutterError.onError | 保留开发期诊断，报告脱敏；安全 ErrorWidget 不依赖已损坏树 |
| 主 isolate 未处理异步错误 | PlatformDispatcher.instance.onError | 明确 handled 语义；采集成功不等于状态已经恢复 |
| 工作 isolate | spawn 的 onError 或受控 addErrorListener 转发 | listener 在执行前生效；序列化 error/stack，定义 worker 失败与退出 |
| 原生 crash/SDK | 所选平台 adapter | 符号、版本与签名匹配，真机验收，按平台能力说明覆盖范围 |
| 已捕获的业务/IO 失败 | Repository/ViewModel 的分类事件 | 预期失败不重复算作 crash，保留必要诊断上下文 |

FlutterError 与 PlatformDispatcher 覆盖不同来源，依据 [Flutter 错误处理](https://docs.flutter.dev/testing/errors)；后者不自动捕获所有子 isolate 错误，见 [API](https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/onError.html)、[Isolate listener](https://api.dart.dev/dart-isolate/Isolate/addErrorListener.html)。

若采用 zone/第三方 SDK 包装启动，确保 binding 初始化与 runApp 在同一 zone，参照 [Flutter zone 检查](https://api.flutter.dev/flutter/foundation/BindingBase/debugZoneErrorsAreFatal.html)。保留已有 handler 或明确替换 owner，避免重复 hook、递归报告与互相覆盖。不把 runZonedGuarded 当作所有 Future 都能安全跨 zone 传播的保证。

重要 Future 被 await 或明确托管其错误与生命周期；fire-and-forget 仍有 owner。工作 isolate 错误必须转换成受控任务失败，不能仅上传报告后让 UI 永久 loading。

同一异常通过多个入口到达时按有限窗口/指纹去重，保留次数而不吞掉新故障。sink 失败不阻塞登录/交易，不递归调用自己；离线报告队列容量、保留期、加密/授权和重试有明确策略。

## 指标、告警与故障等级

关键路径定义成功/失败分母、超时、取消及未确认操作的归属；按应用版本、环境、平台等受控维度分组。启动成功率、关键操作失败率、crash-free 等指标采用约定口径，不混用“session 无崩溃”和“user 无崩溃”。

每个指标有观察窗口、最小样本、目标、告警阈值、去抖/恢复条件、接收负责人及 runbook。安全/不可逆数据风险不因样本少自动忽略；普通噪声不造成无休止告警。

团队定义等级，例如：业务不可用/数据风险、关键路径明显退化、局部可恢复问题。响应与修复时限依据业务设定，不在通用技能中伪造统一 SLA。值班/代班与升级路径可查，不将“监控平台已有”视为运维完成。

## 故障流程与验收

确认范围 → 指定 incident owner → 保全脱敏证据 → 按授权止损/关闭开关/发布修复 → 验证恢复 → 复盘与有 owner/期限的行动。涉及外部通知和生产操作按当前任务授权执行，技能不授予自动向用户或团队发消息的权限。

发布记录与错误报告可关联 build、commit、配置版本和符号；符号缺失应显式告警。复盘记录影响、时间线、触发与防护缺口，转为有效回归测试/监控，不追责个人代替系统改进。

至少注入：Widget 构建错误、主 isolate 异步错误、worker 失败、重复采集、sink 超时/不可用、报告含秘密、离线队列满、符号不匹配、指标分母/采样变化。测试用 fake sink；production 测试事件仅在明确授权、可识别且不污染指标时发送。
