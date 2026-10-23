# Round 42 · 非推荐词书时弱提示切换跟课

**对应需求 / PRD**：[prd-learn-v2.md](prd-learn-v2.md)（ChatPRD `ai-development-brief`）  
**前置**：R40 `recommendedBookId`；R41 词书列表置顶「推荐跟课」  
**原则**：弱提示、不强制；不弹 Dialog；不自动换书；不打断学习主流程  
**参考（公开模式，无付费库）**：常见「设置页 inline tip + 文本按钮」；可选「今日不再」类一次性 dismiss（类系统通知偏好），非 sticky Banner。

---

## 1. 目标与成功标准

当前选中词书 **≠** `hj-ox-7a-2024` 时，在「我的」与「学习」给出可忽略的弱提示，引导去词书页看「推荐跟课」。  
成功：用 pep-ps-3 等非推荐书的用户，打开「我的」/「学习」能看到提示；点「去切换」进入换书（Books）；已是推荐本时不显示。

## 2. 信息架构 / 入口

| 页 | 位置 | 形态 |
|----|------|------|
| **我的**（主） | 「当前词书」卡内、书名/副标题与操作按钮之间 | 浅底一行/两行 +「去切换」 |
| **学习**（辅） | 顶栏书名进度行下方，今日任务条之上 | 单行弱链 +「今日不再」 |

点「去切换」→ 复用现有 `onChangeBook`（进词书列表，推荐已置顶）。

## 3. 主流程

1. `selectedBookId != recommendedBookId`（且 id 非空）→ 显示提示  
2. `== recommended` 或未选书 → 不显示  
3. 学习页：若 prefs `recommend_hint_hide_ymd` == 今日 ymd → 学习提示隐藏（我的仍显示）  
4. 点学习提示旁「今日不再」→ 写入今日 ymd；点「去切换」不写入  

## 4. 线框（窄窗）

```
我的 · 当前词书卡
┌─────────────────────────┐
│ 当前词书                  │
│ 人教PEP三年级上           │
│ 人教版PEP · …             │
│ ┌─────────────────────┐ │
│ │ 跟课推荐：沪教牛津2024七上 │ │
│ │              [去切换] │ │
│ └─────────────────────┘ │
│ [更换教材] [导出…] …     │
└─────────────────────────┘

学习 · 顶栏下
人教PEP三年级上          今日 0/20
跟课推荐 · 去切换   今日不再   ← bodySmall
[学新词][复习错词][自测]
┌ 词卡 … ┐
```

## 5. 视觉

- 色：`colorScheme.secondaryContainer` / `onSecondaryContainer`（弱，非 error）  
- 圆角 12；padding 10×12；无 elevation、无 Banner 槽、无循环动效  
- 学习行：一行，不占主词卡高度；禁止再加 Banner  
- Keys：`me_recommend_switch_hint`、`learn_recommend_switch_hint`、`learn_recommend_hint_dismiss`

## 6. 文案表（中文 UI，必须）

| 键 | 文案 |
|----|------|
| 我的主文 | 跟课推荐：沪教牛津2024七上 |
| 学习主文 | 跟课推荐 |
| CTA | 去切换 |
| 学习 dismiss | 今日不再 |

## 7. 边界与空态

| 态 | 行为 |
|----|------|
| 当前=推荐 | 两处都不显示 |
| 未选书 | 不显示（走 Setup） |
| catalog 无推荐 id | 不显示（防御） |
| 深/浅色 | 用 ColorScheme 容器色 |

## 8. 验收清单

- [x] 选 pep-ps-3：我的可见 `me_recommend_switch_hint`；学习可见 `learn_recommend_switch_hint`
- [x] 选 hj-ox-7a-2024：两处均无
- [x] 点「去切换」触发 onChangeBook（单测 verify）
- [x] 学习点「今日不再」后同学期内再进学习不显示；我的仍显示
- [x] 窄浅：我的 + 学习各 1 张；宽或深至少再 1 张（共≥3）；`docs/shots/r42-ui-acceptance.md`
- [x] 对照 [prd-learn-v2.md](prd-learn-v2.md) R1–R7

## 9. 明确不做

强推 Dialog、自动换书、迁移进度、改 R41 列表、账号/云同步、付费竞品截图库。