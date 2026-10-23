# Round 49 · 到期复习开练强化

**对应 PRD**：[prd-r49-due-review-start.md](prd-r49-due-review-start.md) · 迭代 **B06**（RICE 10.5）  
**原则**：看见「待复习」就能开练；清单可看但不挡主 CTA；对齐 R46 teal。  
**参考（公开）**：墨墨「待复习可点开就练」；Anki 二元入队；不背单词任务感。  
**工具**：本地 PRD；禁用付费 Mobbin/Refero。  
**不动**：`friendly_thumb` / `thumb_*_friendly.png`。

---

## 0. 方向锁

| 要 | 不要 |
|----|------|
| Hero「去复习」1 点直达认读 | 改 SRS / 仅到期独立模式 |
| sheet 主 CTA teal + 列表上方 | seed 蓝、CTA 埋列表底 |
| 空态下一步 + teal「去学新词」 | 空态无行动 |
| 保留 `me_due_review` / `due_review_*` | 改拇指 / 引擎 |
| 竖屏窄优先 | 紫渐变、Banner 墙 |

## 1. 信息架构

```
Hero
├─ 待复习 N ›          → sheet（浏览）
└─ [去复习] teal         → onStartDueReview（有数时）

行动卡 me_actions
└─ [去复习到期] tonal    → onStartDueReview（有数时；与自测并排或次行）

sheet 到期复习
├─ 副：共 N 个到期 · 一键开练
├─ [开始复习] teal       ← 列表上方
└─ list / 空态+去学新词
```

## 2. 组件细则

- `_meTeal = Color(0xFF0D9488)`（同 R45–R48）  
- `me_due_go`：Filled、白字、teal 底；文案「去复习」  
- `me_due_action`：Filled tonal 或 Outlined teal 边；文案「去复习到期」  
- sheet：`due_review_subtitle` · `due_review_start` · `due_review_learn_new`（空态）  
- 空态副文：「学新词时到期词也会优先出现」

## 3. 文案

| 键 | 文案 |
|----|------|
| Hero 直达 | 去复习 |
| 行动 | 去复习到期 |
| sheet 副标 | 共 N 个到期 · 一键开练 |
| 主 CTA | 开始复习 |
| 空态 | 暂无到期复习 |
| 空态副 | 学新词时到期词也会优先出现 |
| 空态 CTA | 去学新词 |

## 4. 验收截图

| 文件 | 内容 |
|------|------|
| `r49-hero-due-narrow-light.png` | Hero 有待复习 +「去复习」 |
| `r49-sheet-narrow-light.png` | sheet：副标 + teal 开始复习在列表上 |
| `r49-sheet-narrow-dark.png` | 同布局深色 |
| `r49-empty-narrow-light.png` | 空态 + teal 去学新词 |
| `r49-ui-acceptance.md` | A1–A6 |

## 5. 明确不做

新间隔；仅到期队列；改拇指；紫渐变；vercel.json。
