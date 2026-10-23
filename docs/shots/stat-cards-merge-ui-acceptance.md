# 插队 · 我的页统计卡合并 · UI 验收

**对应**：`docs/requirements.md` · P2「我的页统计卡合并」  
**产品裁定**：不升 R26；无独立 design-rN；按本清单 + ux-guidelines §8/§9  
**代码**：`lib/screens/me_screen.dart`（`_StatsSummaryCard` / `me_stats_summary`）  
**单测**：`test/me_stats_card_test.dart`（`flutter test` 含此项全绿）  
**截图**：同目录 `stat-merge-*.png`（widget 截图 + 本机 Deng.ttf CJK）

## 环境（须附截图文件名）

- [x] 窄窗 ≤400 · 浅色 → `stat-merge-narrow-light.png`
- [x] 窄窗 ≤400 · 深色 → `stat-merge-narrow-dark.png`
- [x] 全屏/宽窗 ≥900 · 浅色 → `stat-merge-wide-light.png`
- [x] 全屏/宽窗 ≥900 · 深色 → `stat-merge-wide-dark.png`

## 布局与信息

- [x] 底部原三张 `_StatCard` 并成 **一张**（三列）
- [x] 数字保留：`learnedCount` / `todayCount` / `streakDays`
- [x] 圆角 20、elevation 0（`AppTheme.cardTheme`）；窄窗三列不折行、无横向溢出
- [x] 今日目标卡内「已连续 N 天」与周打卡仍在；不删 R23

## 文案 · 不做

- [x] 标签可读：「已学单词」「今日新学」「连续天数」
- [x] **不做**：新图表、勋章、第四统计、搬学习页首屏

## 设计师结论

- 结论：（通过 / 打回）
- 日期：
- 验收人：单词UI设计
- 备注：（须基于上列截图；无截图不写通过）
