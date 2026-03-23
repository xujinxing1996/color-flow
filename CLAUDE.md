# BCMS — Box Color Management System

箱包配色表管理系统。核心任务：将客户 PDF 转换为内部配色表，贯穿生产全流程直至打印纸质单交工厂。

## 项目结构

```
bcms/
├── CLAUDE.md
├── docs/
│   ├── architecture.md       # @docs/architecture.md
│   ├── domain-model.md       # @docs/domain-model.md
│   └── prd.md
├── .claude/
│   ├── rules/
│   │   ├── database.md
│   │   ├── ai-extraction.md
│   │   └── frontend.md
│   └── skills/
│       ├── add-api-endpoint.md
│       ├── db-migration.md
│       ├── add-vue-component.md
│       └── add-extraction-rule.md
├── cmd/
│   └── api/                  # main.go 入口
├── internal/                 # 后端核心（书中约定，不对外暴露）
│   ├── data/                 # DB 查询层（对应书中 models）
│   ├── validator/
│   └── mailer/               # 如需邮件通知
├── services/                 # 业务逻辑（提取、连锁、打印等）
│   ├── extraction/
│   ├── cascade/
│   └── print/
├── db/
│   ├── migrations/           # golang-migrate SQL 文件
│   └── seeds/
├── uploads/                  # PDF 原始文件（dev 本地，生产替换为 OSS）
│   └── pdfs/YYYY-MM/
└── web/                      # Vue 3 前端
    ├── src/
    │   ├── components/
    │   ├── composables/
    │   ├── stores/           # Pinia stores
    │   ├── router/           # Vue Router
    │   └── views/
    └── vite.config.ts
```

## 技术栈

### 前端
- **框架**：Vue 3 + `<script setup>` Composition API
- **构建**：Vite
- **路由**：Vue Router
- **状态管理**：Pinia
- **PDF 渲染**：pdfjs-dist（审核界面左侧对照）
- **UI 组件库**：待定（暂用原生 CSS）

### 后端（Go — Alex Edwards《Let's Go Further》风格）
- **HTTP 路由**：`julienschmidt/httprouter`（轻量，无魔法）
- **数据库驱动**：`pgx/v5`（原生 PostgreSQL，JSONB/UUID 支持好）
- **数据库迁移**：`golang-migrate`（SQL 文件直接管理）
- **配置**：环境变量 + `flag` 标准库（不引入 viper）
- **日志**：`log/slog`（Go 1.21 标准库，无需第三方）
- **密码哈希**：`golang.org/x/crypto/bcrypt`
- **JWT**：`golang-jwt/jwt`
- **PDF 生成（打印）**：`chromedp`（Headless Chrome）

### 数据存储
- **数据库**：PostgreSQL（必须，原因见 @docs/architecture.md）
- **文件存储**：本地磁盘（dev：Codespace 目录 `./uploads/`）
- **缓存**：无（第一期直接查 PostgreSQL）

### AI 提取（中国可用）
- **主力**：通义千问 Qwen-VL（视觉 + 日文，阿里云百炼）
- **辅助**：DeepSeek-V3（纯文字二次确认，置信度 < 0.65 时触发）
- **禁用**：Anthropic API、OpenAI API

### 开发环境
- **IDE**：GitHub Codespaces
- **当前阶段**：dev only，无 CI/CD，无 Docker

## 关键命令

```bash
# 首次初始化（Codespaces postCreate 自动执行，手动也可跑）
bash .devcontainer/setup.sh

# 后端启动
go run ./cmd/api

# 前端启动
cd web && npm run dev

# 数据库迁移
migrate -path ./db/migrations -database $DATABASE_URL up

# 回滚最近一次迁移
migrate -path ./db/migrations -database $DATABASE_URL down 1

# 运行后端测试
go test ./...

# 运行前端测试
cd web && npm run test
```

## Skills（按需 @ 引用）

| 场景 | 引用方式 |
|------|---------|
| 新增 Go API 端点 | `@.claude/skills/add-api-endpoint.md` |
| 新建数据库迁移 | `@.claude/skills/db-migration.md` |
| 新增 Vue 组件 | `@.claude/skills/add-vue-component.md` |
| 新增提取/推导规则 | `@.claude/skills/add-extraction-rule.md` |

## 核心领域概念（必须理解）

**第一核心对象是配色表，不是订单，不是 PDF。**

- `Style`（款式）→ `ColorVariant`（颜色变体，最小操作单元）→ `ColorRow`（配色行）
- 颜色变体 = 款号 + 颜色，是所有业务操作的最小单位
- 配色行字段是动态的，不同款式部件不同，**不能用固定列存储**
- 「同色」是引用，不是值；存储原始值，渲染时解析

完整领域模型见 @docs/domain-model.md

## 不可违反的设计决策

1. **配色行必须用 JSONB 或 EAV 存储**，禁止为部件名新增固定列
2. **「同色」存原始字符串**，禁止在写入时展开为实际色号
3. **AI 只输出草稿 + 置信度**，禁止直接写入正式配色表
4. **乐观锁粒度为字段级**，禁止整表锁
5. **打印输出必须展开所有引用**，禁止输出含「同色」的纸质单

## 第一期范围

- ✅ 支持：类型 A PDF（BEEM 内部指示书）、类型 B PDF（外部规范型）
- ✅ 支持：翻单（同款换色）
- ✅ 支持：Excel 历史数据导入
- ❌ 不支持：类型 C PDF（自由型）
- ❌ 不支持：跨款复用翻单、移动端、工厂在线访问

## 代码规范

- 所有数据库字段命名用 `snake_case`
- 业务层函数命名用领域术语（如 `resolveColorReference`，不用 `expandValue`）
- AI 提取相关代码统一放 `src/services/extraction/`
- 置信度计算逻辑见 @docs/domain-model.md#置信度模型