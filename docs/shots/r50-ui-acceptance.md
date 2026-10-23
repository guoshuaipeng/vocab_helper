# R50 · 今日达成视觉统一 · UI 自验

**日期**：2026-10-23（Asia/Shanghai）  
**对照**：[design-r50.md](../design-r50.md) · [prd-r50-goal-celebrate-wow.md](../prd-r50-goal-celebrate-wow.md)  
**RICE**：B08（7.5） · 免费工具 only（无付费 Refero/Mobbin）  
**不动**：`friendly_thumb` / `thumb_*_friendly.png`；上升沿 / `goal_celebrated_ymd`

## 入口路径

1. 认读「认识」或自测答对使 today 从不足跨到 ≥ goal → 顶 Overlay 纸卡庆祝  
2. 点 teal「继续」或约 4s 自动收 → 继续当前词/题（不挡底双 CTA）  
3. 我的 Hero：「今日已完成 · n/n」teal 勾 + 细进度满格

## 截图

| 文件 | 内容 |
|------|------|
| [r50-banner-narrow-light.png](r50-banner-narrow-light.png) | 纸卡庆祝 + teal「继续」；标题完整 |
| [r50-banner-narrow-dark.png](r50-banner-narrow-dark.png) | 同布局深色 |
| [r50-me-done-narrow-light.png](r50-me-done-narrow-light.png) | 我的完成态 teal 核对 |

## A1–A5

| ID | 结果 | 说明 |
|----|------|------|
| A1 Banner 纸卡底 + outline | ✅ | 非 primaryContainer；shot 测断言 paper 色 |
| A2 「继续」Filled teal；标题可读 | ✅ | `celebrateTeal`；截图 + widget 测 |
| A3 上升沿一次；不挡双 CTA | ✅ | `goal_celebrate_test` 绿；顶 Overlay |
| A4 我的完成态 teal keys | ✅ | `me_today_goal_*`；me-done 截图 |
| A5 docs + push | ✅ | 本收口 + `git push github master` |

## Soft-pass

- Material 图标在截图里偶发空方块（既有 Soft-pass）；对比色/teal CTA 以目视为准。  
- 宽屏 Banner 未拍（竖屏优先 timebox）。

## 明确不做（已遵守）

新勋章/排行；改去重语义；改拇指资源；改 QuizEngine；vercel.json。
