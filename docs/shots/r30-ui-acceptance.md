# Round 30 · 本词书「单元进度」一览 · UI 验收

**对应**：R30 / P1 单元进度一览  
**设计稿**：`docs/design-r30.md`  
**状态**：**UI 验收通过**

## 环境

- [x] 入口 窄窗浅色 → `r30-entry-narrow-light.png`
- [x] Sheet 窄窗浅色 → `r30-sheet-narrow-light.png`
- [x] Sheet 窄窗深色 → `r30-sheet-narrow-dark.png`
- [x] Sheet 宽窗浅色 → `r30-sheet-wide-light.png`
- [x] Sheet 宽窗深色 → `r30-sheet-wide-dark.png`

## 要点

- [x] 我的页当前词书区有次要入口「单元进度」（与导出同级 pill；无书态未附截图，由开发覆盖）
- [x] Sheet 标题「单元进度」；汇总 `已学 a/b · 错词 c`；行列：单元 · 已学 a/b · 错 c + 弱进度条
- [x] 点行 → 关闭 sheet → 写入现有单元筛选 → 切学习 · SnackBar（静态截图未录交互；开发单测/流程覆盖，本轮 UI 不挡）
- [x] 「未分单元」/全无 unit 空态：本轮截图为有 unit 词书 happy path；空态文案由开发对齐 design-r30，UI 不挡
- [x] 窄/宽 × 深/浅对比足够；行触控舒适

## 设计师结论

- 结论：**通过**（tip `e9f79be`）
- 日期：2026-10-23
- 验收人：单词UI设计
- 备注：入口「单元进度」在当前词书区可见；sheet 标题/汇总/行结构/弱进度条符合 design-r30；窄宽×深浅可读。点行筛选与空态未附动图/空态图，不挡 UI 通过。
