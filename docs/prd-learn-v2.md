# PRD · 学习页跟课可见性补齐（Learn v2 / R42）

**模板**：ChatPRD public `ai-development-brief`  
**产品**：单词小助手（Flutter `vocab_helper`）  
**关联设计**：[`design-r42.md`](design-r42.md)  
**状态**：可开发（2026-10-23）  
**协作**：单 bot「单词迭代」全流程（产品→design→开发→自验 UI→复盘）；不外派其它 bot。

---

## 1. 问题与目标用户（Problem and Target User）

**谁**  
- 主用户：跟课学单词的中小学生（及旁观家长）。  
- 场景：已选过人教 PEP 等「精选/旧」词书，或从旧版本升级后仍停在非推荐本。

**障碍（已观察）**  
- R40 只在「未选书」时默认推荐 `hj-ox-7a-2024`；R41 只在「词书列表」置顶推荐。  
- 已选其它书的用户打开「学习 / 我的」时，**看不到**跟课推荐，除非主动进词书页滚动/搜索。  
- 请求：在学习主路径上补一条可忽略的发现入口，而不是再堆仪表盘或强推弹窗。

**为何重要**  
- 跟课课本是产品默认教育路径；看不见推荐 → 继续刷错书，与 R36～R41 投入错位。

**JTBD（Jobs to be done）**  
- 当我正在用一本非推荐词书学习时，我想知道「学校跟课该用哪本」，并能一键去切换，且不被打断当前认读/自测。

---

## 2. 证据与期望结果（Evidence and Desired Outcomes）

**证据（已有，非臆造调研）**  
- 代码事实：`WordbookRepository.recommendedBookId = 'hj-ox-7a-2024'`（R40）。  
- R41 已把推荐卡置顶到 Books，但 Me / Learn 无回流提示。  
- 用户路线图权威诉求含「换成沪教牛津 2024 七上正确词表」；跟课可见性是该路径的延续。  
- **假设（待自验）**：非推荐书用户在「我的·当前词书」看到一行弱提示后，会点「去切换」进入已置顶的推荐卡。

**期望结果**  
- 用户结果：非推荐书时，在「我的」必见、「学习」可见（可今日关闭）跟课提示；一点「去切换」进入换书。  
- 产品结果：不增加 Banner 墙、不自动换书、不挡词卡主角（对齐 ux-guidelines §8）。

---

## 3. 范围与非目标（Scope and Non-Goals）

**最小有用发布（R42）**  
1. 当前 `selectedBookId != recommendedBookId`（且均非空、catalog 含推荐 id）时显示弱提示。  
2. **我的**：当前词书卡内一行浅底 +「去切换」。  
3. **学习**：顶栏下、今日任务之上一行弱链 +「今日不再」。  
4. 「去切换」复用现有 `onChangeBook`（进 Books；推荐已置顶）。  
5. 学习页 dismiss 键：`recommend_hint_hide_ymd` = 当日 `yyyy-MM-dd`；跨日自动恢复。  
6. 中文口语文案（见设计稿文案表）；深浅色用 `ColorScheme` 容器色。

**已做决策**  
- 同日学习提示最多可关；「我的」提示不随「今日不再」隐藏（提案已定）。  
- 不做 Dialog / MaterialBanner 槽 / 自动换书。

**非目标**  
- 强推 Dialog、自动覆盖已选、迁移旧书进度。  
- 改 R41 列表排序、下架精选书、账号/云同步。  
- 学习页再次放大改版（词卡布局见既有 learn-layout；本轮只加一行弱提示）。  
- 付费竞品库（Refero/Mobbin）拉参考图——本轮仅用公开模板 + 通用产品模式（见 retro）。

---

## 4. 需求与验收标准（Requirements and Acceptance Criteria）

