# R47 · 我的页信息层级 · UI 自验

**日期**：2026-10-23（Asia/Shanghai）  
**对照**：[design-r47.md](../design-r47.md) · [prd-r47-mine-hierarchy.md](../prd-r47-mine-hierarchy.md)  
**RICE**：B05（12.3） · 免费工具 only（无付费 Refero/Mobbin）  
**不动**：`friendly_thumb` / `thumb_*_friendly.png`

## 入口路径

1. 打开「我的」→ 首屏纸卡 Hero（当前书 · 今日 · 待复习 · 本周打卡）  
2. 行动区「错词本」+ teal「自测本词书」+「测这些」  
3. 「更多设置」默认收起 → 展开后导出 / 单元 / 口音 / 统计

## 截图

| 文件 | 内容 |
|------|------|
| [r47-hero-narrow-light.png](r47-hero-narrow-light.png) | 首屏 Hero+行动；口音不在首屏 |
| [r47-hero-narrow-dark.png](r47-hero-narrow-dark.png) | 同布局深色 |
| [r47-more-expanded-narrow-light.png](r47-more-expanded-narrow-light.png) | 展开更多设置：导出/单元/口音/统计 |

## A1–A6

| ID | 结果 | 说明 |
|----|------|------|
| A1 窄浅首屏书名+今日+待复习，无口音抢屏 | ✅ | hero 截图；`朗读口音` 折叠前 findsNothing |
| A2 行动区主「自测本词书」teal；错词入口可开 sheet | ✅ | `me_actions` / `me_wrong_book_entry` / teal Filled |
| A3 「更多设置」默认收起；展开后导出/单元/口音/统计 | ✅ | `me_more_section` + expand 旧测绿 |
| A4 待复习有数 / 达成勾 / 错词有数 → teal | ✅ | `_meTeal`；错词数 1 截图可见 teal |
| A5 既有 me_* / export_* keys + 相关 flutter test 绿 | ✅ | expand_me_more + r47/me/export/r30/accent |
| A6 shots + acceptance + requirements/retro + push | ✅ | 本收口 commit + `git push github master` |

## Soft-pass

- 截图图标可能呈空方块（字形）；色与文案可辨即可。  
- 周打卡圆点仍用 scheme.primary（非本轮强制改色）。  
- 「更多设置」内次要 Filled（复习全部错词）未强制改 teal。

## 明确不做（已遵守）

整站导航重做；改拇指；新算法；紫渐变；vercel.json。
