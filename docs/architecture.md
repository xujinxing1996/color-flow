# BCMS 技术架构

> 按需加载。在做技术决策、设计 API、规划模块时引用本文件。

---

## 架构概览

```
┌─────────────────────────────────────────────────┐
│            Web 前端（Vue 3）                      │
│         配色表编辑器 / 审核界面 / 打印预览         │
└────────────────────┬────────────────────────────┘
                     │ REST API
┌────────────────────▼────────────────────────────┐
│                  API 层（Go）                     │
│   color-table  │  extraction  │  supplier  │ ... │
└──────┬─────────────┬──────────────────┬──────────┘
       │             │                  │
┌──────▼──────┐ ┌────▼──────────┐ ┌────▼──────────┐
│  业务服务层  │ │ AI 提取服务    │ │  档案服务      │
│             │ │               │ │  (Supplier/   │
│             │ │               │ │   Part Master)│
└──────┬──────┘ └────┬──────────┘ └────┬──────────┘
       │             │                  │
┌──────▼─────────────▼──────────────────▼──────────┐
│              PostgreSQL                           │
│   color_variants │ color_rows(JSONB) │ suppliers │
└───────────────────────────────────────────────────┘
                             │
                ┌────────────┴────────────┐
                │                         │
       ┌────────▼────────┐     ┌──────────▼──────┐
       │  Qwen-VL API    │     │ DeepSeek-V3 API  │
       │ （视觉提取主力） │     │ （文字二次确认）  │
       └─────────────────┘     └─────────────────┘
```

## Go 依赖清单

遵循《Let's Go Further》风格：**标准库优先，第三方库最小化**。

```
# HTTP
github.com/julienschmidt/httprouter   # 轻量路由，无中间件绑定

# 数据库
github.com/jackc/pgx/v5               # PostgreSQL 驱动，原生支持 JSONB/UUID
github.com/golang-migrate/migrate/v4  # SQL 迁移文件管理

# 认证
github.com/golang-jwt/jwt/v5          # JWT 签发与校验

# 加密
golang.org/x/crypto                   # bcrypt 密码哈希

# PDF 打印
github.com/chromedp/chromedp          # Headless Chrome，生成打印 PDF

# 标准库直接用（不引入第三方替代）
log/slog                              # Go 1.21 结构化日志
encoding/json                         # JSON 处理
flag + os.Getenv                      # 配置读取
```

**不引入**：GORM、sqlc、viper、cobra、zap（slog 足够）。

---

## 认证方案（JWT + 自维护用户表）

遵循书中模式：

```
POST /api/users           # 注册
POST /api/tokens/auth     # 登录，返回 JWT token
```

```go
// users 表
CREATE TABLE users (
  id            BIGSERIAL PRIMARY KEY,
  name          TEXT NOT NULL,
  email         TEXT UNIQUE NOT NULL,
  password_hash BYTEA NOT NULL,
  role          TEXT NOT NULL DEFAULT 'sales',  -- sales / tech / admin
  activated     BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ DEFAULT NOW()
);
```

- Token 有效期：24 小时（可配置）
- 角色字段：`sales`（营业）/ `tech`（技术）/ `admin`（管理员）
- 中间件：`requireRole("sales", "tech")` 注入路由

---

## 文件存储

### Dev 环境（Codespaces）

```
./uploads/pdfs/YYYY-MM/<uuid>.pdf
```

- 通过环境变量 `UPLOADS_DIR` 配置根目录，默认 `./uploads`
- 接口：`GET /api/pdfs/:id/raw` — 后端读文件流返回，前端 pdfjs-dist 渲染
- **禁止**前端直接访问文件路径，必须走后端代理（生产换 OSS 时只改后端）

### 生产环境（待定）

文件存储层抽象为 `FileStore` interface，dev 实现为本地磁盘，生产只需换实现：

```go
type FileStore interface {
    Save(ctx context.Context, key string, r io.Reader) error
    Get(ctx context.Context, key string) (io.ReadCloser, error)
    Delete(ctx context.Context, key string) error
}
```