| ID | 行为 | 验收（Given / When / Then） |
|----|------|---------------------------|
| R1 | 非推荐书显示提示 | Given 选中 `pep-ps-3`，When 打开「我的」「学习」，Then 分别可见 `me_recommend_switch_hint` / `learn_recommend_switch_hint` |
| R2 | 推荐书不显示 | Given 选中 `hj-ox-7a-2024`，When 打开两页，Then 两处 hint 均不存在 |
| R3 | 去切换 | Given 提示可见，When 点「去切换」，Then 触发 `onChangeBook`（单测 verify） |
| R4 | 今日不再（仅学习） | Given 学习提示可见，When 点「今日不再」，Then 写入今日 ymd；同学期再进学习不显示；「我的」仍显示 |
| R5 | 未选书 / catalog 无推荐 | Then 不显示（走 Setup / 防御） |
| R6 | 视觉门禁 | 窄浅：我的+学习各 ≥1；另加宽或深 ≥1；无 overflow；不盖词卡主区 |
| R7 | 文案 | 使用设计稿中文文案；禁止英文调试串上屏 |

---

## 5. 用户旅程与失败态（User Journey and Failure States）

1. **进入**：孩子打开 App → 学习 Tab（或我的）。  
2. **发现**：若当前书 ≠ 推荐 → 见弱提示（学习可「今日不再」）。  
3. **行动**：点「去切换」→ Books（首屏「推荐跟课」）→ 点推荐卡切书。  
4. **完成**：学习/我的提示消失；继续认读。  

| 态 | 表现 |
|----|------|
| 空/未选书 | 不显示 hint |
| 已是推荐 | 不显示 |
| dismiss 当日 | 学习隐藏；我的仍在 |
| 换书失败/未换 | 提示仍在；不报错打扰 |
| 加载中 | 不抢词卡/进度条；hint 随书名就绪后出现 |

---

## 6. 成功度量（Success Measurement）

本地个人应用，**无分析后台**。本轮成功定义为验收表 R1–R7 自验通过 + 截图入库。  

**提案（若日后有埋点）**：`recommend_hint_show` / `recommend_hint_cta` / `recommend_hint_dismiss` 次数；基线未知。  
**护栏**：学习页词卡区不被挤到 <50% 屏高；不得出现循环动画或 error 色恐吓条。

---

## 7. 风险与待决（Risks and Open Questions）

| 项 | 风险/未知 | 下一步 |
|----|-----------|--------|
| 提示打扰 | 学习顶栏再加一行可能挤任务条 | 实现时单行 `bodySmall`；自验窄窗；必要时只保留「我的」为主、学习为辅（设计已定辅） |
| 文案长度 | 「沪教牛津2024七上」在窄窗可能折行 | 我的允许两行；学习主文缩短为「跟课推荐」 |
| 推荐 id 变更 | 写死书名文案 | 提案：展示用 catalog 标题，键仍比 id；本轮可用固定中文（与 R40 一致） |
| 竞品参考 | 跳过付费 Refero/Mobbin | 采用公开模式：settings 内 inline tip + text button；学习顶 optional dismiss chip（见 design 参考说明） |

---

## 8. 实现上下文（Implementation Context）

**栈**：Flutter；仓库 `C:\Users\user\Documents\vocab_helper`。  

**可改**  
- `lib/screens/me_screen.dart`（当前词书卡内插入 hint）  
- `lib/screens/learn_screen.dart`（标题行下、今日任务上）  
- `lib/services/progress_store.dart`（或等价 prefs）：`recommend_hint_hide_ymd` 读写  
- 单测 + `docs/shots/r42-*.png` + `docs/shots/r42-ui-acceptance.md`

**复用**  
- `WordbookRepository.recommendedBookId`  
- `MeScreen.onChangeBook` / 学习侧同等换书回调  
- R41 Books 置顶（勿改）

**勿改（除非阻塞）**  
- 词书 JSON、SRS/R38、OCR/R37、Quiz 题型  

**UI 约定**：`AppTheme.seed`、口语文案、禁止首屏多 Banner；hint 用 `secondaryContainer`，非 `error`。

---

## 变更

| 日期 | 说明 |
|------|------|
| 2026-10-23 | 初稿：对齐 ChatPRD `ai-development-brief`；落地 R42 |