param(
  [string[]]$Topic,
  [string]$UserText = '',
  [string]$TimeScope = '',
  [ValidateSet('helu','feixing')][string]$MethodProfile = 'helu',
  [string]$RegistryPath = (Join-Path (Split-Path -Parent $PSScriptRoot) 'modules\knowledge-route-registry.json'),
  [string]$OutputPath = ''
)

$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path -Parent $PSScriptRoot
$registry = Get-Content -LiteralPath $RegistryPath -Raw -Encoding UTF8 | ConvertFrom-Json

$required = [System.Collections.Generic.List[string]]::new()
$optional = [System.Collections.Generic.List[string]]::new()
$matchedTopics = [System.Collections.Generic.List[string]]::new()
$matchedScopes = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()

function Add-Unique([System.Collections.Generic.List[string]]$List, [string]$Value) {
  if (![string]::IsNullOrWhiteSpace($Value) -and !$List.Contains($Value)) { $List.Add($Value) }
}

function Add-Files($Target, $Files) {
  if ($null -eq $Files) { return }
  foreach ($file in @($Files)) {
    Add-Unique $Target ([string]$file)
  }
}

Add-Files $required $registry.defaults.required
Add-Files $optional $registry.defaults.optional
if ($null -eq $registry.method_profiles -or $null -eq $registry.method_profiles.$MethodProfile) {
  $warnings.Add('方法模式不存在：' + $MethodProfile)
} else {
  Add-Files $required $registry.method_profiles.$MethodProfile.required
  Add-Files $optional $registry.method_profiles.$MethodProfile.optional
}

$explicitTopics = @($Topic | Where-Object { ![string]::IsNullOrWhiteSpace($_) })
$text = (($UserText + ' ' + ($explicitTopics -join ' ') + ' ' + $TimeScope).Trim())

foreach ($property in $registry.topics.PSObject.Properties) {
  $topicName = $property.Name
  $rule = $property.Value
  $isMatch = $explicitTopics -contains $topicName
  foreach ($keyword in @($rule.keywords)) {
    if (![string]::IsNullOrWhiteSpace([string]$keyword) -and $text.Contains([string]$keyword)) {
      $isMatch = $true
    }
  }
  if ($isMatch) {
    $matchedTopics.Add($topicName)
    Add-Files $required $rule.required
    Add-Files $optional $rule.optional
  }
}

foreach ($property in $registry.time_scopes.PSObject.Properties) {
  $scopeName = $property.Name
  $rule = $property.Value
  $isMatch = $TimeScope -eq $scopeName
  foreach ($keyword in @($rule.keywords)) {
    if (![string]::IsNullOrWhiteSpace([string]$keyword) -and $text.Contains([string]$keyword)) { $isMatch = $true }
  }
  if ($isMatch) {
    $matchedScopes.Add($scopeName)
    Add-Files $required $rule.required
    Add-Files $optional $rule.optional
  }
}

foreach ($property in $registry.cross_cutting.PSObject.Properties) {
  $rule = $property.Value
  $matchedKeywords = @($rule.keywords | Where-Object { ![string]::IsNullOrWhiteSpace([string]$_) -and $text.Contains([string]$_) })
  if ($matchedKeywords.Count -gt 0) {
    Add-Files $optional $rule.optional
  }
}

if ($matchedTopics.Count -eq 0) {
  $warnings.Add('未识别明确专项主题：只返回通用基础规则，开始分析前必须向用户确认方向。')
}
if ($matchedScopes.Count -eq 0 -and [string]::IsNullOrWhiteSpace($TimeScope)) {
  $warnings.Add('未识别分析时间范围：需要流年、大限或指定年份时必须先向用户确认。')
}

$allFiles = @($required + $optional | Sort-Object -Unique)
$missing = @($allFiles | Where-Object { !(Test-Path -LiteralPath (Join-Path $skillRoot $_)) })
if ($missing.Count -gt 0) {
  $warnings.Add('路由到的文件不存在：' + ($missing -join ', '))
}

$result = [ordered]@{
  schema_version = 'doushu-v2-knowledge-route-result-1'
  status = if ($missing.Count -eq 0) { 'passed' } else { 'failed' }
  method_profile = $MethodProfile
  report_mode = if ($matchedTopics -contains '完整') { 'complete' } else { 'standard' }
  matched_topics = @($matchedTopics | Sort-Object -Unique)
  matched_time_scopes = @($matchedScopes | Sort-Object -Unique)
  required_files = @($required | Sort-Object -Unique)
  optional_files = @($optional | Sort-Object -Unique | Where-Object { !$required.Contains($_) })
  all_files = $allFiles
  warnings = @($warnings)
}

$json = $result | ConvertTo-Json -Depth 8
if (![string]::IsNullOrWhiteSpace($OutputPath)) {
  $json | Set-Content -LiteralPath $OutputPath -Encoding UTF8
}
$json