候选生产实现：阿里云 OSS（国内首选）或 MinIO（自托管）。

---

## Codespaces 开发环境

### devcontainer.json 需包含

```json
{
  "image": "mcr.microsoft.com/devcontainers/go:1.23",
  "features": {
    "ghcr.io/devcontainers/features/node:1": { "version": "20" },
    "ghcr.io/devcontainers/features/postgresql:1": {}
  },
  "forwardPorts": [4000, 5173, 5432],
  "postCreateCommand": "go mod download && cd web && npm install"
}
```

- 后端端口：`4000`（书中约定）
- 前端 Vite 端口：`5173`
- PostgreSQL 端口：`5432`

### 环境变量（`.env`，不提交 git）

```bash
DATABASE_URL=postgres://bcms:password@localhost/bcms?sslmode=disable
JWT_SECRET=dev-secret-change-in-prod
UPLOADS_DIR=./uploads
QWEN_API_KEY=your-key
DEEPSEEK_API_KEY=your-key
PORT=4000
```

---

原因：
- `ColorRow` 的部件字段是动态的，需要 **JSONB** 存储配色行的动态属性
- 乐观锁基于 `updated_at`，需要数据库级别的时间戳精度
- 冲突记录、修改历史需要可靠的事务保证
- 供应商别名的模糊搜索可用 `pg_trgm` 扩展

**禁止使用**：
- 纯 NoSQL（失去事务保证）
- SQLite（不支持生产级并发）

---

## 配色行存储方案（关键决策）

选用 **JSONB + 部件模板** 方案：

```sql
-- color_rows 表
CREATE TABLE color_rows (
  id              UUID PRIMARY KEY,
  color_variant_id UUID NOT NULL REFERENCES color_variants(id),
  part_category   TEXT NOT NULL,          -- 来自预置分类
  part_name       TEXT NOT NULL,          -- 来自预置部件或自定义
  supplier_id     UUID REFERENCES suppliers(id),
  material        TEXT,
  color_code      TEXT,                   -- 存原始值，含「同色」
  color_note      TEXT,
  is_derived      BOOLEAN DEFAULT FALSE,
  confidence      FLOAT,
  source_text     TEXT,                   -- AI 提取原文
  source_bbox     JSONB,                  -- {page,x,y,w,h}，用于审核界面 PDF 高亮，可为 null
  updated_by      UUID REFERENCES users(id),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);
```

动态列通过「部件模板」（`part_templates` 表）定义每个款式类型的部件集合，前端根据模板动态渲染列。

---

## AI 提取流程

```
上传 PDF
    ↓
格式检测（A / B / C）
    ↓
[类型A] 日文表头解析 + 色卡图片 OCR
[类型B] 中文表头解析
    ↓
Qwen-VL API 提取结构化数据
    ↓
字段映射（客户字段 → 内部字段，查 customer.field_mapping）
    ↓
供应商匹配（material code → supplier_id，模糊匹配 + pg_trgm）
    ↓
推导值填充（同色规则 / 变更说明解析）
    ↓
置信度计算（LLM自估 × 格式校验系数 × 原文可溯系数）
    ↓
写入 parsed_pdfs 表（raw_extraction JSONB + status=needs_review）
    ↓
前端展示草稿，等待人工审核
```

**关键约束**：
- AI 提取结果只写 `parsed_pdfs.raw_extraction`，**不直接写** `color_rows`
- 人工点击「确认提取结果」后才写入正式表
- 每个字段携带 `confidence` 和 `source_text`

---

## 并发控制：字段级乐观锁

```
读取 color_row → 记录 updated_at (T1)
用户编辑字段值
提交修改
    ↓
SELECT updated_at FROM color_rows WHERE id = ? → T2
IF T2 > T1:
    冲突！返回 409，携带 { conflict_field, their_value, their_updated_by }
    前端弹出冲突解决 Modal
ELSE:
    UPDATE color_rows SET ..., updated_at = NOW()
    写入 color_table_history
```

冲突记录写入 `color_table_conflicts`（只写不删，用于审计）。

