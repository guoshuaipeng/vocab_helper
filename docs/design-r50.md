# Round 50 · 今日达成视觉统一

**对应 PRD**：[prd-r50-goal-celebrate-wow.md](prd-r50-goal-celebrate-wow.md) · 迭代 **B08**（RICE 7.5）  
**原则**：达标一刻仍像「同一个单词小助手」；纸卡 + teal；不挡学。  
**参考（公开）**：Duolingo 达成轻提示；墨墨任务完成态；不背单词纸感卡。  
**工具**：本地 PRD；禁用付费 Mobbin/Refero。  
**不动**：`friendly_thumb` / `thumb_*_friendly.png`；上升沿逻辑。

---

## 0. 方向锁

| 要 | 不要 |
|----|------|
| 纸卡底 + outline 边 + 圆角 16–24 | primaryContainer 实心块 |
| 「继续」Filled teal `#0D9488` | seed 蓝 CTA |
| 标题完整「今日目标达成」+ 至多一枚 🌟/✓ | 勋章墙、循环彩带 |
| 顶 Overlay 不挡底双 CTA | 全屏不可关 Dialog |
| 保留 `goal_celebrate_*` keys | 改 ProgressStore 去重语义 |

## 1. 信息架构

```
Overlay（AppBar 下）
┌ 纸卡 ─────────────────────┐
│ ✓ 今日目标达成 🌟          │  ← onSurface + teal 勾
│ 已学 n / goal              │  ← onSurfaceVariant 可
│              [ 继续 ] teal │
└────────────────────────────┘
```

我的 Hero 完成态：维持 R47（teal 勾 +「今日已完成 · n/n」+ 细进度满格）。

## 2. 组件细则

- `celebrateTeal = Color(0xFF0D9488)`（同 knowTeal / quizTeal / _meTeal）  
- paper：light `surfaceContainerLow` / dark `surfaceContainerHigh`  
- `BorderRadius.circular(20)`；`BorderSide(outlineVariant α0.45)`；shadow α≈0.08  
- 标题 16sp w600 onSurface；副文 14sp onSurfaceVariant  
- `goal_celebrate_continue`：Filled、白字、teal 底（非 TextButton seed）  
- 自动隐藏 4s 不变；`autoHide: Duration.zero` 测用保留

## 3. 文案

| 键 | 文案 |
|----|------|
| 标题 | 今日目标达成 🌟（或 ✓ + 今日目标达成） |
| 副文 | 已学 {n} / {goal} |
| 按钮 | 继续 |
| 我的 | 今日已完成 · {n}/{goal}（已有） |

## 4. 验收截图

| 文件 | 内容 |
|------|------|
| `r50-banner-narrow-light.png` | Overlay 纸卡 + teal 继续 |
| `r50-banner-narrow-dark.png` | 同布局深色 |
| `r50-me-done-narrow-light.png` | 我的完成态（核对 teal） |
| `r50-ui-acceptance.md` | A1–A5 |

## 5. 明确不做

新勋章/排行；改去重；改拇指；紫渐变；vercel.json。
