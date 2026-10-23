# 复盘

## Round 1（2026-10-23）

- 计划：搭 Flutter 项目 + 闪卡学习 + 词书种子 + 简单进度 + 测试
- 实际：本地安装 Flutter 3.47.7；项目路径 Documents\vocab_helper；Expo 半成品已改名搁置
- 卡住：首次 flutter 下载 Dart/SDK、precache 占锁；云端代理被用户明确禁用
- 根因：环境从零开始 + 路径切换（云端→本地→Expo→Flutter）
- 预防：先确认本机工具链再选型；长任务加锁时避免并行 flutter 命令

## Round 2（2026-10-23）
- 计划：产品/交互设计写入流程；加入沪教版；选型交互展示词数
- 实际：docs/design-r2.md；沪教版三～六 + 七年级；catalog 含 wordCount
- 卡住：公开沪教全书 JSON 难找，四～七年级用精选
- 预防：优先找可下载结构化词库；精选需标注来源

## Round 3（2026-10-23）
- 计划：我的页当前词书+清空本词书进度；学完反馈；脚注补沪教；测试
- 实际：ProgressStore 按词书前缀清理；MeScreen 卡片与确认框；learn 完成态；progress_store_test
- 卡住：无
- 预防：进度键带词书前缀，便于按书清理

## Round 4（2026-10-23）
- 计划：学习卡英文 TTS 朗读按钮；设计说明；测试
- 实际：flutter_tts + WordSpeaker 抽象；卡片右上角喇叭；FakeWordSpeaker 测试
- 卡住：Windows TTS 依赖本机语音包，真机听感需用户确认
- 预防：TTS 用接口隔离，便于测试与换引擎

## Round 5（2026-10-23）
- 计划：词书页点选切换；确认对话框；测试回归
- 实际：BooksScreen onTap + store.setSelectedBookId；保留全屏选型入口
- 卡住：无
- 预防：高频路径提供列表直达，全屏选型作首次/细筛

- 补充：Windows 需 nuget.exe（已装到 C:\Users\user\tools）才能编 flutter_tts


## Round 6（2026-10-23）
- 计划：每日目标设置与进度展示
- 实际：ProgressStore.dailyGoal；我的进度条；学习页今日进度；夹取 5～200
- 卡住：无
- 预防：目标数值做夹取，避免 0 除与离谱输入

## 过程复盘（每 6 轮 · 2026-10-23）
- 时间：同日连续多轮，单轮多数 <20 分钟；环境与依赖（Flutter 锁、nuget）占了额外时间
- 返工：Expo→Flutter 一次选型切换；flutter_tts Windows 缺 nuget 导致编不过
- 用户发现：暂无正式用户 bug 反馈；需求侧明确「本地、不要云端」
- 可标准化：词书 JSON + catalog 结构已稳定；ProgressStore 前缀约定可写入规则
- 下阶段：词书补全脚本化；Android SDK；发音引擎抽离已完成

## Round 7（2026-10-23）
- 计划：喇叭与翻卡分离；窄窗标题两行
- 实际：朗读放卡片顶栏；翻卡仅内容区；标题/进度分行
- 卡住：无
- 预防：可点控件不要叠在 GestureDetector 翻卡层上

## Round 8（2026-10-23）
- 计划：错词本持久化 + 我的页复习入口
- 实际：wrong_ids；不认识写入；认识移出；复习错词模式
- 卡住：中途被问安卓/iOS 朗读（代码已支持，缺本机 Android SDK / Mac）
- 预防：平台能力与本机工具链分开说明

## Round 9（2026-10-23）
- 计划：按单元筛选；无 unit 时自动分组
- 实际：Word.unit；withUnits 每 15 词一组；学习页 FilterChip；按词书记住筛选
- 卡住：公开词库多数无单元字段
- 预防：模型预留 unit，导入真数据时可直接用

## Round 10（2026-10-23）
- 计划：英音/美音切换
- 实际：ProgressStore.ttsAccent；我的 SegmentedButton；朗读前 setAccent
- 卡住：系统未装对应语音包时听感可能无差别
- 预防：文案标明依赖系统语音包

## Round 11（2026-10-23）
- 计划：新词自动朗读开关
- 实际：autoSpeak 偏好；开局与换词后 _maybeAutoSpeak；默认关
- 卡住：无
- 预防：出声类功能默认关闭

## Round 12（2026-10-23）
- 计划：扩充小学词书
- 实际：人教/外研/沪教多册各增数十词；刷新 catalog wordCount
- 卡住：公开全书难获，仍为精选+主题扩充
- 预防：导入脚本保留 Merge-Book 去重，便于多轮追加
- 产品反哺需求：词书搜索、单元词数、沪教八九、Android SDK