---

## 网页渲染原始 PDF（审核界面）

审核界面采用**左右分栏布局**：左侧展示原始 PDF，右侧展示 AI 提取草稿。

**前端方案：`pdfjs-dist`（Mozilla PDF.js）**

```
npm install pdfjs-dist
```

- Vue 组件：`PdfViewer`，封装 PDF.js canvas 渲染
- 支持翻页、缩放
- PDF 文件通过后端接口代理返回（`GET /api/pdfs/:id/raw`），不直接暴露存储路径
- PDF 原始文件存储在服务器本地或对象存储（MinIO / 阿里云 OSS）

**字段联动高亮**（重要交互）：
- 用户点击右侧某个提取字段时，左侧 PDF 对应区域高亮
- 实现依赖 AI 提取时记录的 `bbox`（边界框坐标），存入 `source_bbox: {page, x, y, w, h}`
- `color_rows.source_text` 旁边增加 `source_bbox` 字段（可选，有则高亮，无则降级只显示原文）

**PDF 存储**：
- 上传时存入 `parsed_pdfs.file_path`
- 原始文件不可删除（审核溯源依赖）
- 建议按月分目录：`uploads/pdfs/YYYY-MM/:id.pdf`

---

## 打印输出（两种方式都支持）

打印前必须执行：
1. `expandAllReferences(colorVariant)` — 展开所有「同色」引用为实际色号
2. `expandDanglingLines(colorVariant)` — 展开所有 `〜` 为完整内容
3. 输出格式：A4 横向，每行独立完整

### 方式一：浏览器打印（`window.print()`）

- 前端维护独立的 `@media print` CSS，隐藏导航栏、按钮等无关元素
- Vue 组件 `PrintPreview` 在打印模式下切换为「展开态」（无 `〜`，无引用）
- 用户点击「打印」→ 弹出打印预览页（新 tab 或 modal）→ 调用 `window.print()`
- 优点：零后端依赖，快；缺点：跨浏览器样式有差异，复杂表格可能分页错乱

### 方式二：后端生成 PDF 文件（Go）

**Go 方案：`chromedp`（Headless Chrome）**

```
go get github.com/chromedp/chromedp
```

流程：
```
前端请求 POST /api/print/:color_variant_id
    ↓
Go 后端调用 chromedp 渲染打印用 HTML 模板
    ↓
chromedp 输出 PDF bytes（A4 横向）
    ↓
返回 PDF 文件流，前端触发下载
```

- HTML 模板复用前端 `PrintPreview` 组件的样式（保持一致）
- 输出稳定，适合需要存档的场景
- 缺点：服务器需安装 Chrome / Chromium，增加部署复杂度

**替代方案**（若部署环境不允许安装 Chrome）：
- `go-wkhtmltopdf`（依赖 wkhtmltopdf 二进制）
- 纯 Go 的 `gopdf`（需手动排版，成本高，不推荐）

### 入口统一

前端打印按钮提供两个选项：
- 「快速打印」→ `window.print()`
- 「下载 PDF」→ 调后端接口生成文件

---

## 目录约定

```
src/
  api/
    routes/          # 路由定义
    middleware/      # 认证、权限、错误处理
  services/
    color-table/     # 配色表 CRUD、版本管理
    extraction/      # AI 提取、置信度计算
    supplier/        # 供应商匹配
    cascade/         # 连锁变更
    print/           # 打印输出（chromedp PDF 生成）
  db/
    schema/          # 表定义
    migrations/      # 迁移文件
    queries/         # 复杂查询
  web/
    components/
      ColorTableEditor/     # 配色表编辑器（核心组件）
      ExtractionReview/     # AI 提取审核界面（左右分栏）
        PdfViewer.vue       #   左侧：PDF 渲染（pdfjs-dist）
        ExtractionPanel.vue #   右侧：提取草稿 + 置信度标注
      PrintPreview/         # 打印预览（兼容 window.print 和后端 PDF）

uploads/
  pdfs/
    YYYY-MM/         # 原始上传 PDF，按月归档，不可删除
```