# R41 UI 自验收 · 词书列表推荐本置顶

**结论**：通过  
**日期**：2026-10-23（Asia/Shanghai）  
**tip（feat）**：`25b00d3`  

## 对照 design-r41

| 项 | 结果 |
|----|------|
| 首屏「推荐跟课」+ 推荐卡 | 通过（无需滚动） |
| 原 version 组不重复推荐本 | 通过（单测 key 唯一；沪教牛津2024 空组已省略） |
| 切书流程不变 | 未改 `_selectBook` |

## 截图

- `docs/shots/r41-books-pinned-narrow-light.png` — 当前选 pep-ps-3 时首屏仍见推荐置顶