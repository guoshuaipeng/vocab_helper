# Round 26 · UI 验收（交给「单词UI设计」）

**对应**：`docs/design-r26.md` · 自测变体「拼写默写」；对照 ux-guidelines §8/§9/§10  
**前置**：R18 看义、R22 听音；`quiz_variant`  
**代码**：`lib/screens/quiz_screen.dart` · `QuizEngine.gradeSpell` · `ProgressStore.quizVariant`（含 `spell`）  
**单测**：`test/quiz_spell_test.dart`（判分 + widget 对/错/空）；全量 `flutter test` 绿  
**截图前缀**：`r26-`

## 环境（须附截图）

- [x] 窄窗 ≤400 · 浅色 → `r26-narrow-light.png`
- [x] 窄窗 ≤400 · 深色 → `r26-narrow-dark.png`
- [x] 全屏/宽窗 ≥900 · 浅色 → `r26-wide-light.png`（主列 maxWidth 520）
- [x] 全屏/宽窗 ≥900 · 深色 → `r26-wide-dark.png`
- [x] 窄窗键盘弹起 → `r26-narrow-keyboard.png`（viewInsets +「检查」仍可见）

## 入口与题型

- [x] Segmented 三档：`看义选词 | 听音选义 | 拼写`（窄窗缩「看|听|写」）
- [x] `quiz_variant` 记住偏好；首次默认看义
- [x] 无独立 Tab

## 拼写题行为

- [x] 题干：中文 `meaning`；判分前不露正确拼写
- [x] 输入：单行 TextField；无自动大写/纠错/联想；占位「输入英文单词」
- [x] 「检查」Filled，竖向 padding ≥14；支持键盘 done
- [x] 判分：trim + 大小写不敏感；无编辑距离容错
- [x] 对：文案「拼对了」+ removeWrong + bumpTodayCount；不 markLearned
- [x] 错：标红 +「正确答案：{word}」+ markWrong；锁定后「下一题」
- [x] 空提交：提示「先写出单词」；不判错、不进错词

## 视觉 · 键盘

- [x] 输入框圆角 16；surfaceContainerHighest；resizeToAvoidBottomInset
- [x] 窄窗键盘弹起时「检查」仍可见
- [x] 无紫渐变 / 贴纸 Badge

## 回归 / 不做

- [x] 看义 / 听音题型与 R18/R22 未回退（既有 listen 单测绿）
- [x] **不做**：语音输入、手写、模糊容错、限时、整句听写、改底部 Tab
- [x] 单测：判分 + widget（对/错/空提交）；既有 test 绿

## 设计师结论

- 结论：**通过**
- 日期：2026-10-23
- 验收人：单词UI设计
- 备注：已目视 r26-narrow-light/dark、r26-wide-light/dark（1500×1266）、r26-narrow-keyboard。三档 Segmented（宽窗全称 / 窄窗「看|听|写」）选中写/拼写；题干仅中文、判分前不露拼写；输入框+「检查」；键盘态 inset 后「检查」仍可见。深浅色对比够、无紫渐变。大小写/空提交由 quiz_spell_test 覆盖。无打回。
