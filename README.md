# 单词小助手

中小学生背英语单词的 Flutter App（iOS / Android / Windows / Web）。

## 环境

- Flutter 3.47+（本机路径：`C:\Users\user\flutter`）
- 打安卓包还需 Android Studio / Android SDK
- 打 iOS 包需要 macOS + Xcode

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
```
