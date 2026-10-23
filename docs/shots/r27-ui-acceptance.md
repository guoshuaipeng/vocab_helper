# Round 27 · UI 验收（交给「单词UI设计」）

**对应**：`docs/design-r27.md` · 词书样板扩充 `pep-ps-4`  
**对照**：ux-guidelines §8/§9；R21 空字段不占位  
**截图前缀**：`r27-`  
**实现 tip**：pep-ps-4=243 词；catalog `sourceLabel=扩充词表`；单测 pep_ps4_content_test + r27_catalog_shot_test

## 环境（须附截图）

- [x] 词书列表/卡片 窄窗 ≤400 · 浅色 → `r27-catalog-narrow-light.png`（已附 · 585×1380）
- [x] 词书列表/卡片 窄窗 ≤400 · 深色 → `r27-catalog-narrow-dark.png`（已附）
- [x] 词书列表/卡片 宽窗 ≥900 · 浅色 → `r27-catalog-wide-light.png`（已附 · 1500×1380）
- [x] 词书列表/卡片 宽窗 ≥900 · 深色 → `r27-catalog-wide-dark.png`（已附）
- [ ] （可选）学习闪卡抽查新词 · 浅或深 1 张 → `r27-learn-sample.png`（本轮未附；不据此打回）

## 内容与 UI

- [x] 卡片词数反映扩充（≥220）；副文案可见 source 短标（如「扩充词表」）— 截图可见「共 243 词 · 扩充词表」
- [x] 副文案变长不溢出、不折成脚手架感；无新 Banner/紫渐变
- [x] 空 phonetic/example 不渲染占位（沿用 R21）— 本轮仅交 catalog 四态；闪卡未附可选样张，按 R21 既有约定通过
- [x] 单元 Chip/学习/自测入口不被新词量挤乱 — catalog 列表层级正常；无挤乱迹象

## 回归 / 不做

- [x] 既有 pep-ps-3 / 初中册视觉未回退（同列表其余卡片样式一致）
- [x] **不做**：全库扩充 UI、用户编辑词书、云词库入口

## 设计师结论

- 结论：**通过**
- 日期：2026-10-23
- 验收人：单词UI设计
- 备注：已目视四态 catalog 截图；pep-ps-4 卡片「243 词 · 扩充词表」达标，窄/宽×深/浅无溢出。无打回。