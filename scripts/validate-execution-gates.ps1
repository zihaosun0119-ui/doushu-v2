param(
  [Parameter(Mandatory=$true)][string]$ExecutionManifest,
  [Parameter(Mandatory=$true)][string]$ReportFile,
  [ValidateSet('complete','health','career','relationship','social','finance','other')]
  [string]$Mode = 'other'
)
$ErrorActionPreference = 'Stop'
$failures = [System.Collections.Generic.List[string]]::new()
if (!(Test-Path -LiteralPath $ExecutionManifest)) { $failures.Add('缺少 execution-manifest.json') }
if (!(Test-Path -LiteralPath $ReportFile)) { $failures.Add('缺少报告文件') }
if ($failures.Count -eq 0) {
  try { $m = Get-Content -Raw -LiteralPath $ExecutionManifest | ConvertFrom-Json } catch { $failures.Add('execution-manifest.json 不是有效 JSON') }
  $required = @('input','data','direction','analysis','specialty','independent_review','rendering','voice_review','dedupe','delivery')
  if ($null -eq $m -or $m.schema_version -ne 'doushu-v2-execution-2') { $failures.Add('manifest schema_version 不正确') }
  if ($null -eq $m -or $m.workflow_status -ne 'passed') { $failures.Add('workflow_status 未通过') }
  foreach ($s in $required) { if ($null -eq $m.stages.$s -or $m.stages.$s -ne 'passed') { $failures.Add("阶段未通过: $s") } }
  if ($null -eq $m.actual_resources -or @($m.actual_resources).Count -lt 1) { $failures.Add('未记录实际调用资源') }
  $text = Get-Content -Raw -LiteralPath $ReportFile
  foreach ($bad in @('$doushu-v2','user-rendering-v3','restrained-professional-voice','execution-manifest')) { if ($text.Contains($bad)) { $failures.Add("报告泄漏内部标识: $bad") } }
  foreach ($must in @('资料说明','现在怎么做')) { if (!$text.Contains($must)) { $failures.Add("报告缺少用户结构: $must") } }
  if ($Mode -eq 'health' -and !$text.Contains('医疗')) { $failures.Add('健康报告缺少医疗边界说明') }
}
if ($failures.Count -gt 0) { Write-Error ("doushu v2 execution gate: FAIL`n" + ($failures -join "`n")); exit 1 }
Write-Output 'doushu v2 execution gate: PASS'
