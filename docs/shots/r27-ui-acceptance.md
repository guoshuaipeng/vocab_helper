# Round 27 · UI 验收（交给「单词UI设计」）

**对应**：`docs/design-r27.md` · 词书样板扩充 `pep-ps-4`  
**对照**：ux-guidelines §8/§9；R21 空字段不占位  
**截图前缀**：`r27-`  
**实现 tip**：pep-ps-4=243 词；catalog `sourceLabel=扩充词表`；单测 pep_ps4_content_test + r27_catalog_shot_test

## 环境（须附截图）

- [x] 词书列表/卡片 窄窗 ≤400 · 浅色 → `r27-catalog-narrow-light.png`（已附）
- [x] 词书列表/卡片 窄窗 ≤400 · 深色 → `r27-catalog-narrow-dark.png`（已附）
- [x] 词书列表/卡片 宽窗 ≥900 · 浅色 → `r27-catalog-wide-light.png`（已附）
- [x] 词书列表/卡片 宽窗 ≥900 · 深色 → `r27-catalog-wide-dark.png`（已附）
- [ ] （可选）学习闪卡抽查新词 · 浅或深 1 张 → `r27-learn-sample.png`

## 内容与 UI

- [ ] 卡片词数反映扩充（≥220）；副文案可见 source 短标（如「扩充词表」）
- [ ] 副文案变长不溢出、不折成脚手架感；无新 Banner/紫渐变
- [ ] 空 phonetic/example 不渲染占位（沿用 R21）
- [ ] 单元 Chip/学习/自测入口不被新词量挤乱

## 回归 / 不做

- [ ] 既有 pep-ps-3 / 初中册视觉未回退
- [ ] **不做**：全库扩充 UI、用户编辑词书、云词库入口

## 设计师结论

- 结论：（通过 / 打回）
- 日期：
- 验收人：单词UI设计
- 备注：（须基于截图；词量数字以卡片可见为准）