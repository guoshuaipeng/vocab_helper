# PRD · R50 今日达成视觉统一（B08）

**模板**：ChatPRD public `ai-development-brief`  
**产品**：单词小助手（Flutter · vocab_helper）  
**状态**：已完成 · UI 自验通过  
**对应 backlog**：迭代 PRD [prd-iteration-rice-2026-10-23.md](prd-iteration-rice-2026-10-23.md) **B08**（RICE **7.5**，排序 #8 · 未完成最高可落）  
**设计**：[design-r50.md](design-r50.md)  
**工具**：免费 ChatPRD 结构 + 公开竞品模式 + Impeccable；**禁用**付费 Refero/Mobbin、云端代理。

---

## 1. Problem and Target User

- **谁**：达每日目标的孩子（认读「认识」或自测答对跨线）。  
- **障碍**：R33 Overlay 庆祝卡仍用 `primaryContainer` + seed 语义；学习/自测/我的（R43–R49）已统一纸卡 + teal `#0D9488`，达标一刻气质回潮。  
- **为何现在**：B01–B06 已收口；RICE 未完成最高可落为 B08（7.5）；B07 需纸质、B09+ 需设备。

## 2. Evidence and Desired Outcomes

| 证据 | 出处 | 期望结果 |
|------|------|----------|
| 「今日达成与 wow 统一」 | 迭代 PRD B08 | 庆祝卡纸感 + 同主色语义；不挡双 CTA |
| R33 已有上升沿/去重 | design-r33 · ProgressStore | **复用**触发与 keys；只改 chrome |
| 学/测/我的已纸卡+teal | R43/R45/R47 | Banner 对齐 paper + `#0D9488` CTA |

## 3. Scope and Non-Goals

### 做
- `goal_celebrate_banner`：纸卡底（light `surfaceContainerLow` / dark `surfaceContainerHigh`）、圆角 16–24、`outlineVariant` 边、轻阴影；标题/副文 `onSurface`；勾或星用 teal；「继续」Filled teal 白字。  
- 我的页完成态已 teal（R47）：仅核对文案/勾色一致，**不重做 Hero**。  
- 保留全部 `goal_celebrate_*` / `me_today_goal_*` keys；上升沿逻辑零改。  
- 单测 + 窄浅/窄深 Banner 截图（必要时我的完成态窄浅）；requirements/retro；`git push github master`。

### 不做
- 新勋章 / 排行 / 音效强制 / 全屏不可关弹窗。  
- 改 `dailyGoal` 算法、`goal_celebrated_ymd` 语义、跨日规则。  
- 改 `friendly_thumb` / `thumb_*_friendly.png`。  
- 改 QuizEngine；紫渐变；无关 `vercel.json`。  
- 付费调研、云代理。

## 4. Requirements and Acceptance Criteria

| ID | 行为 | 验收 |
|----|------|------|
| A1 | Banner 纸卡底 + outline 边；非 primaryContainer 实心底抢戏 | 窄浅/窄深截图可辨 |
| A2 | 「继续」Filled teal `#0D9488`；标题「今日目标达成」完整可读 | widget 测 + 截图 |
| A3 | 上升沿仍弹一次；「继续」/自动收后不挡学习双 CTA | `goal_celebrate_test` 绿 |
| A4 | 我的「今日已完成 · n/n」仍 teal 勾；既有 keys 保留 | me 相关测绿 |
| A5 | docs/shots/r50-* + acceptance；requirements/retro；push | tip 可查 |

## 5. User Journey

1. 认读/自测使 today 从不足跨到 ≥ goal → 顶区 Overlay 纸卡庆祝。  
2. 点「继续」或约 4s → 收起，继续当前词/题。  
3. 我的页 Hero 见「今日已完成 · n/n」teal 态。

## 6. Success Measurement

- 庆祝卡与学习纸卡气质一致（色/圆角/边）；主 CTA 语义 = teal。  
- 回归：`goal_celebrate_test` · me/r33 完成态相关绿。

## 7. Risks

| 风险 | 应对 |
|------|------|
| Overlay 截图含不全 | RepaintBoundary 包 MaterialApp（沿用 R33 shot） |
| 深色纸卡对比不足 | onSurface 字 + teal CTA；截图自验 |
| 时间盒 | 只改 banner widget；不碰拇指/引擎 |

## 8. Implementation Context

- 主改：`lib/widgets/goal_celebrate_banner.dart`  
- 测：`test/goal_celebrate_test.dart`；新/扩 `r50_*_shot_test`  
- 不动拇指；machineId `48ac8334-4d7a-4bfd-8f6c-f2820d793124`

## 9. RICE 简述

Reach 4 × Impact 0.5 × Conf 0.75 / Effort 0.20 = **7.5**（迭代表 #8；B01–B06 已完成）。

## 10. 变更

| 日期 | 说明 |
|------|------|
| 2026-10-23 | 首版：R50 选 B08；进行中 |
