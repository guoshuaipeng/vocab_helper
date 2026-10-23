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

