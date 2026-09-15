param(
  [Parameter(Mandatory=$true)][string]$ExecutionManifest,
  [string]$ReportFile,
  [ValidateSet('preflight','final')][string]$Phase = 'final',
  [ValidateSet('complete','health','career','relationship','social','finance','other')][string]$Mode = 'other'
)
$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()
$manifestPath = [System.IO.Path]::GetFullPath($ExecutionManifest)
$base = Split-Path -Parent $manifestPath
function Add-Failure([string]$Message) { [void]$failures.Add($Message) }
function Get-Status($Value) { if ($null -eq $Value) { return $null }; if ($Value -is [string]) { return [string]$Value }; return [string]$Value.status }
function Get-Entries($Value) { if ($null -eq $Value) { return @() }; return @($Value) }
function Resolve-RecordedPath([string]$Path) { if ([string]::IsNullOrWhiteSpace($Path)) { return $null }; if ([System.IO.Path]::IsPathRooted($Path)) { return $Path }; return Join-Path $base $Path }
function Test-RecordedFiles($Entries, [string]$Label) {
  $items = Get-Entries $Entries
  if ($items.Count -eq 0) { Add-Failure "$Label 未记录文件"; return }
  foreach ($item in $items) {
    $path = [string]$item.path; $hash = [string]$item.sha256
    if ([string]::IsNullOrWhiteSpace($path) -or [string]::IsNullOrWhiteSpace($hash)) { Add-Failure "$Label 文件记录不完整"; continue }
    $resolved = Resolve-RecordedPath $path
    if (!(Test-Path -LiteralPath $resolved -PathType Leaf)) { Add-Failure "$Label 文件不存在: $path"; continue }
    if ((Get-Item -LiteralPath $resolved).Length -le 0) { Add-Failure "$Label 文件为空: $path"; continue }
    $actual = (Get-FileHash -LiteralPath $resolved -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $hash.Trim().ToLowerInvariant()) { Add-Failure "$Label 文件哈希不匹配: $path" }
  }
}
if (!(Test-Path -LiteralPath $manifestPath -PathType Leaf)) { Add-Failure '缺少 execution-manifest.json' }
$m = $null
if ($failures.Count -eq 0) { try { $m = Get-Content -Raw -LiteralPath $manifestPath -Encoding UTF8 | ConvertFrom-Json; if ($null -eq $m) { Add-Failure 'execution-manifest.json 不能是 JSON null' } } catch { Add-Failure 'execution-manifest.json 不是有效 JSON' } }
if ($null -ne $m) {
  if ($m.schema_version -ne 'doushu-v2-execution-3') { Add-Failure 'manifest schema_version 不正确' }
  if (@('pending','running','passed') -notcontains [string]$m.workflow_status) { Add-Failure 'workflow_status 无效' }
  if ([string]$m.workflow_status -eq 'pending') { Add-Failure 'workflow_status 仍为 pending，不能伪装通过' }
  foreach ($name in @('input_intake','modules','knowledge_route')) {
    $section = $m.$name
    if ($null -eq $section) { Add-Failure "缺少记录: $name"; continue }
    if ($name -ne 'modules' -and (Get-Status $section) -ne 'passed') { Add-Failure "阶段未通过: $name" }
    Test-RecordedFiles $section.required_files "$name.required_files"
  }
  foreach ($mod in @('01-input-intake','02-chart-data','03-analysis')) { if ($null -eq $m.modules.$mod -or (Get-Status $m.modules.$mod) -ne 'passed') { Add-Failure "模块未通过: $mod" } }
  if ($Mode -eq 'complete' -and ($null -eq $m.modules.'03-complete-report' -or (Get-Status $m.modules.'03-complete-report') -ne 'passed')) { Add-Failure '完整模式模块未通过: 03-complete-report' }
  if ($Mode -eq 'complete' -and [string]$m.report_mode -ne 'complete') { Add-Failure '完整模式缺少 report_mode=complete' }
  if ($Phase -eq 'final' -and ($null -eq $m.modules.'04-quality-delivery' -or (Get-Status $m.modules.'04-quality-delivery') -ne 'passed')) { Add-Failure '模块未通过: 04-quality-delivery' }
  if ($null -ne $m.input_intake) {
    if ($null -eq $m.input_intake.pending_questions -or @($m.input_intake.pending_questions).Count -ne 0) { Add-Failure 'input_intake.pending_questions 不为空' }
  }
  foreach ($name in @('data','direction','analysis','specialty','rendering','voice_review','dedupe','independent_review')) { if ($null -eq $m.stages.$name -or (Get-Status $m.stages.$name) -ne 'passed') { Add-Failure "阶段未通过: $name" } }
  if ($Phase -eq 'final' -and (Get-Status $m.stages.delivery) -ne 'passed') { Add-Failure '阶段未通过: delivery' }
  $method = $m.method_preflight
  if ($null -eq $method) {
    Add-Failure '缺少 method_preflight：未执行方法与具体性预检'
  } else {
    if ((Get-Status $method) -ne 'passed') { Add-Failure '方法 Preflight 未通过' }
    Test-RecordedFiles $method.files 'method_preflight.files'
    $profile = [string]$method.profile
    if (@('helu','feixing') -notcontains $profile) { Add-Failure 'method_preflight.profile 必须是 helu 或 feixing' }
    $requiredChecks = @('feixing_chart_rules','feixing_level_chain','concrete_conclusions','boundary_check')
    if ($profile -eq 'feixing') {
      $requiredChecks += @('feixing_monthly_split','feixing_school_boundary')
    } else {
      $requiredChecks += @('helu_coordinate','qi_shu_mapping','original_stem_transformations','level_tracking')
    }
    if ($Mode -eq 'complete') {
      $requiredChecks += @('complete_scope','feixing_full_chain','helu_full_chain','trine_review','cross_domain')
    }
    foreach ($check in $requiredChecks) {
      if ($null -eq $method.checks -or $method.checks.$check -ne $true) { Add-Failure "method_preflight.checks 未通过: $check" }
    }
    if ($Mode -eq 'complete' -and $null -ne $method.checks) {
      $decision = $method.checks.decision_support
      if ($decision -ne $true -and [string]$decision -ne 'not_applicable') { Add-Failure '完整模式 decision_support 未通过或未标记 not_applicable' }
    }
  }
  if ($null -eq $m.knowledge_route.warnings -or @($m.knowledge_route.warnings).Count -ne 0) { Add-Failure 'knowledge_route.warnings 不为空' }
  if ($null -eq $m.blocking_issues -or @($m.blocking_issues).Count -ne 0) { Add-Failure 'blocking_issues 不为空' }
  $requiredRoute = Get-Entries $m.knowledge_route.required_files
  $actualRoute = Get-Entries $m.knowledge_route.actual_files_read
  foreach ($req in $requiredRoute) {
    $match = $actualRoute | Where-Object { [string]$_.path -eq [string]$req.path -and [string]$_.sha256 -eq [string]$req.sha256 }
    if (!$match) { Add-Failure "知识路由必读文件未实际记录: $($req.path)" }
  }
  $review = $m.independent_review; if ($null -eq $review) { $review = $m.stages.independent_review }
  if ((Get-Status $review) -ne 'passed') { Add-Failure '独立复核未通过' }
  Test-RecordedFiles $review.files 'independent_review.files'
  if ($null -eq $review.language_proofreading) { Add-Failure '缺少独立语言审校记录' } else { if ((Get-Status $review.language_proofreading) -ne 'passed') { Add-Failure '独立语言审校未通过' }; Test-RecordedFiles $review.language_proofreading.files 'independent_review.language_proofreading.files' }
  if ($ReportFile -and (Test-Path -LiteralPath $ReportFile -PathType Leaf)) {
    if ($null -ne $m.report_source) {
      $sourcePath = Resolve-RecordedPath ([string]$m.report_source.path)
      if (!$sourcePath -or [System.IO.Path]::GetFullPath($sourcePath) -ne [System.IO.Path]::GetFullPath($ReportFile)) { Add-Failure 'ReportFile 与 manifest.report_source 不匹配' }
      Test-RecordedFiles @($m.report_source) 'report_source'
    } elseif ($Phase -eq 'final') { Add-Failure 'final 缺少 manifest.report_source' }
    $text = [string](Get-Content -Raw -LiteralPath $ReportFile -Encoding UTF8)
    if ([string]::IsNullOrWhiteSpace($text)) { Add-Failure '报告正文为空' }
    foreach ($bad in @('$doushu-v2','user-rendering-v3','restrained-professional-voice','execution-manifest')) { if ($text.Contains($bad)) { Add-Failure "报告泄漏内部标识: $bad" } }
    $coverageItems = Get-Entries $m.coverage
    $neededCoverage = @('input-context','action-plan'); if ($Mode -eq 'health') { $neededCoverage += 'medical-boundary' }
    foreach ($needed in $neededCoverage) { $found = $coverageItems | Where-Object { [string]$_.id -eq $needed }; if (!$found) { Add-Failure "缺少正文 coverage: $needed" } }
    foreach ($coverage in $coverageItems) { if ([string]::IsNullOrWhiteSpace([string]$coverage.id) -or [string]::IsNullOrWhiteSpace([string]$coverage.excerpt)) { Add-Failure 'coverage 项缺少 id 或非空摘录'; continue }; if (!$text.Contains([string]$coverage.excerpt)) { Add-Failure "正文缺少 coverage 摘录: $($coverage.id)" } }
    if ($Mode -eq 'health' -and !$text.Contains('医疗')) { Add-Failure '健康报告缺少医疗边界说明' }
  } else { Add-Failure '缺少报告文件' }
  if ($Phase -eq 'final') { if ([string]$m.workflow_status -ne 'passed') { Add-Failure 'final 要求 workflow_status=passed' }; if ($null -eq $m.qa_record -or (Get-Status $m.qa_record) -ne 'passed') { Add-Failure '缺少通过的 QA 记录' } else { Test-RecordedFiles $m.qa_record.files 'qa_record.files' }; Test-RecordedFiles $m.artifacts 'artifacts' }
}
if ($failures.Count -gt 0) { Write-Error ("doushu v2 execution gate ($Phase): FAIL`n" + ($failures -join "`n")); exit 1 }
Write-Output "doushu v2 execution gate ($Phase): PASS"
