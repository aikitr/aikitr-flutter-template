# 规范门禁、例外与复制资源

## 1. 按顺序落地

先确定模块 owner、允许依赖和基线，再接入检查。对已有项目先迁移一个业务纵切；不能为了让样例配置通过，自动重命名全仓或放开所有层。

1. 使用架构矩阵确认现有目录归属、公开入口和装配路径，记录规则等级。
2. 从生命周期开始，依次明确数据演进、性能、观测、发布和隐私的负责人及验收场景；按业务风险实施。
3. 接入格式、分析、生成一致性和边界检查；CI 没运行的能力标为未验证。
4. 建立有截止日期的迁移例外；逐个关闭违例，再提高门禁覆盖。

必须规则如泄漏凭据、重放无幂等协议的支付、跨账号复用数据不能用“命名不同”类理由豁免。团队目录和命名偏好可以调整，但调整后的矩阵、检查策略和文档要一致。编译、解析、未分类源码、源文件逃逸及 feature 循环不能在本工具中以例外绕过。

## 2. 可复制资源

| 资源 | 用途与填写要求 |
| --- | --- |
| [PR 模板](../assets/templates/pull-request.md) | 问题、行为、实际验证、兼容与评审；只保留相关项 |
| [ADR 模板](../assets/templates/adr.md) | 需要长期追踪的决策、替代方案、后果与重评条件 |
| [例外记录](../assets/templates/exception-record.yaml) | 批准、负责人、精确规则/范围、补偿措施、到期与移除条件 |
| [性能预算](../assets/templates/performance-budget.yaml) | 定义设备、构建、条件、样本、分位数及项目目标；`null` 不能当门禁已配置 |
| [发布清单](../assets/templates/release-checklist.md) | 可追溯产物、兼容、平台与隐私验收、停发和处置 |
| [功能开关登记](../assets/templates/feature-flag-record.yaml) | 类型、离线默认、兼容、owner、到期与删除计划 |
| [边界策略](../assets/engineering_toolkit/architecture.yaml) | 单应用 Feature-first 的默认允许矩阵，按实际目录适配 |
| [Dart 检查工具](../assets/engineering_toolkit/boundary_check/bin/check_boundaries.dart) | AST 解析与机器可执行的路径边界、模块循环、例外检查 |
| [生成一致性工具](../assets/engineering_toolkit/verify_generated.py) | 提交生成源码策略下检查 tracked、新增和 ignored Dart 输出 |
| [CI 示例](../assets/workflows/flutter-quality.yaml) | 格式、分析、测试、上述检查和三个 iOS flavor 的模拟器构建 |

前六项是表单，空字段需要由项目补齐；本技能不伪造预算、审批人或测试结果。检查工具可运行且有测试；CI 是需要适配的示例，不能把 YAML 有效当作 GitHub 执行或 iOS 构建通过。

## 3. 安装与运行检查工具

从仓库根目录将配套检查工具复制到工程工具目录：

```sh
skill_dir="$PWD/.agents/skills/aikitr-flutter-enterprise-standards"
test -f "$skill_dir/SKILL.md"
test ! -e tool/architecture_checks
test ! -e architecture.yaml
test ! -e tool/verify_generated.py
test ! -e tool/test_verify_generated.py
mkdir -p tool
cp -R "$skill_dir/assets/engineering_toolkit/boundary_check" tool/architecture_checks
cp "$skill_dir/assets/engineering_toolkit/architecture.yaml" architecture.yaml
cp "$skill_dir/assets/engineering_toolkit/verify_generated.py" tool/verify_generated.py
cp "$skill_dir/assets/engineering_toolkit/test_verify_generated.py" tool/test_verify_generated.py
```

先确认目标文件不存在，已有文件做合并。该独立 Dart package 自带 `pubspec.lock`，最低 SDK 由 pubspec 与锁文件共同约束；依赖升级后重新执行它的测试。不要把它声明为应用运行时依赖。Pub workspace 需要将这个工具保留为独立工具包，或按 workspace 的解析规则调整并重验锁文件。

```sh
project_root="$PWD"
cd tool/architecture_checks
dart pub get --enforce-lockfile
dart analyze --fatal-infos
dart test
dart run bin/check_boundaries.dart \
  --root "$project_root" --config "$project_root/architecture.yaml"
```

JSON 输出包含 `findings` 与 `suppressed` 数量；退出码 `0` 无违例、`1` 有违例、`2` 检查未完成。CI 对 `1` 和 `2` 都失败，不能把配置读取错误当作通过。工具测试使用包内固定的策略 fixture，不依赖外层项目布局；项目定制矩阵另补合法/非法依赖 fixture，不修改工具测试来掩盖实际违例。

