# Round 23 · UI 验收（交给「单词UI设计」）

**对应**：`docs/design-r23.md` · 我的页「连续打卡」周视图  
**前置**：R6 今日目标；R22 / R25 已通过  
**代码**：78d25d5 / 3318b1a（handoff 7319ae3）  
**单测**：`flutter test` 全绿（47）

## 环境

- [x] 窄窗 ≤400（7 格 `Expanded` 单行；格径 28 / 热区 40）
- [x] 全屏 / 宽窗 ≥900（嵌在今日目标卡内，非统计墙）
- [x] 浅色 / 深色（`ColorScheme`；无贴纸 Badge / 紫渐变 / 火焰循环）

## 入口与布局

- [x] 位置：「我的」今日目标卡片内底部（进度条与「待复习」之下）
- [x] 周定义：自然周**周一～周日**；`weekCheckIns` 只含今天所在周
- [x] 7 格等分单行；格径 28、热区 40；圆点 shape；达标动效 180ms
- [x] 与「已连续 N 天」并存；底部 Stat「连续天数」未删

## 七格状态

- [x] **达标**：实心 `primary` + 小勾
- [x] **未达标**：空心 `outline`
- [x] **无记录**：更浅 `outlineVariant`（不伪造达标；单测覆盖）
- [x] **今日进行中**：描边加粗 2.5 + 半填/内点
- [x] **未来日**：极浅占位，无 onTap（不可点）
- [x] 格上不标 count；Tooltip：已达标 / 未达标（N/目标） / 无记录 / 今日 N/目标 / 未到

## 数据口径

- [x] 某日达标 = `dayCount >= dailyGoal`
- [x] 计数来源：`markLearned` / `bumpTodayCount`；改目标不重算历史（单测）
- [x] `day_count_yyyy-MM-dd` 跨日归档；`ensureDayRolled` / `_archiveIfRolled`
- [x] 连续天数仍用 `streakDays()`

## 文案与动效

- [x] 星期：一…日；「本周打卡」；「已连续 N 天」
- [x] 达标填实 AnimatedContainer 180ms
- [x] 无补打卡 / 社交文案

## 回归 / 不做项

- [x] 今日目标进度条 / 改目标 / streak 数字并存
- [x] **不做**：社交勋章、排行、分享、补打卡、月历、自定义周起始、搬学习页
- [x] flutter test 47/47；跨日归档、周一/周日边界、无历史键、改目标不改归档均有测

## 设计师结论（请填写）

- 结论：**通过**
- 日期：2026-10-23（Asia/Shanghai）
- 验收人：单词UI设计
- 备注：对照 design-r23 达标；无打回项。
