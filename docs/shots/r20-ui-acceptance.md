# Round 20 · UI 验收（「单词UI设计」结论）

**对应**：`docs/design-r20.md` · 轻量间隔复习 1/3/7  
**实现**：代码已在仓库；单测 `review_schedule` / `learn_queue` / `today_task` 等 **17 passed**（本机 `flutter test`）

## 核对结果

### 认读队列
- [x] 队列 = 从未认识 ∪ 已到期待复习；未到期不入队（`learn_screen` + `learn_queue_test`）
- [x] 排序：到期复习（旧→新）在前，新词在后
- [x] 副文案：`新词 a · 复习 b · 剩余 c`；无「SRS/SM-2」
- [x] 今日无新词且无到期：`今天没有新词和到期复习`

### 今日任务 · 学新词
- [x] 副文案：`新词 a · 复习 b`（已替换「还差 N」）
- [x] `b>0` 时小圆点 `learn_due_dot`（primary 8px）
- [x] 无第四「复习」按钮；复习并入学新词队列

### 闪卡
- [x] 队列内已学（到期复习）词正面英文下 `复习` 标签：`labelSmall` + primary；`review_tag`
- [x] 新词无标签；非贴纸浮动 Badge

### 我的页
- [x] 今日目标卡下：`待复习 N 个（含到期词）` / `暂无到期复习`（`me_due_review`）
- [x] `dueReviewCountForBook` 按词书 id 前缀

### 边界
- [x] 认识后当日不入队；+1 天后到期（`review_schedule_test`）
- [x] 不认识 / `markWrong`（含自测选错）回 1 天桶并进错词本
- [x] 清空本词书进度清 review 键
- [x] 自测答对仅 `bumpTodayCount`，不 `markLearned` / 不推进 stage

## 设计师结论

- 结论：**通过**
- 日期：2026-10-23（Asia/Shanghai）
- 验收人：单词UI设计
- 备注：复习标签用 `learnedIds` 判断；在认读队列语义下等价于到期复习词。错词复习模式若词已学过也会带「复习」字样，可接受、不挡车。

请「单词迭代」勾选 requirements 中 R20 UI 验收项并移出「进行中」。
