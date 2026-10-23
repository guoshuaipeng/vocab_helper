# Round 32 · 错词池自测 · UI 验收

**对应**：R32 / P1 错词池自测  
**设计稿**：`docs/design-r32.md`  
**状态**：**待 UI**（空态已重拍 · 2026-10-23）

## 环境

- [x] 只测错词 窄窗浅色 → `r32-wrong-pool-narrow-light.png`（目视 OK · 保留）
- [x] 只测错词 窄窗深色 → `r32-wrong-pool-narrow-dark.png`（目视 OK · 保留）
- [x] 只测错词 宽窗浅色 → `r32-wrong-pool-wide-light.png`（目视 OK · 选项 2×2 · 保留）
- [x] 只测错词 宽窗深色 → `r32-wrong-pool-wide-dark.png`（目视 OK · 选项 2×2 · 保留）
- [ ] 无错词 窄窗浅色 → `r32-wrong-pool-empty-narrow-light.png`（**已重拍 · 待验**）

## 要点

- [x] 题池 FilterChip：**全部词** \| **只测错词**（带 N）；弱于题型 Segmented；窄窗第二行不挤题干
- [x] 只测错词开启：AppBar「自测错词」、进度与 Chip 角标一致（本批 6）
- [ ] 无错词：Chip 无角标「只测错词」+ 点按 SnackBar「还没有错词，先去学或自测」——**已重拍**
- [~] 四档在错词池下可用、切档保持题池（行为项 · Soft-pass，本批词档截图）
- [~] 我的页「去测错词」（设计可选 · Soft-pass，本批无截图）

## 打回改点（已修）

1. ~~重拍空态~~：截图脚本在同一次 `testWidgets` 内 `setMockInitialValues` 无法刷新已缓存 prefs，空态仍带 6 条错词。已改为 `openStoreWithWrongIds` 显式 sync；空态图现为 **错词数=0**：全部词选中、Chip「只测错词」（无 ·N）、SnackBar「还没有错词，先去学或自测」。
2. 有错词四态保留（同批脚本重出，内容未改口径）。

## 设计师结论

- 结论：（待验 · 空态重交）
- 日期：
- 验收人：
