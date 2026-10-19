# 创作知识库（creative_kb）

面向小说等创作场景的本地知识库应用：**灵感碎片 → AI 整理 → 结构化资料库 → 检索复用**。
Flutter 单代码库，支持 **Windows 桌面** 与 **Android**。数据 100% 本地（SQLite），UI 全中文。

## 功能（v1）

- **灵感碎片**：快捷录入、AI 优化（纠错/提炼/拆分/打标签）、原始与 AI 双版本存储、转提示词/资料条目
- **提示词库**：从碎片生成 3 风格版本、定向优化（4 方向）、变量提取与填充、版本历史与回滚
- **创作资料库**：五步入库向导、内置 4 套分类 Schema（通用/历史官职/仙侠宝物/宗门势力）且用户可扩展、
  双向关联条目、FTS5 关键词 + 语义混合检索（未配置嵌入模型时自动降级 FTS5）
- **Agent 中枢**：多厂商 API Key（DeepSeek/通义/豆包/智谱/自定义，Key 走系统安全存储，不进数据库）、
  模型拉取与启发式标签、4 档思考强度、任务队列、全链路 token 记账与单次/单日额度防护
- **用量统计**：今日/累计 token、按模块与模型图表、费用参考（内置价格表，查不到只记 token）
- 响应式导航：宽度 ≥900 侧栏（NavigationRail）/ <700 底部导航（NavigationBar）

## 技术栈

Flutter（Material 3 中文）· flutter_riverpod · drift（SQLite + FTS5 trigram）· dio（OpenAI 兼容 SSE）
· flutter_secure_storage · flutter_markdown · window_manager（Windows 默认 1200×800，最小 900×600）

## 目录结构（关键部分）

```
lib/
├── main.dart            # 入口：窗口初始化、打开数据库、首启 seed
├── app.dart             # MaterialApp、Material 3 主题（深青 seed）、中文本地化
├── core/
│   ├── router.dart      # 路由常量表（定稿，只允许追加）
│   ├── db/              # drift 表结构/数据库/13 个 DAO（tables.dart、database.dart 定稿）
│   └── seed/            # 内置 Schema、intensity 预设、价格表、首启种子逻辑
├── features/
│   ├── shell/           # 响应式导航壳（Rail/BottomBar 切换）
│   └── fragments|prompts|kb|usage|settings/   # 五大模块（骨架期均为占位页）
└── shared/              # 跨模块占位组件（PlaceholderPage/EmptyState/TagChipList）
```

## 本地构建

环境：Flutter stable（开发基于 3.47.x）。Windows 桌面构建需 VS C++ 桌面负载，Android 需 SDK。

```bash
# 国内镜像（建议写入用户环境变量）
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

flutter pub get
flutter run -d windows          # 或 -d <android-device>
flutter analyze && flutter test
```

drift 代码生成（修改 `lib/core/db/tables.dart` 或 DAO 后必须重跑）：

```bash
dart run build_runner build
```

## 数据目录（运行时）

`getApplicationSupportDirectory()/creative_kb/` 下：

- `app.db` —— SQLite 数据库（含 kb_fts FTS5 虚表与同步触发器）
- `schemas/` —— 分类 Schema JSON，首启写入 4 套内置 Schema，可直接编辑/新增（热加载）
- `exports/` —— 数据导出目录

## 发版流程

修改 `pubspec.yaml` 的 `version`（语义化）→ 打 `v*` tag → GitHub Actions 构建
Windows 便携 zip 与 Android APK 并发布到 Releases（CI 配置见 `.github/workflows/`，由集成收尾任务交付）。

## FAQ

- **pub 下载慢/失败**：配置上方两个镜像环境变量后重试。
- **Windows 提示 Developer Mode / 符号链接**：不影响 `analyze`/`test`；仅插件本地构建需要开发者模式。
- **`flutter test` 首次运行**：sqlite3 包会下载预编译 SQLite 库；若 GitHub 访问超时，重试即可，
  亦可在 `pubspec.yaml` 的 `hooks.user_defines.sqlite3` 配置 `source: system` 等替代来源
  （注意系统 winsqlite3.dll 不含 FTS5，仅适合无检索的纯编译验证）。
- **Android 安装提示未知来源**：允许安装即可，应用不请求网络以外任何敏感权限。

## 截图

（占位：UI 完成后补充灵感/资料库/设置三张截图）
