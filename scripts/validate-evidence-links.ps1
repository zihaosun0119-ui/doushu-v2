$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$ref = Join-Path $root 'references'
$failures = [System.Collections.Generic.List[string]]::new()
$registry = Get-Content -Raw -Encoding UTF8 (Join-Path $ref 'source-registry-v1.md')
$digestFiles = Get-ChildItem -LiteralPath (Join-Path $ref 'source-digests') -Filter '*.md' -File
$digests = ($digestFiles | ForEach-Object { Get-Content -Raw -Encoding UTF8 $_.FullName }) -join "`n"
$matrix = Get-Content -Raw -Encoding UTF8 (Join-Path $ref 'pattern-evidence-matrix.md')
$deep = Get-ChildItem -LiteralPath (Join-Path $ref 'patterns-deep') -Filter '*.md' -File | Where-Object Name -ne 'index.md'
$deepText = ($deep | ForEach-Object { Get-Content -Raw -Encoding UTF8 $_.FullName }) -join "`n"

foreach($id in ([regex]::Matches($matrix,'\|\s*([A-J]\d{2})\s*\|') | ForEach-Object {$_.Groups[1].Value} | Sort-Object -Unique)) {
  if($deepText -notmatch "(?m)^###\s+$id｜") { $failures.Add("矩阵项目没有对应深度卡：$id") }
}
foreach($id in ([regex]::Matches($matrix,'\|\s*(S\d{2}|M\d{2})\s*\|') | ForEach-Object {$_.Groups[1].Value} | Sort-Object -Unique)) {
  if($digests -notmatch "(?<![A-Z0-9])$id(?![A-Z0-9])") { $failures.Add("矩阵来源没有对应摘要：$id") }
}
foreach($id in @('S36','S37')) { if($registry -notmatch "(?<![A-Z0-9])$id(?![A-Z0-9])" -or $digests -notmatch "(?<![A-Z0-9])$id(?![A-Z0-9])"){ $failures.Add("补充来源未完整登记：$id") } }
foreach($file in $deep) {
  $text=Get-Content -Raw -Encoding UTF8 $file.FullName
  foreach($m in [regex]::Matches($text,'(?m)^###\s+([A-J]\d{2})｜')) {
    $id=$m.Groups[1].Value; $row=([regex]::Matches($matrix,"(?m)^\|\s*$id\s*\|[^\r\n]+"))[0].Value
    $refs=[regex]::Matches($row,'\b(?:S|M)\d{2}\b')|% Value|sort -Unique
    foreach($refId in $refs){if($text -notmatch "(?<![A-Z0-9])$refId(?![A-Z0-9])"){ $failures.Add("$id 深度卡没有重复登记矩阵来源：$refId") }}
  }
}
if($failures.Count){$failures|%{Write-Error $_};exit 1}
Write-Output "evidence links: PASS (matrix_cards=120, deep_files=$($deep.Count), supplements=2)"
