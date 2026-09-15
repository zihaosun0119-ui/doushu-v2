# 04 质量与交付模块

## 输入

`01-input-intake`、`02-chart-data`、`03-analysis` 均为 `passed`，并已有完整分析结果。若 `report_mode = complete`，还必须有 `03-complete-report = passed`。

## 动作

执行独立复核或本地独立审校，先检查每次都必须存在的飞星基础层，再按 `method_profile` 检查河洛坐标/气数位或飞星源宫/落宫、原盘或大限宫干四化、禄忌/自化跟踪、推理链、具体现实场景、触发条件、验证点、行动建议、案例边界、重复结论、时间窗口及健康/财务/关系边界。完整模式另检查飞星独立链、河洛独立链、关键三方四正、全盘范围、动态跨领域和决策支持记录。

修复复核问题后，按 `references/user-rendering-v3.md`、`references/user-report-rewrite-contract-v1.md` 和所选方法文件生成用户正文，完成克制专业语言审校、重复检查和边界检查。先把对应模式的检查写入带 `profile` 的 `method_preflight`，再运行 `scripts/validate-execution-gates.ps1 -Phase preflight`。通过后生成和检查 HTML/PDF，将产物与 QA 记录及哈希写入 manifest；完成后运行 `-Phase final`，通过才交付。preflight 时 delivery 与本模块尚未完成，不得预填 passed。完整字段与状态见 `references/execution-contract-v2.md`。

## 输出

复核记录、用户可读正文、专业依据、通过的 `execution-manifest.json`、交付清单和用户要求的 HTML/PDF。

## 门禁

没有复核记录、问题未修复、正文泄露内部流程或未解释术语、健康越过医疗边界、事业/感情出现确定性预测、manifest 不完整或门禁脚本失败：禁止交付并标记 `failed`。
