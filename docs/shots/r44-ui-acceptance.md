# R44 UI 自验 · 推荐本补音标

日期：2026-10-23（Asia/Shanghai）  
词书：hj-ox-7a-2024  
截图命令：UPDATE_SHOTS=1 flutter test test/r44_phonetic_shot_test.dart

## 内容门槛（单测）

- [x] 单字词 phonetic ≥85%（实测约 **92.6%** = 238/257）
- [x] 抽查 guitar / honest / patient / improve / confident 均含 /…/
- [x] JSON source 注明 dictionaryapi.dev + spot-check
- [x] example 可选：单字词约 78%（超过可选 50%，未砍）

## 截图

| 文件 | 场景 | 结果 |
|------|------|------|
| [r44-narrow-light-phonetic.png](r44-narrow-light-phonetic.png) | 窄浅 · 未揭晓 · guitar 词下音标 | **Pass** |
| [r44-narrow-dark-phonetic.png](r44-narrow-dark-phonetic.png) | 窄深 · 未揭晓（可选） | **Pass** |

## 验收勾选（design-r44）

- [x] A1 单字词 phonetic ≥85%
- [x] A2 抽查 ≥5 词含 /
- [x] A3 窄浅未揭晓可见词下音标
- [x] A4 自测不展示音标（R21 约定，本轮未改 quiz UI）
- [x] A5 相关内容单测绿；本地 tip；未 push

## 备注

- 短语/多词诚实留空；API 530 失败词（约 19 单字）未瞎编。
- 宽窗截图本轮 timebox 砍掉（窄浅已证主路径）。
- IPA 部分字形依赖本机字体；结构为词下 /…/ 行，与 R43 布局一致。
