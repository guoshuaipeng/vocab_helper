# 插队 · 搜索「已经是这本」· UI 验收

**对应**：docs/requirements.md · P2「搜索点当前词书短提示」  
**对照**：ux-guidelines §9  
**截图前缀**：search-current-

## 环境（须附截图）

- [ ] 窄窗 ≤400 · 浅色（点当前书后出现反馈）→ `search-current-narrow-light.png`
- [ ] 窄窗 ≤400 · 深色 → `search-current-narrow-dark.png`
- [ ] 宽窗 ≥900 · 浅色或深色至少 1 张 → `search-current-wide.png`

## 要点

- [ ] 搜索命中行**已是当前词书**时：有一句口语反馈（SnackBar「已经是这本」或同等勾选高亮）
- [ ] **不**弹出切换确认对话框
- [ ] 文案口语、短；深浅色 SnackBar/高亮可读

## 不做

- 改搜索排序/索引、强制切换词书

## 设计师结论

- 结论：（通过 / 打回）
- 日期：
- 验收人：单词UI设计
- 备注：（须基于截图；截到 SnackBar 或高亮瞬间）