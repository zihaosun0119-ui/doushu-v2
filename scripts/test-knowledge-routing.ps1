$ErrorActionPreference = 'Stop'

$skillRoot = Split-Path -Parent $PSScriptRoot
$router = Join-Path $PSScriptRoot 'resolve-knowledge-route.ps1'
$registry = Join-Path $skillRoot 'modules\knowledge-route-registry.json'

function Invoke-Route([string]$Text, [string]$Topic = '', [string]$TimeScope = '', [string]$MethodProfile = 'helu') {
  $args = @{ UserText = $Text; RegistryPath = $registry }
  if ($Topic) { $args.Topic = $Topic }
  if ($TimeScope) { $args.TimeScope = $TimeScope }
  if ($MethodProfile) { $args.MethodProfile = $MethodProfile }
  return (& $router @args | ConvertFrom-Json)
}

$failures = [System.Collections.Generic.List[string]]::new()
$careerHealth = Invoke-Route '工作压力很大，想知道要不要辞职，未来三年怎么办'
if ($careerHealth.matched_topics -notcontains '事业') { $failures.Add('career topic not detected') }
if ($careerHealth.matched_topics -notcontains '健康') { $failures.Add('health topic not detected') }
if ($careerHealth.matched_time_scopes -notcontains '未来三年') { $failures.Add('time scope not detected') }
if ($careerHealth.required_files -notcontains 'references/career-analysis-v2.md') { $failures.Add('career rule not routed') }
if ($careerHealth.required_files -notcontains 'references/health-rules-full-v2.md') { $failures.Add('health rule not routed') }
if ($careerHealth.required_files -notcontains 'references/decision-support-v2.md') { $failures.Add('decision support not routed') }
if ($careerHealth.required_files -notcontains 'references/feixing-fourhua-method-v1.md') { $failures.Add('feixing baseline not routed for default profile') }
if ($careerHealth.status -ne 'passed') { $failures.Add('career+health route failed') }

$relationship = Invoke-Route '我想了解感情和伴侣关系' '感情'
if ($relationship.matched_topics -notcontains '感情') { $failures.Add('relationship topic not detected') }
if ($relationship.required_files -notcontains 'references/relationship-analysis-v2.md') { $failures.Add('relationship rule not routed') }

$feixing = Invoke-Route '请按飞星四化分析今年事业，准到月' '飞星断盘' '流年' 'feixing'
if ($feixing.method_profile -ne 'feixing') { $failures.Add('feixing method profile not recorded') }
if ($feixing.required_files -notcontains 'references/feixing-fourhua-method-v1.md') { $failures.Add('feixing rule not routed') }
if ($feixing.required_files -contains 'references/analysis-core-v2.md') { $failures.Add('feixing route mixed helu core rule') }

$complete = Invoke-Route '请生成完整命局全盘详细分析报告' '完整' '本命' 'helu'
if ($complete.report_mode -ne 'complete') { $failures.Add('complete report mode not detected') }
foreach ($file in @('references/complete-report-mode-v1.md','references/dynamic-cross-domain-v1.md','references/palace-analysis-v1.md','references/star-interaction-v1.md','references/career-analysis-v2.md','references/relationship-analysis-v2.md','references/health-rules-full-v2.md')) {
  if ($complete.required_files -notcontains $file) { $failures.Add("complete rule not routed: $file") }
}

$unknown = Invoke-Route '帮我分析一下'
if ($unknown.warnings.Count -eq 0) { $failures.Add('unknown topic warning missing') }

if ($failures.Count -gt 0) {
  $failures | ForEach-Object { Write-Error $_ }
  exit 1
}

Write-Output 'doushu v2 knowledge routing: PASS'
