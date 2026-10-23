# PRD · 学习页眼前一亮大改（Learn Wow / R43）

**模板**：ChatPRD public ai-development-brief  
**产品**：单词小助手（Flutter ocab_helper）  
**关联设计**：[design-r43.md](design-r43.md)  
**状态**：设计就绪 · **R42 后立刻开发**（2026-10-23）  
**协作**：单 bot「单词迭代」全流程；免费工具 only（ChatPRD 公开模板 + Impeccable / frontend-design 思路）；**不用**付费 Refero/Mobbin MCP、不开 cloud agents。

---

## 1. 问题与目标用户（Problem and Target User）

**谁**  
- 主用户：用沪教牛津 2024 七上（及同类词书）跟课认读的中小学生；家长旁观可接受。  
- 设备优先：**手机竖屏**；iPad / 横屏走更宽双栏。

**障碍（已观察，非臆造调研）**  
- 学习进行中词卡仍偏小、像 MVP；顶栏 chrome 偏忙（任务条、模式芯片、进度文案叠层）。  
- SnackBar 易盖住底部 CTA；芯片堆砌、层级扁平，一眼看不到「单词是主角」。  
- 用户明确要求：R42 收完后做一版**大的改造**，要「眼前一亮」。

**为何重要**  
- 认读是每日最高频路径；视觉与交互若仍像仪表盘，再多题型也难建立「认真学一会」的沉浸感。  
- 跟课默认书（hj-ox-7a-2024）已就绪；本轮把注意力从「找书」拉回「学词体验」。

**JTBD**  
- 当我打开「学习」开始认读时，我想一眼只盯着当前单词，用大按钮做「认识 / 不认识」决定，并在翻到下一词时感到节奏清晰——而不是在一堆芯片和次要入口里找主操作。

---

## 2. 证据与期望结果（Evidence and Desired Outcomes）

**证据（已有）**  
- 历史反馈：词卡小、chrome 忙、SnackBar 盖 CTA、chip dump、层级平。  
- 既有约定：[ux-guidelines.md](ux-guidelines.md)（主角清晰、禁紫渐变/Banner 墙）；[design-r36-learn-layout.md](design-r36-learn-layout.md)（词卡 ≥55% 高）；R25 呼吸感已做过一轮但未达「眼前一亮」。  
- 用户授权：R42 后立刻大改；手机竖屏优先；保留现有自测档与 SRS。

**公开模式参考（散文引用，无付费 URL）**  
- Duolingo 式：一屏一任务、顶栏极简进度。  
- Quizlet 式：大卡 + 点按揭晓释义。  
- Anki 式：二元判断（认识 / 不认识）驱动复习。

**期望结果**  
- 用户结果：竖屏进入认读后，**单词是绝对主角**；底栏两大胶囊 CTA 无法被忽略；次要模式不占主列。  
- 产品结果：一次可交付的视觉+交互重设计；SRS 间隔、现有 quiz 引擎、书/单元入口、中文文案均保留。

---

## 3. 范围与非目标（Scope and Non-Goals）

**最小有用发布（R43）——单一可交付**  
1. **学习 · 认读进行中（studying）** 视觉与交互大改：大号展示词为英雄、柔和抬升纸质词卡、顶栏仅细进度、底栏双肥胶囊 CTA（认识 / 不认识）。  
2. 次要模式（学新词 / 复习错词 / 自测档等）收入 **溢出菜单或底部 sheet**，主列不再 chip dump。  
3. 学习 idle / 首页态可做**更轻 chrome**（不强制重做整站）。  
4. 动效：进/出卡、揭晓释义、答对微反馈；**200–300ms**；答后卡 flip/slide；CTA 轻按压缩 + 可选轻触感。  
5. 宽/横屏：词卡左栏 / CTA 右栏。  
6. 竖屏分区硬指标：顶 chrome ≤15% 高；词卡 ≥55%；CTA 区 ≥18%。  
7. 中文文案表 + Key + 截图清单见 design。

**已做决策（方向锁，不可漂）**  
- **唯一主方向**：focused study session（专注学词会话）。  
- **拒绝**：紫/靛渐变皮肤、芯片堆、奶油底装饰衬线换字、泛 Material 默认密度。  
- **记忆点**：答后卡 flip/slide + CTA 软按压缩。  
- R42 弱提示若仍在学习顶：并入极薄顶栏或 overflow，**不得**再挤掉词卡主角区。

**非目标**  
- 新自测题型、改 SRS 算法、云同步/账号。  
- 付费竞品库拉图（Refero/Mobbin）。  
- 重做「我的 / 词书」整页、换主题色种子为紫系。  
- 本轮不实现 Flutter（文档先行；R42 实现并行、互不打断）。

---

## 4. 需求与验收标准（Requirements and Acceptance Criteria）

