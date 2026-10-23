# PRD · R48 单元 overflow 路径可读（B04）

**模板**：ChatPRD public `ai-development-brief`  
**产品**：单词小助手（Flutter · vocab_helper）  
**状态**：已完成 · UI 自验通过  
**对应 backlog**：迭代 PRD [prd-iteration-rice-2026-10-23.md](prd-iteration-rice-2026-10-23.md) **B04**（RICE **14.0**，排序 #4 · 未完成最高分）  
**设计**：[design-r48.md](design-r48.md)  
**工具**：免费 ChatPRD 结构 + 公开竞品模式 + Impeccable；**禁用**付费 Refero/Mobbin、云端代理。

---

## 1. Problem and Target User

- **谁**：按课进度学的孩子（跟课换单元）。  
- **障碍**：R43 后单元进 overflow「更多练习」；当前排在学新词/复习错词/自测**之后**，首屏不易见；细顶栏只显书名，选了单元后持久反馈弱（仅 1.4s 弱 hint）。  
- **为何现在**：B01/B03/B05 已收口；RICE 未完成最高为 B04（14.0）；B06/B07/设备项或依赖纸质/真机，本轮可落体验抛光。

## 2. Evidence and Desired Outcomes

| 证据 | 出处 | 期望结果 |
|------|------|----------|
| 「单元路径藏深」 | 迭代 PRD §2.2 | overflow 内「选择单元」打开即首屏可见 |
| B04 成功度量 | RICE 表 | 筛选反馈不挡双 CTA；弱提示/细顶栏可读当前单元 |
| 跟课优先 | ux-guidelines §4 | 不恢复芯片墙；入口仍在 overflow |

## 3. Scope and Non-Goals

### 做
- overflow「更多练习」内把「选择单元」提到**列表首项**（学新词等仍保留）。  
- 细顶栏：有单元筛选时进度副文案持久带当前单元名（如 `今日 n/g · 书 · Unit X`）；无筛选不加噪音。  
- 已筛选时 overflow 单元行用 teal 语义（勾/副文案），便于回看。  
- 切单元仍用静默重载 + 短弱 hint（不 SnackBar 挡 CTA）；既有 `unit_picker_*` / `unit_filter_hint` keys 保留。  
- 单测 + 窄浅/窄深 overflow 截图；requirements/retro；`git push github master`。

### 不做
- 恢复主列单元芯片墙。  
- 改 `friendly_thumb` / `thumb_*`。  
- 改 QuizEngine / SRS / 词表内容。  
- 我的页单元进度大改（R30/R47 已有）。  
- 付费调研、云代理、无关 `vercel.json`。

## 4. Requirements and Acceptance Criteria

| ID | 行为 | 验收 |
|----|------|------|
| A1 | 打开 overflow 后无需滚动即见「选择单元」且为列表第一项 | widget 测顺序 + `r48-overflow-narrow-light.png` |
| A2 | 选单元后细顶栏副文案含单元名；双 CTA 仍可见；无 SnackBar | `unit_filter_ui_test` + 截图 |
| A3 | 已筛选时 overflow 单元行可见当前单元副文案 | 截图/测 |
| A4 | 既有 unit picker / today_task_* keys 不删；相关 flutter test 绿 | CI/本地 |
| A5 | docs/shots/r48-* + acceptance；requirements/retro；push | tip 可查 |

## 5. User Journey

1. 学习页点 ⋮ → 首项「选择单元」→ 选 Unit → 回到词卡，顶栏可见「· Unit」。  
2. 再开 ⋮ → 单元行副文案仍显示当前单元，可再换。

## 6. Success Measurement

- 从「要换单元」到选中：overflow 打开后 0 滚动可见入口。  
- 回归：`unit_filter_ui_test` · `today_task_test` · `r43_learn_wow_test` · learn layout。

## 7. Risks

| 风险 | 应对 |
|------|------|
| 重排导致 today_task 测假设顺序 | 测以 key 为准，不依赖索引；补「首项是单元」断言 |
| 顶栏文案过长溢出 | ellipsis；单元名优先夹在书名后 |
| 时间盒 | 不砍重排+顶栏持久；不做宽屏双栏 |

## 8. Implementation Context

- 主改：`lib/screens/learn_screen.dart`（`_openMorePractice` 顺序 + `thinChrome` 文案）  
- 测：`unit_filter_ui_test` 扩展；新 `r48_*_shot_test`  
- 不动拇指；machineId `48ac8334-4d7a-4bfd-8f6c-f2820d793124`

## 9. RICE 简述

Reach 5 × Impact 1 × Conf 0.70 / Effort 0.25 = **14.0**（迭代表 #4；B01/B03/B05 已完成）。

## 10. 变更

| 日期 | 说明 |
|------|------|
| 2026-10-23 | 首版：R48 选 B04；进行中 |
