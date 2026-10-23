# Round 32 · 错词池自测 · UI 验收

**对应**：R32 / P1 错词池自测  
**设计稿**：`docs/design-r32.md`  
**状态**：**UI 通过**（空态复验 tip `e637ec7` · 有错词四态 tip `74ff88e` · 2026-10-23）

## 环境

- [x] 只测错词 窄窗浅色 → `r32-wrong-pool-narrow-light.png`
- [x] 只测错词 窄窗深色 → `r32-wrong-pool-narrow-dark.png`
- [x] 只测错词 宽窗浅色 → `r32-wrong-pool-wide-light.png`
- [x] 只测错词 宽窗深色 → `r32-wrong-pool-wide-dark.png`
- [x] 无错词 窄窗浅色 → `r32-wrong-pool-empty-narrow-light.png`（SnackBar「还没有错词，先去学或自测」；「全部词」仍选中）

## 要点

- [x] 题池 FilterChip：**全部词** \| **只测错词**（可带 N）；弱于题型 Segmented
- [x] 只测错词开启后题池角标/AppBar「自测错词」；宽窗选项 2×2
- [x] 无错词：点「只测错词」→ SnackBar 文案达标（设计允许 disabled 或提示）
- [~] 四档在错词池下可用、切档保持题池（行为 Soft-pass）
- [~] 我的页「去测错词」（设计可选 Soft-pass）

## 设计师结论

- 结论：**通过**
- 日期：2026-10-23
- 验收人：单词UI设计
- tip：有错词 `74ff88e` · 空态复验 `e637ec7`