## Round 13（2026-10-23）
- 计划：词书搜索；学习页本单元词数
- 实际：BooksScreen 搜索命中切换词书；learn 副标题本单元计数
- 卡住：跨全库搜索同步加载，已限 40 条
- 预防：后续可建内存倒排索引

## Round 14（2026-10-23）
- 计划：建立需求单一来源文件；修复 R13 残留；README 写明
- 实际：docs/requirements.md；README 必读指引；dev-rules #13；补 _unitWordCount
- 卡住：无
- 预防：需求只进 requirements.md，避免聊天与 backlog 双源

## Round 15（2026-10-23）
- 计划：按 requirements P0 加沪教八/九年级
- 实际：hj-jh-8 / hj-jh-9 精选；刷新 catalog；勾选 requirements
- 卡住：无全书公开 JSON
- 预防：精选必须在 source 字段标明

## Round 16（2026-10-23）
- 计划：错词本可选只复习当前单元
- 实际：Me 双入口；LearnScreen.reviewWrongUnitScoped；filterWrongWords 单测；design-r16
- 卡住：无
- 预防：错词「全部」与学习单元筛选解耦，避免误以为复习错词总会被单元截断


## Round 17（2026-10-23）
- 计划：requirements P1 — 真实 unit，至少一套人教初中
- 实际：pep_jh_7a / 7b 写入近似 Unit 标签；source 标明非官方
- 卡住：无公开权威单元-词对应 JSON
- 预防：近似划分必须写进 source；有对照表再替换
## Round 18（2026-10-23）
- 计划：按 requirements 落地「看中文选英文」自测；勾选 R16 主需求与错词本单元抛光
- 实际：QuizEngine + QuizScreen；我的双入口 + 学习页 AppBar；错选进错词本、选对移出；design-r18
- 卡住：无
- 预防：出题逻辑保持纯函数便于单测；自测答对不 markLearned，避免与闪卡「认识」语义混淆

## Round 19（2026-10-23）
- 计划：学习页「今日任务」三入口（学新词 / 复习错词 / 自测），对齐 design-r19 §4.1
- 实际：LearnScreen 任务条 + HomeShell 联动；ValueKey 单测；无错词 Tooltip+辅文；maxWidth 520
- 卡住：widget 测与 Segmented「自测」文案冲突，改用 ValueKey；有错词时二次 pump 场景未稳定，改用 store 单测补角标数据
- 预防：任务条按钮加稳定 Key；UI 验收交给 单词UI设计（fullscreen/narrow/light/dark）

## Round 22（2026-10-23）
- 计划：听音选义自测（Segmented + TTS 降级 + FakeWordSpeaker 单测），对齐 design-r22
- 实际：quiz_variant / listenMode 引擎 + UI；TTS 失败整轮降级看义；无语音包禁用听音段；UI 验收通过
- 卡住：无；美感抛光刻意留给 R25，避免听音主线膨胀
- 预防：有声题型必须预置「失败整轮降级」与单测 FakeSpeaker；功能验收与体验跃迁可分轮，但要写清边界


## Round 23 · 连续打卡周视图（2026-10-23）

- 按日 day_count_ 归档 + 自然周七态比「只显示 streak 数字」更能看见习惯。
- 改目标不重算历史，避免家长调目标后「伪达标」。

## Round 25 · 体验跃迁（2026-10-23）

- 功能绿 ≠ 体验绿；ux §8 美感底线要进验收。
- 闪卡做主角、点按 ≤220ms 回声，比堆新模式更能去脚手架感。

## Round 24 · 跨词书搜索索引（2026-10-23）

- 预建索引比每次输入扫库更稳；就绪前给进度、就绪后重跑同一查询，避免空窗。
- 截断 40 + 稳定序（当前书优先）够用，别做成无限列表。

## Round 26 · 拼写默写（2026-10-23）

- 提取练习接在再认（看义/听音）后；判分纯函数便于单测。
- 交验必须带键盘弹起截图，否则 UI 无法验「检查不被挡」。

## Round 27 · pep-ps-4 样板扩充（2026-10-23）

- 计划：一本样板扩到 ≥220 + unit + source 短标；四态 catalog 交验
- 实际：243 词 Unit1–12；sourceLabel「扩充词表」；UI 目视通过（2026-10-23）
- 顺利：内容脚本卡覆盖率 + 独立 shot 测，比手点快；不做全库避免膨胀
- 改进：交验前在 requirements 把「进行中」收口模板备好（完成详情段），少一次文档补丁
- 规则：样板先于全库；sourceLabel 与 JSON source 分层（已够用，不升 dev-rules）


