# PRD · R45 自测页视觉对齐学习页（B01）

**模板**：ChatPRD public `ai-development-brief`  
**产品**：单词小助手（Flutter · vocab_helper）  
**状态**：已完成 · UI 自验通过  
**对应 backlog**：迭代 PRD [`prd-iteration-rice-2026-10-23.md`](prd-iteration-rice-2026-10-23.md) **B01**（RICE **85.3**，排序 #1）  
**设计**：[design-r45.md](design-r45.md)  
**工具**：免费 ChatPRD 结构 + 公开竞品模式 + Impeccable；**禁用**付费 Refero/Mobbin、云端代理。

---

## 1. 现状（为何现在做）

- R43 学习页已 focused study：纸卡、细进度、teal「认识」、次要进 overflow。  
- 自测仍：密 Segmented + FilterChip + 默认 `Card` + seed `primary` 蓝 CTA → 同会话像两个 App（体验缺陷表已记）。  
- R44 已做推荐本音标内容轮；B01 编码顺延为本轮 **R45**（requirements 已排期）。  
- 不新开题型；QuizEngine / 五档 / 错词池 / 错题再练行为零回归。

## 2. 缺口 / 竞品（公开模式）

| 来源 | 模式 | 我们 | 本轮动作 |
|------|------|------|----------|
| 百词斩 / 不背单词 | 学测一体皮肤 | 学 wow、测滞后 | 自测 chrome 对齐 |
| Quizlet | 大卡题干、模式不抢戏 | 顶栏控件忙 | 题干纸卡 + 控件降权 |
| Duolingo（公开） | 细进度 + 主色 CTA 统一 | 测仍 seed 蓝 | 主 CTA / 答对态 → teal `#0D9488` |

**不抄**：紫靛渐变、贴纸墙、删五档。

## 3. Goals

孩子从学习 overflow 进自测后，仍感到「同一个单词小助手」：纸感题干、细进度、teal 确认路径；五档与引擎行为不变。

## 4. Scope（做）

- 题干区：学习页同款纸卡（`surfaceContainerLow` / dark `High`、圆角 24、轻阴影）。  
- 顶栏：细进度 `minHeight: 4`；书名/题号降为 `bodySmall` + `onSurfaceVariant`。  
- Segmented / 题池 Chip：保留全部能力；窄屏紧凑密度，视觉次要于题干。  
- 主路径 FilledButton（检查/提交/下一题/回学习）与答对高亮边 → teal `#0D9488`（与学习「认识」锁色）。  
- 听音/听写喇叭：提高对比（`onSurface` / 非弱 variant），热区逻辑不变。  
- 结束页主 CTA 同 teal；错题再练仍 Outlined。

## 5. Non-goals

新题型；改 QuizEngine / SRS；改学习页布局；紫渐变；删档位或题池；付费调研。

## 6. Acceptance

- [x] A1 窄浅截图：纸卡题干 + 细进度 + teal 主 CTA 可见  
- [x] A2 五档 Segmented + 题池 Chip 仍可用（再练中仍锁档）  
- [x] A3 相关 `flutter test`（quiz_* / engine）绿  
- [x] A4 `docs/shots/r45-*.png` + `r45-ui-acceptance.md`（至少窄浅 + 窄深；宽/听写可选）  
- [x] A5 requirements / retro 收口；`git push github master`（触发部署）；勿提交无关 `vercel.json`

## 7. 风险与技术约束

| 风险 | 应对 |
|------|------|
| prefs 单测污染 | 沿用既有 quiz 测文件模式；勿中途 `setMockInitialValues` |
| 截图图标空方块 | Soft-pass 字形；色/对比度须可辨 |
| 改 CTA 色影响找 key | **保留全部 ValueKey**；只改样式 |
| 时间盒 ~30–40min | 砍宽屏额外抛光，不砍测试与窄屏验收 |
| 禁止云代理 | 仅本机 `machineId` 48ac8334… |

## 8. RICE 依据（摘录）

Reach 8 × Impact 2 × Conf 0.80 / Effort 0.15 ≈ **85.3** → 高于 B03(20)/B04(14)/B05(12)。本轮只落地 B01。

## 9. 变更

| 日期 | 说明 |
|------|------|
| 2026-10-23 | R45 开工 PRD：承接迭代表 B01；原分析稿称 R44 编码，实际 R44=音标内容，本轮补齐视觉对齐 |
