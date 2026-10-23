# Round 35 · 自测结束「错题再练」· UI 验收

**对应**：R35 / P1 自测结束错题再练  
**设计稿**：`docs/design-r35.md`  
**状态**：**UI 通过**（tip 691c43f · 2026-10-23）  
**代码**：`QuizScreen` 结束页 CTA + `_sessionWrongIds`；`QuizEngine.applySessionWrong` / `wordsForRetry` / `buildRetrySession`  
**单测**：`test/quiz_engine_test.dart`（R35 group）· `test/quiz_end_test.dart`  
**截图前缀**：`r35-`

## 环境（须附截图）

- [x] 有错结束 · 窄窗浅色 → `r35-end-wrong-narrow-light.png`（错题再练 Outlined + 回学习 Filled）
- [x] 有错结束 · 窄窗深色 → `r35-end-wrong-narrow-dark.png`
- [x] 有错结束 · 宽窗浅色 → `r35-end-wrong-wide-light.png`
- [x] 有错结束 · 宽窗深色 → `r35-end-wrong-wide-dark.png`
- [x] 无错结束 · 窄窗浅色 → `r35-end-ok-narrow-light.png`（无「错题再练」，仅「回学习」）
- [x] 再练进行中 · 窄窗浅色 → `r35-retry-narrow-light.png`（顶栏/弱标「错题再练 · N」）

## 要点

- [x] 有错显示「错题再练」；无错不显示
- [x] 「回学习」Filled 主按钮；「错题再练」Outlined 次按钮；padding ≥14
- [x] 再练题来自本场错词；档锁定（Segmented onSelectionChanged=null）
- [~] 再练结束后可再点或回学习（行为 Soft-pass · 单测覆盖入口与池）
- [x] 窄/宽 × 深/浅可读；无两主同权

## 不做

- 再练中切档、新错词算法、成绩分享

## 设计师结论

- 结论：**通过**
- 日期：2026-10-23
- 验收人：单词迭代（自验）
- tip：691c43f
- 备注：六图目视通过；有错双 CTA / 无错单主按钮 / 再练中弱标与题干符合 design-r35。