## Round 28（2026-10-23）
- 计划：我的页导出本词书已学进度（纯文本预览 + 复制/分享）
- 实际：ProgressExport + MeScreen bottom sheet；入口「导出本词书进度」；复制 SnackBar；四态预览截图
- 卡住：首交截图只截到入口（RepaintBoundary 未包 modal overlay）→ UI 打回
- 根因：shot root 在 Scaffold body 内，sheet 在 navigator overlay 外
- 预防：含对话框/sheet 的截图用 MaterialApp.builder 包住 navigator；截前 pumpAndSettle；CJK 勿强绑 monospace

## Round 29（2026-10-23）
- 计划：我的页「待复习 N」可点 → 到期词 sheet +「开始复习」进认读（沿用 R20 队列）
- 实际：dueReviewEntriesForBook；MeScreen InkWell + bottom sheet；空态「去学新词」；四态+空态截图；UI 通过
- 顺利：列表过滤/排序单测与 UI 测分开；shot 用 MaterialApp.builder 包 overlay（承接 R28 教训）
- 注意：空列表勿挂转圈（会拖死 pumpAndSettle）；entries 空则短路结束 loading
- 预防：含 sheet 的交验清单必须含预览/列表态，不只入口数字


## Round 30（2026-10-23）
- 计划：我的页「单元进度」sheet — 按 unit 已学/总/错词；点行复用现有单元筛选进学习
- 实际：unit_progress 聚合 + MeScreen sheet；SnackBar「已筛选 · {unit}」；五态截图；UI 通过（e9f79be）
- 顺利：聚合纯函数单测与 UI 测分开；pep-ps-4 自带 Unit 1–12，截图不必造假 unit
- 注意：loadBook 会 withUnits()，生产词书几乎总有 unit；「全无 unit」空态用合成 WordBook 单测覆盖即可
- 预防：sheet 截图继续用 MaterialApp.builder + ColoredBox 铺底，避免黑边被当成深色主题（承接 accent-tts 教训）


## Round 31（2026-10-23）
- 计划：自测第四档「词」看词选义 — 英文题干 + 四中文义；窄窗义词听写
- 实际：quiz_variant=word；听音同款义项去重；我的页副文案四档；UI 首轮打回后宽窗 2×2 四义同屏（b66fcb2）
- 卡住：宽窗 900×700 纵向 ListView 只露 3 项，第 4 项被「查看结果」顶出首屏
- 根因：矮屏 Expanded 剩余高度 < 4×56；默认滚动位裁掉一项
- 预防：多选项交验必须含宽×矮；空间不够改网格/压缩题干，勿假设 ListView「可滚」等于「首屏齐全」


## Round 32（2026-10-23）
- 计划：自测题池 Chip「全部词 | 只测错词」；尊重单元；四档通用；无错词提示；可选我的「去测错词」
- 实际：buildQuizPool + QuizScreen FilterChip；Me「去测错词」；有错词四态一次过（74ff88e）；空态首交因 prefs 缓存仍带 6 条错词被打回，显式 sync 后重拍 SnackBar 通过（e637ec7）
- 卡住：同一次 testWidgets 内 setMockInitialValues 不刷新已打开的 SharedPreferences，空态截图与窄浅几乎同帧
- 根因：InMemory prefs 实例跨 capture 复用；wrong_ids 未写回清空
- 预防：多 capture 必须 open 后按意图 sync（clear/markWrong）；空态断言 wrongCount==0 且文案无「· N」后再 toImage

## Round 33（2026-10-23）
- 计划：todayCount 上升沿跨 dailyGoal → 同日一次轻反馈；我的页完成态
- 实际：bumpTodayCount 返回 celebrate + goal_celebrated_ymd；我的「今日已完成 · n/n」一次过（2b6bfdb）；首交 MaterialBanner 标题被 AppBar 槽高裁切打回，改 Overlay 顶栏轻卡片后通过（a7e54fa）
- 卡住：MaterialBanner 多行 content 在 Scaffold banner 槽内高度不够，只露副文「已学 n/goal」+「继续」
- 根因：Banner 槽按单行/旁挂 actions 布局，Column 标题被裁；截图还曾把 Overlay 放在 RepaintBoundary 外
- 预防：多行非模态提示优先 Overlay/自定义卡，勿依赖 MaterialBanner 多行；shot 的 RepaintBoundary 须包住 MaterialApp（含 Overlay）

