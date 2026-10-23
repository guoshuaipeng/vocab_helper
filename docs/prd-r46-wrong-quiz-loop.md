# PRD · R46 错词本→自测一键闭环（B03）

**模板**：ChatPRD public `ai-development-brief`  
**产品**：单词小助手（Flutter · vocab_helper）  
**状态**：已完成 · UI 自验通过  
**对应 backlog**：迭代 PRD [`prd-iteration-rice-2026-10-23.md`](prd-iteration-rice-2026-10-23.md) **B03**（RICE **20.0**，排序 #3）  
**设计**：[design-r46.md](design-r46.md)  
**词表基准**：沪教牛津2024七上（`hj-ox-7a-2024`）  
**工具**：免费 ChatPRD 结构 + 公开竞品模式 + Impeccable；**禁用**付费 Refero/Mobbin、云端代理。

---

## 1. Problem and Target User

- **谁**：跟课清错词的孩子 / 旁观家长。  
- **障碍**：R39 错词本已可浏览，R32 自测有「只测错词」，但从「看到清单」到「开测」仍绕——sheet 主 CTA 是认读复习，「去测错词」是次要 Outlined；进测后题池 Chip 仍可切回「全部词」，闭环感弱。  
- **为何现在**：R45 自测 chrome 已与学习页对齐（纸卡+teal）；本轮只抛光入口与锁池，不堆新题型。

## 2. Evidence and Desired Outcomes

| 证据 | 出处 | 期望结果 |
|------|------|----------|
| 「到期复习 / 错词闭环可再顺」 | 迭代 PRD §2.2 | 清单内 ≤1 点进错词池自测 |
| B03 成功度量 | RICE 表 | 一键「测这些」进既有错词池档；有锁档提示 |
| R39/R32 已有能力 | design-r39 / r32 | **复用** `QuizMode.wrong` / `buildQuizPool`；不新算法 |

## 3. Scope and Non-Goals

### 做
- 错词本 sheet：主 CTA 改为 Filled teal「测这些」→ `onQuizWrong`；认读「复习这些错词」降为 Outlined 次要。  
- 空态：友好文案 + teal「去学新词」（与 R45 主色一致）。  
- `QuizMode.wrong` 进场：题池**锁在错词**——展示「测这些错词 · N」锁态提示；不可切回「全部词」（book/unit 模式 Chip 行为不变）。  
- 认读错词本轮结束后：提供「测这些错词」一键进同池自测（可选强化闭环）。  
- 我的「学习自测」卡「去测错词」文案对齐「测这些」（有错可点）。  
- 窄屏竖屏优先截图；视觉对齐 R45（teal `#0D9488` / 纸卡不变）。

### 不做
- 新错词进出算法 / SRS / 新题型 / 改 QuizEngine 判分。  
- 改 `friendly_thumb` / `thumb_*_friendly.png`。  
- 跨词书错词合并、滑动删除、sheet 内单元切换。  
- 付费调研、云代理、提交无关 `vercel.json`。

## 4. Requirements and Acceptance Criteria

| ID | 行为 | 验收 |
|----|------|------|
| A1 | sheet 有错：主「测这些」Filled teal → 进 `QuizMode.wrong` | 单测 key + 窄浅截图可见主次 |
| A2 | 进场后题池锁错词；见「测这些错词 · N」；无「全部词」可切 | widget 测 + 截图 |
| A3 | 空态：暂无错词 + 去学新词（teal） | 空态窄浅截图 |
| A4 | book 模式 Chip 切换错词池仍可用（R32 不回归） | `quiz_wrong_pool_test` 绿 |
| A5 | `flutter test` 相关绿；`docs/shots/r46-*.png` + `r46-ui-acceptance.md` | CI/本地 |
| A6 | requirements/retro 收口；`git push github master` | tip 可查 |

## 5. User Journey and Failure States

1. 我的 · 错词本 → 打开 sheet → 点「测这些」→ 自测标题「自测错词」+ 锁池提示 → 用现有五档测完。  
2. 空：sheet「暂无错词」→「去学新词」回学习。  
3. 认读错词结束（可选）：「测这些错词」→ 同上。  
4. 失败：无词书入口不可点；错词池空时 book 模式点 Chip 仍 SnackBar「还没有错词…」（R32）。

## 6. Success Measurement

- 手工/截图：从错词清单到开测 **1 次点击**（关 sheet 后自动 push Quiz）。  
- 回归：R32 Chip 切换、R35 错题再练、R45 chrome keys 均保留。

## 7. Risks and Open Questions

| 风险 | 应对 |
|------|------|
| prefs 单测污染 | 一文件一 mock / 分场景 `pumpWidget(SizedBox.shrink)` |
| 改主 CTA 文案断旧 shot | 更新 r39 依赖 key 的测；新 r46 shot |
| 锁池误伤 book 模式 | 仅 `mode == QuizMode.wrong` 锁；book/unit 仍双 Chip |
| 时间盒 | 砍认读结束 CTA 若超时，**不砍** sheet 主路径与锁池 |

## 8. Implementation Context

- `lib/screens/me_screen.dart` · `_WrongBookSheet`  
- `lib/screens/quiz_screen.dart` · pool chips / title  
- `lib/screens/learn_screen.dart` + `lib/main.dart`（认读结束可选）  
- 服务层：`WrongBookList` / `buildQuizPool` / `QuizMode.wrong` **零改语义**  
- machineId `48ac8334-4d7a-4bfd-8f6c-f2820d793124`

## 9. RICE 简述

Reach 5 × Impact 1 × Conf 0.80 / Effort 0.20 ≈ **20.0** → 排序 #3；R45 已完成 B01，本轮落地 B03。

## 10. 变更

| 日期 | 说明 |
|------|------|
| 2026-10-23 | R46 开工 PRD：承接 B03；requirements 原排「R46」与迭代表「R45 建议 B03」对齐为本编码轮 |
