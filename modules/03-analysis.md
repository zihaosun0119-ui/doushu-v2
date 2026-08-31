# 03 分析模块

## 输入

`01-input-intake`、`02-chart-data` 均为 `passed`，并已确认报告方向和时间范围。

## 动作

先读取 `modules/knowledge-route-registry.json` 并运行 `scripts/resolve-knowledge-route.ps1`，只加载本次任务所需资源。

完成通用基础分析，再按需执行案例检索、前事验证、专项深入分析和决策支持。没有使用案例时记录“未使用案例”，不得伪造检索结果。专项报告只抽取已有分析结论，不重新推演命盘。

流月任务读取 `references/monthly-analysis-output-v1.md`；需要跨事业、合作、迁移等领域时再读取 `references/dynamic-cross-domain-v1.md`。分析前必须读取 `monthlyDataStatus`，状态为 `partial` 或 `unavailable` 时不得输出具体流月宫位或四化结论。

每项核心判断记录盘面依据、组合推理、替代解释、成立条件、时间窗口、置信度和现实验证点，并将路由结果和实际读取资源写入 `execution-manifest.json`。

## 输出

分析结果、专项转换草稿、案例/前事状态、结论编号、知识路由结果和实际资源清单。

## 门禁

路由失败、加载路由外资源、缺少通用分析、案例被当作结论、不确定性被写成确定预测，或专项层产生无依据新结论：`failed`。
