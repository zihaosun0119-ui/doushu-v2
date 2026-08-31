# 02 命盘与运限数据模块

## 输入

`01-input-intake` 必须为 `passed`，且已有确认的出生资料。

## 动作

按 `chart_key` 复用或生成结构化命盘，核验命宫、身宫、十二宫、主辅煞星、庙旺、三方四正、四化、大限和所需流年。

可使用 `scripts/enrich-brightness.js`、`scripts/enrich-flow.js` 和相关 registry；数据未变化时不得重复生成。

涉及流月时必须运行 `scripts/validate-monthly-flow.js`。状态为 `partial` 时运行 `scripts/merge-mingli-fallback.js` 补齐流月命宫、十二宫、月干四化和叠宫，并再次校验；不得把 `jieqiMonths` 当成完整流月。

## 输出

结构化命盘、运限数据、实际使用的资料清单和数据一致性结果。

## 门禁

无法可靠生成命盘、关键运限缺失或数据来源未记录：`failed` 或 `blocked`，不得进入案例和分析模块。流月任务只有 `monthlyDataStatus` 为 `complete` 或 `fallback` 时才能进入具体月份分析。
