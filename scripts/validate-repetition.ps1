$ErrorActionPreference = 'Stop'
$root = Join-Path (Split-Path -Parent $PSScriptRoot) 'references\patterns-deep'
$cores = @()
foreach($file in Get-ChildItem -LiteralPath $root -Filter '*.md' -File | Where-Object Name -ne 'index.md') {
  $text=Get-Content -Raw -Encoding UTF8 $file.FullName
  foreach($m in [regex]::Matches($text,'(?ms)^###\s+([A-J]\d{2})｜[^\r\n]+.*?^####\s+核心机制\r?\n\r?\n(.*?)(?=^####\s+成立前提)')) {
    $core=([regex]::Replace($m.Groups[2].Value,'\s','')).Trim()
    $cores += [PSCustomObject]@{Id=$m.Groups[1].Value;Core=$core}
  }
}
$duplicates=$cores | Group-Object Core | Where-Object Count -gt 1
if($duplicates){Write-Error ('核心机制段落重复：' + (($duplicates | ForEach-Object {($_.Group | ForEach-Object Id) -join ','}) -join ';')); exit 1}
if($cores.Count -ne 120){Write-Error "核心机制卡数量不是120：$($cores.Count)"; exit 1}
Write-Output "repetition gate: PASS (unique_core_mechanisms=$($cores.Count), deferred_cards=0)"
