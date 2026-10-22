# 创作知识库（creative_kb）

面向小说等创作场景的本地知识库应用：**灵感碎片 → AI 整理 → 结构化资料库 → 检索复用**。
Flutter 单代码库，支持 **Windows 桌面** 与 **Android**。数据 100% 本地（SQLite），UI 全中文。

## 功能（v1）

- **灵感碎片**：快捷录入（Ctrl+Enter 提交）、AI 优化（纠错/提炼/多主题拆分/打标签）、
  原始与 AI 双版本对比、转提示词草稿 / 转资料条目、换强度重新优化
- **提示词库**：小说/绘画/Agent 三类模板，从碎片生成 3 风格版本对比保存、
  定向优化（压缩/扩写/适配模型/风格转换）、变量提取与填充复制、版本历史与一键回滚
- **创作资料库**：五步入库向导（粘贴/文件导入 → AI 清洗分类 → Schema 校验映射 → 预览 → 入库）、
  **AI 搜集**（DeepSeek Search/Fetch 联网收集资料 → 自动结构化 → 预览入库）、
  内置 4 套分类 Schema（通用/历史官职/仙侠宝物/宗门势力），用户可编辑/新增（JSON 热加载）、
  分类树、条目双向关联跳转、FTS5 关键词 + 语义混合检索（未配置嵌入模型自动降级并提示）、极速入库模式
- **Agent 中枢**：多厂商 API Key（DeepSeek/通义千问/豆包/智谱/自定义；Key 只写系统安全存储，
  数据库仅存引用名；输入框支持粘贴）、一键拉取模型并自动打标签（可手动修正）、4 档思考强度、
  任务队列（重试/超时/额度拦截）、全链路 token 记账与单次/单日额度防护、数据导出导入（zip）
- **用量统计**：今日/累计 token、按模块与模型图表、最近明细与费用参考（内置价格表，查不到只记 token）
- **更新检查**：发布仓库内置，一键检查最新版本（无需配置）；Android 应用内下载并拉起安装，
  桌面打开 Release 页；启动自动检查可关
- 响应式导航：宽度 ≥900 侧栏（NavigationRail）/ 700–899 折叠 / <700 底部导航（NavigationBar）；
  首启无配置时各页面均有空态引导

## 技术栈

Flutter（Material 3 中文）· flutter_riverpod · drift（SQLite + FTS5 trigram）· dio（OpenAI 兼容 SSE）
· flutter_secure_storage · flutter_markdown · archive（备份 zip）· open_filex（APK 安装）· window_manager（Windows 默认 1200×800，最小 900×600）

## 目录结构（关键部分）

```
lib/
├── main.dart            # 入口：窗口初始化、换入待导入库文件、打开数据库、首启 seed
├── app.dart             # MaterialApp、主题、中文本地化、命名路由 → 页面接线
├── core/
│   ├── router.dart      # 路由常量表（定稿，只允许追加）
│   ├── db/              # drift 表结构/数据库/13 个 DAO（tables.dart、database.dart 定稿）
│   ├── llm/             # OpenAI 兼容客户端（SSE 手解析）、厂商预设、模型标签、强度、结构化输出
│   ├── tasks/           # 任务队列（状态机/重试/超时/额度）与 token 记账
│   ├── search/          # FTS5 加权 + 向量余弦混合检索
│   ├── storage/         # API Key 安全存储封装
│   ├── update/          # GitHub Releases 更新检查（semver 比对）
│   └── seed/            # 内置 Schema、intensity 预设、价格表、首启种子逻辑
├── features/
│   ├── shell/           # 响应式导航壳 + 启动更新检查
│   ├── fragments/       # 灵感碎片（录入/优化/双版本/转化跳转）
│   ├── prompts/         # 提示词库（生成/优化/变量/版本）
│   ├── kb/              # 资料库（向导/分类树/详情/检索/Schema 注册表）
│   ├── usage/           # 用量看板
│   └── settings/        # 设置（厂商 Key/强度/额度/Schema/更新/导出导入）
└── shared/              # 跨模块组件（EmptyState/TagChipList）
```

