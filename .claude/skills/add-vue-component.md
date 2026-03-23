# Skill: 新增 Vue 3 组件

> 使用方式：`@.claude/skills/add-vue-component.md`
> 适用场景：新建一个业务组件或页面

---

## 组件文件结构

```
src/web/components/<功能模块>/
  <ComponentName>.vue       # 主组件
  <ComponentName>.test.ts   # 单元测试（可选，复杂组件必须）
  index.ts                  # 统一导出（模块有多个组件时）
```

---

## 标准组件模板

```vue
<script setup lang="ts">
import { ref, computed } from 'vue'

// --- Props ---
interface Props {
  colorVariantId: string
  readonly?: boolean
}
const props = withDefaults(defineProps<Props>(), {
  readonly: false,
})

// --- Emits ---
const emit = defineEmits<{
  saved: [rowId: string]
  cancelled: []
}>()

// --- State ---
const loading = ref(false)
const error = ref<string | null>(null)

// --- Computed ---
const canEdit = computed(() => !props.readonly)

// --- Methods ---
async function handleSave() {
  loading.value = true
  error.value = null
  try {
    // TODO: 调用 API
    emit('saved', 'row-id')
  } catch (e) {
    error.value = e instanceof Error ? e.message : '未知错误'
  } finally {
    loading.value = false
  }
}
</script>

<template>
  <div class="...">
    <!-- 内容 -->
    <div v-if="error" class="error-banner">{{ error }}</div>
  </div>
</template>
```

---

## 命名规范

- 组件文件名：`PascalCase.vue`（如 `ColorRowEditor.vue`）
- Props：`camelCase`（如 `colorVariantId`）
- Emits：`kebab-case` 事件名，TypeScript 类型化（如上例）
- CSS class：`kebab-case`

---

## 置信度标签渲染规范

**禁止显示数字**，统一使用 `ConfidenceBadge` 组件：

```vue
<ConfidenceBadge :score="row.confidence" :is-derived="row.isDerived" />
```

`ConfidenceBadge` 内部映射：
- `score >= 0.85` → `自动通过`（绿）
- `0.65 <= score < 0.85` → `需确认`（橙）
- `score < 0.65` → `请核查`（红）
- `isDerived = true` → `推导值`（灰，忽略 score）

---

## 「同色」引用显示规范

不直接渲染原始 `color_code` 字段，使用 `resolveColorRef` composable：

```vue
<script setup lang="ts">
import { useColorRef } from '@/composables/useColorRef'

const { resolvedValue, isReference } = useColorRef(
  () => row.colorCode,
  () => variantRows,  // 同变体所有行，用于解析「同色」
)
</script>

<template>
  <!-- 显示解析后的值 + 来源标注 -->
  <span>{{ resolvedValue }}</span>
  <span v-if="isReference" class="ref-hint">（同色）</span>
</template>
```

---

## 悬垂线显示规范

在 `ColorTableEditor` 矩阵中，跨颜色变体比较相同内容：

```vue
<!-- 使用 isDangling composable 判断是否显示 〜 -->
<template>
  <td>
    <span v-if="isDangling(rowIndex, variantIndex)">〜</span>
    <span v-else>{{ resolvedValue }}</span>
  </td>
</template>
```

打印模式下 `isDangling` 始终返回 `false`，确保每格都输出完整值。

---

## 打印模式切换

组件需感知打印模式，使用全局 `usePrintMode` composable：

```vue
<script setup lang="ts">
import { usePrintMode } from '@/composables/usePrintMode'
const { isPrinting } = usePrintMode()
</script>

<template>
  <!-- 打印模式隐藏操作按钮 -->
  <button v-if="!isPrinting">编辑</button>
</template>
```
