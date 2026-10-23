# Round 38 · 简易记忆曲线 · UI 验收

**对应**：R38 / 扩展 R20  
**设计稿**：`docs/design-r38.md`  
**状态**：**UI 通过**（自验 · 2026-10-23 Asia/Shanghai）  
**代码**：`ProgressStore` 档位 1/3/7/14/30；学习页 `review_next_hint`；我的页 `me_review_curve_hint`  
**单测**：`test/review_schedule_test.dart` · `test/review_curve_test.dart`  
**截图前缀**：`r38-`

## 环境（须附截图）

- [x] 学习反馈 · 窄窗浅色 → `r38-hint-narrow-light.png`（「下次 · 明天复习」）
- [x] 学习反馈 · 窄窗深色 → `r38-hint-narrow-dark.png`
- [x] 学习反馈 · 宽窗浅色 → `r38-hint-wide-light.png`（左词卡 + 右按钮布局保留）
- [x] 学习反馈 · 宽窗深色 → `r38-hint-wide-dark.png`
- [x] 我的 · 窄窗浅色 → `r38-me-narrow-light.png`（「间隔会随认识变长」）
- [x] 我的 · 窄窗深色 → `r38-me-narrow-dark.png`

## 要点

- [x] 档位表 0..4 → 1/3/7/14/30；认识升档封顶 4；不认识/自测错回 stage0 +1 天
- [x] 认识后短提示「下次 · {文案}」；prefs `review_next_hint_enabled` 可关（默认开）
- [x] 我的「待复习」旁弱说明「间隔会随认识变长」
- [x] 到期队列语义不变；文案无 SRS/SM-2
- [x] 旧 stage 0..3 兼容；下一档映射新表（单测覆盖）

## 不做

- 完整 SM-2、EF 面板、遗忘曲线大图、云同步

## 设计师结论

- 结论：**通过**
- 日期：2026-10-23（Asia/Shanghai）
- 验收人：单词迭代（自验）
- 备注：六图目视通过；宽屏学习布局未回退；提示与我的说明可读。
