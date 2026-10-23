# Round 33 · 今日目标达成轻反馈 · UI 验收

**对应**：R33 / P1 今日目标达成反馈  
**设计稿**：`docs/design-r33.md`  
**状态**：**待 UI**（Banner 标题已重拍 · 2026-10-23）

## 环境

- [x] 我的完成态 窄窗浅色 → `r33-me-done-narrow-light.png`（保留）
- [x] 我的完成态 窄窗深色 → `r33-me-done-narrow-dark.png`（保留）
- [x] 我的完成态 宽窗浅色 → `r33-me-done-wide-light.png`（保留）
- [x] 我的完成态 宽窗深色 → `r33-me-done-wide-dark.png`（保留）
- [ ] 达成 Banner 窄窗浅色 → `r33-banner-narrow-light.png`（**已重拍 · 待验**）
- [ ] 达成 Banner 窄窗深色 → `r33-banner-narrow-dark.png`（**已重拍 · 待验**）

## 要点

- [ ] 上升沿 → 顶栏轻卡片：**「今日目标达成」**（≥16sp 完整可读）+「已学 n / goal」+「继续」
- [x] 不挡底栏「查看结果」；primaryContainer 浅底
- [x] 我的页满目标：「今日已完成 · n/n」+ 勾；进度满格
- [~] 同日一次去重（行为 Soft-pass）

## 打回改点（已修）

1. ~~Banner 标题不可辨~~：MaterialBanner 在 AppBar 下高度裁切多行 content。已改为 **Overlay 顶栏轻卡片**（AppBar 下方），标题「今日目标达成」完整露出；重拍窄浅/窄深。
2. 我的完成态四图保留。

## 设计师结论

- 结论：（待验 · Banner 重交）
- 日期：
- 验收人：
