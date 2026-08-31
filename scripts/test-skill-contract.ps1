$ErrorActionPreference = 'Stop'

$skillRoot = Split-Path -Parent $PSScriptRoot
$skill = Get-Content -LiteralPath (Join-Path $skillRoot 'SKILL.md') -Raw -Encoding UTF8
$analysisCore = Get-Content -LiteralPath (Join-Path $skillRoot 'references\analysis-core-v2.md') -Raw -Encoding UTF8
$reportModes = Get-Content -LiteralPath (Join-Path $skillRoot 'references\report-modes-v2.md') -Raw -Encoding UTF8
$decisionSupport = Get-Content -LiteralPath (Join-Path $skillRoot 'references\decision-support-v2.md') -Raw -Encoding UTF8
$userRendering = Get-Content -LiteralPath (Join-Path $skillRoot 'references\user-rendering-v3.md') -Raw -Encoding UTF8
$healthRules = Get-Content -LiteralPath (Join-Path $skillRoot 'references\health-rules-full-v2.md') -Raw -Encoding UTF8
$runner = Get-Content -LiteralPath (Join-Path $skillRoot 'scripts\run-report.ps1') -Raw -Encoding UTF8
$executionContract = Get-Content -LiteralPath (Join-Path $skillRoot 'references\execution-contract-v2.md') -Raw -Encoding UTF8
$inputGate = Get-Content -LiteralPath (Join-Path $skillRoot 'references\input-intake-gate-v2.md') -Raw -Encoding UTF8
$gateScript = Get-Content -LiteralPath (Join-Path $skillRoot 'scripts\validate-execution-gates.ps1') -Raw -Encoding UTF8
$knowledgeContract = Get-Content -LiteralPath (Join-Path $skillRoot 'references\knowledge-expansion-contract-v3.md') -Raw -Encoding UTF8
$palaceMatrix = Get-Content -LiteralPath (Join-Path $skillRoot 'references\palace-analysis-v1.md') -Raw -Encoding UTF8
$starInteraction = Get-Content -LiteralPath (Join-Path $skillRoot 'references\star-interaction-v1.md') -Raw -Encoding UTF8
$socialRegistry = Get-Content -LiteralPath (Join-Path $skillRoot 'references\social-source-registry-v1.md') -Raw -Encoding UTF8
$antiRepetition = Get-Content -LiteralPath (Join-Path $skillRoot 'references\anti-repetition-v1.md') -Raw -Encoding UTF8
$patternLibrary = Get-Content -LiteralPath (Join-Path $skillRoot 'references\pattern-library-v1.md') -Raw -Encoding UTF8
$knowledgeValidator = Get-Content -LiteralPath (Join-Path $skillRoot 'scripts\validate-knowledge-base.ps1') -Raw -Encoding UTF8

$failures = [System.Collections.Generic.List[string]]::new()
function Require-Text([string]$Content, [string]$Needle, [string]$Label) {
  if ($Content.IndexOf($Needle, [System.StringComparison]::Ordinal) -lt 0) {
    $failures.Add("$Label missing: $Needle")
  }
}

