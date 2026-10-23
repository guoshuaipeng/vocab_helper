# R40 UI 自验 · 默认推荐沪教牛津2024七上

**日期**：2026-10-23（Asia/Shanghai）  
**结论**：**通过**

## 验收对照 design-r40

| 项 | 结果 |
|----|------|
| Setup 无选中时预选 沪教牛津2024 / hj-ox-7a-2024 | 通过 · Setup 四态截图 |
| Setup 顶注「默认跟课：沪教牛津 2024 七上（可改）」 | 通过 · 浅/深均可读 |
| 推荐本 subtitle 含「推荐」 | Setup + 词书列表均通过 |
| 已选 pep-ps-3 不强制覆盖 | 通过 · `recommend_book_test` keep 场景 |
| 窄×浅 Setup + Books | 通过 |
| 窄×深 / 宽×浅 / 宽×深 | 通过（本轮补齐） |

## 截图矩阵

| 场景 | 窄×浅 | 窄×深 | 宽×浅 | 宽×深 |
|------|-------|-------|-------|-------|
| Setup 预选 | `r40-setup-preselect-narrow-light.png` | `r40-setup-preselect-narrow-dark.png` | `r40-setup-preselect-wide-light.png` | `r40-setup-preselect-wide-dark.png` |
| Books 推荐 | `r40-books-recommended-narrow-light.png` | `r40-books-recommended-narrow-dark.png` | `r40-books-recommended-wide-light.png` | `r40-books-recommended-wide-dark.png` |

## 目视

- 浅色/深色下顶注与「推荐」对比可读
- 词书列表推荐本可见（R41 已置顶；本矩阵仍作 R40 推荐态证据）

## 备注

首轮仅交窄浅两图；本轮补齐四态 + pep-ps-3 keep 单测。不改 R42 进行中范围。
