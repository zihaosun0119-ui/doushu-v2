# 04 质量与交付模块

## 输入

`01-input-intake`、`02-chart-data`、`03-analysis` 均为 `passed`，并已有完整分析结果。

## 动作

执行独立复核或本地独立审校，检查数据一致性、推理链、案例边界、重复结论、时间窗口及健康/财务/关系边界。

修复复核问题后，按 `references/user-rendering-v3.md` 和 `references/user-report-rewrite-contract-v1.md` 生成用户正文，完成克制专业语言审校、重复检查和边界检查。最后运行 `scripts/validate-execution-gates.ps1`；仅在门禁通过后生成和检查 HTML/PDF。

## 输出

复核记录、用户可读正文、专业依据、通过的 `execution-manifest.json`、交付清单和用户要求的 HTML/PDF。

## 门禁

没有复核记录、问题未修复、正文泄露内部流程或未解释术语、健康越过医疗边界、事业/感情出现确定性预测、manifest 不完整或门禁脚本失败：禁止交付并标记 `failed`。

