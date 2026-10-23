# R48 · 单元 overflow 路径可读 · UI 自验

**日期**：2026-10-23（Asia/Shanghai）  
**对照**：[design-r48.md](../design-r48.md) · [prd-r48-unit-overflow.md](../prd-r48-unit-overflow.md) · 迭代 **B04**（RICE 14.0）

## 截图

| 文件 | 内容 |
|------|------|
| [r48-overflow-narrow-light.png](r48-overflow-narrow-light.png) | ⋮ 打开：「选择单元」为首项 |
| [r48-overflow-narrow-dark.png](r48-overflow-narrow-dark.png) | 同布局深色 |
| [r48-filtered-narrow-light.png](r48-filtered-narrow-light.png) | 已筛：顶栏含「· 第1组」+ 弱 hint + 双 CTA |

## A1–A5

| ID | 结果 | 说明 |
|----|------|------|
| A1 单元首项 | ✅ | overflow 内 unit_picker 在 today_task_learn 之上；截图可见 |
| A2 顶栏持久+不挡 CTA | ✅ | `今日 n/g · 书 · 第1组`；无 SnackBar；认识/不认识可见 |
| A3 已筛 overflow 副文案 | ✅ | 单元行 subtitle 为当前单元；teal 勾 |
| A4 keys/回归 | ✅ | unit_filter / today_task / r43_learn_wow 绿 |
| A5 docs+push | ✅ | 本清单 + requirements/retro |

## 测试

`flutter test`：`unit_filter_ui_test` · `r48_unit_overflow_shot_test` · `today_task_test` · `r43_learn_wow_test` — 全绿。  
（r43 测侧 drain 拇指飞行 timer；未改 `friendly_thumb` / thumb 资源。）

## 裁剪

未恢复芯片墙；未改我的页单元进度。
