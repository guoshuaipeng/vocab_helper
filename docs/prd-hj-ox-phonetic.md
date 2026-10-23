# Product Brief · 推荐词书沪教牛津2024七上补音标（R44）

模板：ChatPRD 公开 `ai-development-brief`（本地 Markdown，不催付费）  
产品：单词小助手 · vocab_helper  
日期：2026-10-23（Asia/Shanghai）  
状态：可开发

---

## Problem and Target User

**谁**：默认选中推荐本「沪教牛津 · 七年级上（2024）」的跟课初一学生（及旁观家长）。  
**障碍**：学习页（R43）大词卡已支持「有则显示」`phonetic`，但 `assets/wordbooks/hj-ox-7a-2024.json` 330 词全部 `phonetic=""`、`example=""`。推荐本用户等于空转音标 UI；样板 `pep-ps-3`（R21）已有完整 `/…/` IPA，体验落差明显。  
**为何要紧**：跟课认读依赖「词下音标」建立正确发音预期；UI 已就绪，缺口在内容，不是再堆控件。

---

## Evidence and Desired Outcomes

| 观察 | 来源 |
|------|------|
| hj-ox phonetic=0 / example=0（330 词） | 本仓库 JSON 统计 2026-10-23 |
| 学习页正面有则渲染 phonetic | `learn_screen.dart` R43 大词卡 |
| pep-ps-3 已有 `/ˈruːlə/` 式 IPA | R21 样板 |
| 公开模式：Anki/百词斩「词下音标 + 点按揭晓释义」 | 公开截图/产品习惯（非付费 MCP） |

**期望结果**：推荐本单字词音标覆盖率 ≥85%；短语诚实留空；学习页未揭晓态可见词下音标；自测页仍不展示音标（R21 约定）。

**RICE（本轮）**

| 维 | 评估 |
|----|------|
| Reach | 默认推荐本全用户 |
| Impact | 高（跟课认读） |
| Confidence | 高（UI 已就绪） |
| Effort | 中（批量补 phonetic；短语可空） |

---

## Scope and Non-Goals

**做（最小有用）**

1. 为 `hj-ox-7a-2024.json` 批量补 `phonetic`：英式 IPA 优先，格式与 pep-ps-3 一致（`/ˈɒnɪst/`）。  
2. 数据源：免费 Dictionary API `https://api.dictionaryapi.dev/api/v2/entries/en/{word}`；优先含 ɒ/ɑː/ə 等英式标记的 phonetic；失败不瞎编。  
3. 短语/多词（含空格）API 失败则保持空。  
4. 单测门槛 + 学习页窄浅未揭晓截图自验。  
5. JSON/docs 注明来源：dictionaryapi.dev + 人工抽查。

**可选（timebox）**：API 有例句则填 `example`，单字词目标 ≥50%；不够则砍 example，保音标。

**不做**

- 新题型；改 SRS；改 R43 布局；付费设计 MCP；一次改全库其它词书  
- 用户可编辑音标；云同步；凑满 337 缺词（另缺口）  
- 自测页展示音标

---

## Requirements and Acceptance Criteria

| # | 行为 | 验收 |
|---|------|------|
| R1 | 单字词（无空格）phonetic 非空比例 ≥85% | `hj_ox` 内容单测门槛 |
| R2 | 非空 phonetic 以 `/` 起止 | 抽查 ≥5 词（含 guitar/honest） |
| R3 | 短语可空；禁止臆造 | 多词保持 `""` 或 API 真值 |
| R4 | 学习页未揭晓可见音标 | 窄浅截图 + acceptance |
| R5 | 自测页不展示音标 | 回归既有约定（无需新 UI） |
| R6 | source/docs 注明 dictionaryapi.dev | JSON `source` 或 docs 脚注 |

---

## User Journey and Failure States

1. 用户打开推荐本 → 学习认读。  
2. 正面大词下显示 `/…/`（若有）→ 点按揭晓中文。  
3. 无音标词：该行不渲染（现有 `isNotEmpty`），不出现「—」。  
4. API/enrich 失败词：留空，后续可人工补；不阻塞学习。

---

## Success Measurement

- **内容**：单字词 phonetic 覆盖率 ≥85%（分母=无空格词数）。  
- **体验**：`docs/shots/r44-*.png` 未揭晓态可见音标；acceptance 勾选。  
- **工程**：相关 `flutter test` 绿；本地 tip SHA；未 push。

---

## Risks and Open Questions

| 风险 | 缓解 |
|------|------|
| 免费 API 限流/缺词 | 节流重试；缺词留空；≥85% 即可收口 |
| 美式/英式混杂 | 优先含 ɒ/ɑː/ə 的条目；与 pep 斜杠格式对齐 |
| 短语无独立音标 | 诚实留空（本轮接受） |
| example timebox | 优先音标；例句可砍 |

---

## Implementation Context

- 资产：`assets/wordbooks/hj-ox-7a-2024.json`（330 词，约 257 单字 / 73 短语）  
- UI：已支持；本轮**只改数据** + 测试/截图  
- 设计：`docs/design-r44.md`；对照 `docs/ux-guidelines.md`、R21  
- 约束：本机 Windows 开发；禁止 Cursor 云端代理；一项一 commit；不 push
