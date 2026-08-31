$ErrorActionPreference = 'Stop'

$skillRoot = Split-Path -Parent $PSScriptRoot
$moduleRoot = Join-Path $skillRoot 'modules'
$registryPath = Join-Path $moduleRoot 'module-registry.json'
$registry = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$failures = [System.Collections.Generic.List[string]]::new()

foreach ($moduleId in $registry.sequence) {
  $entry = $registry.modules.$moduleId
  if ($null -eq $entry) {
    $failures.Add("registry entry missing: $moduleId")
    continue
  }
  $modulePath = Join-Path $moduleRoot $entry.file
  if (!(Test-Path -LiteralPath $modulePath)) {
    $failures.Add("module file missing: $($entry.file)")
    continue
  }
  $content = Get-Content -LiteralPath $modulePath -Raw -Encoding UTF8
  foreach ($section in @('## 输入','## 动作','## 输出','## 门禁')) {
    if ($content.IndexOf($section, [System.StringComparison]::Ordinal) -lt 0) {
      $failures.Add("$($entry.file) missing section: $section")
    }
  }
}

$skill = Get-Content -LiteralPath (Join-Path $skillRoot 'SKILL.md') -Raw -Encoding UTF8
if ($skill -notmatch 'modules/module-registry\.json') { $failures.Add('SKILL.md missing module registry routing') }
if ($skill -notmatch 'HARD_GATE') { $failures.Add('SKILL.md missing hard gate') }

if ($failures.Count -gt 0) {
  $failures | ForEach-Object { Write-Error $_ }
  exit 1
}

Write-Output "doushu v2 modular contract: PASS ($($registry.sequence.Count) modules)"

