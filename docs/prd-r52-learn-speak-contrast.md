# PRD · R52 学习喇叭高对比（B02）

**模板**：ChatPRD public ai-development-brief  
**对应迭代**：[prd-iteration-rice-2026-10-23-r52.md](prd-iteration-rice-2026-10-23-r52.md) · **B02**（RICE **81.0**）  
**设计**：[design-r52.md](design-r52.md)  
**状态**：可开发 → 本轮落地  
**不动**：拇指资源 / 飞中动画；QuizEngine；TTS 引擎。

---

## 问题

学习页大词卡右上角朗读入口在浅/深截图里对比偏弱（`onSurfaceVariant`），儿童找喇叭摩擦高于翻卡本身。自测页大喇叭已在 R45 用 `onSurface`；学习页未跟齐。

## 谁

认读时要点朗读的孩子（跟课主路径，Reach 高）。

## 成功度量

1. 非朗读态图标色 = `ColorScheme.onSurface`；朗读中仍 `primary` 且禁用防连点。  
2. 可选浅底圆（`surfaceContainerHighest` 低透明）增强轮廓，不抢词面。  
3. `ValueKey('flashcard_speak')` 保留；热区不并入翻卡 GestureDetector。  
4. 浅/深窄窗截图喇叭可辨；单测断言颜色语义。  
5. **不**改 `friendly_thumb` / `thumb_*_friendly.png` / Overlay 飞中逻辑。

## 范围

| 做 | 不做 |
|----|------|
| `learn_screen` 喇叭色 + 可选浅底 | 换 TTS / 新发音引擎 |
| 单测 + r52 截图 + acceptance | 改卡字号/间距/揭晓 |
| requirements / retro / push | 拇指；B07/B09/B11–B12；vercel |

## 验收 A1–A5

| ID | 标准 |
|----|------|
| A1 | 非朗读：Icon 色为 onSurface（非 onSurfaceVariant） |
| A2 | 朗读中：primary + onPressed null（既有） |
| A3 | 浅底圆可见且不挡词面；热区独立 |
| A4 | 窄浅/窄深 shot；MaterialIcons 加载 |
| A5 | 拇指相关文件 git diff 为零 |

## 风险

截图字形 Soft-pass；对比以色为准。PowerShell 补丁勿吞 `$`。

## 非目标

堆新功能填时间盒；猜词；真机项。
