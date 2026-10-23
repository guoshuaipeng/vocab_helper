# Round 52 · 学习喇叭高对比

**对应 PRD**：[prd-r52-learn-speak-contrast.md](prd-r52-learn-speak-contrast.md) · 迭代 **B02**（RICE 81.0）  
**原则（Impeccable）**：朗读入口一眼可辨；次于词面；不与翻卡热区合并。  
**参考（公开模式）**：Quizlet 大卡角标朗读；百词斩喇叭与翻面分离。  
**工具**：本地 PRD；禁用付费 Mobbin/Refero。  
**不动**：`friendly_thumb` / `thumb_*_friendly.png` / 飞中动画。

---

## 0. 方向锁

| 要 | 不要 |
|----|------|
| 图标 `onSurface`（朗读中 `primary`） | 继续 `onSurfaceVariant` 弱灰 |
| 可选浅底圆增强轮廓 | 大彩色圆抢词面 |
| 保留 `flashcard_speak` | 并入翻卡 GestureDetector |
| 浅/深可辨 | 换 TTS / 改拇指 |

---

## 1. 组件细则（学习大词卡右上）

- `IconButton` · key `flashcard_speak` · tooltip「朗读」  
- `styleFrom`：  
  - `foregroundColor`：`_speaking ? primary : onSurface`  
  - `backgroundColor`：`surfaceContainerHighest` α≈0.55（浅底圆）  
- `icon`：`Icons.volume_up`  
- `onPressed`：`_speaking ? null : _speakCurrent`（既有）

---

## 2. 验收截图

| 文件 | 内容 |
|------|------|
| `r52-speak-narrow-light.png` | 窄浅 · 卡面 + 高对比喇叭 |
| `r52-speak-narrow-dark.png` | 窄深 · 同布局 |
| `r52-ui-acceptance.md` | A1–A5 |

---

## 3. 明确不做

换 TTS；改拇指；B07/B09/B11–B12；新题型；vercel.json。
