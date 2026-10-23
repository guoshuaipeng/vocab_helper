# Round 16 设计说明

## 需求
错词本支持「只复习当前单元」（与学习页同一套 `ProgressStore.unitFilterForBook`）。

## 交互
- **我的 → 复习全部错词**：本词书全部错词，不受单元筛选影响。
- **我的 → 只复习当前单元**：仅复习学习页当前选中单元里的错词；未选单元时按钮禁用，并提示先去学习页选单元。
- 单元限定模式下，学习页仍显示单元 Chip，可切换单元后重新组卷（与学习筛选同源）。

## 实现要点
- `filterWrongWords`：纯函数，便于单测。
- `LearnScreen.reviewWrongUnitScoped`：错词模式下是否套用单元筛选。
- 不新增独立偏好键，复用已有 unit filter。
