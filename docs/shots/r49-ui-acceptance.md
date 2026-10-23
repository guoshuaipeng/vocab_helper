# R49 · 到期复习开练强化 · UI 自验

**日期**：2026-10-23（Asia/Shanghai）  
**对照**：[design-r49.md](../design-r49.md) · [prd-r49-due-review-start.md](../prd-r49-due-review-start.md)  
**RICE**：B06（10.5） · 免费工具 only（无付费 Refero/Mobbin）  
**不动**：`friendly_thumb` / `thumb_*_friendly.png`

## 入口路径

1. **我的 · Hero「去复习」**（有到期）→ 1 点进认读（`onStartDueReview`）  
2. **我的 ·「待复习 N」** → sheet → teal「开始复习」（列表上方）→ 同上（≤2 点）  
3. **我的 · 行动「去复习到期 · N」** → 同 1  
4. 空：sheet「暂无到期复习」+ 下一步文案 → teal「去学新词」

## 截图

| 文件 | 内容 |
|------|------|
| [r49-hero-due-narrow-light.png](r49-hero-due-narrow-light.png) | Hero「去复习」+ 行动「去复习到期」 |
| [r49-sheet-narrow-light.png](r49-sheet-narrow-light.png) | sheet：副标 + teal 开始复习在列表上方 |
| [r49-sheet-narrow-dark.png](r49-sheet-narrow-dark.png) | 同布局深色 |
| [r49-empty-narrow-light.png](r49-empty-narrow-light.png) | 空态 + 提示 + teal 去学新词 |

## A1–A6

| ID | 结果 | 说明 |
|----|------|------|
| A1 Hero 去复习 1 点开练 | ✅ | key `me_due_go`；widget 测 |
| A2 sheet teal CTA 在列表上 | ✅ | `due_review_start` Y < list Y；截图 |
| A3 空态下一步 + teal | ✅ | `due_review_empty_hint` + `due_review_learn_new` |
| A4 行动区去复习到期 | ✅ | `me_due_action`；hero 截图可见 |
| A5 既有 keys + 测试绿 | ✅ | due_review_ui / list / r47 / wrong_book |
| A6 docs + push | ✅ | 本收口 commit + `git push github master` |

## Soft-pass

- 空态按钮在极矮视口可能贴底；产品路径以 Hero「去复习」为主。  
- 宽屏额外 sheet 未拍（竖屏优先 timebox）。

## 明确不做（已遵守）

新间隔公式；仅到期独立队列；改拇指资源；改 QuizEngine；vercel.json。
