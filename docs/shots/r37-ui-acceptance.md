# R37 UI 自验 · 拍照识词

**日期**：2026-10-23（Asia/Shanghai）  
**结论**：**通过（Windows 可验路径 + iOS 接线待真机）**

## 截图

| 图 | 说明 |
|----|------|
| r37-confirm-narrow-light.png | 窄窗浅色 · 确认列表（已在书/新词/缺义） |
| r37-confirm-narrow-dark.png | 窄窗深色 |
| r37-confirm-wide-light.png | 宽窗浅色 |

入口：学习顶栏扫描仪图标 / 我的「拍照加词」。源页含拍照（iOS）/相册/粘贴文字。

## 自验清单

- [x] 确认列表可勾选、编辑 spelling/义、选已有或新建单元
- [x] 无义新词不可加入（SnackBar 提示）
- [x] 取消/重来不写入；确认后 overlay 可查、单元筛选切到目标单元
- [x] 单测：OCR 文本抽取、匹配、overlay 去重、加入流程
- [x] 不破坏 R38 复习曲线单测 / 词书结构
- [ ] **iPhone 真机**：相机 + Vision OCR 出词（本机 Windows 无法验；AppDelegate MethodChannel 已接线）

## 平台说明

| 平台 | 本轮可用性 |
|------|------------|
| Windows | 粘贴文字 → 确认 → 加单元 → 学习可见（完整业务） |
| iOS 真机 | 拍照/相册 + Vision；需装真机包验证 |
| Android | 入口可用；图片 OCR 提示后置（粘贴仍可用） |
