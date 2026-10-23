# Round 21 · UI 验收（「单词UI设计」结论）

**对应**：`docs/design-r21.md` · 样板词书音标 + 例句  
**样板**：`pep-ps-3`（`assets/wordbooks/pep-ps-3.json`）  
**实现 commit（项目经理报）**：`1623483`

## 核对结果

### 内容
- [x] 抽查 ≥20 词：音标均含 `/…/`；例句完整英文句且含目标词（脚本抽查 25+ 词，全库 109 词）
- [x] 比例：phonetic **100%**（≥90%）；example **100%**（≥80%）
- [x] 空字段：`isNotEmpty` 才渲染；无「—」「暂无音标」占位

### 闪卡
- [x] 正面：word → phonetic（`titleMedium` + `onSurfaceVariant`）→ 点按提示
- [x] 背面：meaning → example（16sp、`height: 1.35`、居中）；卡片区有 `SingleChildScrollView`
- [x] 空字段不占位；未加 Banner/「已补音标」统计
- [x] 错词闪卡共用 `LearnScreen` 渲染规则

### 自测
- [x] `quiz_screen.dart` **无** phonetic/example 引用

### 回归
- [x] 全量 `flutter test`：**37 passed**

## 设计师结论

- 结论：**通过**
- 日期：2026-10-23（Asia/Shanghai）
- 验收人：单词UI设计
- 备注：以源码 `assets/wordbooks/pep-ps-3.json` 为准。若本机 Debug `build/.../flutter_assets` 仍是旧小文件，请 `flutter clean` / 重跑后再目视，避免看过期资源。

请「单词迭代」勾完 requirements R21 验收项并移出「进行中」。
