# Round 47 · 我的页信息层级

**对应 PRD**：[prd-r47-mine-hierarchy.md](prd-r47-mine-hierarchy.md) · 迭代 **B05**（RICE 12.3）  
**原则（Impeccable）**：一屏看清「书 · 今日 · 待复习」；测/错词次之；设置与工具折叠。  
**参考（公开模式）**：Duolingo 主路径清晰、设置靠后；墨墨任务感；不背单词跟课书置顶。  
**工具**：本地 PRD；禁用付费 Mobbin/Refero。  
**不动**：`friendly_thumb` / `thumb_*_friendly.png`。

---

## 0. 方向锁

| 要 | 不要 |
|----|------|
| 纸卡 Hero（圆角24 / paper 色 / 轻阴影） | 多张同权 Material Card 墙 |
| 主 CTA teal `#0D9488` | seed 蓝当确认色、紫渐变 |
| 「更多设置」默认折叠 | 口音插在今日与自测之间 |
| 保留全部既有 ValueKey | 重做导航 / 加账号 |
| 竖屏窄优先 | 宽屏仪表盘大改 |

---

## 1. 信息架构（竖屏）

```
我的进度
┌─ 纸卡 Hero me_hero ─────────────────┐
│ 当前词书 · 书名大 · 已学弱文案        │
│ [推荐 hint]  [更换教材]               │
│ 今日目标 大数字 + 细进度4px + 状态    │
│ 待复习 N →（有数 teal）               │
│ 本周打卡 dots                         │
└──────────────────────────────────────┘
┌─ 纸卡行动 me_actions ───────────────┐
│ 错词本 N · 查看·测这些 →              │
│ [自测本词书 teal]  [测这些]           │
└──────────────────────────────────────┘
▶ 更多设置 me_more_section（默认收起）
   导出 / 单元进度 / 拍照 / 清空进度
   学习自测副文案 + 自测单元
   复习错词 / 清空错词
   朗读口音 + 自动朗读
   统计三列
```

---

## 2. 组件细则

### 2.1 纸卡
- `paper` = light `surfaceContainerLow` / dark `surfaceContainerHigh`
- `BorderRadius.circular(24)`；`outlineVariant` α0.45；shadow α0.06
- 常量 `_meTeal = Color(0xFF0D9488)`（同 learn/quiz）

### 2.2 Hero
- 书名 ≥18 w600；今日数字 ~28 bold；进度 `minHeight: 4`
- 达成勾 / 待复习有数 / 错词有数 → `_meTeal`
- keys：`me_recommend_switch_hint` · `me_today_goal_*` · `me_due_review` · `me_review_curve_hint` · `me_week_checkin`

### 2.3 行动
- `me_wrong_book_entry` 保留  
- `自测本词书` Filled + teal 白字  
- `me_quiz_wrong_pool`「测这些」tonal/次要

### 2.4 更多设置
- `ExpansionTile` key `me_more_section`；subtitle「导出 · 单元 · 口音 · 统计」  
- 内含：`export_progress` · `me_unit_progress` · `me_photo_vocab` · `me_quiz_card_subtitle` · `me_accent_tts_hint` · `me_stats_summary`

---

## 3. 文案

| 键 | 文案 |
|----|------|
| 折叠标题 | 更多设置 |
| 折叠副标 | 导出 · 单元 · 口音 · 统计 |
| 行动区错词副 | 查看 · 测这些（无书：先选一本词书） |

---

## 4. 验收截图

| 文件 | 内容 |
|------|------|
| `r47-hero-narrow-light.png` | 首屏 Hero+行动，口音不在首屏 |
| `r47-hero-narrow-dark.png` | 同布局深色 |
| `r47-more-expanded-narrow-light.png` | 展开更多设置可见导出/口音/统计 |
| `r47-ui-acceptance.md` | A1–A6 |

---

## 5. 明确不做

整站导航重做；改拇指；新算法；紫渐变；vercel.json。
