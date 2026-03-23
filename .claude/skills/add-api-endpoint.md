# Skill: 新增 Go API 端点

> 使用方式：`@.claude/skills/add-api-endpoint.md`
> 适用场景：新增一个完整的 REST 端点（含路由、handler、service、DB query）

---

## 步骤

### 1. 确认接口契约

先明确以下内容再动手：
- HTTP 方法 + 路径（如 `POST /api/color-variants/:id/rows`）
- 请求体结构（JSON）
- 响应体结构（JSON）
- 需要的权限（营业 / 技术 / 管理员）

### 2. 定义请求/响应结构体

在 `src/api/types/` 下新增或复用已有文件：

```go
// 请求体
type CreateColorRowRequest struct {
    PartCategory string  `json:"part_category" validate:"required"`
    PartName     string  `json:"part_name" validate:"required"`
    SupplierID   *string `json:"supplier_id"`
    Material     string  `json:"material"`
    ColorCode    string  `json:"color_code"`
    ColorNote    *string `json:"color_note"`
}

// 响应体
type ColorRowResponse struct {
    ID          string  `json:"id"`
    PartCategory string `json:"part_category"`
    // ... 其余字段
    Confidence  *float64           `json:"confidence,omitempty"`
    SourceText  *string            `json:"source_text,omitempty"`
    UpdatedAt   time.Time          `json:"updated_at"`
}
```

### 2. 在 `internal/data/` 定义查询层

路径：`internal/data/<模型名>.go`（对应书中 models）

```go
type ColorRowModel struct {
    DB *pgxpool.Pool
}

func (m ColorRowModel) Insert(ctx context.Context, row *ColorRow) error {
    query := `
        INSERT INTO color_rows (color_variant_id, part_category, part_name, ...)
        VALUES ($1, $2, $3, ...)
        RETURNING id, updated_at`

    ctx, cancel := context.WithTimeout(ctx, 3*time.Second)
    defer cancel()

    return m.DB.QueryRow(ctx, query,
        row.ColorVariantID, row.PartCategory, row.PartName, ...,
    ).Scan(&row.ID, &row.UpdatedAt)
}
```

**注意**：
- 所有写操作必须同步写 `color_table_history`
- `updated_by` 使用传入的 `actorID`，不从 context 隐式取
- `color_code` 存原始值，不展开「同色」

### 3. 在 handler 层绑定路由（httprouter 风格）

路径：`cmd/api/<模块名>.go`（书中约定）

```go
// app 结构体挂载所有依赖（书中 application struct）
func (app *application) createColorRowHandler(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
    variantID := ps.ByName("id")

    var input struct {
        PartCategory string  `json:"part_category"`
        PartName     string  `json:"part_name"`
        ColorCode    string  `json:"color_code"`
    }
    if err := app.readJSON(w, r, &input); err != nil {
        app.badRequestResponse(w, r, err)
        return
    }

    // 从 context 取当前用户（书中 contextGetUser 模式）
    user := app.contextGetUser(r)

    row, err := app.services.ColorTable.CreateColorRow(r.Context(), variantID, input, user.ID)
    if err != nil {
        app.serverErrorResponse(w, r, err)
        return
    }
    app.writeJSON(w, http.StatusCreated, envelope{"color_row": row}, nil)
}
```

路由注册在 `cmd/api/routes.go`：
```go
router.HandlerFunc(http.MethodPost,
    "/v1/color-variants/:id/rows",
    app.requireRole("sales")(app.createColorRowHandler),
)
```

### 4. 权限中间件

书中 `requireAuthenticatedUser` 基础上扩展角色检查：

```go
func (app *application) requireRole(roles ...string) httprouter.Handle {
    return func(w http.ResponseWriter, r *http.Request, ps httprouter.Params) {
        user := app.contextGetUser(r)
        for _, role := range roles {
            if user.Role == role {
                next(w, r, ps)
                return
            }
        }
        app.notPermittedResponse(w, r)
    }
}
```

### 5. 写单元测试

路径：`src/services/<模块名>/<功能>_test.go`

至少覆盖：
- 正常创建成功
- `color_variant` 不存在时返回 404
- 并发冲突时返回 409（如适用）

### 6. 检查清单

- [ ] 请求体有 `validate` tag
- [ ] 响应体不暴露内部 ID 格式（用 UUID string）
- [ ] 写操作有对应 `color_table_history` 记录
- [ ] 路由已注册
- [ ] 测试已补充
