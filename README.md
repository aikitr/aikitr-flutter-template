# Flutter iOS 应用模板

一套可以复制后直接运行的 iOS Flutter 项目起点。开发环境默认使用本地演示登录和固定内容数据，不依赖后端；staging、prod 不会退回演示数据，接入业务数据实现前会明确显示配置提示。

## 技术与目录

模板固定使用 `.fvmrc` 中的 Flutter 稳定版，并提交 `pubspec.lock`。主要依赖是 Riverpod 3（状态与依赖注入）、go_router（路由）、Dio（网络）、Freezed 与 json_serializable（不可变模型）、SharedPreferencesAsync（非敏感设置）、flutter_secure_storage（Keychain 凭据）、Flutter Localizations 与 ARB（中文和英文）。UI 采用 Cupertino，并统一维护主题与间距。

```text
lib/
├── app/                 # 启动配置、路由、主题、国际化
├── core/                # 网络、异常、存储、通用 UI
└── features/
    ├── auth/            # 会话契约、演示实现、登录与启动页面
    ├── articles/        # 列表、详情、分页、模型与数据源
    └── settings/        # 主题、语言与组件展示
```

页面只处理展示和交互；Controller/AsyncNotifier 管页面状态；Repository 隔离数据来源。先把模型和 Repository 契约放在对应 feature 中。只有当业务规则复杂或被多个模块复用时，再增加 UseCase，避免预先堆空层。

## 企业级工程规范

仓库内置项目级 Flutter/Dart 规范技能，覆盖目录与依赖边界、命名与组件、生命周期恢复、数据迁移、性能、隐私、测试和发布。查看 [技能入口](.agents/skills/aikitr-flutter-enterprise-standards/SKILL.md)，其中也包含可复制的检查工具、CI 示例和团队模板。

## 环境准备与首次运行

需要 macOS、Xcode（含 iOS Simulator）和能运行 Flutter iOS 工程的稳定 Flutter SDK。可以用 FVM 安装项目固定版本：

```sh
dart pub global activate fvm
fvm install
fvm flutter doctor -v
fvm flutter pub get
fvm dart run build_runner build
fvm flutter gen-l10n
fvm flutter run \
  --flavor dev \
  --target lib/main_dev.dart \
  --dart-define-from-file=config/dev.json
```

安装并启动 iOS 模拟器后，也可以直接在 IDE 中选 `dev` Scheme。最低部署版本为 iOS 15。当前开发环境若没有完整 Xcode，可运行 Dart 分析和单元测试，但无法本地构建或启动 iOS 模拟器。

## 环境与数据实现

Xcode 共享 Scheme 与 Flutter 入口对应如下：

| Scheme | Dart 入口 | Bundle ID 后缀 | 初始数据行为 |
|---|---|---|---|
| `dev` | `lib/main_dev.dart` | `.dev` | 本地演示登录和固定文章 |
| `staging` | `lib/main_staging.dart` | `.staging` | 必须配置真实 SessionRepository 和 API |
| `prod` | `lib/main_prod.dart` | 无 | 必须配置真实 SessionRepository 和 API |

`config/dev.json`、`config/staging.json`、`config/prod.json` 只放非敏感编译参数，例如 API 地址：

```json
{
  "API_BASE_URL": "https://api.example.com"
}
```

用对应配置运行或构建：

```sh
fvm flutter run --flavor staging --target lib/main_staging.dart \
  --dart-define-from-file=config/staging.json

fvm flutter build ios --simulator --no-codesign \
  --flavor prod --target lib/main_prod.dart \
  --dart-define-from-file=config/prod.json
```

首版没有假设真实认证 API。开发环境的 `SessionRepository.signIn()` 和登录页是无凭据的演示实现。接入真实认证时，除了在 `features/auth/application/session_controller.dart` 的 `sessionRepositoryProvider` 绑定业务 Repository，还需要按业务身份认证方式替换 `features/auth/presentation/login_page.dart`，并为登录凭据扩展 Repository/Controller 契约；模板不会在 staging/prod 显示演示登录入口。文章数据在 `features/articles/application/article_providers.dart` 绑定对应 `ArticleRepository`。prod/staging 的 API 地址缺失时网络 Provider 会返回配置异常，不会偷偷切换到演示内容。Dio 统一处理超时、请求取消、异常映射和不含查询参数/请求体的日志；401 会通知会话失效。Token 刷新应在后端协议确定后放入认证数据层。

默认 REST 文章示例使用：

