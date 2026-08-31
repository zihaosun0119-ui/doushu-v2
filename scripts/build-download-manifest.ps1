$ErrorActionPreference = 'Stop'
$skillRoot = Split-Path -Parent $PSScriptRoot
$refs = Join-Path $skillRoot 'references'
$archive = Join-Path $refs 'source-archive'
$output = Join-Path $refs 'source-digests\download-manifest.md'

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# 公开下载资料清单')
$lines.Add('')
$lines.Add('本表由脚本按本地文件生成，只证明文件已保存及其完整性指纹，不证明其观点已被采用。')
$lines.Add('')
$lines.Add('| 相对路径 | 字节数 | SHA256 |')
$lines.Add('|---|---:|---|')

if (Test-Path -LiteralPath $archive) {
  Get-ChildItem -LiteralPath $archive -Recurse -File | Sort-Object FullName | ForEach-Object {
    $relative = $_.FullName.Substring($archive.Length).TrimStart('\').Replace('\','/')
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $_.FullName).Hash.ToLowerInvariant()
    $lines.Add('| ' + $relative + ' | ' + $_.Length + ' | `' + $hash + '` |')
  }
}

$lines.Add('')
$lines.Add("生成时间：$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')")
Set-Content -LiteralPath $output -Value $lines -Encoding UTF8
Write-Output "download manifest: $output"
