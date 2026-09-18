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
$dataMethod = Get-Content -LiteralPath (Join-Path $skillRoot 'references\data-method-contract-v1.md') -Raw -Encoding UTF8
$inputGate = Get-Content -LiteralPath (Join-Path $skillRoot 'references\input-intake-gate-v2.md') -Raw -Encoding UTF8
$reportSelection = Get-Content -LiteralPath (Join-Path $skillRoot 'references\report-selection-gate-v1.md') -Raw -Encoding UTF8
$gateScript = Get-Content -LiteralPath (Join-Path $skillRoot 'scripts\validate-execution-gates.ps1') -Raw -Encoding UTF8
$knowledgeContract = Get-Content -LiteralPath (Join-Path $skillRoot 'references\knowledge-expansion-contract-v3.md') -Raw -Encoding UTF8
$palaceMatrix = Get-Content -LiteralPath (Join-Path $skillRoot 'references\palace-analysis-v1.md') -Raw -Encoding UTF8
$starInteraction = Get-Content -LiteralPath (Join-Path $skillRoot 'references\star-interaction-v1.md') -Raw -Encoding UTF8
$socialRegistry = Get-Content -LiteralPath (Join-Path $skillRoot 'references\social-source-registry-v1.md') -Raw -Encoding UTF8
$antiRepetition = Get-Content -LiteralPath (Join-Path $skillRoot 'references\anti-repetition-v1.md') -Raw -Encoding UTF8
$patternLibrary = Get-Content -LiteralPath (Join-Path $skillRoot 'references\pattern-library-v1.md') -Raw -Encoding UTF8
$knowledgeValidator = Get-Content -LiteralPath (Join-Path $skillRoot 'scripts\validate-knowledge-base.ps1') -Raw -Encoding UTF8
$analysisPrompt = Get-Content -LiteralPath (Join-Path $skillRoot 'references\analysis-chain-prompt-v2.md') -Raw -Encoding UTF8
$specialPrompts = Get-Content -LiteralPath (Join-Path $skillRoot 'references\special-report-prompts-full-v1.md') -Raw -Encoding UTF8

