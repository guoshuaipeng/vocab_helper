# Round 34 · 自测变体「听写」· UI 验收

**对应**：R34 / P1 听写自测（听音后默写）  
**设计稿**：`docs/design-r34.md`  
**状态**：**UI 通过**（tip `3da2979` · 2026-10-23）  
**代码**：`lib/screens/quiz_screen.dart`（第五档 `dictation`）· `ProgressStore.quizVariant` · Me 自测副文案  
**单测**：`test/quiz_dictation_test.dart`（自动朗读/再听次数、对错空交、TTS 不可用回退）  
**截图前缀**：`r34-`

## 环境（须附截图）

- [x] 窄窗 ≤400 · 浅色 → `r34-narrow-light.png`（五档「默」选中；喇叭+再听；输入中）
- [x] 窄窗 ≤400 · 深色 → `r34-narrow-dark.png`
- [x] 宽窗 ≥900 · 浅色 → `r34-wide-light.png`（档标「听写」）
- [x] 宽窗 ≥900 · 深色 → `r34-wide-dark.png`
- [x] 窄窗输入态 → `r34-narrow-input.png`

## 入口与题型

- [x] Segmented 五档：义 | 词 | 听 | 写 | **默**（窄单字 / 宽「听写」）
- [~] `quiz_variant=dictation` 可持久化（行为 Soft-pass · 代码 ProgressStore）
- [~] 题池 Chip（全部词 / 只测错词）仍可用（seed 截图隐藏 Chip；代码 path 仍在）

## 听写行为

- [x] 判分前不露英文拼写、不露中文义；主视觉喇叭位 +「再听」
- [~] 入题自动朗读；「再听」可重复（行为 Soft-pass · 单测覆盖）
- [x] 占位「写出你听到的单词」（代码）；主按钮「提交」padding ≥14
- [~] trim + 大小写不敏感；空提交不判错、不进错词（行为 Soft-pass · 单测）
- [~] 对：勾 +「拼对了」+ 露出拼写；错：正确答案 + 可再听（行为 Soft-pass）
- [~] TTS 不可用：听/默档 disabled 或 SnackBar（代码对齐口音卡；截图未拍）

## 文案 / 我的

- [~] 我的 · 学习自测副文案含「听写」（代码 `me_screen`；未单独截图）

## 回归 / 不做

- [x] 义/词/听/写档标仍在五档内
- [x] **不做**：手写板、语音识别、第六档、改复习算法

## 设计师结论

- 结论：**通过**
- 日期：2026-10-23
- 验收人：单词UI设计
- tip：`3da2979`
- 备注：五图目视通过（窄「默」/宽「听写」、判分前无拼写泄露、再听+输入+提交、深浅可读）。Material 图标在截图环境呈空方块（与既往轮次截图一致，不单就此打回）。题池 Chip / 空交 / TTS 降级 / 我的副文案按代码+单测 Soft-pass。