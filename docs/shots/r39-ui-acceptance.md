# R39 UI 自验 · 错词本可浏览清单

**日期**：2026-10-23（Asia/Shanghai）  
**结论**：**通过**

## 验收对照 design-r39

| 项 | 结果 |
|----|------|
| 我的 · 错词本数字行可点（查看错词 ›） | 通过 · `r39-entry-narrow-light.png` |
| 有错 → sheet 列词+义+单元；主「复习这些错词」/次「去测错词」 | 通过 · 窄/宽×深/浅 sheet 图 |
| 无错 → 空态「暂无错词」+「去学新词」 | 通过 · `r39-empty-narrow-light.png` |
| 截断 >40 脚注 | 单测覆盖；本轮截图用 3 词 |
| Sheet 内无清空 | 通过 |

## 相对设计稿的微调

Material `showDragHandle` 底栏易把底部 CTA 滚出首屏；本轮将 **主/次 CTA 置于标题下、列表上**，保证开 sheet 即见「复习/去测」。文案与行为不变。

## 截图

- `r39-entry-narrow-light.png`
- `r39-sheet-narrow-light.png` / `r39-sheet-narrow-dark.png`
- `r39-sheet-wide-light.png` / `r39-sheet-wide-dark.png`
- `r39-empty-narrow-light.png`