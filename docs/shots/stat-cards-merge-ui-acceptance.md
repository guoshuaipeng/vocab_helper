# 插队 · 我的页统计卡合并 · UI 验收

**对应**：`docs/requirements.md` · P2「我的页统计卡合并」  
**产品裁定**：不升 R26；无独立 design-rN；按本清单 + ux-guidelines §8/§9  
**代码**：cac37bc · `lib/screens/me_screen.dart`（`_StatsSummaryCard` / `me_stats_summary`）  
**单测**：`test/me_stats_card_test.dart` 绿  
**截图**：同目录 `stat-merge-*.png`

## 环境（须附截图文件名）

- [x] 窄窗 ≤400 · 浅色 → `stat-merge-narrow-light.png`
- [x] 窄窗 ≤400 · 深色 → `stat-merge-narrow-dark.png`
- [x] 全屏/宽窗 ≥900 · 浅色 → `stat-merge-wide-light.png`
- [x] 全屏/宽窗 ≥900 · 深色 → `stat-merge-wide-dark.png`

## 布局与信息

- [x] 底部原三张 `_StatCard` 并成 **一张**（三列 + 竖分隔）
- [x] 数字保留：已学 / 今日新学 / 连续（截图 3 / 4 / 6）
- [x] 圆角卡片、窄窗三列不折行、无横向溢出（单测 360 宽）
- [x] 今日目标卡内「已连续 N 天」与周打卡仍在（宽屏截图可见）

## 文案 · 不做

- [x] 标签：「已学单词」「今日新学」「连续天数」可读
- [x] **不做**：新图表、勋章、第四统计、搬学习页首屏

## 设计师结论

- 结论：**通过**
- 日期：2026-10-23（Asia/Shanghai）
- 验收人：单词UI设计
- 备注：已目视四态截图；一张三列合并达标，R23 周打卡并存。无打回项。