| ID | 行为 | 验收（Given / When / Then） |
|----|------|---------------------------|
| W1 | 英雄词 | Given 认读进行中，When 看主卡，Then 英文词为最大层级（竖屏约 44–56sp 级），音标/提示次要 |
| W2 | 分区比例 | Given 手机竖屏浅色，When 量 AppBar 下内容区，Then 顶 chrome ≤15%、卡区 ≥55%、CTA ≥18%（允许 ±2% 测量公差） |
| W3 | 双 CTA | Given 未揭晓或已揭晓，When 看底栏，Then 仅两大胶囊「不认识」「认识」；触高充足（竖向 padding ≥14） |
| W4 | 揭晓 | Given 释义隐藏，When 点卡（或等价热区），Then 中文释义以 Quizlet 式揭示出现；喇叭与翻卡热区不冲突 |
| W5 | 次要入口折叠 | Given 认读进行中，When 看主列，Then 无模式芯片墙；学新词/复习/自测等在 overflow 或 sheet 内可达 |
| W6 | 动效 | Given 点「认识」或「不认识」，When 切下一词，Then 卡有 flip 或 slide（二选一主实现）；时长 200–300ms；无循环装饰动画 |
| W7 | CTA 反馈 | Given 按下 CTA，When 按住，Then 有 scale 压缩；松手后恢复；可选 haptic（设备支持时） |
| W8 | 宽布局 | Given 宽≥700 或 landscape 且宽≥600，When 认读中，Then 卡左 / CTA 右，词卡不扁 |
| W9 | 保留逻辑 | Given 任意书（含 hj-ox-7a-2024），When 点认识/不认识，Then SRS 间隔与错词入出本行为与 R38/既有一致；自测引擎入口仍可达 |
| W10 | 文案与色 | Then 中文口语 UI；深浅走 ColorScheme；无紫靛渐变皮肤；无英文调试串 |
| W11 | 截图门禁 | 窄浅认读 ≥1、窄深 ≥1、宽或横 ≥1；清单写入 docs/shots/r43-ui-acceptance.md（实现轮） |

---

## 5. 用户旅程与失败状态（User Journey and Failure States）

1. **进入**：打开「学习」→ 若已在认读队列 → 直接进入 focused studying。  
2. **专注**：见细顶进度 + 大纸卡单词；可点卡揭晓释义、点喇叭朗读。  
3. **判断**：点「认识」或「不认识」→ 卡 flip/slide 离场 → 下一词进入。  
4. **切换模式**：点溢出菜单 / sheet → 选学新词、复习错词、某档自测等 → 进入既有流程。  
5. **完成**：队列空或达今日目标 → 沿用既有空态/达成反馈（R33），文案可轻抛光但不新开范围。

| 态 | 表现 |
|----|------|
| 加载 | 卡区骨架或居中 progress；不出现芯片墙 |
| 空队列 | 明确下一步 CTA（去选单元 / 学新词 / 复习）；仍保持轻 chrome |
| 无释义数据 | 揭晓区显示友好中文「暂无释义」；不崩 |
| TTS 失败 | 既有失败提示；不得用 SnackBar 长时间盖住双 CTA（改顶/浮动且避开底 ≥72） |
| R42 弱提示仍显示 | 并入顶薄条或可今日关闭；高度计入 ≤15% chrome |

---

## 6. 成功度量（Success Measurement）

本地个人应用，无分析后台。本轮成功 = W1–W11 自验通过 + 截图入库 + 用户主观「比上一版更亮眼」（对话确认即可）。  

**提案埋点（若日后有）**：learn_wow_reveal / learn_wow_know / learn_wow_unknown / learn_wow_overflow_open；基线未知。  
**护栏**：不回归 SRS；自测各档仍可从 overflow 进入；无紫渐变；无 chip dump。

---

## 7. 风险与待决（Risks and Open Questions）

| 项 | 风险/未知 | 下一步 |
|----|-----------|--------|
| 与 R42 顶提示争高 | 弱提示可能突破 15% chrome | R42 实现后量高度；超则只留图标/溢出入口 |
| flip vs slide | 两套动效成本 | design 定主实现 **slide 离场 + 轻 fade 入场**；flip 为加分项 |
| 今日任务三入口折叠 | 用户找不到自测 | overflow 内保留原 keys 文案；验收点得到 |
| elevation 与 ux 约定 | guidelines 曾写 elevation 0 | 本轮纸卡允许 **极低阴影/表面色抬升**；仍禁重 Material 默认密堆 |
| 字体 | 「display」易漂成装饰衬线 | 用现有/系统 **无装饰展示级字重**，禁止奶油底衬线换字皮肤 |

---

## 8. 实现上下文（Implementation Context）

**栈**：Flutter；仓库本地 ocab_helper。  

**提案可改（实现轮，非本提交）**  
- lib/screens/learn_screen.dart 及词卡/CTA 子组件  
- 主题表面色/阴影 token（若有 app_theme）  
- 单测 keys；docs/shots/r43-*.png + acceptance  

**必须保留**  
- SRS（R20/R38）、quiz 各档引擎、书/单元筛选入口、中文 copy、AppTheme.seed 非紫系  

**本提交只写文档**：prd-learn-wow.md、design-r43.md、
equirements.md 排期；**不改 Flutter**。

---

## 变更

| 日期 | 说明 |
|------|------|
| 2026-10-23 | 初稿：ChatPRD ai-development-brief；方向锁 focused study session；R42 后立刻 |