## Round 34 · 听写自测（2026-10-23）
- 计划：自测第五档「默/听写」— 听音后默写；判分前不露拼写；复用 R22 TTS + R26 输入判分 + R32 题池
- 实际：`quiz_variant=dictation`；窄「默」/宽「听写」；自动朗读+再听；空交不判错；四态+输入截图；UI 通过（tip `3da2979` → 收口 `4d45ff2`）
- 顺利：听+写组合不新开引擎；行为项（自动播/空交/TTS 降级）靠 FakeWordSpeaker 单测 Soft-pass，截图专攻无泄露与档标
- 注意：截图环境 Material 图标呈空方块（与既往轮一致，不单打回）；勿为图标假阳性重拍
- 预防：有声+输入题型 — 难截听感可 Soft-pass（须单测），答案泄露与窄宽档标必须有截图证据

## Round 35 · 错题再练（2026-10-23）
- 计划：自测结束页有错→「错题再练」；本场错词去重池；档锁定；「回学习」主按钮；自验截图
- 实际：`applySessionWrong`/`buildRetrySession`；结束页 Outlined+Filled；六图；UI 自验通过（tip `691c43f`）
- 协作：本轮起单 bot「单词迭代」全流程，不再交 UI/PM bot
- 顺利：引擎纯函数先落地再接线；seed 路径用选项并集作干扰词书，单测不必真加载 JSON
- 注意：去掉「再测一轮」主 CTA，全对只留「回学习」——与旧 quiz-end 验收文案不同，以 design-r35 为准
- 预防：结束页 CTA 改版必同步改旧 shot/acceptance 文案预期；再练中务必锁 Segmented，避免「再练却切档」跑题

## Round 36 · 沪教牛津2024七上词书（2026-10-23）

- 计划：上架沪教牛津 2024 七上（六三 Unit1–8）正式词书，接近 ~337；旧 `hj-jh-7` 标明精选非全书
- 实际：`hj-ox-7a-2024.json` **330** 词上架（tip `2efb150`）；catalog sourceLabel「2024六三」；单测 load/count/8 units/无空义；词书列表窄浅截图自验通过
- **诚实缺口**：较 Quizlet 总表参考 337 **仍差约 7 词**；公开源交叉后不以猜词凑满；草稿 `.draft.json` 保留对照；待纸质课本核对再补
- 并行：单元点选 sheet `1626625`、学习页词卡放大 `74dd9bb` 不回滚；本轮收口不启动 R37/R38
- 顺利：内容轨与布局轨分 commit，互不抢改
- 预防：教材词表轮必须写清「目标 vs 实际上架」差额；差词进 retro，勿 silently pad

## 2026-10-23 · R38 简易记忆曲线

- 在 R20 上把档位拉到 1/3/7/14/30（封顶 stage4）；不认识/自测错仍回 1 天桶。
- UI 只做可解释短提示（下次·文案）+ 我的弱说明；不做 EF/曲线图。
- 旧 stage3 下次认识进 30 天档；单测覆盖升档/打回/封顶/兼容。
- 截图：学习提示窄宽深浅 + 我的两态。
## Round 39（2026-10-23）
- 计划：错词本可浏览清单（我的入口 → sheet 词+义 → 复习/测）
- 实际：WrongBookList 组装+截断；MeScreen 入口+sheet；CTA 置标题下以免 drag-handle 滚出首屏；单测+六图自验
- 卡住：Material 底栏 sheet 在测试里坐标常低于视口；底部 sticky CTA 易不可见
- 预防：双 CTA 的 sheet 优先「标题下即 CTA」；截图前 ensureVisible

## Round 40（2026-10-23）
- 计划：无选中词书时 Setup 预选沪教牛津2024七上；Setup/Books 标「推荐」
- 实际：WordbookRepository.recommendedBookId；Setup 顶注+预选；Books subtitle「推荐」；单测拆文件避 prefs 污染；首轮两张窄浅；收口补齐四态截图 + pep-ps-3 keep 测
- 卡住：① Books ListView 惰性构建需 scrollUntilVisible（R41 已置顶）；② 同文件连续两个 Setup testWidgets 第二例 hint 丢失——合并为单 testWidgets 双场景
- 预防：推荐卡验收必须可见（scroll/置顶）；Setup 多场景 prefer 单 testWidgets 或分文件；下一轮 R42 弱提示切换

## Round 41（2026-10-23）
- 计划：词书列表把 R40 推荐本置顶为「推荐跟课」，原分组去重
- 实际：`_buildBookSections`；空 version 省略；单测无需滚动；窄浅截图
- 卡住：PowerShell 替换 books_screen 整段易空白符失败 → 整文件重写
- 预防：大块 UI 重构优先整文件写入；推荐可见性与标签分两轮也可合并
## 工具约定（2026-10-23）

- 个人免费使用：产品参考 **跳过付费** Refero / Mobbin；PRD 用 ChatPRD 公开模板 `ai-development-brief` + 公开交互模式即可。
- 单 bot「单词迭代」全流程，无跨 bot 交接。