$failures = [System.Collections.Generic.List[string]]::new()
function Require-Text([string]$Content, [string]$Needle, [string]$Label) {
  if ($Content.IndexOf($Needle, [System.StringComparison]::Ordinal) -lt 0) {
    $failures.Add("$Label missing: $Needle")
  }
}
function Forbid-Text([string]$Content, [string]$Needle, [string]$Label) {
  if ($Content.IndexOf($Needle, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
    $failures.Add("$Label contains forbidden term: $Needle")
  }
}

Require-Text $skill 'references/analysis-core-v2.md' 'skill routing'
Require-Text $skill 'references/analysis-deep-rules-full-v2.md' 'skill routing'
Require-Text $skill 'references/health-rules-full-v2.md' 'skill routing'
Require-Text $skill 'references/report-modes-v2.md' 'skill routing'
Require-Text $skill 'references/decision-support-v2.md' 'skill routing'
Require-Text $skill 'references/data-method-contract-v1.md' 'fixed data method routing'
Require-Text $skill 'references/user-rendering-v3.md' 'skill routing'
Require-Text $skill 'career-analysis-v2.md' 'skill routing'
Require-Text $skill 'relationship-analysis-v2.md' 'skill routing'
Require-Text $skill 'restrained-professional-voice' 'skill delivery'
Require-Text $skill 'execution-manifest.json' 'skill execution manifest'
Require-Text $skill 'methodology-and-user-report-v2.md' 'methodology and user report routing'
Require-Text $skill 'report_mode = complete' 'complete report mode routing'
Require-Text $skill '03-complete-report' 'complete report module routing'
Require-Text $skill 'HARD_GATE' 'skill hard gate'
Require-Text $skill 'input-intake-gate-v2.md' 'mandatory input intake routing'
Require-Text $skill 'report-selection-gate-v1.md' 'mandatory report selection routing'
Require-Text $inputGate '暂停并询问' 'mandatory input intake gate'
Require-Text $inputGate '出生时间不明确' 'birth time clarification gate'
Require-Text $inputGate '报告选择页' 'report selection input gate'
Require-Text $reportSelection 'task.reportTypes' 'report selection request field'
Require-Text $reportSelection '用户确认选择前' 'report selection confirmation gate'
Require-Text $reportSelection '开始前请先选择要生成的报告' 'report selection prompt template'
Require-Text $executionContract 'independent_review' 'execution contract review'
Require-Text $executionContract 'input_intake' 'execution contract input intake stage'
Require-Text $executionContract 'preflight' 'execution contract preflight gate'
Require-Text $executionContract 'final' 'execution contract final gate'
Require-Text $dataMethod 'rawDates.chineseDate' 'bazi data method'
Require-Text $dataMethod 'monthlyList(目标年, true)' 'monthly data method'
Require-Text $dataMethod '斗君算法' 'monthly palace method'
Require-Text $dataMethod '五虎遁' 'monthly stem method'
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
Require-Text $healthRules '新版健康专项提示词（优先读取）' 'health prompt override'
Require-Text $healthRules '父母家族体质溯源' 'health family section'
Require-Text $healthRules '独家专属用药与避坑指南' 'health medication section'
Require-Text $healthRules '定制体检与精准防守方案' 'health screening section'
Require-Text $userRendering '先说最重要的结论' 'rendering contract'
$career = Get-Content -LiteralPath (Join-Path $skillRoot 'references\career-analysis-v2.md') -Raw -Encoding UTF8
$relationship = Get-Content -LiteralPath (Join-Path $skillRoot 'references\relationship-analysis-v2.md') -Raw -Encoding UTF8
Require-Text $career '最佳工作机制' 'career contract'
Require-Text $career '财富与价值变现' 'career contract'
Require-Text $career '优势链与风险链' 'career contract'
Require-Text $relationship '相处模式' 'relationship contract'
Require-Text $relationship '关系时间地图' 'relationship contract'
Require-Text $relationship '关系底层模式' 'relationship contract'
Require-Text $relationship 'AnySearch' 'relationship method fallback'
Require-Text $relationship '家庭财富层次' 'relationship partner profile'
Require-Text $relationship '至少列出 10 个具体时间点' 'relationship meeting window'
Require-Text $relationship '给用户的进入建议' 'relationship meeting advice'
Require-Text $relationship '外貌：结合夫妻宫主星' 'relationship partner profile'
Require-Text $relationship '家庭：结合夫妻宫三方四正' 'relationship partner profile'
Require-Text $relationship '性格与相处模式' 'relationship partner profile'
Require-Text $relationship '来源方向' 'relationship meeting context'
Require-Text $relationship '触发事件' 'relationship meeting context'
Require-Text $relationship '判断方法与来源' 'relationship methodology'
Require-Text $analysisPrompt '感情专项固定提示词（新版）' 'relationship prompt override'
Require-Text $analysisPrompt '公历时间（农历）｜场合｜触发遇见对象的原因｜关系落点' 'relationship prompt date table'
Require-Text $analysisPrompt '默认只交付 Markdown' 'relationship markdown delivery'
Require-Text $specialPrompts '感情专项提示词覆盖（新版，优先执行）' 'special relationship prompt override'
Require-Text $specialPrompts '默认列出 6—10 个重点窗口' 'special relationship date rule'
Require-Text $analysisPrompt '健康专项固定提示词（新版，优先执行）' 'health prompt override'
Require-Text $analysisPrompt '本人身体出厂设置' 'health body section'
Require-Text $analysisPrompt '用药与避坑指南' 'health medication section'
Require-Text $specialPrompts '健康专项提示词覆盖（新版，优先执行）' 'special health prompt override'
Require-Text $specialPrompts '父母家族体质溯源' 'special health family section'
Require-Text $specialPrompts '药物安全' 'special health medication safety'
Require-Text $runner "Invoke-Stage 'analysis-source-qa'" 'report runner'
Require-Text $runner "Invoke-Stage 'chart-source-qa'" 'report runner'
Require-Text $runner 'brightnessMetadata' 'report runner'
Require-Text $runner '[string]$AnalysisManifest' 'report runner'
Require-Text $runner "Invoke-Stage 'analysis-manifest-qa'" 'report runner'
Require-Text $runner 'Get-FileHash' 'report runner'

$skillRootsForTerms = @($skillRoot, (Join-Path (Split-Path -Parent $skillRoot) 'doushu'))
foreach ($root in $skillRootsForTerms) {
  Get-ChildItem -LiteralPath $root -Recurse -File -Filter '*.md' | ForEach-Object {
    $content = Get-Content -LiteralPath $_.FullName -Raw -Encoding UTF8
    foreach ($term in @(('置' + '信度'), ('置' + '信'), ('con' + 'fidence'))) { Forbid-Text $content $term $_.FullName }
  }
}

if ($failures.Count -gt 0) {
  $failures | ForEach-Object { Write-Error $_ }
  exit 1
}

Write-Output 'doushu v2 skill contract: PASS'
