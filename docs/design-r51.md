# Round 51 · 导出发现性

**对应 PRD**：[prd-r51-export-discoverability.md](prd-r51-export-discoverability.md) · 迭代 **B10**（RICE 6.0）  
**原则（Impeccable）**：家长 3 秒找到导出；不破坏 R47「书·今日·测」主角；工具次于行动。  
**参考（公开模式）**：Duolingo 分享/进度靠后但可见；墨墨导出在设置侧且入口清晰。  
**工具**：本地 PRD；禁用付费 Mobbin/Refero。  
**不动**：`friendly_thumb` / `thumb_*_friendly.png`。

---

## 0. 方向锁

| 要 | 不要 |
|----|------|
| 行动下可见导出纸卡行 | 回同权 Card 墙 / 首屏 Banner |
| 空态可读 + 预览可复制 | 空进度禁止打开 sheet |
| 复制 teal `#0D9488` | seed 蓝抢戏 |
| 保留 `export_progress` / `export_*` | 改拇指 / 云同步 |
| 更多设置副标「单元 · 口音 · 统计」 | 折叠内再藏唯一入口 |

---

## 1. 信息架构（竖屏）

```
我的进度
┌─ Hero me_hero ─┐
└────────────────┘
┌─ 行动 me_actions ─┐
│ 错词 · 自测 · 测这些 │
└───────────────────┘
┌─ 导出 me_export_row ─┐   ← R51 提权（key export_progress）
│ 📤 导出进度            │
│ 复制或分享给家长 · 老师 │
│ →                      │
└───────────────────────┘
▶ 更多设置（副标：单元 · 口音 · 统计）
   单元 / 拍照 / 清空 / 口音 / 统计
```

---

## 2. 组件细则

### 2.1 导出行
- `_mePaper`；InkWell / ListTile 感；圆角 24 一致  
- 无书：`onTap` null；副文「先选一本词书」  
- 有书：副文「复制或分享给家长 · 老师」  
- key：`export_progress`（唯一）

### 2.2 Sheet
- 标题「导出进度」  
- 空进度（已学+错词=0）：`export_empty_hint` 文案「本词书还没有已学或错词 · 学几个再导出也行」  
- 预览 `export_preview`；分享 Outlined；复制 Filled `_meTeal`  
- keys：`export_preview` · `export_share` · `export_copy` · `export_empty_hint`（仅空时）

### 2.3 更多设置
- subtitle：`单元 · 口音 · 统计`  
- children 去掉原 TextButton.icon 导出

---

## 3. 文案

| 键 | 文案 |
|----|------|
| 行标题 | 导出进度 |
| 行副标（有书） | 复制或分享给家长 · 老师 |
| 行副标（无书） | 先选一本词书 |
| 空态 | 本词书还没有已学或错词 · 学几个再导出也行 |
| 折叠副标 | 单元 · 口音 · 统计 |

---

## 4. 验收截图

| 文件 | 内容 |
|------|------|
| `r51-export-entry-narrow-light.png` | 首屏可见导出行（未展开更多） |
| `r51-export-entry-narrow-dark.png` | 同布局深色 |
| `r51-export-empty-sheet-narrow-light.png` | 空进度 sheet + 空态 |
| `r51-export-sheet-narrow-light.png` | 有进度预览 + teal 复制 |
| `r51-ui-acceptance.md` | A1–A6 |

---

## 5. 明确不做

云同步；PDF；改拇指；B07/B09/B11–B12；vercel.json。
