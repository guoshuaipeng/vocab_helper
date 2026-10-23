# R46 · 错词本→自测一键闭环 · UI 自验

**日期**：2026-10-23（Asia/Shanghai）  
**对照**：[design-r46.md](../design-r46.md) · [prd-r46-wrong-quiz-loop.md](../prd-r46-wrong-quiz-loop.md)  
**RICE**：B03（20.0） · 免费工具 only（无付费 Refero/Mobbin）  
**不动**：`friendly_thumb` / `thumb_*_friendly.png`

## 入口路径

1. **我的 → 错词本卡 /「查看 · 测这些」** → sheet → 主 CTA **「测这些」**（teal）→ `QuizMode.wrong`  
2. **我的 → 学习自测 →「测这些」**（有错时）→ 同上  
3. **学习 · 认读错词结束 →「测这些错词」** → 同上  
4. 进场后 AppBar「测这些错词」+ 锁池 Chip「测这些错词 · N」（不可切「全部词」）

## 截图

| 文件 | 内容 |
|------|------|
| [r46-sheet-narrow-light.png](r46-sheet-narrow-light.png) | sheet 有词：副标 + 主「测这些」teal + 次「复习这些错词」 |
| [r46-sheet-empty-narrow-light.png](r46-sheet-empty-narrow-light.png) | 空态：暂无错词 + teal「去学新词」 |
| [r46-quiz-locked-narrow-light.png](r46-quiz-locked-narrow-light.png) | 自测锁池 + 纸卡题干（R45 chrome） |
| [r46-quiz-locked-narrow-dark.png](r46-quiz-locked-narrow-dark.png) | 同布局深色 |

## A1–A6

| ID | 结果 | 说明 |
|----|------|------|
| A1 sheet 主测这些 → wrong | ✅ | key `wrong_book_quiz`；窄浅截图可见 teal 主 CTA |
| A2 锁池提示 · 无全部词可切 | ✅ | `quiz_pool_locked`；wrong 模式无 `quiz_pool_chips` |
| A3 空态友好 | ✅ | empty + `wrong_book_learn_new` teal |
| A4 R32 book Chip 不回归 | ✅ | `quiz_wrong_pool_test` 绿 |
| A5 测试 + 截图清单 | ✅ | wrong_book_ui / quiz_* / r46 shot |
| A6 requirements/retro + push | ✅ | 本收口 commit + `git push github master` |

## Soft-pass

- 截图喇叭/锁图标可能呈空方块（字形）；色与文案可辨即可。  
- 宽屏额外 sheet 未拍（竖屏优先 timebox）。

## 明确不做（已遵守）

新错词算法；改拇指资源；新题型；改 QuizEngine 判分；vercel.json。