## 快速上手

1. 启动应用 → 五个页面可直接浏览（无 Key 时 AI 按钮置灰并给出引导）
2. 「设置 → 厂商与 API Key」添加厂商（如 DeepSeek）并粘贴 API Key → 点「拉取模型」
3. 在灵感页随手记一条灵感，勾选「AI 优化后保存」体验整理流水线
4. 需要语义检索时，在厂商模型列表中把 embedding 模型的「向量化」标签启用即可

## 本地构建

环境：Flutter stable（开发基于 3.47.x）。Windows 桌面构建需 VS C++ 桌面负载，Android 需 SDK。

```bash
# 国内镜像（建议写入用户环境变量）
export PUB_HOSTED_URL=https://pub.flutter-io.cn
export FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn

flutter pub get
flutter run -d windows          # 或 -d <android-device>
flutter analyze                 # 0 error
flutter test                    # 全绿
```

drift 代码生成（修改 `lib/core/db/tables.dart` 或 DAO 后必须重跑）：

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 数据目录（运行时）

`getApplicationSupportDirectory()/creative_kb/` 下：

- `app.db` —— SQLite 数据库（含 kb_fts FTS5 虚表与同步触发器）
- `schemas/` —— 分类 Schema JSON，首启写入内置 Schema，可直接编辑/新增（保存即热加载）
- `exports/` —— 「设置 → 数据导出/导入」的 zip 落盘目录（含数据库一致性快照 + schemas + 版本清单；
  导入前自动再备份一份，导入后重启应用生效）

## 发版流程

1. 修改 `pubspec.yaml` 的 `version`（语义化 `major.minor.patch`，是应用内更新检查的唯一版本来源）
2. 提交并打 tag：`git tag v0.1.1 && git push origin v0.1.1`
3. GitHub Actions 自动构建（`.github/workflows/release.yml`）：
   Windows 便携 zip（`creative_kb-windows-amd64.zip`）+ Android APK（`creative_kb-android.apk`），
   连同自动生成的 Release Notes 发布到 GitHub Releases
4. 用户端「设置 → 更新检查」即可发现新版：桌面打开 Release 页下载，Android 直接下载 APK 安装

> 应用内更新仓库名在「设置 → 更新检查」配置（`owner/repo`），发布前请改成真实仓库；
> 仓库未发布任何 Release（404）时检查静默跳过。

## CI

- `.github/workflows/ci.yml`：push / PR → `flutter pub get` → `flutter analyze` → `flutter test`
- `.github/workflows/release.yml`：push `v*` tag → 构建 Windows zip 与 Android APK 并发 Release

## FAQ

- **pub 下载慢/失败**：配置上方两个镜像环境变量后重试
  （`PUB_HOSTED_URL=https://pub.flutter-io.cn`、`FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`）。
- **Windows 提示 Developer Mode / 符号链接**：不影响 `analyze`/`test`；仅插件本地构建需要开发者模式。
- **`flutter test` 首次运行**：sqlite3 包会下载预编译 SQLite 库；若 GitHub 访问超时，重试即可，
  亦可在 `pubspec.yaml` 的 `hooks.user_defines.sqlite3` 配置 `source: system` 等替代来源
  （注意系统 winsqlite3.dll 不含 FTS5，仅适合无检索的纯编译验证）。
- **Android 安装提示「未知来源应用」**：这是未上架应用的正常系统提示，允许安装即可；
  应用仅在使用 AI 功能时访问所选厂商 API 与 GitHub 更新检查，不请求其他敏感权限。
- **API Key 存在哪**：Windows 凭据管理器 / Android Keystore（flutter_secure_storage），
  数据库只保存引用名；删除厂商时同步清除密文。
- **导入备份后界面没变化**：数据库文件在下次启动时换入，重启应用即可。

## 截图

（占位：灵感 / 资料库 / 设置 三张截图，发版前补充）
