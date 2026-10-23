# Round 22 · UI 验收（交给「单词UI设计」）

**对应**：`docs/design-r22.md` · 听音选义  
**前置**：R18 看义选词；R21 已通过  
**代码**：c93cef0 / bbf8d9c / e6a41af

## 环境

- [x] 窄窗 ≤400（主列 `maxWidth: 520` 居中；Segmented + 纵向选项，无硬编码宽度溢出）
- [x] 全屏 / 宽窗 ≥900（主列 `maxWidth: 520`）
- [x] 浅色 / 深色（`ColorScheme` / `ThemeMode.system`；对错色走 primary/errorContainer）

## 入口与题型

- [x] 自测顶栏 Segmented：`看义选词 | 听音选义`；偏好可记住（`quiz_variant`）
- [x] 学习页/今日任务「自测」、我的·自测：跟上次题型；首次默认看义
- [x] 无独立 Tab；口音走全局 WordSpeaker

## 听音题行为

- [x] 题干：听英文选意思；判分前**不**显示目标拼写（单测断言 `apple` 不可见）
- [x] 进题自动朗读 1 次；「再听一遍」热区 height 48，与选项分离
- [x] 四选一为**中文义**（去重）；词池 <4 时 2～3 选项仍可用
- [x] 对：primaryContainer + removeWrong + bumpTodayCount；错：errorContainer + 正解 + 再播英文 + markWrong
- [x] 判分后可显示 `英文 · 中文`；**不** markLearned

## TTS 降级

- [x] speak 失败：SnackBar「暂时没法朗读，已改为看中文选英文」→ **整轮**切回看义（`_forceMeaning` + `_boot`）
- [x] 无英文语音包：禁用听音段 + 提示「请安装系统英文语音包后再用听音」
- [x] 单测 FakeWordSpeaker 覆盖进题 speak / 降级 / 禁用（`quiz_listen_test` + engine 相关 **全部通过**）

## 视觉与文案

- [x] 选项规格同 R18（高 56）；题干大喇叭 56；切题型 AnimatedSize 150ms
- [x] 文案无 SRS/SM-2；深浅色走 ColorScheme；无横向溢出风险

## 设计师结论（请填写）

- 结论：**通过**
- 日期：2026-10-23（Asia/Shanghai）
- 备注：听音功能与 design-r22 一致；美感抛光不在本轮范围，等 R25 交验（`r25-ui-acceptance`）。无打回项。
