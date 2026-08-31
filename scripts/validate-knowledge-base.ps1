$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path -Parent $PSScriptRoot
$sources = Get-Content -Raw -Encoding UTF8 (Join-Path $skillRoot 'references\source-registry-v1.md')
$patterns = Get-Content -Raw -Encoding UTF8 (Join-Path $skillRoot 'references\pattern-library-v1.md')
$palaces = Get-Content -Raw -Encoding UTF8 (Join-Path $skillRoot 'references\palace-analysis-v1.md')
$stars = Get-Content -Raw -Encoding UTF8 (Join-Path $skillRoot 'references\star-interaction-v1.md')
$failures = [System.Collections.Generic.List[string]]::new()

$sourceIds = [regex]::Matches($sources, '\|\s*(?:S|M)\d{2}\s*\|') | ForEach-Object { $_.Value -replace '\s','' } | Sort-Object -Unique
$patternIds = [regex]::Matches($patterns, '\|\s*[A-J]\d{2}\s*\|') | ForEach-Object { $_.Value -replace '\s','' } | Sort-Object -Unique
$palaceNames = @('命宫','兄弟宫','夫妻宫','子女宫','财帛宫','疾厄宫','迁移宫','仆役宫','官禄宫','田宅宫','福德宫','父母宫')
$starNames = @('紫微','天机','太阳','武曲','天同','廉贞','天府','太阴','贪狼','巨门','天相','天梁','七杀','破军')

if ($sourceIds.Count -lt 50) { $failures.Add("资料/方法不足 50 条：$($sourceIds.Count)") }
if ($patternIds.Count -lt 100 -or $patternIds.Count -gt 200) { $failures.Add("格局/结构组合必须为 100—200 条：$($patternIds.Count)") }
foreach ($name in $palaceNames) {
  if ($palaces.IndexOf("### $name", [StringComparison]::Ordinal) -lt 0) { $failures.Add("缺少宫位十二维展开：$name") }
}
foreach ($name in $starNames) {
  if ($stars.IndexOf("| $name |", [StringComparison]::Ordinal) -lt 0) { $failures.Add("缺少主星联动入口：$name") }
}
if ($palaces.IndexOf('1本义：', [StringComparison]::Ordinal) -lt 0 -or $palaces.IndexOf('12流年：', [StringComparison]::Ordinal) -lt 0) {
  $failures.Add('十二宫矩阵缺少 1—12 维度标记')
}
if ($failures.Count -gt 0) { $failures | ForEach-Object { Write-Error $_ }; exit 1 }
Write-Output "doushu v2 knowledge base: PASS (sources=$($sourceIds.Count), patterns=$($patternIds.Count), palaces=12, main_stars=14)"
