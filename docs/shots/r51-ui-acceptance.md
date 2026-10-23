# R51 · 导出发现性 · UI 自验

**日期**：2026-10-23（Asia/Shanghai）  
**对照**：[design-r51.md](../design-r51.md) · [prd-r51-export-discoverability.md](../prd-r51-export-discoverability.md)  
**RICE**：B10（6.0） · 免费工具 only（无付费 Refero/Mobbin）  
**不动**：`friendly_thumb` / `thumb_*_friendly.png`

## 入口路径

1. 打开「我的」→ Hero / 行动区下方可见「导出进度」纸卡行（**无需**展开「更多设置」）  
2. 点导出 → sheet 预览 → 复制（teal）/ 分享  
3. 无已学且无错词 → sheet 顶部空态提示，仍可复制模板文本  
4. 「更多设置」副标改为「单元 · 口音 · 统计」；口音仍不在首屏

## 截图

| 文件 | 内容 |
|------|------|
| [r51-export-entry-narrow-light.png](r51-export-entry-narrow-light.png) | 首屏可见导出行（未展开更多） |
| [r51-export-entry-narrow-dark.png](r51-export-entry-narrow-dark.png) | 同布局深色 |
| [r51-export-empty-sheet-narrow-light.png](r51-export-empty-sheet-narrow-light.png) | 空进度 sheet + 空态 |
| [r51-export-sheet-narrow-light.png](r51-export-sheet-narrow-light.png) | 有进度预览 + teal 复制 |

## A1–A6

| ID | 结果 | 说明 |
|----|------|------|
| A1 窄浅首屏无需展开可见导出 | ✅ | `export_progress` / `me_export_row`；entry 截图 |
| A2 无书 disabled +「先选一本词书」 | ✅ | `progress_export_ui_test` |
| A3 有书预览+复制/分享+SnackBar | ✅ | export UI 测绿 |
| A4 空进度空态文案；复制仍可用 | ✅ | empty sheet 截图 + r51 empty 测 |
| A5 更多默认收起；口音不在首屏；副标无「导出」 | ✅ | r47/r51 测；副标「单元 · 口音 · 统计」 |
| A6 shots + acceptance + requirements/retro + push | ✅ | 本收口 |

## Soft-pass

- 截图图标可能呈空方块（字形）；色与文案可辨即可。  
- R28 旧 shot 未强制重刷；本轮以 r51-* 为准。

## 明确不做（已遵守）

云同步；PDF；改拇指；B07/B09/B11–B12；无关 vercel.json。
