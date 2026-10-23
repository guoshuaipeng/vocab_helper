# R43 · 学习页眼前一亮 · UI 自验

**日期**：2026-10-23（Asia/Shanghai）  
**对照**：[design-r43.md](../design-r43.md) · [prd-learn-wow.md](../prd-learn-wow.md)  
**参考**：百词斩 / 不背单词式「大词 + 点按揭晓 + 细进度」；免费工具 only。

## 截图

| 文件 | 内容 |
|------|------|
| [r43-narrow-light.png](r43-narrow-light.png) | 竖屏浅 · 未揭晓 |
| [r43-narrow-light-revealed.png](r43-narrow-light-revealed.png) | 竖屏浅 · 已揭晓释义 |
| [r43-narrow-dark.png](r43-narrow-dark.png) | 竖屏深 |
| [r43-wide.png](r43-wide.png) | 宽屏卡左 / CTA 右 |
| [r43-overflow.png](r43-overflow.png) | 更多练习 sheet |

## W1–W11

| ID | 结果 | 说明 |
|----|------|------|
| W1 英雄词 | ✅ | `learn_wow_word` 展示级字重；截图可见大词 |
| W2 分区 | ✅ | 测：卡高 / LearnScreen 高 > 0.50；顶仅细进度+溢出；底双 CTA |
| W3 双 CTA | ✅ | 不认识 outline · 认识 teal `#0d9488` 肥胶囊 |
| W4 揭晓 | ✅ | 点卡/提示后释义出现，英文词仍在 |
| W5 次要折叠 | ✅ | 主列无 chip；overflow → 学新词/复习/自测/单元 |
| W6 动效 | ✅ | 答后水平 slide ~250ms（主实现）；未做 3D flip |
| W7 CTA 反馈 | ✅ | `_PressScale` → AnimatedScale 0.98 |
| W8 宽布局 | ✅ | `r43-wide.png` |
| W9 SRS | ✅ | 点「认识」后 learned 增加且换词 |
| W10 文案色 | ✅ | 中文 UI；无紫靛渐变；seed 仍 `#4F8CFF` |
| W11 截图 | ✅ | 本清单五图 |

## 裁剪（timebox）

- 未做答后确认 SnackBar/对话框（导向：可选且易挡 CTA，跳过）。
- 未做 3D flip；未做图片四选一。
- R42 弱提示保留为顶栏单行。

## 测试

`flutter test`（相关）：`r43_learn_wow_test` · `today_task_test` · `unit_filter_ui_test` · `learn_scale_test` · `learn_layout_shot_test` · R42 learn hint 套件 — 全绿。
