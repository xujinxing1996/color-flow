# BCMS 领域模型参考

> 按需加载。在处理业务逻辑、数据库 schema、AI 提取时引用本文件。

---

## 数据模型

```
Customer（客户）
  ├── pdf_format_type: 'A' | 'B' | 'C'
  └── field_mapping: JSONB          -- 客户字段 → 内部字段映射

Style（款式）
  ├── style_code                    -- 如 FF-8566-2
  ├── style_name, size, factory, customer, due_date
  └── ColorVariant[]

ColorVariant（颜色变体 = 最小操作单元）
  ├── color_code                    -- 如 IVORY / GRAY / BK
  ├── color_name
  ├── version: number               -- 每次修改递增，乐观锁依据
  ├── locked_by / locked_at
  └── ColorRow[]

ColorRow（配色行）
  ├── part_category                 -- 面料 / 辅料 / 五金 / 塑料件 / 印花…
  ├── part_name                     -- 本体 / 内衬 / 缝线…
  ├── supplier_id → Supplier
  ├── material                      -- 如 579可堤拉防水PU
  ├── color_code                    -- 如 28#本白，或「同色」（存原始值）
  ├── color_note
  ├── is_derived: boolean           -- 推导值不参与置信度计算
  ├── confidence: float             -- 0~1，界面转为状态标签显示
  ├── source_text                   -- AI 提取时的原文，用于审核溯源
  ├── updated_by → User
  └── updated_at                    -- 乐观锁检测字段

Supplier（供应商）
  ├── name
  ├── alias: string[]               -- 多别名，用于模糊匹配 PDF 中的材料代号
  ├── specialty: string[]
  └── MaterialCode[]
        ├── code                    -- 如 28 / DL-4244
        ├── color_name
        └── color_rgb               -- 可选，用于打印色块

Order（订单）
  ├── color_variant_id
  ├── quantity
  ├── status: 'pending' | 'confirmed' | 'in_production'
  └── source_pdf_id → ParsedPDF

ParsedPDF（AI 解析记录）
  ├── pdf_format_type: 'A' | 'B'
  ├── raw_extraction: JSONB
  ├── review_status: 'needs_review' | 'approved'
  └── CorrectionLog[]

ColorTableHistory（字段修改历史）
  ├── color_variant_id
  ├── changed_by, changed_at
  ├── field_name, old_value, new_value

ColorTableConflict（并发冲突记录，只写不删）
  ├── color_row_id
  ├── user_a, user_b
  ├── value_a, value_b
  ├── resolved_by, resolved_value
```

---

## 「同色」引用解析规则

| 原始值 | 解析为 |
|--------|--------|
| `同色` / `面料同色` / `表地同色` | 同行本体（`part_name = '本体'`）的 `color_code` |
| `各色共通` | 所有颜色变体此字段值相同 |
| `数据见附件` | 标记 `is_external_ref = true`，不存储具体值 |

**实现要点**：
- DB 存原始字符串（`color_code = '同色'`）
- 读取时执行 `resolveColorReference(row, variant)` 展开
- 打印时必须展开，禁止输出原始引用

---

## 置信度模型

```
综合置信度 = LLM自估 × 格式校验系数 × 原文可溯系数
```

格式校验系数：

| 条件 | 系数 |
|------|------|
| supplier_id 命中 Supplier 表 | ×1.0 |
| 供应商未命中 | ×0.6 |
| 色号符合已知格式 | ×1.0 |
| 色号格式无法识别 | ×0.7 |
| 部件名成功映射到预置分类 | ×1.0 |
| 部件名无法映射 | ×0.8 |

原文可溯系数：

| 条件 | 系数 |
|------|------|
| `source_text` 非空 | ×1.0 |
| `source_text` 为空 | ×0.8 |
| `is_derived = true` | 不参与计算，单独标注 |

界面展示（禁止显示数字）：

| 置信度 | 标签 | 颜色 |
|--------|------|------|
| ≥ 0.85 | 自动通过 | 绿色 |
| 0.65–0.85 | 需确认 | 橙色 |
| < 0.65 | 请核查 | 红色 |
| is_derived = true | 推导值 | 灰色 |

---

## 连锁变更规则

| 主字段变更 | 需确认的关联字段 |
|-----------|----------------|
| 本体色号 | 缝线、包边带、拉链、拉链头、金属件 |
| 内衬色号 | 内衬印花底色 |
| 织带色号 | 织带印花底色 |
| 金属件规格 | 拉链头 |

规则存储在 `cascade_rules` 表，管理员可配置，不硬编码。

---

## 部件分类体系（预置）

```
面料：本体 / 内衬（裏地）/ 保冷材 / 拉片
辅料：缝线 / 包边带 / 织带（背带/前片/持ち手）/ 合皮配件
印花/外协：丝网印花 / 橡胶印花 / 刺绣 / 织带印花
五金：拉链 / 拉链头 / 磁扣/插锁 / 调节扣（三档）/ 装饰件
塑料件：调节扣（塑料）/ 插锁（塑料）
织标/名牌：品牌织标 / 品番ネーム
内件：内袋布 / 保冷袋内衬
```

分类规则：
- 金属件和塑料件必须分开（统一改亚镍时塑料件不受影响）
- 缝线归辅料，不单独设顶级分类

---

## 审核状态流转

```
草稿 → 待审核 → 审核中 → 已确认
                        ↘ 已打回 → 草稿（营业修改后重新提交）
```

---

## 术语对照（中文 ↔ 日文）

| 中文 | 日文 |
|------|------|
| 款式 | 品番 |
| 颜色变体 | 色番 / COL |
| 配色表 | カラー表記 / 配色指示書 |
| 本体面料 | 本体 / 素材1 |
| 内衬 | 裏地 / 素材4 |
| 缝线 | 縫製糸 / ステッチ |
| 织标 | 織りネーム |
| 三档扣 | 調節コキ |
| 保冷材 | 保冷シート / 銀色のシート |
| 亚镍 | つや消しSV |
