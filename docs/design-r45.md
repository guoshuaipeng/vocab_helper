# Round 45 · 自测页视觉对齐学习页（focused quiz chrome）

**对应 PRD**：[prd-r45-quiz-chrome.md](prd-r45-quiz-chrome.md) · 迭代 B01  
**原则（Impeccable）**：一屏一任务=答题；题干≥半屏感；顶栏控件降权不删除；主确认色与学习页 teal 统一。  
**参考（公开模式）**：Quizlet 大卡题干；Duolingo 细进度+主色 CTA；百词斩/不背单词学测一体皮肤。  
**工具**：本地 PRD + frontend 思路；禁用付费 Mobbin/Refero。

---

## 0. 方向锁

| 要 | 不要 |
|----|------|
| 纸卡题干（同学习页 paper 色/圆角24/轻阴影） | 默认密 Material Card 墙 |
| 细进度 4px + 弱书名/题号 | 粗进度 + titleMedium 抢戏 |
| Segmented/Chip 紧凑次要 | 删五档或题池 |
| 主 Filled + 答对边框 → `#0D9488` | 紫靛渐变、seed 蓝当「认识/下一题」语义 |
| 保留全部既有 ValueKey | 为改皮重写 QuizEngine |

---

## 1. 竖屏分区（主）

```
┌ AppBar 自测 · …              ┐
│ ▓▓░░░░  题 3/10 · 书名弱     │  ← ≤12% 细 chrome
│ [义|词|听|写|默] 紧凑         │  ← 次要
│ (全部词)(只测错词) 次要 Chip   │
│ ┌─────────────────────────┐  │
│ │      题干纸卡（大）       │  │  ← ≥45% 视觉重量
│ └─────────────────────────┘  │
│ [选项…] 或 输入框             │
│ [  检查 / 下一题  teal肥 ]    │
└───────────────────────────────┘
```

宽屏：maxWidth 520 居中即可（本轮不强制双栏）；选项网格逻辑保留。

---

## 2. 组件细则

### 2.1 纸卡题干
- `paper` = light `surfaceContainerLow` / dark `surfaceContainerHigh`
- `BorderRadius.circular(24)`；`outlineVariant` 0.45 边；shadow alpha 0.06
- 看义：中文义 display 级（~28–32）；看词：英文 ~32–40 w800；听/听写：大喇叭 + 再听，喇叭色 `onSurface`（或 speaking 时 teal）
- **不展示 phonetic**（R21/R44 约定）

### 2.2 进度与文案
- `LinearProgressIndicator` minHeight **4**（现 6→4）
- 书名行可并入题号弱文案，或书名 `bodySmall` onSurfaceVariant

### 2.3 Segmented / Chip
- 窄宽均 `VisualDensity.compact` + shrinkWrap（再练 `onSelectionChanged: null` 不变）
- Chip 保持 `quiz_pool_*` keys

### 2.4 CTA / 答对态
- 常量 `const quizTeal = Color(0xFF0D9488);`（与 learn `knowTeal` 同值）
- `FilledButton` styleFrom backgroundColor: quizTeal, foregroundColor: white
- 选项正确：`BorderSide(color: quizTeal)` + 可用 tealContainer 感（`primaryContainer` 可保留若难取容器色，但边框必须 teal）
- 结束页「回学习」Filled teal；「错题再练」Outlined 不变

---

## 3. 状态

| 态 | 表现 |
|----|------|
| 未答 | 选项可点；下一题 disabled 或检查可点 |
| 答对 | 正确项 teal 边；文案「答对了！」teal |
| 答错 | 错项 error；正确项仍标出 |
| 再练 | 档锁 + badge「错题再练」 |
| 结束 | 百分数可用 teal；主回学习 |

---

## 4. 验收截图

| 文件 | 内容 |
|------|------|
| `docs/shots/r45-narrow-light.png` | 看义或看词进行中：纸卡+细进度+teal CTA |
| `docs/shots/r45-narrow-dark.png` | 同布局深色 |
| `docs/shots/r45-end-narrow-light.png` | 结束页（可选但推荐） |
| `docs/shots/r45-ui-acceptance.md` | 勾选 A1–A5 |

---

## 5. 明确不做

新题型；引擎改分；学习页重排；喇叭换引擎；提交 vercel.json。
