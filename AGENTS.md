# AGENTS.md — 创作知识库（creative_kb）

> 给接手本仓库的 AI Agent 的入口说明。**先读 `docs/06-开发与维护指南.md`**，
> 那里有完整的目录结构、数据模型、约定、开发/发版流程与环境坑。

## 快速定位

- 产品：本地优先创作知识库（Flutter，Windows + Android，GitHub Releases 分发）。
- 入口：`lib/main.dart` → `lib/app.dart` → `lib/features/shell/app_shell.dart`（8 个一级入口）。
- 数据：`lib/core/db/`（drift，schemaVersion 3；表定义 `tables.dart`，迁移 `database.dart`）。
- AI：`lib/core/llm/`（OpenAI 兼容客户端、结构化输出、视觉 OCR、DeepSeek tools）。
- 设计系统：`lib/shared/theme.dart`。
- 内置书籍：`assets/books/<dir>/book.json` + `DefaultBookSeeder.assetPaths`。
- 测试：`test/` 与 `lib/` 同构；`flutter analyze` + `flutter test` 必须全绿。

## 硬性规则

1. 不改 `pubspec` 依赖版本策略之外的敏感配置；新增依赖用 `flutter pub add`。
2. 新增表：注册 + DAO + `schemaVersion` 递增 + `onUpgrade` 建表。
3. AI Key 只存 `flutter_secure_storage`；不要写入数据库或日志。
4. 所有 AI 调用必须记 `usage_log` 并受额度/单次上限约束。
5. URL 抓取必须校验 http/https、解析 IP 拒绝内网/环回、限制重定向与体积。
6. 提交前跑 `flutter analyze` 与 `flutter test`；发版走 tag `v*`，CI 自动出包。
