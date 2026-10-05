# 1. 应用生命周期、权限与恢复

## 职责与不变量

app 的生命周期适配层订阅 AppLifecycleListener/WidgetsBindingObserver，由 composition 连接需要恢复的业务公开能力；业务决策仍归 feature。不得建立一个包含所有业务状态的全局 lifecycle singleton。

生命周期通知可能跳过，系统终止前也可能没有回调。因此关键草稿、幂等操作记录与队列在业务提交点或受控自动保存时持久化，不能只在 paused/detached/dispose 时保存。依据 [AppLifecycleState](https://api.flutter.dev/flutter/dart-ui/AppLifecycleState.html)。

需要恢复的关键外部副作用（如支付、下单和 outbox 提交），**先原子保存稳定操作 ID/幂等键、必要请求快照、账号/租户及协议/配置版本，成功后再发送**。保存失败不得发送并宣称可恢复；不保存 token 等无关秘密。发送后结果未知，保留 unknown/needsAttention；确认结果的本地写入失败也不能把该操作当成新的未提交任务，重启先按原 ID 查证。

| 事件 | 默认策略 | 业务负责人需要明确的例外 |
| --- | --- | --- |
| inactive | 暂停依赖焦点的交互；不是确定的登出/终止 | 生物识别、来电、系统权限弹窗可能短暂打断 |
| hidden/paused | 降低轮询，释放不需要的资源；必要的后台工作转平台能力 | 音频、定位、上传需独立授权、资源预算和平台实现 |
| resumed | 合并恢复触发，检查会话作用域和数据新鲜度，再按需刷新 | 不在每次通知时重复登录、提交或创建订阅 |
| 进程冷启动 | 从受验证的持久化记录恢复，读取启动/会话状态 | 不假设内存任务、计时器或最后一次生命周期通知存在 |

恢复任务 single-flight，保留 generation/账号/租户标识；退出、换账号和新一次恢复使旧结果失效。前后台事件不是网络已恢复的证明，实际请求仍处理离线/超时。

## 恢复顺序与数据分类

1. 校验环境配置、必要存储可用性和 schema；失败进入可恢复启动状态。
2. 恢复身份并确定账号/租户命名空间；失败不能读取另一账号草稿或静默认定已登录。
3. 验证恢复的导航意图：路由、ID、授权与有效期；不从旧 BuildContext 或 Widget 对象恢复。
4. 读取允许显示的缓存/草稿，明确过期或待同步状态；按策略查询新数据。
5. 对未确认支付/提交使用稳定操作 ID 查询服务端结果，按协议继续同步；不能自动把“进行中”重演为一次新付款。

| 内容 | 默认恢复规则 |
| --- | --- |
| 导航、Tab、滚动位置 | UI restoration 或轻量展示状态；版本兼容且不携带秘密 |
| 草稿 | 业务 Repository 持久化；按账号/租户、schema、保存时间和保留期校验 |
| 缓存列表 | 仅在缓存策略允许时展示，并标明 stale/offline；不是交易事实 |
| 待提交/未确认操作 | 持久化操作 ID/幂等键，服务端查证；已有记录不能重新生成键 |
| token、权限、支付成功状态 | 安全存储/系统/后端重新验证；不从 UI restoration 信任这些事实 |

RestorationManager/RestorableProperty 管理的是 UI 状态，不替代业务数据库。采用 go_router 时单独验证导航恢复与平台配置；设置 restorationScopeId 不表示全部页面已可恢复。参考 [Android 状态恢复](https://docs.flutter.dev/platform-integration/android/restore-state-android)、[iOS 状态恢复](https://docs.flutter.dev/platform-integration/ios/restore-state-ios)。

## 权限与原生能力

请求权限由用户可理解的业务动作触发，说明目的；表示 notDetermined、granted、limited、denied、restricted 等适用状态，不把所有失败都变成一个布尔值。

系统能力适配可放 core/platform，业务需求通过本 feature 的纯契约声明；页面不直接访问 SDK。拒绝/受限制提供合适的替代路径，永久拒绝按平台能力引导设置，不循环弹权限框。

回到前台重新检查相关权限；设置中撤销权限不能沿用旧缓存授权。权限弹窗/生物识别导致的 inactive 不应清空表单或重复触发申请。

后台任务通过 iOS/Android 的正式能力执行，定义时间限制、过期取消、账号验证与可重复执行语义；持续运行的 Dart timer 不是可靠后台调度。敏感屏幕按数据分类决定后台快照遮罩及重新解锁，不默认对所有页面强制生物识别。

## 验收与责任

app owner 负责观察与装配，feature owner 定义恢复协议，平台 owner 验证权限/后台限制。至少验证：编辑中强制终止、冷启动深链、短暂系统弹窗、恢复时离线、重复 resumed、恢复与退出竞争、权限撤销、旧版草稿、操作记录保存失败、已发送但确认尚未落盘时被杀、未确认交易查询、后台任务到期。

unit 测策略和过期响应，widget 测恢复/不可恢复展示，设备验收真实进程终止、权限与平台后台行为。每项标记“已运行”“人工验证”或“未支持”，不能用热重载模拟进程恢复。
