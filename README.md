# 单词小助手

中小学生背英语单词的 Flutter App（iOS / Android / Windows / Web）。

## 需求来源（换 bot 也先看这里）

**唯一需求文件：[`docs/requirements.md`](docs/requirements.md)**

- 所有未完成需求、优先级、「进行中」主需求都只写在这个文件里。
- 用户会通过其它渠道往该文件追加需求；聊天记录不是需求来源。
- **任何新接手的人 / 自动化助手 / 换 bot**：打开仓库后第一步读 `docs/requirements.md`，从「进行中」或最高优先级未勾选项取 1 个主需求继续迭代，不要问「要不要继续」。
- 完成一项就改成 `[x]`，并在文件底部「变更记录」留一行。
- 迭代节奏：读 requirements → 交互/UI 设计（`docs/design-rN.md`）→ 开发 → 测试 → 设计师验收 → 复盘（`docs/retro.md`）。规则见 `docs/dev-rules.md`。

其它文档：

| 文件 | 用途 |
|------|------|
| `docs/requirements.md` | **需求单一来源（必读）** |
| `docs/dev-rules.md` | 开发规则（≤15 条） |
| `docs/retro.md` | 每轮复盘 |
| `docs/design-r*.md` | 各轮交互/UI 设计说明 |
| `docs/backlog.md` | 旧待办镜像（以 requirements 为准） |

## 环境

- Flutter 3.47+（本机示例：`C:\Users\user\flutter`）
- 打安卓包还需 Android Studio / Android SDK（用户可后置，不挡产品迭代）
- 打 iOS 包需要 macOS + Xcode
- Windows 桌面跑 TTS 需本机语音包；带 `flutter_tts` 编译 Windows 时 PATH 中要有 `nuget.exe`
- **本产品约定在用户本机开发，不使用 Cursor 云端代理**（除非用户再要求）

## 运行

```powershell
cd C:\Users\user\Documents\vocab_helper
flutter pub get
flutter run -d windows
# 或
flutter run -d chrome
```

手机真机：接上 USB 并开启调试后 `flutter devices`，再 `flutter run`。

## 测试

```powershell
flutter test
flutter analyze
```

## 仓库

- Gitee：https://gitee.com/CodeYG/vocab_helper