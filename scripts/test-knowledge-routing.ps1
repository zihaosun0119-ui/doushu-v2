$ErrorActionPreference = 'Stop'

$skillRoot = Split-Path -Parent $PSScriptRoot
$router = Join-Path $PSScriptRoot 'resolve-knowledge-route.ps1'
$registry = Join-Path $skillRoot 'modules\knowledge-route-registry.json'

function Invoke-Route([string]$Text, [string]$Topic = '', [string]$TimeScope = '') {
  $args = @{ UserText = $Text; RegistryPath = $registry }
  if ($Topic) { $args.Topic = $Topic }
  if ($TimeScope) { $args.TimeScope = $TimeScope }
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
if ($careerHealth.status -ne 'passed') { $failures.Add('career+health route failed') }

$relationship = Invoke-Route '我想了解感情和伴侣关系' '感情'
if ($relationship.matched_topics -notcontains '感情') { $failures.Add('relationship topic not detected') }
if ($relationship.required_files -notcontains 'references/relationship-analysis-v2.md') { $failures.Add('relationship rule not routed') }

$unknown = Invoke-Route '帮我分析一下'
if ($unknown.warnings.Count -eq 0) { $failures.Add('unknown topic warning missing') }

if ($failures.Count -gt 0) {
  $failures | ForEach-Object { Write-Error $_ }
  exit 1
}

Write-Output 'doushu v2 knowledge routing: PASS'

