$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path -Parent $PSScriptRoot
$refs = Join-Path $skillRoot 'references'
$digestRoot = Join-Path $refs 'source-digests'
$failures = [System.Collections.Generic.List[string]]::new()

$required = @(
  'digest-schema.md',
  'classics.md',
  'modern-books.md',
  'research-and-institutions.md',
  'social-media-and-cases.md',
  'local-analysis-methods.md',
  'supplemental-pattern-sources.md'
)

$texts = [System.Collections.Generic.List[string]]::new()
foreach ($name in $required) {
  $path = Join-Path $digestRoot $name
  if (-not (Test-Path -LiteralPath $path)) {
    $failures.Add("缺少来源摘要：$name")
    continue
  }
  $text = Get-Content -Raw -Encoding UTF8 -LiteralPath $path
  if ($text.Length -lt 200) { $failures.Add("来源摘要过短：$name") }
  if ($text -match '(?i)\b(?:TODO|TBD)\b') { $failures.Add("存在占位符：$name") }
  $texts.Add($text)
}

$all = $texts -join "`n"
foreach ($prefix in @('S','M')) {
  $max = if ($prefix -eq 'S') { 30 } else { 20 }
  for ($i = 1; $i -le $max; $i++) {
    $id = '{0}{1:d2}' -f $prefix, $i
    if ($all -notmatch "(?<![A-Z0-9])$id(?![A-Z0-9])") { $failures.Add("来源/方法没有独立摘要：$id") }
  }
}

$urls = [regex]::Matches($all, 'https?://[^\s)>|]+') | ForEach-Object { $_.Value.TrimEnd('.',',',';','，','。') } | Sort-Object -Unique
if ($urls.Count -lt 25) { $failures.Add("可追溯网页不足25个：$($urls.Count)") }

$matrixPath = Join-Path $refs 'pattern-evidence-matrix.md'
if (-not (Test-Path -LiteralPath $matrixPath)) {
  $failures.Add('缺少格局证据矩阵')
} else {
  $matrix = Get-Content -Raw -Encoding UTF8 -LiteralPath $matrixPath
  $ids = [regex]::Matches($matrix, '\|\s*([A-J]\d{2})\s*\|') | ForEach-Object { $_.Groups[1].Value } | Sort-Object -Unique
  if ($ids.Count -ne 120) { $failures.Add("格局证据矩阵编号不是120条：$($ids.Count)") }
}

if ($failures.Count -gt 0) {
  $failures | ForEach-Object { Write-Error $_ }
  exit 1
}

Write-Output "source evidence: PASS (digests=$($required.Count), core_registered=50, supplemental=2, urls=$($urls.Count), patterns=120)"
