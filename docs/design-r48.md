# Round 48 · 单元 overflow 路径可读

**对应 PRD**：[prd-r48-unit-overflow.md](prd-r48-unit-overflow.md) · 迭代 **B04**（RICE 14.0）  
**原则**：跟课换单元 ≤2 点；overflow 首屏见单元；不挡认识/不认识。  
**参考（公开）**：Quizlet 模式进菜单但筛选可回看；不背单词跟课单元可见。  
**工具**：本地 PRD；禁用付费 Mobbin/Refero。  
**不动**：`friendly_thumb` / `thumb_*_friendly.png`。

---

## 0. 方向锁

| 要 | 不要 |
|----|------|
| overflow 内「选择单元」列表**第一项** | 埋在自测下面 |
| 细顶栏持久 `· {单元}` | 恢复主列芯片墙 |
| 弱 hint 1.4s + 不 SnackBar | 挡 CTA 的 Banner |
| teal 语义标已筛选 | 紫渐变 |
| 保留全部既有 ValueKey | 改拇指 / 引擎 |

---

## 1. Overflow 信息架构

```
更多练习
┌─ 选择单元          ← 首项（B04）
│  副：全部 · N 单元 / 当前单元名
│  已筛选 → teal 勾色 trailing 可选
├─ 学新词
├─ 复习错词
└─ 自测
```

---

## 2. 细顶栏

- 无筛选：`今日 n/g · {书名}`（现状）  
- 有筛选：`今日 n/g · {书名} · {单元}`（ellipsis）  
- key：进度行仍 `learn_progress_thin`；hint 仍 `unit_filter_hint`

---

## 3. 文案

| 键 | 文案 |
|----|------|
| Overflow 标题 | 更多练习 |
| 单元行 title | 选择单元 |
| 单元副（全） | 全部 · N 单元 |
| 单元副（筛） | 当前单元名 |
| 切后弱 hint | 已筛选 · {单元} / 显示全部 |

---

## 4. 验收截图

| 文件 | 内容 |
|------|------|
| `r48-overflow-narrow-light.png` | ⋮ 打开：选择单元为首项 |
| `r48-overflow-narrow-dark.png` | 同布局深色 |
| `r48-filtered-narrow-light.png` | 已筛单元：顶栏含单元名 + 双 CTA |
| `r48-ui-acceptance.md` | A1–A5 |

---

## 5. 明确不做

芯片墙；改拇指；新算法；紫渐变；vercel.json。
