# Round 46 · 错词本→自测一键闭环

**对应 PRD**：[prd-r46-wrong-quiz-loop.md](prd-r46-wrong-quiz-loop.md) · 迭代 **B03**（RICE 20.0）  
**原则（Impeccable）**：一屏一任务=清错词；主 CTA=测；次要=认读；进测后锁池提示，勿让用户迷路切回全书。  
**参考（公开模式）**：墨墨/不背单词「错词本可测」；Quizlet 模式进入后锁定语境。  
**工具**：本地 PRD；禁用付费 Mobbin/Refero。  
**不动**：`friendly_thumb` / `assets/icons/thumb_*_friendly.png`；QuizEngine 判分。

---

## 0. 方向锁

| 要 | 不要 |
|----|------|
| sheet 主「测这些」Filled `#0D9488` | 主 CTA 仍是认读、测只是 Outlined |
| `QuizMode.wrong` 锁池 +「测这些错词 · N」 | 进场后仍可 Chip 切「全部词」 |
| 空态友好 + teal 去学新词 | 空态死胡同 |
| 复用 R32/R39 数据与导航 | 新错词算法、新题型 |
| 竖屏窄优先 | 宽屏双栏大改 |

---

## 1. 信息架构

```
我的 · 错词本卡 → sheet「错词本」
  ├ 有词：[测这些] 主 teal → QuizMode.wrong（锁池）
  │       [复习这些错词] 次 Outlined → 认读错词
  └ 空：  暂无错词 + [去学新词]

学习 · 认读错词结束（可选）
  └ [测这些错词] → 同上 QuizMode.wrong
```

---

## 2. 组件细则

### 2.1 WrongBookSheet
- 标题下弱文案：`共 N 个错词 · 一键测掉`（有词时）。  
- **主** `ValueKey('wrong_book_quiz')`：Filled + teal 背景白字「测这些」。  
- **次** `ValueKey('wrong_book_review')`：Outlined「复习这些错词」。  
- 空态 keys 保留：`wrong_book_empty` / `wrong_book_learn_new`；学新词按钮用同 teal。  
- 截断脚注不变。

### 2.2 Quiz 锁池（仅 mode==wrong）
- 不渲染可切的 `quiz_pool_all`。  
- 展示锁态 Chip/Banner：`ValueKey('quiz_pool_locked')`，文案 `测这些错词 · N`（N=`_wrongInScope`）。  
- `_poolWrongOnly` 恒 true；book/unit 模式仍双 Chip（R32）。  
- AppBar 标题保持「自测错词」；纸卡/细进度/teal CTA 沿用 R45。

### 2.3 我的学习自测卡
- `me_quiz_wrong_pool` label：`测这些`（有错启用）。

### 2.4 认读错词结束（强化）
- `LearnScreen.onQuizWrong`；结束页主按钮「测这些错词」；「去学新词」次要。

---

## 3. 文案

| 键 | 文案 |
|----|------|
| 主 CTA | 测这些 |
| 次 CTA | 复习这些错词 |
| 副标 | 共 {n} 个错词 · 一键测掉 |
| 锁池 | 测这些错词 · {n} |
| 空 | 暂无错词 / 认读点「不认识」或自测答错会进来 |
| 空 CTA | 去学新词 |
| 认读结束主 | 测这些错词 |

---

## 4. 验收截图

| 文件 | 内容 |
|------|------|
| `r46-sheet-narrow-light.png` | sheet 有词：主测这些 teal + 列表 |
| `r46-sheet-empty-narrow-light.png` | 空态 |
| `r46-quiz-locked-narrow-light.png` | 自测错词锁池提示 + 纸卡 |
| `r46-quiz-locked-narrow-dark.png` | 同布局深色 |
| `r46-ui-acceptance.md` | A1–A6 |

---

## 5. 明确不做

新算法；改拇指资源；删五档；紫渐变；vercel.json。
