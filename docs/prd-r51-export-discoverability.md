# PRD · R51 导出发现性（B10）

**模板**：ChatPRD public `ai-development-brief`  
**产品**：单词小助手（Flutter · vocab_helper）  
**状态**：已收口 · UI 自验通过  
**对应 backlog**：迭代 PRD [`prd-iteration-rice-2026-10-23.md`](prd-iteration-rice-2026-10-23.md) **B10**（RICE **6.0**，排序 #10；B07/B09/B11–B12 跳过）  
**设计**：[design-r51.md](design-r51.md)  
**工具**：免费 ChatPRD 结构 + 公开竞品模式 + Impeccable；**禁用**付费 Refero/Mobbin、云端代理。

---

## 1. Problem and Target User

- **谁**：要备份进度或发给老师的家长（旁观）。  
- **障碍**：R47 把导出收进「更多设置」默认折叠；副标虽写「导出」但仍需展开，3 秒内难找到；空进度预览仅「（暂无）」弱。  
- **为何现在**：B01–B06/B08 已收口；未完成可落最高为 B10（6.0）；B07 需纸质、B09/B11–B12 需设备。

## 2. Evidence and Desired Outcomes

| 证据 | 出处 | 期望结果 |
|------|------|----------|
| 「导出入口发现性」 | 迭代 PRD B10 | 我的页 3 秒内找到导出；预览仍可用 |
| R47 导出进折叠 | design-r47 · me_more_section | 对齐层级：不回 Card 墙；提权到行动区下可见行 |
| R28 纯文本预览 | design-r28 | 复制/分享逻辑零改；空态可读 |

## 3. Scope and Non-Goals

### 做
- 行动区下方、更多设置上方：可见「导出进度」纸卡行（无需展开）；保留 `export_progress`。  
- 「更多设置」副标去掉「导出」；折叠内不再重复导出钮。  
- 无书：行 disabled +「先选一本词书」。  
- 有书但已学+错词皆空：sheet 顶部空态提示；预览仍可复制/分享。  
- 复制钮 Filled teal `#0D9488` 对齐学/测/我的。  
- 单测 + 窄浅/窄深入口 + 空态 sheet 截图；requirements/retro；`git push github master`。

### 不做
- 云同步 / PDF / Excel / 邮件自动发。  
- 重做 Hero/行动主 CTA；改拇指 `friendly_thumb` / `thumb_*_friendly.png`。  
- B07 补词、B09 Vision、B11–B12 Android。  
- 无关 `vercel.json`；付费调研。

## 4. Requirements and Acceptance Criteria

| ID | 行为 | 验收 |
|----|------|------|
| A1 | 窄浅首屏（无需展开更多）可见导出行 | `export_progress` findsOneWidget；截图 |
| A2 | 无书 disabled +「先选一本词书」 | widget 测 |
| A3 | 有书点开 → 预览 + 复制/分享；复制 SnackBar | 既有 export 测绿 |
| A4 | 空进度 sheet 有空态文案；复制仍可用 | 截图 + 测 |
| A5 | 更多设置默认收起；口音仍不在首屏；副标无「导出」 | r47 回归测改绿 |
| A6 | docs/shots/r51-* + acceptance；requirements/retro；push | tip 可查 |

## 5. User Journey

1. 打开「我的」→ Hero / 行动后立刻见「导出进度」。  
2. 点导出 → sheet 预览 → 复制或分享。  
3. 无进度时见空态说明，仍可复制模板文本。

## 6. Success Measurement

- 窄 390：不滚动/不展开即可点到导出（或轻滚仍在行动区下一屏内）。  
- 回归：export UI/shot、me hierarchy（口音折叠）、unit/accent 需 expand。

## 7. Risks

| 风险 | 应对 |
|------|------|
| 与 R47「折叠导出」冲突 | 本轮明确提权；更新 r47 测期望 |
| expand_me_more 用 export 判展开 | 改判 `me_unit_progress` |
| 双入口混淆 | 折叠内删除重复钮 |

## 8. Implementation Context

- 主改：`lib/screens/me_screen.dart`（入口位置 + sheet 空态 + teal 复制）  
- 测：`progress_export_ui_test`、`expand_me_more`、`r47_*`、新 `r51_*`  
- 不动拇指；machineId `48ac8334-4d7a-4bfd-8f6c-f2820d793124`

## 9. RICE 简述

Reach 3 × Impact 0.5 × Conf 0.60 / Effort 0.15 = **6.0**（迭代表 #10；本轮可落）。

## 10. 变更

| 日期 | 说明 |
|------|------|
| 2026-10-23 | R51 开工：选 B10 导出发现性 |

| 2026-10-23 | R51 收口：导出行提权+空态+teal 复制；A1–A6 自验；push github/master |

