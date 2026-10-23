# R42 UI 自验收 · 非推荐词书弱提示切换跟课

**结论**：通过  
**日期**：2026-10-23（Asia/Shanghai）  
**对照**：[design-r42.md](../design-r42.md) · [prd-learn-v2.md](../prd-learn-v2.md) R1–R7

## 对照清单

| 项 | 结果 |
|----|------|
| pep-ps-3：我的可见 `me_recommend_switch_hint` | 通过（单测 + 截图） |
| pep-ps-3：学习可见 `learn_recommend_switch_hint` | 通过 |
| hj-ox-7a-2024：两处均无 | 通过（单测） |
| 「去切换」触发 onChangeBook | 通过（单测 verify） |
| 「今日不再」仅隐藏学习当日；我的仍显示 | 通过（单测） |
| 未选书不显示 | 通过 |
| secondaryContainer / 圆角 12 / 无 Dialog | 目视通过 |

## 截图

- `r42-me-narrow-light.png` — 窄浅 · 我的当前词书卡内提示
- `r42-learn-narrow-light.png` — 窄浅 · 学习顶栏下弱链
- `r42-me-wide-light.png` — 宽浅 · 我的
- `r42-learn-narrow-dark.png` — 窄深 · 学习

**如何复拍**：`UPDATE_SHOTS=1 flutter test test/r42_shot_*.dart`（各文件独立进程，避免 SharedPreferences mock 串扰）
