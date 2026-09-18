# 02 命盘与运限数据模块

## 输入

`01-input-intake` 必须为 `passed`，且已有确认的出生资料。

## 动作

先读取 `references/data-method-contract-v1.md`，按其中固定来源复用或生成结构化命盘。每次准备十二宫、命身、十四主星、辅煞、生年四化、自化/互化、大限、流年、八字四柱和流月斗君/五虎遁数据；缺项只重建该层。两种方法共用同一命盘，三方四正只在需要时记录。

可使用 `scripts/enrich-brightness.js`、`scripts/enrich-flow.js` 和相关 registry；按 `references/data-cache-contract-v1.md` 分层核验缓存键、哈希及时间覆盖。有效缓存直接复用，参数、算法或案例库变动只使相关缓存失效。候选盘使用独立缓存键，禁止覆盖确认盘。

涉及流月时必须运行 `scripts/validate-monthly-flow.js`。缺月数据时用本地 `iztro` 重新生成完整流月；不得把节气月干支当成完整流月。

## 输出

结构化命盘、运限数据、实际使用的资料清单和数据一致性结果。

## 门禁

无法可靠生成命盘、关键运限缺失或数据来源未记录：`failed` 或 `blocked`，不得进入案例和分析模块。流月任务只有 `monthlyDataStatus` 为 `complete` 时才能进入具体月份分析。
