# R40 UI 自验收 · 默认推荐沪教牛津2024七上

**结论**：通过  
**日期**：2026-10-23（Asia/Shanghai）  
**tip（feat）**：`df4f5f0`  

## 对照 design-r40

| 项 | 结果 |
|----|------|
| Setup 无选中时预选 沪教牛津2024 / hj-ox-7a-2024 | 通过（见 setup 截图） |
| Setup 顶注「默认跟课：…（可改）」 | 通过 |
| 推荐本 subtitle 含「推荐」 | Setup + 词书列表均通过 |
| 不强制覆盖已选 | 单测覆盖；本轮未改已选路径 |

## 截图

- `docs/shots/r40-setup-preselect-narrow-light.png` — Setup 预选态
- `docs/shots/r40-books-recommended-narrow-light.png` — 词书列表滚至推荐本

## 备注

词书页推荐本仍在「沪教牛津2024」分组内，需下滚才见；下一轮可考虑置顶（R41 候选）。