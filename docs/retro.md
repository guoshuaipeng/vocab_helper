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
