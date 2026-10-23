# Round 25 · UI 验收（交给「单词UI设计」）

**对应**：`docs/design-r25.md` · 体验跃迁；对照 `docs/ux-guidelines.md` §8  
**前置**：R22 已通过；本轮**不加**新学习模式  
**代码**：fef6a1f（feat: Round 25 学习页呼吸感与即时反馈）；handoff 868a046  
**单测**：`flutter test` 全绿（42）

## 环境

- [x] 窄窗 ≤400（主列 maxWidth 520）
- [x] 全屏 / 宽窗 ≥900
- [x] 浅色 / 深色（闪卡浅色 surface+outlineVariant；深色 surfaceContainerHighest）

## 视觉权重

- [x] 闪卡为视觉主角（圆角 20、elevation 0 等价 BoxDecoration、内边距水平 28；Expanded 单词区明显高于任务条）
- [x] 任务条减重：外层 padding 8、格 minHeight 56；未选中描边 outlineVariant@40%；宽屏主文案 ≥14sp（LayoutBuilder）；窄窗三格仍单行
- [x] 无紫渐变 / 贴纸 Badge / 新 Banner / 统计墙回潮

## 即时反馈

- [x] 翻面：AnimatedSwitcher 200ms + Fade+Scale(0.98→1)
- [x] 「认识」：卡片边框 primary 轻闪 150ms 再切词；剩余数更新；闪动期间按钮禁用
- [x] 「不认识」：边框 error 轻闪 150ms；勿全屏大红恐吓
- [x] 底栏按下有涟漪（Material）；竖向 padding ≥14
- [x] 朗读中：喇叭 primary 高亮且禁用防连点；失败 SnackBar「暂时没法朗读」

## 空态 / 完成态 / 插队收口

- [x] 完成态字号 22 + 口语文案；主按钮「再来一轮」/「去自测一下」
- [x] 空态 CTA 分流：未选书→去选择年级；错词空→去学新词；单元空→看全部；加载失败→重试
- [x] 切单元短 SnackBar：「已筛选 …」/「显示全部」
- [x] 清空错词有确认对话框（对齐清空进度）
- [x] 自测「下一题/查看结果」竖向 padding ≥14

## 回归

- [x] 今日任务 / 间隔复习 / 音标例句 / R22 听音行为未回退（既有用例仍绿）
- [x] 既有 flutter test 绿（42/42）

## 设计师结论（请填写）

- 结论：**通过**
- 日期：2026-10-23（Asia/Shanghai）
- 验收人：单词UI设计
- 备注：对照 design-r25 与 ux §8 美感底线达标；按钮按下 scale 0.98 为设计可选未做，不挡通过。无打回项。