Require-Text $skill 'references/analysis-core-v2.md' 'skill routing'
Require-Text $skill 'references/analysis-deep-rules-full-v2.md' 'skill routing'
Require-Text $skill 'references/health-rules-full-v2.md' 'skill routing'
Require-Text $skill 'references/report-modes-v2.md' 'skill routing'
Require-Text $skill 'references/decision-support-v2.md' 'skill routing'
Require-Text $skill 'references/user-rendering-v3.md' 'skill routing'
Require-Text $skill 'career-analysis-v2.md' 'skill routing'
Require-Text $skill 'relationship-analysis-v2.md' 'skill routing'
Require-Text $skill 'restrained-professional-voice' 'skill delivery'
Require-Text $skill 'execution-manifest.json' 'skill execution manifest'
Require-Text $skill 'HARD_GATE' 'skill hard gate'
Require-Text $skill 'input-intake-gate-v2.md' 'mandatory input intake routing'
Require-Text $inputGate '暂停并询问' 'mandatory input intake gate'
Require-Text $inputGate '出生时间不明确' 'birth time clarification gate'
Require-Text $executionContract 'independent_review' 'execution contract review'
Require-Text $executionContract 'input_intake' 'execution contract input intake stage'
Require-Text $executionContract '不得生成或交付最终 HTML/PDF' 'execution contract delivery gate'
Require-Text $gateScript 'workflow_status' 'gate workflow status'
Require-Text $gateScript 'independent_review' 'gate independent review'
Require-Text $skill 'knowledge-expansion-contract-v3.md' 'knowledge routing'
Require-Text $skill 'anti-repetition-v1.md' 'anti repetition routing'
Require-Text $knowledgeContract '100—200' 'knowledge target'
Require-Text $palaceMatrix '12 个维度' 'palace matrix'
Require-Text $starInteraction '十四主星最低覆盖项' 'star interaction'
Require-Text $socialRegistry 'B 站' 'social source registry'
Require-Text $antiRepetition '不可直接复用的表达' 'anti repetition contract'
Require-Text $skill 'pattern-library-v1.md' 'pattern routing'
Require-Text $patternLibrary '120 条分析组合' 'pattern library count declaration'
Require-Text $knowledgeValidator 'sources=' 'knowledge validator'
Require-Text $analysisCore '结论编号' 'analysis contract'
Require-Text $reportModes '健康专项' 'report modes'
Require-Text $reportModes '事业专项' 'report modes'
Require-Text $reportModes '感情专项' 'report modes'
Require-Text $reportModes '社交专项' 'report modes'
Require-Text $decisionSupport '低成本验证动作' 'decision support'
Require-Text $healthRules '五脏六腑' 'health contract'
Require-Text $userRendering '先说最重要的结论' 'rendering contract'
$career = Get-Content -LiteralPath (Join-Path $skillRoot 'references\career-analysis-v2.md') -Raw -Encoding UTF8
$relationship = Get-Content -LiteralPath (Join-Path $skillRoot 'references\relationship-analysis-v2.md') -Raw -Encoding UTF8
Require-Text $career '最佳工作机制' 'career contract'
Require-Text $career '财富与价值变现' 'career contract'
Require-Text $career '优势链与风险链' 'career contract'
Require-Text $relationship '吸引模式' 'relationship contract'
Require-Text $relationship '冲突与长期运行' 'relationship contract'
Require-Text $relationship '关系时间地图' 'relationship contract'
Require-Text $relationship '关系底层模式' 'relationship contract'
Require-Text $relationship '资料说明' 'relationship contract'
Require-Text $relationship '现在怎么做' 'relationship contract'
Require-Text $relationship '一个低成本行动' 'relationship contract'
Require-Text $relationship '观察期限' 'relationship contract'
Require-Text $relationship '推进条件' 'relationship contract'
Require-Text $relationship 'Must-have' 'relationship contract'
Require-Text $relationship 'Dealbreaker' 'relationship contract'
Require-Text $relationship '高关联' 'relationship contract'
Require-Text $relationship '对方投入与关系发展' 'relationship contract'
Require-Text $relationship '情绪回流 ≠ 关系重建' 'relationship contract'
Require-Text $relationship '调整或止损信号' 'relationship contract'
Require-Text $runner "Invoke-Stage 'analysis-source-qa'" 'report runner'
Require-Text $runner "Invoke-Stage 'chart-source-qa'" 'report runner'
Require-Text $runner 'brightnessMetadata' 'report runner'
Require-Text $runner '[string]$AnalysisManifest' 'report runner'
Require-Text $runner "Invoke-Stage 'analysis-manifest-qa'" 'report runner'
Require-Text $runner 'Get-FileHash' 'report runner'

if ($failures.Count -gt 0) {
  $failures | ForEach-Object { Write-Error $_ }
  exit 1
}

Write-Output 'doushu v2 skill contract: PASS'
