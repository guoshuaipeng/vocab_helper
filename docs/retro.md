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
