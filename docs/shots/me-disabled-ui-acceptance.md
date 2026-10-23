# me-disabled — UI 验收（复验）

## 状态
**待复验**（对比度打回已修）

## 修复点
- 深色 disabled 前景/按钮底对比 ≥ **3:1**（`AppTheme.disabledForeground` 深色 alpha 0.70；`contrastRatio` 可测）
- 新截图：`me-disabled-narrow-dark.png`、`me-disabled-contrast.png`

## 截图
| 文件 | 说明 |
|------|------|
| `docs/shots/me-disabled-narrow-dark.png` | 窄屏深色，自测/复习区 disabled |
| `docs/shots/me-disabled-contrast.png` | 宽屏深色对比参考 |

## 验收清单
- [x] 无教材/无可测词时「自测」「复习」呈 disabled，文案仍可读（非糊成一片）
- [x] 深色下 disabled 字色 vs 按钮面对比 ≥ 3:1（单元测试断言）
- [x] 浅色未明显变差（alpha 0.45）
- [x] 新截图已入库

## 备注
复验请对照上表两张图 + `test/me_disabled_test.dart` 中 `contrast >= 3.0`。
