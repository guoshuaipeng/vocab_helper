# PRD · R49 到期复习开练强化（B06）

**模板**：ChatPRD public `ai-development-brief`  
**产品**：单词小助手（Flutter · vocab_helper）  
**状态**：已完成 · UI 自验通过  
**对应 backlog**：迭代 PRD [prd-iteration-rice-2026-10-23.md](prd-iteration-rice-2026-10-23.md) **B06**（RICE **10.5**，排序 #6 · 未完成最高分）  
**设计**：[design-r49.md](design-r49.md)  
**工具**：免费 ChatPRD 结构 + 公开竞品模式 + Impeccable；**禁用**付费 Refero/Mobbin、云端代理。

---

## 1. Problem and Target User

- **谁**：有到期词的孩子（间隔复习已发生，但少点开练）。  
- **障碍**：R29 已有「待复习 N → sheet → 开始复习」（2 点可达），但相对 R46 错词闭环：sheet 主 CTA 仍是默认 seed 色且压在列表下方易被拖动手柄/列表挤掉；Hero 只有弱行进清单，**没有一键开练**；空态「去学新词」未对齐 teal。  
- **为何现在**：B01/B03/B04/B05 已收口；RICE 未完成最高为 B06（10.5）；B07 需纸质、B08 可尾巴、设备项有依赖。

## 2. Evidence and Desired Outcomes

| 证据 | 出处 | 期望结果 |
|------|------|----------|
| 「到期复习 / 错词闭环可再顺」 | 迭代 PRD §2.2 | 从「待复习 N」到开练 ≤2 点；有数时 **1 点**可直达认读 |
| B06 成功度量 | RICE 表 | 入口强调、空态有下一步；不改间隔公式 |
| R29 已有能力 | design-r29 | **复用** due sheet / `onStartDueReview`→`_learnNew`；队列仍到期优先∪新词 |

## 3. Scope and Non-Goals

### 做
- Hero：有到期时增加 teal「去复习」直达认读（key `me_due_go`）；原行 `me_due_review` 仍开清单。  
- 到期 sheet：对齐 R46——副标「共 N 个到期 · 一键开练」；主 CTA Filled teal「开始复习」**置于列表上方**；空态 teal「去学新词」+ 弱下一步文案。  
- 行动区（可选强化）：有到期时增加 tonal「去复习到期」入口（key `me_due_action`），与错词/自测同卡可见。  
- 既有 keys（`me_due_review` / `due_review_*`）保留；单测 + 窄浅/窄深截图；requirements/retro；`git push github master`。

### 不做
- 新间隔公式 / SM-2 / 仅到期独立队列模式（仍遵循 R20：到期∪新词）。  
- 改 `friendly_thumb` / `thumb_*_friendly.png`。  
- 改 QuizEngine；跨词书到期合并；日历热力；推送。  
- 付费调研、云代理、无关 `vercel.json`。

## 4. Requirements and Acceptance Criteria

| ID | 行为 | 验收 |
|----|------|------|
| A1 | 有到期：Hero 可见「去复习」；点即 `onStartDueReview`（≤1 点开练） | widget 测 + 截图 |
| A2 | 点「待复习 N」仍开 sheet；主「开始复习」teal 且在列表上方 | `due_review_ui_test` + r49 sheet 截图 |
| A3 | 空态：暂无到期复习 + 下一步文案 + teal「去学新词」 | 空态窄浅截图 |
| A4 | 行动区有到期时可见「去复习到期」或等价 CTA | 截图/测 |
| A5 | 既有 due/me keys 不删；相关 flutter test 绿 | 本地 |
| A6 | docs/shots/r49-* + acceptance；requirements/retro；push | tip 可查 |

## 5. User Journey

1. 我的 · Hero「去复习」→ 学习认读（到期优先）。  
2. 我的 ·「待复习 N」→ sheet 看清单 →「开始复习」→ 同上。  
3. 空：sheet「暂无到期复习」→「去学新词」。

## 6. Success Measurement

- 有数时从 Hero 到开练 **1 次点击**；经清单仍 ≤2。  
- 回归：`due_review_ui_test` · `due_review_list_test` · me/r47 相关绿。

## 7. Risks

| 风险 | 应对 |
|------|------|
| Hero 双 CTA 挤窄屏 | 「去复习」紧凑 Filled；清单行保留 chevron |
| prefs 单测污染 | 一测一 mock；场景间 `pumpWidget(SizedBox.shrink)` |
| 时间盒 | 不砍 Hero 一键 + sheet teal 置顶；行动区可并入同卡一行 |

## 8. Implementation Context

- 主改：`lib/screens/me_screen.dart`（Hero due + `_DueReviewSheet` + actions）  
- 测：扩展 `due_review_ui_test`；新 `r49_*_shot_test`  
- 不动拇指；machineId `48ac8334-4d7a-4bfd-8f6c-f2820d793124`

## 9. RICE 简述

Reach 6 × Impact 0.5 × Conf 0.70 / Effort 0.20 = **10.5**（迭代表 #6；B01–B05/B04 已完成）。

## 10. 变更

| 日期 | 说明 |
|------|------|
| 2026-10-23 | 首版：R49 选 B06；进行中 |
