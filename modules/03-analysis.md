# 03 分析模块

## 输入

`01-input-intake`、`02-chart-data` 均为 `passed`，并已确认报告方向和时间范围。

## 动作

先读取 `modules/knowledge-route-registry.json` 并运行 `scripts/resolve-knowledge-route.ps1`，只加载本次任务所需资源。

每次都先完成排盘后的飞星基础层：原局生年四化、命宫飞化、自化/互化/连环忌、大限、流年和流月因果链数据；然后按 `method_profile` 确定主轴：`helu` 再完成坐标、命疾福、命财官气数位、主问宫气数位、原盘宫干四化、本宫与对宫，`feixing` 则把飞星链提升为主断并将河洛、中州、许铨仁作为分栏对照。三方四正只有在所选模式需要论格局或流月承接时作为次级参考。没有使用案例时记录“未使用案例”，不得伪造检索结果。专项报告只抽取已有分析结论，不重新推演命盘。

流月任务读取 `references/monthly-analysis-output-v1.md`、`references/methodology-and-user-report-v2.md` 和 `references/helu-specificity-and-preflight-v1.md`；需要跨事业、合作、迁移等领域时再读取 `references/dynamic-cross-domain-v1.md`。分析前必须读取 `monthlyDataStatus`。状态为 `complete` 或 `fallback` 时，按目标年份自然月份覆盖 12 个月，每月登记主题、重点领域、现实表现、行动、依据摘要、置信度和不确定性；状态为 `partial` 或 `unavailable` 时不得输出具体流月宫位、月干四化、叠宫或月份断语，必须把缺口写入报告。

每项核心判断记录所选模式的主宫/源宫、气数位或飞星落宫、原盘宫干（如适用）、化曜落点、具体现实对象和变化、组合推理、替代解释、成立条件、时间窗口、置信度、现实验证点和具体行动，并将路由结果和实际读取资源写入 `execution-manifest.json`。`report_mode = complete` 时，本模块只完成共用基础推演和方向事实登记，必须把完整全盘汇总交给 `03-complete-report`，不得提前用专项摘要代替完整模式。禁止只写“有机会、压力大、财运好、关系变化”等未落地结论。

## 输出

分析结果、专项转换草稿、案例/前事状态、结论编号、知识路由结果、实际资源清单、飞星基础层记录和带 `profile` 的 `method_preflight` 记录。无论主轴为何，飞星基础层必须登记；`helu` 与 `feixing` 再各自登记对应方法文件规定的检查项。

## 门禁

路由失败、加载路由外资源、缺少河洛坐标或气数位、案例被当作结论、核心判断缺少现实场景/触发条件/验证点/行动、不确定性被写成确定预测，或专项层产生无依据新结论：`failed`。
