# Doushu v2 执行契约（execution-3）

门禁脚本：`scripts/validate-execution-gates.ps1`。`-Phase` 可取 `preflight` 或 `final`，默认 `final`。preflight 检查执行记录和用户正文草稿是否完整，可不记录交付阶段和最终产物；final 还必须有非空报告、QA 记录和最终产物，且逐文件 SHA-256 一致。final 的 `report_source` 必须与传入的 `-ReportFile` 路径和哈希一致。

## 可操作规则

每次任务先建立 manifest，状态从 `pending` 开始。pending 不能通过门禁，也不能被改写成“已完成”来代替实际记录。只有实际读取或生成后，才将对应项置为 `passed` 并填写文件记录。脚本检查文件确实存在、非空、哈希匹配；哈希只提供文件追溯，不能证明文件内容已完成语义执行。

必须记录 `input_intake.required_files`、`modules.required_files`、`knowledge_route.required_files`。这些数组的每一项都是 `{path, sha256}`，路径相对 manifest 所在目录解析，或使用绝对路径。不要将相对 skill 根目录的路径未经转换直接写入任务 manifest。路由脚本可以先返回相对 skill root 的字符串路径；执行者必须对每个路径实际读取、计算 SHA-256，并把它转换为对象写入 `required_files`，同时在 `actual_files_read` 逐项写入同样的 path/hash，门禁会匹配两者。knowledge route 的 `warnings` 和顶层 `blocking_issues` 必须为空。独立复核必须同时包含复核文件 `files` 与 `language_proofreading.files`，两者分别逐一核验；复核语言应明确说明由独立审校完成（子智能体不可用时记录本地复核原因）。

preflight 时 workflow_status 使用 running，模块 01–03 为 passed，04-quality-delivery 和 delivery 保持 pending；生成与 QA 完成后才将后两项和工作流标为 passed，运行 final。stages.rendering 表示用户正文转换完成，不代表 PDF 渲染验收。旧 execution-2 清单需要按真实产物补齐新字段后使用，不得只更改版本号。

`method_preflight` 是实际命理输出的硬门禁，preflight 和 final 都必须存在且为 `passed`。每次排盘都必须完成飞星基础层，因此无论 `profile`（`helu` 或 `feixing`）为何，都必须通过 `feixing_chart_rules`、`feixing_level_chain`、`concrete_conclusions`、`boundary_check`；`helu` 还必须通过 `helu_coordinate`、`qi_shu_mapping`、`original_stem_transformations`，`feixing` 还必须通过 `feixing_monthly_split`、`feixing_school_boundary`。`report_mode = complete` 另必须通过 `complete_scope`、`feixing_full_chain`、`helu_full_chain`、`trine_review`、`cross_domain`；存在多个选择时还必须通过 `decision_support`，无选择时记录 `not_applicable`。其中 `concrete_conclusions` 均要求每条核心结论有现实对象、变化、触发、时间、验证和行动。缺少任一项，门禁失败。

正文覆盖至少包含 input-context（资料和假设）、action-plan（行动建议）；health 模式追加 medical-boundary（医疗边界），调用时须传入 -Mode health。`coverage` 使用 `{id, excerpt}` 项：每个摘录必须非空并实际出现在报告正文中。不要把固定标题当作覆盖证明，标题允许合并。

## execution-3 示例

初始文件可以如下建立；它明确是 pending，不能伪装成通过：

```json
{
  "schema_version": "doushu-v2-execution-3",
  "workflow_status": "pending",
  "stages": {
    "data": "pending", "direction": "pending", "analysis": "pending",
    "specialty": "pending", "independent_review": "pending",
    "rendering": "pending", "voice_review": "pending", "dedupe": "pending",
    "delivery": "pending"
  },
  "input_intake": {"status":"pending", "pending_questions":[], "required_files":[]},
  "modules": {"01-input-intake":"pending", "02-chart-data":"pending", "03-analysis":"pending", "03-complete-report":"pending", "04-quality-delivery":"pending", "required_files":[]},
  "report_mode": "standard",
  "method_preflight": {"status":"pending", "profile":"helu", "files":[], "checks":{"feixing_chart_rules":false,"feixing_level_chain":false,"helu_coordinate":false,"qi_shu_mapping":false,"original_stem_transformations":false,"level_tracking":false,"complete_scope":false,"feixing_full_chain":false,"helu_full_chain":false,"trine_review":false,"cross_domain":false,"decision_support":"not_applicable","concrete_conclusions":false,"boundary_check":false}},
  "knowledge_route": {"status":"pending", "required_files":[], "actual_files_read":[], "warnings":[]},
  "independent_review": {"status":"pending", "files":[], "language_proofreading":{"status":"pending", "files":[]}},
  "coverage": [], "qa_record": {"status":"pending", "files":[]},
  "artifacts": [], "blocking_issues": []
}
```

完成后，先运行：

```powershell
pwsh -File .\scripts\validate-execution-gates.ps1 -ExecutionManifest .\execution-manifest.json -ReportFile .\report.md -Phase preflight
```

生成并检查最终 HTML/PDF、QA 记录后运行：

```powershell
pwsh -File .\scripts\validate-execution-gates.ps1 -ExecutionManifest .\execution-manifest.json -ReportFile .\report.md -Phase final
```

完成记录的最小形状如下（所有 `...` 都必须替换为真实值，不能照抄）：

```json
{
  "schema_version":"doushu-v2-execution-3", "workflow_status":"passed",
  "stages":{"data":"passed","direction":"passed","analysis":"passed","specialty":"passed","independent_review":"passed","rendering":"passed","voice_review":"passed","dedupe":"passed","delivery":"passed"},
  "input_intake":{"status":"passed","pending_questions":[],"required_files":[{"path":"input.json","sha256":"..."}]},
  "modules":{"01-input-intake":"passed","02-chart-data":"passed","03-analysis":"passed","04-quality-delivery":"passed","required_files":[{"path":"modules-record.json","sha256":"..."}]},
  "knowledge_route":{"status":"passed","required_files":[{"path":"knowledge.md","sha256":"..."}],"actual_files_read":[{"path":"knowledge.md","sha256":"..."}],"warnings":[]},
  "method_preflight":{"status":"passed","profile":"helu","files":[{"path":"analysis-preflight.json","sha256":"..."}],"checks":{"feixing_chart_rules":true,"feixing_level_chain":true,"helu_coordinate":true,"qi_shu_mapping":true,"original_stem_transformations":true,"concrete_conclusions":true,"boundary_check":true}},
  "independent_review":{"status":"passed","files":[{"path":"independent-review.md","sha256":"..."}],"language_proofreading":{"status":"passed","files":[{"path":"language-review.md","sha256":"..."}]}},
  "coverage":[{"id":"input-context","excerpt":"报告中实际出现的输入语境摘录"},{"id":"action-plan","excerpt":"报告中实际出现的行动建议摘录"}],
  "report_source":{"path":"report.md","sha256":"..."},
  "qa_record":{"status":"passed","files":[{"path":"qa.md","sha256":"..."}]},
  "artifacts":[{"path":"report.html","sha256":"..."}], "blocking_issues":[]
}
```

失败时停止交付，并报告执行门禁失败、失败项和修复动作；不得把草稿当最终报告。