## 4. 检查覆盖与明确限制

工具扫描应用 `lib/` 下所有 Dart 文件，不自动忽略生成源码；按 YAML 首个匹配 group 分类，无匹配即失败。规范化本应用 package URI 和相对 URI，检查 import、export、URI 形式的 part/part-of 及所有条件分支；从消费者追踪 export 链的本地层及显式外部 package/dart 导出，检查 feature 图无环。跨 feature 仅批准 `from → to` 且通过 `lib/features/<to>/<to>.dart`。

- `<feature>.dart` 默认仅导出纯 Dart 模型/契约。UI/路由入口单独声明路径和 group，由 app 消费；不能把页面加入纯契约 barrel。
- `entry`、`composition` 的豁免基于 group ID 和路径，限制名单并评审变更；文件命名不是业务职责证明。
- packages/dart allowlist 按项目依赖调整，只增加该层确需的条目；不通过 `'*'` 修复纯层违例。具体 allowlist 是团队策略。
- whole-library export 采取保守判断，不按 `show/hide` 做符号级精简；不支持 named `part of`，遇到即失败。需要这类能力时扩展 library-aware 分析并加用例。
- 拒绝 lib 中 symlink，避免隐藏未检查的源码。生成器如需链接目录，应改变生成策略或明确扩展解析，不能跳过目录。
- 检查单应用的本地源码图，不解析外部包实现及其传递依赖，也不验证类型/API、包许可证或完整 Pub workspace 包图；与 `flutter analyze`、依赖图审查及消费方测试共同使用。

多包项目逐个检查适用的应用，并另加 workspace package 图与公开入口校验。不能因为本工具通过就声称“所有包依赖纯 Dart”“所有共享包无环”或“业务逻辑符合架构”。

## 5. 精确例外与到期

边界 YAML 的 `exceptions` 接受精确 `rule/source/target` 和非空 owner/reason/issue，`expires` 必须是引号包裹的真实 `YYYY-MM-DD`。截止日期为 UTC 当天零点的排他上限，例如 `2026-11-01` 从该日 `00:00 UTC` 起失败。时间测试注入固定时钟。

仅 layer、transitive_layer、cross_feature、package、dart 及 transitive_package/transitive_dart 可精确抑制；同一条边触发不同规则时分别评估，不能一个记录屏蔽所有风险。已到期记录即使代码已删除仍失败，未到期但已不匹配违例的记录也失败，要求清理记录。审批、补偿和移除条件在独立例外文档中记录；工具校验字段与匹配，不验证人的审批真伪。

`cross_feature` 是有意设计的依赖登记，记录对应 ADR 与消费者测试，仍不得形成环。临时跨 feature 实现访问属于精确例外，不能伪装为永久公开契约批准。

## 6. 生成文件和 CI 使用边界

在干净 Git 检出、锁定解析和运行所有已配置生成器后执行：

```sh
python3 tool/verify_generated.py --root .
python3 -m unittest discover -s tool -p 'test_verify_generated.py'
```

默认源码范围 lib/test/integration_test/tool；可用 `--paths` 明确新增源目录。脚本只读，比较 HEAD 与工作区（含 staged），并检查 untracked 文件及 ignored Dart 输出；排除 `.dart_tool`、Python 缓存及位于 package 根的 build/coverage，真实源码目录如 `lib/build` 仍检查。它需要仓库根和有效 HEAD，检查失败退出 `2`。默认假设相关生成 Dart 全部提交；构建时生成的项目应另定义其可重复输出/排除策略，不能直接套用本门禁。

复制 CI 后先对齐 SDK 完整 revision、版本文件、生成开关、工具位置、flavor/入口/非敏感配置路径；设置仓库变量 `XCODE_DEVELOPER_DIR` 指向已验证的 runner Xcode。iOS 示例要求三环境均存在，缺失明确失败。平台矩阵依据实际支持增删，单入口应用不强行建立三个入口。

示例无签名、部署步骤和生产 secrets，外部 checkout 固定 SHA、最小只读权限；PR 不使用 pull_request_target 执行不可信代码。macOS/Ubuntu 标签不能冻结整套 runner 镜像；记录实际 Xcode/原生工具版本，需要更强复现性时使用维护的受控镜像。模拟器 debug build 仅检查编译和配置，不替代真实配置启动、流程、profile/release 性能、签名或真机验收。
