# Round 36 · 沪教牛津 2024 七上词书 · UI 验收

**对应**：R36 / P1 正确词表上架  
**设计稿**：`docs/design-r36.md`  
**状态**：**UI 通过**（tip `2efb150` · 收口 docs 本 commit · 2026-10-23）  
**资产**：`assets/wordbooks/hj-ox-7a-2024.json` + catalog `hj-ox-7a-2024`  
**单测**：`test/hj_ox_7a_2024_content_test.dart`  
**截图前缀**：`r36-`

## 环境（须附截图）

- [x] 词书列表 · 窄窗浅色 → `r36-catalog-narrow-light.png`（可见「沪教牛津 · 七年级上（2024）」· 共 330 词 · 2024六三）
- [~] 学习页某 Unit · 窄浅（Soft-pass：学习页抛光另轨 `74dd9bb` / design-r36-learn-layout；本轮词书数据轨不重拍学习页）

## 要点

- [x] catalog 可选中新书；sourceLabel「2024六三」
- [x] 与 `hj-jh-7`「精选·非七上全书」不混淆
- [x] 330 词 · 8 Unit · 无空 meaning（单测）
- [x] 较目标 ~337 **诚实差约 7 词**（不以猜词凑满）

## 不做

- R37 OCR / R38 SRS；改回 learn_screen；五四学制词表

## 设计师结论

- 结论：**通过**
- 日期：2026-10-23
- 验收人：单词迭代（自验）
- tip：`2efb150`
- 备注：词书列表窄浅目视通过；词量缺口记入 retro，待纸质课本补词。
