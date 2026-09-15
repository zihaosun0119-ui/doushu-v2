$ErrorActionPreference = 'Stop'
$root = Join-Path ([System.IO.Path]::GetTempPath()) ('doushu-gates-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root | Out-Null
$gate = Join-Path $PSScriptRoot 'validate-execution-gates.ps1'
$pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue).Source
if (!$pwsh) { $pwsh = (Get-Command powershell).Source }
function Write-Case([object]$m, [string]$name) { $p=Join-Path $root "$name.json"; $m | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $p -Encoding UTF8; return $p }
function Record([string]$name) { $p=Join-Path $root $name; Set-Content -LiteralPath $p -Value "record:$name" -Encoding UTF8; return @{path=$name;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash} }
function Invoke-Gate([string]$manifest, [string]$phase, [string]$report=$null, [string]$mode='other') { $args=@('-NoProfile','-File',$gate,'-ExecutionManifest',$manifest,'-Phase',$phase,'-Mode',$mode); if ($report) {$args += @('-ReportFile',$report)}; & $pwsh @args 2>&1 | Out-Null; return $LASTEXITCODE }
function Clone($value) { return ($value | ConvertTo-Json -Depth 20 | ConvertFrom-Json) }
function Assert([bool]$condition, [string]$message) { if (!$condition) { throw "测试失败: $message" } }
try {
  $input=Record 'input.json'; $module=Record 'module.json'; $route=Record 'knowledge.md'; $methodRecord=Record 'analysis-preflight.json'; $review=Record 'review.md'; $language=Record 'language-review.md'; $qa=Record 'qa.md'; $artifact=Record 'report.html'
  $report=Join-Path $root 'report.md'; Set-Content -LiteralPath $report -Value 'input excerpt`naction excerpt`nmedical excerpt' -Encoding UTF8
  $reportSource=@{path='report.md';sha256=(Get-FileHash -LiteralPath $report -Algorithm SHA256).Hash}; $base=@{schema_version='doushu-v2-execution-3';workflow_status='passed';stages=@{data='passed';direction='passed';analysis='passed';specialty='passed';independent_review='passed';rendering='passed';voice_review='passed';dedupe='passed';delivery='passed'};input_intake=@{status='passed';pending_questions=@();required_files=@($input)};modules=@{'01-input-intake'='passed';'02-chart-data'='passed';'03-analysis'='passed';'04-quality-delivery'='passed';required_files=@($module)};method_preflight=@{status='passed';profile='helu';files=@($methodRecord);checks=@{feixing_chart_rules=$true;feixing_level_chain=$true;helu_coordinate=$true;qi_shu_mapping=$true;original_stem_transformations=$true;level_tracking=$true;concrete_conclusions=$true;boundary_check=$true}};knowledge_route=@{status='passed';required_files=@($route);actual_files_read=@($route);warnings=@()};independent_review=@{status='passed';files=@($review);language_proofreading=@{status='passed';files=@($language)}};coverage=@(@{id='input-context';excerpt='input excerpt'},@{id='action-plan';excerpt='action excerpt'});report_source=$reportSource;qa_record=@{status='passed';files=@($qa)};artifacts=@($artifact);blocking_issues=@()}
  $manifest=Write-Case $base 'good'
  $preflight=Clone $base; $preflight.workflow_status='running'; $preflight.modules.'04-quality-delivery'='pending'; $preflight.stages.delivery='pending'; $preflight.qa_record.status='pending'; $preflight.artifacts=@(); $preflight.report_source=$null
  $preflightManifest=Write-Case $preflight 'preflight'; Assert ((Invoke-Gate $preflightManifest 'preflight' $report) -eq 0) '正常 preflight'
  Assert ((Invoke-Gate $manifest 'final' $report) -eq 0) '正常 final'
  $missing=Clone $base; $missing.independent_review=@{status='passed';files=@($review);language_proofreading=@{status='passed';files=@()}}; Assert ((Invoke-Gate (Write-Case $missing 'missing-review') 'final' $report) -ne 0) '缺复核'
  $pending=Clone $base; $pending.workflow_status='pending'; Assert ((Invoke-Gate (Write-Case $pending 'pending') 'preflight' $report) -ne 0) '空状态/pending'
  $nullManifest=Join-Path $root 'null.json'; Set-Content -LiteralPath $nullManifest -Value 'null' -Encoding UTF8; Assert ((Invoke-Gate $nullManifest 'preflight' $report) -ne 0) 'JSON null'
  $noRoute=Clone $base; $noRoute.knowledge_route=@{status='passed';required_files=@();actual_files_read=@();warnings=@()}; Assert ((Invoke-Gate (Write-Case $noRoute 'no-route') 'preflight' $report) -ne 0) '缺路由'
  $noDelivery=Clone $base; $noDelivery.stages.delivery='pending'; Assert ((Invoke-Gate (Write-Case $noDelivery 'no-delivery') 'final' $report) -ne 0) '未完成交付'
  Assert ((Invoke-Gate $preflightManifest 'final' $report) -ne 0) '仅完成 preflight 不能最终交付'
  $noIndependent=Clone $base; $noIndependent.independent_review.files=@(); Assert ((Invoke-Gate (Write-Case $noIndependent 'no-independent') 'preflight' $report) -ne 0) '语言审校不能替代独立复核'
  $noMethod=Clone $base; $noMethod.method_preflight.checks.concrete_conclusions=$false; Assert ((Invoke-Gate (Write-Case $noMethod 'no-method-specificity') 'preflight' $report) -ne 0) '具体性预检不能缺项'
  $feixing=Clone $base; $feixing.method_preflight.profile='feixing'; $feixing.method_preflight.checks=@{feixing_chart_rules=$true;feixing_level_chain=$true;feixing_monthly_split=$true;feixing_school_boundary=$true;concrete_conclusions=$true;boundary_check=$true}; Assert ((Invoke-Gate (Write-Case $feixing 'feixing-profile') 'preflight' $report) -eq 0) '飞星模式预检'
  $complete=Clone $base; $complete | Add-Member -NotePropertyName 'report_mode' -NotePropertyValue 'complete'; $complete.modules | Add-Member -NotePropertyName '03-complete-report' -NotePropertyValue 'passed'; $complete.method_preflight.checks | Add-Member -NotePropertyName 'complete_scope' -NotePropertyValue $true; $complete.method_preflight.checks | Add-Member -NotePropertyName 'feixing_full_chain' -NotePropertyValue $true; $complete.method_preflight.checks | Add-Member -NotePropertyName 'helu_full_chain' -NotePropertyValue $true; $complete.method_preflight.checks | Add-Member -NotePropertyName 'trine_review' -NotePropertyValue $true; $complete.method_preflight.checks | Add-Member -NotePropertyName 'cross_domain' -NotePropertyValue $true; $complete.method_preflight.checks | Add-Member -NotePropertyName 'decision_support' -NotePropertyValue 'not_applicable'; Assert ((Invoke-Gate (Write-Case $complete 'complete-mode') 'preflight' $report 'complete') -eq 0) '完整模式预检'
  $unread=Clone $base; $unread.knowledge_route.actual_files_read=@(); Assert ((Invoke-Gate (Write-Case $unread 'unread-route') 'preflight' $report) -ne 0) '必读知识缺少读取记录'
  $noCoverage=Clone $base; $noCoverage.coverage=@(); Assert ((Invoke-Gate (Write-Case $noCoverage 'no-coverage') 'preflight' $report) -ne 0) '空覆盖记录'
  $wrongExcerpt=Clone $base; $wrongExcerpt.coverage[0].excerpt='absent excerpt'; Assert ((Invoke-Gate (Write-Case $wrongExcerpt 'wrong-excerpt') 'preflight' $report) -ne 0) '摘录不在正文'
  $questions=Clone $base; $questions.input_intake.pending_questions=@('missing time'); Assert ((Invoke-Gate (Write-Case $questions 'questions') 'preflight' $report) -ne 0) '仍有输入缺项'
  $noQa=Clone $base; $noQa.qa_record.files=@(); Assert ((Invoke-Gate (Write-Case $noQa 'no-qa') 'final' $report) -ne 0) '缺 QA 记录'
  $sourceTamper=Clone $base; $sourceTamper.report_source.sha256=('0' * 64); Assert ((Invoke-Gate (Write-Case $sourceTamper 'source-tamper') 'final' $report) -ne 0) '正文哈希失效'
  Add-Content -LiteralPath (Join-Path $root 'report.html') -Value 'tampered'; Assert ((Invoke-Gate $manifest 'final' $report) -ne 0) '篡改产物'
  Write-Output 'execution gate tests: PASS (19 independent cases)'
} finally {
  $tempRoot=[System.IO.Path]::GetFullPath([System.IO.Path]::GetTempPath()); $resolvedRoot=[System.IO.Path]::GetFullPath($root)
  if (!$resolvedRoot.StartsWith($tempRoot, [System.StringComparison]::OrdinalIgnoreCase) -or $resolvedRoot -eq $tempRoot) { throw '拒绝删除不在临时目录内的测试目录' }
  Remove-Item -LiteralPath $resolvedRoot -Recurse -Force
}
