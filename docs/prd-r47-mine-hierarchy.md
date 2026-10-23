# PRD · R47 我的页信息层级（B05）

**模板**：ChatPRD public `ai-development-brief`  
**产品**：单词小助手（Flutter · vocab_helper）  
**状态**：已完成  
**对应 backlog**：迭代 PRD [`prd-iteration-rice-2026-10-23.md`](prd-iteration-rice-2026-10-23.md) **B05**（RICE **12.3**，排序 #5）  
**设计**：[design-r47.md](design-r47.md)  
**工具**：免费 ChatPRD 结构 + 公开竞品模式 + Impeccable；**禁用**付费 Refero/Mobbin、云端代理。

---

## 1. Problem and Target User

- **谁**：旁观家长 + 自管进度的孩子。  
- **障碍**：我的页词书/单元/拍照/错词/目标/打卡/导出/口音等同权 Card 墙；口音设置插在今日与自测之间；对照学习/自测「主角清晰 + teal + 纸卡」，仪表盘感回潮。  
- **为何现在**：R45/R46 学测主路径已统一；本轮只整理信息架构与视觉权重，不重做导航、不加账号。

## 2. Evidence and Desired Outcomes

| 证据 | 出处 | 期望结果 |
|------|------|----------|
| 「我的页密度高」 | 迭代 PRD §2.2 | 首屏「当前书 + 今日 + 待复习」主角 |
| B05 成功度量 | RICE 表 | 其余分组折叠或靠后；窄浅截图可辨层级 |
| 学/测已纸卡+teal | R43/R45 | 我的页纸卡圆角24 + 主 CTA `#0D9488` |

## 3. Scope and Non-Goals

### 做
- 首屏纸卡 Hero：当前词书（瘦）+ 今日目标（细进度）+ 待复习入口 + 本周打卡。  
- 行动区：错词本入口 +「自测本词书」Filled teal +「测这些」。  
- 「更多设置」折叠：导出 / 单元进度 / 拍照加词 / 清空进度 / 自测单元与复习错词次要钮 / 朗读口音 / 统计三列。  
- 待复习有数、错词有数、目标达成 → teal 语义（非 seed 蓝抢戏）。  
- 保留既有 ValueKey；竖屏窄优先截图。  
- requirements/retro 收口；`git push github master`。

### 不做
- 重做整站 Tab/导航、加账号/云同步。  
- 改 `friendly_thumb` / `thumb_*_friendly.png`。  
- 新错词/SRS 算法、新题型。  
- 紫渐变、贴纸 Badge、首屏多 Banner。  
- 提交无关 `vercel.json`。

## 4. Requirements and Acceptance Criteria

| ID | 行为 | 验收 |
|----|------|------|
| A1 | 窄浅首屏可见书名 + 今日数字 + 待复习，无口音卡抢首屏 | `r47-hero-narrow-light.png` |
| A2 | 行动区主「自测本词书」teal；错词入口仍可点开 sheet | key + 截图 |
| A3 | 「更多设置」默认收起；展开后导出/单元/口音/统计可用 | `me_more_section` + 旧测绿 |
| A4 | 有到期时待复习用 teal 权重；达成勾用 teal | 逻辑 + 可选 shot |
| A5 | 既有 me_* / export_* keys 不删；相关 flutter test 绿 | CI/本地 |
| A6 | `docs/shots/r47-*.png` + acceptance；requirements/retro；push | tip 可查 |

## 5. User Journey

1. 打开「我的」→ 一眼看清「在学哪本 / 今日差几个 / 有无待复习」。  
2. 要点测或清错词 → 行动区一键。  
3. 要导出/换口音/看统计 → 展开「更多设置」。

## 6. Success Measurement

- 窄屏 390×844：Hero+行动无需滚动即可识别主任务。  
- 回归：R42 推荐 hint、R28 导出、R30 单元、R39/R46 错词、口音缺包提示、统计三列。

## 7. Risks

| 风险 | 应对 |
|------|------|
| 折叠导致旧测找不到/点不到 | 保留 key 在树内；点击类测先 expand `me_more_section` |
| prefs 单测污染 | 一文件一场景；不中途 setMockInitialValues |
| 时间盒 | 不砍 Hero+行动+折叠；宽屏双栏不做 |

## 8. Implementation Context

- 主改：`lib/screens/me_screen.dart`（build 信息架构）  
- 测：export / unit / accent / stats / r42 me hint 等按需补 expand  
- 不动拇指资源；machineId `48ac8334-4d7a-4bfd-8f6c-f2820d793124`

## 9. RICE 简述

Reach 7 × Impact 1 × Conf 0.70 / Effort 0.40 ≈ **12.3** → 排序 #5；R45/R46 已完成，本轮落地 B05。

## 10. 变更

| 日期 | 说明 |
|------|------|
| 2026-10-23 | R47 开工 PRD：承接 B05 我的页信息层级 |
| 2026-10-23 | R47 收口：Hero+行动+更多设置；A1–A6 自验；push github/master |
