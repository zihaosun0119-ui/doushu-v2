# 02 命盘与运限数据模块

## 输入

`01-input-intake` 必须为 `passed`，且已有确认的出生资料。

## 动作

按 `chart_key` 复用或生成结构化命盘。每次先完成飞星基础数据：原局十二宫、命身、十四主星、辅煞、生年四化、自化、互化/连环忌、大限、流年命宫和流月斗君/五虎遁数据；再按 `method_profile` 追加河洛坐标、命疾一六、命财官、主问宫气数位和原盘宫干四化，或将飞星链提升为主断。若 `report_mode = complete`，同时准备全盘十二宫覆盖、关键三方四正和全盘专题所需的资料状态。两种模式共用底层命盘，但运限宫干和流月规则必须按所选模式记录。三方四正只在需要论格局或流月承接时记录。

可使用 `scripts/enrich-brightness.js`、`scripts/enrich-flow.js` 和相关 registry；按 `references/data-cache-contract-v1.md` 分层核验缓存键、哈希及时间覆盖。有效缓存直接复用，参数、算法或案例库变动只使相关缓存失效。候选盘使用独立缓存键，禁止覆盖确认盘。

涉及流月时必须运行 `scripts/validate-monthly-flow.js`。状态为 `partial` 时运行 `scripts/merge-mingli-fallback.js` 补齐流月命宫、十二宫、月干四化和叠宫，并再次校验；不得把 `jieqiMonths` 当成完整流月。

## 输出

结构化命盘、运限数据、实际使用的资料清单和数据一致性结果。

## 门禁

无法可靠生成命盘、关键运限缺失或数据来源未记录：`failed` 或 `blocked`，不得进入案例和分析模块。流月任务只有 `monthlyDataStatus` 为 `complete` 或 `fallback` 时才能进入具体月份分析。
