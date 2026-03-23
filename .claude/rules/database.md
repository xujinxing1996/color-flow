---
globs: ["src/db/**", "src/services/**/*.ts", "src/services/**/*.py"]
---

# 数据库规则

## 数据库访问规范（pgx/v5）

- 使用 `pgx/v5`，**不用** `database/sql` 或 GORM
- 查询统一放 `internal/data/` 目录（对应书中 models 层），不在 handler 层写 SQL
- JSONB 字段使用 `pgtype.JSONB` 或直接序列化为 `[]byte`
- UUID 使用 `pgtype.UUID`，不用 `string` 传参
- 所有查询必须传入 `context.Context`，超时设置在 handler 层

```go
// 标准查询模式（书中风格）
func (m ColorRowModel) Get(ctx context.Context, id pgtype.UUID) (*ColorRow, error) {
    query := `SELECT id, part_category, ... FROM color_rows WHERE id = $1`
    ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
    defer cancel()
    // ...
}
```



### color_rows 表
- `color_code` 字段存储原始值，**禁止在写入时展开「同色」**
- 新增部件类型时**禁止**在 color_rows 表加固定列，使用现有字段或 part_templates
- `updated_at` 必须由数据库自动维护（`DEFAULT NOW()` + trigger），不由应用层设置
- `is_derived = true` 的行在计算置信度时跳过，单独标注

### color_table_conflicts 表
- 只允许 INSERT，**禁止 UPDATE / DELETE**
- 所有并发冲突必须写入此表，不得静默丢弃

### color_table_history 表
- 每次 color_rows 字段变更必须同步写入
- `old_value` 和 `new_value` 存字符串（含原始「同色」引用）

## 查询规范

- 供应商模糊搜索使用 `pg_trgm`（`similarity()` 或 `%` 操作符），不用 `LIKE '%x%'`
- 读取 color_variant 时带上所有 color_rows，避免 N+1
- 置信度过滤查询（如「所有需确认的行」）在 DB 层过滤，不在应用层遍历

## 迁移规范

- 迁移文件名格式：`YYYYMMDD_HHMMSS_description.sql`
- 每次迁移必须包含 rollback 语句
- 禁止在迁移中硬编码数据（供应商初始数据走 seed 文件）