- `GET /articles?page=1&pageSize=5`，响应包含 `items` 与 `hasMore`；每个条目有 `id`、`title`、`summary`、`body`、`author`。
- `GET /articles/{id}`，响应为同一文章对象；不存在时返回空对象或由 Repository 映射为 `null`。

这是接入边界示例，不代表真实后端协议。按项目 API 改 `RestArticleRepository` 的路径和响应映射即可。

敏感凭据放 Keychain，不放配置 JSON 或 SharedPreferences。设置项使用异步 SharedPreferences API，并按应用标识与环境隔离 Keychain 会话键名。

## 新增业务模块

1. 在 `lib/features/<feature>/` 新建 `presentation/`、`application/`、`data/`、`domain/`。
2. 在 `domain/` 声明业务模型与 Repository 抽象；不可变 JSON 模型用 Freezed 和 `fromJson`。
3. 在 `data/` 实现本地或网络 Repository，在 `application/` 声明 Riverpod Provider/AsyncNotifier。
4. 页面在 `presentation/` 订阅状态并调用 Controller；把页面状态转换成现有 `AppAsyncView`、`AppErrorView` 等组件。
5. 在 `lib/app/app_router.dart` 注册路由。需要登录的页面默认经过会话访问控制。
6. 为 Repository、Controller 和关键页面行为补测试。跨模块或复杂业务规则增长时，再提取 UseCase。

常用通用组件位于 `lib/core/ui/`：`AppPage`、`AppNavigationBar`、`AppButton`、`AppInputField`、`AppAsyncView`、`AppLoadingView`、`AppEmptyView`、`AppErrorView`、`AppPaginatedList`，以及确认弹窗和 Action Sheet。进入“设置 → 组件展示”查看运行示例。颜色、字体和圆角集中在 `lib/app/theme/app_theme.dart`，页面文本放入中英文 ARB。

修改模型或文案后重新生成：

```sh
fvm dart run build_runner build
fvm flutter gen-l10n
```

Freezed 和本地化生成文件需要提交。分析与测试：

```sh
fvm dart format --output=none --set-exit-if-changed lib test tool integration_test
fvm flutter analyze --fatal-infos
fvm flutter test
```

在已启动的 iOS 模拟器上跑端到端流程：

```sh
fvm flutter test integration_test/app_flow_test.dart \
  --flavor dev \
  -d <模拟器设备 ID> \
  --dart-define-from-file=config/dev.json
```

## 复制为新项目

先准备一个不存在或空的目标目录，再运行：

```sh
dart run tool/initialize_template.dart \
  --target ../weather-app \
  --project-name weather_app \
  --display-name "天气" \
  --bundle-id com.example.weather
```

复制工具会更新 Dart 包名、iOS Bundle ID、显示名称、ARB 文案和模板元信息；dev 与 staging 自动使用 `com.example.weather.dev`、`com.example.weather.staging`。目标目录非空时会拒绝写入。`.git`、IDE 配置、依赖缓存和构建产物不会复制。生成后按首次运行步骤执行即可。

## iOS 签名与发布

在 Xcode 打开 `ios/Runner.xcodeproj`，为 Runner target 配置 Apple Developer Team、签名方式及业务所需的权限描述与能力。正式包通过带 `config/prod.json` 的 Flutter 构建命令生成，确保编译时环境参数与 prod Scheme 一致：

```sh
fvm flutter build ipa \
  --flavor prod \
  --target lib/main_prod.dart \
  --dart-define-from-file=config/prod.json
```

构建完成后上传 `build/ios/ipa/` 下的归档包到 App Store Connect。也可以用 Xcode Organizer 管理归档，但需要确保该次 Flutter Archive 已按业务配置传入 prod Dart define。开发和预发布版本会带环境后缀且显示名称带环境标记。首次接入推送、Apple 登录等原生能力时，再按能力要求添加 entitlements、隐私用途文案和证书配置。

## 自动检查与后续能力

GitHub Actions 会检查 Dart 格式、静态分析、测试、代码生成是否最新，在 macOS 上分别构建 dev/staging/prod iOS Simulator 版本，并在 dev 模拟器运行登录、浏览、设置持久化与退出的端到端流程。推送通知放入通知/设备令牌模块，数据库放入具体 feature 的 Repository 实现，内购放入独立购买 feature，Apple 登录接入 SessionRepository，崩溃监控接入启动层日志适配器。首版不预置这些服务，也不把它们混进通用 UI 层。
