# Round 18 设计说明

## 需求
落地 `docs/requirements.md` Round 16 主需求：学习自测「看中文选英文」四选一。

## 交互
- **入口**
  - 学习页 AppBar 测验图标 → 自测当前单元（无单元筛选则本词书）
  - 我的 →「自测本单元/本词书」「自测错词」
- **一题一屏**：题干=中文释义；纵向大触控英文选项（目标 4 个）
- **反馈**：选对轻提示；选错标红并展示正解，可点喇叭朗读
- **错词本**：错选 `markWrong`；选对 `removeWrong`（与闪卡进出规则一致，不因自测直接 markLearned）

## 实现要点
- `QuizEngine`：纯函数出题；同单元优先干扰项，不足从全书补齐
- `QuizScreen`：独立全屏；窄窗友好；`seedQuestions` 仅测试用
- 不编造小学单元名；pep-ps-3 真实 unit 仍属后续 P0

## 验收
- `flutter analyze` 无问题
- `flutter test` 全绿（含出题偏好 + 判分/错词本 widget 测）
