# 单词小助手

中小学生背英语单词的 Flutter App（iOS / Android / Windows / Web）。

## 接下来做什么？（必读）

**产品需求统一写在 [`docs/requirements.md`](docs/requirements.md)。**

- 任何人（开发、产品、自动化迭代助手）打开本仓库，先看该文件就知道当前优先级与未完成项。
- 新需求请追加到 `docs/requirements.md`，不要只留在聊天记录里。
- 每轮迭代：读 requirements → 设计（`docs/design-rN.md`）→ 开发 → 测试 → 复盘（`docs/retro.md`）。

其它文档：

| 文件 | 用途 |
|------|------|
| `docs/requirements.md` | **需求单一来源** |
| `docs/backlog.md` | 旧待办列表（逐步以 requirements 为准） |
| `docs/dev-rules.md` | 开发规则（≤15 条） |
| `docs/retro.md` | 每轮复盘 |
| `docs/design-r*.md` | 各轮交互/UI 设计说明 |

## 环境

- Flutter 3.47+（本机示例：`C:\Users\user\flutter`）
- 打安卓包还需 Android Studio / Android SDK
- 打 iOS 包需要 macOS + Xcode
- Windows 桌面跑 TTS 需本机语音包；带 `flutter_tts` 编译 Windows 时 PATH 中要有 `nuget.exe`

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