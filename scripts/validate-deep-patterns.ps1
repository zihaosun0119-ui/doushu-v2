$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path -Parent $PSScriptRoot
$root = Join-Path $skillRoot 'references\patterns-deep'
$failures = [System.Collections.Generic.List[string]]::new()
$cards = [System.Collections.Generic.List[object]]::new()

if (-not (Test-Path -LiteralPath $root)) { throw "缺少深度结构卡目录：$root" }
foreach ($file in Get-ChildItem -LiteralPath $root -Filter '*.md' -File | Where-Object Name -ne 'index.md') {
  $text = Get-Content -Raw -Encoding UTF8 -LiteralPath $file.FullName
  $matches = [regex]::Matches($text, '(?ms)^###\s+([A-J]\d{2})｜[^\r\n]+\r?\n(.*?)(?=^###\s+[A-J]\d{2}｜|\z)')
  foreach ($m in $matches) {
    $id=$m.Groups[1].Value; $body=$m.Groups[2].Value
    $cn=([regex]::Matches($body,'[\u3400-\u9fff]')).Count
    if ($cn -lt 300) { $failures.Add("$id 中文字符不足300：$cn") }
    foreach($heading in @('反证','限制','破格')) {
      if ($body -match "(?m)^#{1,6}\s*$heading") { $failures.Add("$id 含禁止章节标题：$heading") }
    }
    foreach($required in @('核心机制','成立前提','多领域表现与发散推导','触发与现实核对','依据与使用状态')) {
      if ($body -notmatch [regex]::Escape("#### $required")) { $failures.Add("$id 缺少结构段：$required") }
    }
    if ($body -notmatch 'S\d{2}|M\d{2}') { $failures.Add("$id 缺少来源/方法编号") }
    $cards.Add([PSCustomObject]@{Id=$id;File=$file.Name;Chars=$cn;Text=$body})
  }
}

$ids=$cards | ForEach-Object Id | Sort-Object
$duplicates=$ids | Group-Object | Where-Object Count -gt 1
if($duplicates){$failures.Add("深度卡编号重复：$($duplicates.Name -join ',')")}
$matrix=Get-Content -Raw -Encoding UTF8 (Join-Path $skillRoot 'references\pattern-evidence-matrix.md')
$deferred=[regex]::Matches($matrix,'\|\s*([A-J]\d{2})\s*\|[^\r\n]*\|[^\r\n]*\|[^\r\n]*\|\s*0\s*\|') | ForEach-Object {$_.Groups[1].Value}
foreach($id in $deferred){if($ids -contains $id){$failures.Add("证据暂缓项仍生成深度卡：$id")}}
if($cards.Count -ne 120){$failures.Add("通过证据门禁的深度卡数量应为120，实际为$($cards.Count)")}

if($failures.Count -gt 0){$failures | ForEach-Object {Write-Error $_}; exit 1}
$min=($cards | Measure-Object Chars -Minimum).Minimum
$max=($cards | Measure-Object Chars -Maximum).Maximum
Write-Output "deep patterns: PASS (cards=$($cards.Count), min_chinese_chars=$min, max_chinese_chars=$max, deferred=$($deferred.Count))"
