# R52 · 学习喇叭高对比 · UI 自验

**日期**：2026-10-23（Asia/Shanghai）  
**对照**：[design-r52.md](../design-r52.md) · [prd-r52-learn-speak-contrast.md](../prd-r52-learn-speak-contrast.md)  
**RICE**：B02（81.0） · 免费工具 only（无付费 Refero/Mobbin）  
**不动**：`friendly_thumb` / `thumb_*_friendly.png` / 飞中动画

## 入口路径

1. 打开学习页 → 大词卡右上角喇叭  
2. 非朗读态：`onSurface` + 浅底圆（`surfaceContainerHighest` α0.55）  
3. 点喇叭朗读（不翻卡）；朗读中 primary + 禁用（既有）

## 截图

| 文件 | 内容 |
|------|------|
| [r52-speak-narrow-light.png](r52-speak-narrow-light.png) | 窄浅 · 卡面 + 高对比喇叭 |
| [r52-speak-narrow-dark.png](r52-speak-narrow-dark.png) | 窄深 · 同布局 |

## A1–A5

| ID | 结果 | 说明 |
|----|------|------|
| A1 非朗读 onSurface | ✅ | `r52_learn_speak_contrast_test`；非 onSurfaceVariant |
| A2 朗读中 primary+禁用 | ✅ | 既有 `_speaking` 路径；本轮未改逻辑 |
| A3 浅底圆；热区≠翻卡 | ✅ | bg α≈0.55；点喇叭后 reveal_hint 仍在 |
| A4 窄浅/窄深 shot + MaterialIcons | ✅ | 本目录两图 |
| A5 拇指 diff 为零 | ✅ | 未改 assets/icons/thumb_* / friendly_thumb |

## Soft-pass

- 截图字形偶发空方块时，以色对比与浅底圆为准。

## 明确不做（已遵守）

换 TTS；改拇指；B07/B09/B11–B12；堆伪需求。
