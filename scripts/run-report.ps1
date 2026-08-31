param(
  [Parameter(Mandatory = $true)]
  [string]$ChartJson,
  [Parameter(Mandatory = $true)]
  [string]$ReportMarkdown,
  [Parameter(Mandatory = $true)]
  [string]$OutputPdf,
  [Parameter(Mandatory = $true)]
  [string]$ChartKey,
  [Parameter(Mandatory = $true)]
  [string]$AnalysisManifest,
  [string]$AlternateChartJson,
  [int]$StartYear = 2023,
  [int]$EndYear = 2032,
  [switch]$KeepIntermediates,
  [switch]$CleanupIntermediates,
  [switch]$SkipArtifactMarker
)

$ErrorActionPreference = 'Stop'

function Require-File([string]$Path, [string]$Label) {
  if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
    throw "$Label missing: $Path"
  }
  return (Resolve-Path -LiteralPath $Path).Path
}

function Find-CommandPath([string[]]$Candidates, [string]$Label) {
  foreach ($candidate in $Candidates) {
    if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
      return $candidate
    }
  }
  throw "$Label not found. Checked: $($Candidates -join ', ')"
}

function Assert-PreparedChart([string]$Path, [string]$Label) {
  $chart = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json
  $gongs = @($chart.ziwei.gongs)
  if ($gongs.Count -ne 12) {
    throw "$Label must contain 12 ziwei gongs; found $($gongs.Count)"
  }
  if (-not $chart.ziwei.brightnessMetadata) {
    throw "$Label missing brightnessMetadata. Run enrich-brightness.js before authoring the report."
  }
  $starsWithBrightness = @($gongs | ForEach-Object { @($_.mainStarDetails) + @($_.auxStarDetails) } | Where-Object { $_.brightness })
  if ($starsWithBrightness.Count -lt 1) {
    throw "$Label has no usable star brightness values."
  }
  return $chart
}

function ConvertFrom-CodePoints([int[]]$CodePoints) {
  return -join ($CodePoints | ForEach-Object { [char]$_ })
}

$skillRoot = Split-Path -Parent $PSScriptRoot
$chartPath = Require-File $ChartJson 'chart'
$markdownPath = Require-File $ReportMarkdown 'report markdown'
$analysisManifestPath = Require-File $AnalysisManifest 'analysis manifest'
$caseKey = $ChartKey
$caseKey = ($caseKey -replace '[^0-9A-Za-z._-]', '_')
$markdownDirectory = Split-Path -Parent $markdownPath
$candidateCaseDirectory = Split-Path -Parent $markdownDirectory
$candidateReportsDirectory = Split-Path -Parent $candidateCaseDirectory
if ((Split-Path -Leaf $markdownDirectory) -eq 'input' -and
    (Split-Path -Leaf $candidateReportsDirectory) -eq 'reports') {
  $workspaceRoot = Split-Path -Parent $candidateReportsDirectory
  $caseDirectory = $candidateCaseDirectory
} else {
  $workspaceRoot = $markdownDirectory
  $caseDirectory = Join-Path $workspaceRoot ("reports\$caseKey")
}
$inputDirectory = Join-Path $caseDirectory 'input'
$outputDirectory = Join-Path $caseDirectory 'output'
New-Item -ItemType Directory -Path $inputDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
Copy-Item -LiteralPath $chartPath -Destination (Join-Path $inputDirectory 'chart.json') -Force
Copy-Item -LiteralPath $markdownPath -Destination (Join-Path $inputDirectory 'report-source.md') -Force
$manifestArchivePath = Join-Path $inputDirectory 'analysis-manifest.json'
if ([System.IO.Path]::GetFullPath($analysisManifestPath) -ne [System.IO.Path]::GetFullPath($manifestArchivePath)) {
  Copy-Item -LiteralPath $analysisManifestPath -Destination $manifestArchivePath -Force
}
$outputPath = Join-Path $outputDirectory ([System.IO.Path]::GetFileName($OutputPdf))
$outputDir = Split-Path -Parent $outputPath
New-Item -ItemType Directory -Path $outputDir -Force | Out-Null

$node = Find-CommandPath @(
  (Get-Command node -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
) 'Node.js'
$userProfile = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $workspaceRoot))
$python = Find-CommandPath @(
  (Join-Path $userProfile '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'),
  (Join-Path $userProfile 'AppData\Local\hermes\venv\Scripts\python.exe'),
  (Get-Command python -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1)
) 'Python'
$pdftotext = Find-CommandPath @(
  (Get-Command pdftotext -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
  'D:\pdftotext.exe'
) 'pdftotext'
$pdftoppm = Find-CommandPath @(
  (Get-Command pdftoppm -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -First 1),
  'D:\Program Files\Tencent\Marvis\Knowledgebase\1.0.1000.303\knowledgebase\index_build\file_parse\pdf\thirdparty\poppler_minimal\pdftoppm.exe'
) 'pdftoppm'
$markerCandidates = @(
  (Get-ChildItem -Path 'C:\Users' -Recurse -File -Filter 'mark_artifact_operation_started.mjs' -ErrorAction SilentlyContinue |
    Where-Object { $_.FullName -match '\\pdf\\[^\\]+\\skills\\pdf\\container_tools\\mark_artifact_operation_started\.mjs$' } |
    Select-Object -First 1 -ExpandProperty FullName)
)
if ($env:CODEX_HOME) {
  $markerCandidates = @(
    (Join-Path $env:CODEX_HOME 'plugins\cache\openai-primary-runtime\pdf\26.819.11345\skills\pdf\container_tools\mark_artifact_operation_started.mjs')
  ) + $markerCandidates
}
$artifactMarker = $markerCandidates | Where-Object { $_ -and (Test-Path -LiteralPath $_ -PathType Leaf) } | Select-Object -First 1

$runId = Get-Date -Format 'yyyyMMdd-HHmmss'
$runRoot = Join-Path (Join-Path $caseDirectory 'runs') $runId
$renderDir = Join-Path $runRoot 'rendered'
$flowPath = Join-Path $runRoot 'flow.json'
$alternateFlowPath = Join-Path $runRoot 'alternate-flow.json'
$htmlPath = Join-Path $runRoot 'report.html'
$stagedPdf = Join-Path $runRoot 'report.pdf'
$textPath = Join-Path $runRoot 'report.txt'
$manifestPath = Join-Path $runRoot 'manifest.json'
$manifestOutput = "$outputPath.manifest.json"
New-Item -ItemType Directory -Path $runRoot -Force | Out-Null

$stages = [System.Collections.Generic.List[object]]::new()
function Invoke-Stage([string]$Name, [scriptblock]$Action) {
  $watch = [Diagnostics.Stopwatch]::StartNew()
  try {
    & $Action
    $watch.Stop()
    $stages.Add([pscustomobject]@{stage = $Name; elapsed_ms = $watch.ElapsedMilliseconds; status = 'ok'})
  } catch {
    $watch.Stop()
    $stages.Add([pscustomobject]@{stage = $Name; elapsed_ms = $watch.ElapsedMilliseconds; status = 'failed'; error = $_.Exception.Message})
    throw
  }
}

try {
  $script:preparedChart = $null
  $script:analysisManifestData = $null
  Invoke-Stage 'chart-source-qa' {
    $script:preparedChart = Assert-PreparedChart $chartPath 'main chart'
  }

  Invoke-Stage 'analysis-manifest-qa' {
    $script:analysisManifestData = Get-Content -LiteralPath $analysisManifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($analysisManifestData.schema_version -ne 1) { throw 'Unsupported analysis manifest schema' }
    if ($analysisManifestData.chart_key -ne $ChartKey) { throw 'Analysis manifest chart_key mismatch' }
    $expectedResources = @{
      analysis_rules = 'read'
      brightness_source = 'read'
      brightness_enrichment = 'executed'
      flow_extension = 'executed'
      case_search = 'executed'
      voice_review = 'executed'
      verification_checklist = 'passed'
    }
    foreach ($entry in $expectedResources.GetEnumerator()) {
      if ($analysisManifestData.resources.($entry.Key) -ne $entry.Value) {
        throw "Analysis manifest resource status invalid: $($entry.Key)"
      }
    }
    if ($analysisManifestData.resources.nihaixia.status -notin @('read', 'not_used') -or
        -not $analysisManifestData.resources.nihaixia.reason) {
      throw 'Analysis manifest must record nihaixia status and reason'
    }
    if (@($analysisManifestData.health.evidence_categories).Count -lt 3) {
      throw 'Analysis manifest health evidence requires at least three categories'
    }
    if (@($analysisManifestData.health.modules).Count -lt 6 -or
        $analysisManifestData.health.medical_boundary -ne 'passed') {
      throw 'Analysis manifest health module is incomplete'
    }
    $manifestFlowPath = Require-File $analysisManifestData.files.flow 'manifest flow'
    $manifestCasesPath = Require-File $analysisManifestData.files.cases 'manifest cases'
    $pathChecks = @(
      @{actual=$chartPath; declared=$analysisManifestData.files.chart; label='chart'},
      @{actual=$markdownPath; declared=$analysisManifestData.files.report; label='report'}
    )
    foreach ($item in $pathChecks) {
      if ((Resolve-Path -LiteralPath $item.actual).Path -ne (Resolve-Path -LiteralPath $item.declared).Path) {
        throw "Analysis manifest file path mismatch: $($item.label)"
      }
    }
    $hashChecks = @(
      @{path=$chartPath; expected=$analysisManifestData.hashes.chart_sha256; label='chart'},
      @{path=$markdownPath; expected=$analysisManifestData.hashes.report_sha256; label='report'},
      @{path=$manifestFlowPath; expected=$analysisManifestData.hashes.flow_sha256; label='flow'},
      @{path=$manifestCasesPath; expected=$analysisManifestData.hashes.cases_sha256; label='cases'}
    )
    foreach ($item in $hashChecks) {
      $actualHash = (Get-FileHash -LiteralPath $item.path -Algorithm SHA256).Hash.ToLowerInvariant()
      if ($actualHash -ne [string]$item.expected) { throw "Analysis manifest hash mismatch: $($item.label)" }
    }
    $declaredFlow = Get-Content -LiteralPath $manifestFlowPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if (@($declaredFlow.years).Count -lt 1 -or $declaredFlow.metadata.status -notin @('generated', 'partial')) {
      throw 'Analysis manifest flow has no usable annual data'
    }
  }

  $flowScript = Join-Path $skillRoot 'scripts\enrich-flow.js'
  Invoke-Stage 'flow' {
    & $node $flowScript "--input=$chartPath" "--startYear=$StartYear" "--endYear=$EndYear" "--output=$flowPath"
    Require-File $flowPath 'main flow' | Out-Null
    $flowHash = (Get-FileHash -LiteralPath $flowPath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($flowHash -ne [string]$analysisManifestData.hashes.flow_sha256) {
      throw 'Regenerated flow does not match the analysis manifest'
    }
  }

  if ($AlternateChartJson) {
    $alternateChartPath = Require-File $AlternateChartJson 'alternate chart'
    Invoke-Stage 'alternate-chart-source-qa' {
      Assert-PreparedChart $alternateChartPath 'alternate chart' | Out-Null
    }
    Invoke-Stage 'alternate-flow' {
      & $node $flowScript "--input=$alternateChartPath" "--startYear=$StartYear" "--endYear=$EndYear" "--output=$alternateFlowPath"
      Require-File $alternateFlowPath 'alternate flow' | Out-Null
    }
  }

  Invoke-Stage 'case-search' {
    $caseOutput = Join-Path $runRoot 'cases.json'
    & $node (Join-Path $skillRoot 'scripts\case-library.js') search "--chart_key=$ChartKey" | Set-Content -LiteralPath $caseOutput -Encoding UTF8
    Require-File $caseOutput 'case search result' | Out-Null
  }

  Invoke-Stage 'analysis-source-qa' {
    $reportText = Get-Content -LiteralPath $markdownPath -Raw -Encoding UTF8
    $requiredSections = @(
      (ConvertFrom-CodePoints @(0x8D44,0x6599,0x6838,0x9A8C)),
      (ConvertFrom-CodePoints @(0x4F9D,0x636E)),
      (ConvertFrom-CodePoints @(0x6839,0x636E)),
      (ConvertFrom-CodePoints @(0x9A8C,0x8BC1,0x72B6,0x6001)),
      (ConvertFrom-CodePoints @(0x547D,0x5BAB,0x4E0E,0x8EAB,0x5BAB)),
      (ConvertFrom-CodePoints @(0x4E09,0x65B9,0x56DB,0x6B63)),
      (ConvertFrom-CodePoints @(0x65E5,0x6708)),
      (ConvertFrom-CodePoints @(0x683C,0x5C40)),
      (ConvertFrom-CodePoints @(0x4E8B,0x4E1A)),
      (ConvertFrom-CodePoints @(0x8D22,0x52A1)),
      (ConvertFrom-CodePoints @(0x5173,0x7CFB)),
      (ConvertFrom-CodePoints @(0x5065,0x5EB7)),
      (ConvertFrom-CodePoints @(0x8FC1,0x79FB)),
      (ConvertFrom-CodePoints @(0x6D41,0x5E74)),
      (ConvertFrom-CodePoints @(0x524D,0x4E8B,0x9A8C,0x8BC1)),
      (ConvertFrom-CodePoints @(0x884C,0x52A8,0x65B9,0x6848)),
      (ConvertFrom-CodePoints @(0x7F6E,0x4FE1,0x5EA6)),
      (ConvertFrom-CodePoints @(0x4E13,0x4E1A,0x63A8,0x8BBA)),
      (ConvertFrom-CodePoints @(0x73B0,0x5B9E,0x8F6C,0x6362))
    )
    $missingSections = @($requiredSections | Where-Object {
      $reportText.IndexOf($_, [System.StringComparison]::Ordinal) -lt 0
    })
    if ($missingSections.Count -gt 0) {
      throw "Deep analysis draft incomplete; missing sections: $($missingSections -join ', ')"
    }
    $contentLength = ($reportText -replace '\s', '').Length
    if ($contentLength -lt 4000) {
      throw "Deep analysis draft is too short for a complete life report: $contentLength non-whitespace characters"
    }
  }

  Invoke-Stage 'html' {
    $htmlBuilder = Join-Path $workspaceRoot 'tmp\build_2002_report_html.py'
    & $python $htmlBuilder "--source=$markdownPath" "--output=$htmlPath"
    if (-not (Test-Path -LiteralPath $htmlPath -PathType Leaf)) {
      throw "HTML report missing: $htmlPath; python=$python; builder=$htmlBuilder"
    }
  }

  Invoke-Stage 'pdf' {
    if ($artifactMarker -and -not $SkipArtifactMarker) {
      & $node $artifactMarker '--operation-kind' 'create' '--expected-output-count' '1' '--output-format' 'pdf'
    }
    $pdfBuilder = Join-Path $workspaceRoot 'tmp\build_2002_report_pdf.py'
    & $python $pdfBuilder "--source=$markdownPath" "--output=$stagedPdf"
    Require-File $stagedPdf 'staged PDF report' | Out-Null
  }

  Invoke-Stage 'text-qa' {
    & $pdftotext -layout $stagedPdf $textPath
    for ($i = 0; $i -lt 40 -and -not (Test-Path -LiteralPath $textPath -PathType Leaf); $i++) {
      Start-Sleep -Milliseconds 250
    }
    Require-File $textPath 'PDF text extraction' | Out-Null
    $text = Get-Content -LiteralPath $textPath -Raw -Encoding UTF8
    $requiredMarkers = @(
      "$([char]0x4F9D)$([char]0x636E)",
      "$([char]0x6839)$([char]0x636E)",
      "$([char]0x9A8C)$([char]0x8BC1)$([char]0x72B6)$([char]0x6001)",
      "$([char]0x6D41)$([char]0x5E74)",
      "$([char]0x7F6E)$([char]0x4FE1)$([char]0x5EA6)"
    )
    foreach ($required in $requiredMarkers) {
      if ($text.IndexOf($required, [System.StringComparison]::Ordinal) -lt 0) {
        throw "PDF missing required content: $required"
      }
    }
  }

  Invoke-Stage 'render-qa' {
    New-Item -ItemType Directory -Path $renderDir -Force | Out-Null
    & $pdftoppm -png -r 110 $stagedPdf (Join-Path $renderDir 'page')
    $pages = @()
    for ($i = 0; $i -lt 40 -and $pages.Count -lt 1; $i++) {
      $pages = @(Get-ChildItem -LiteralPath $renderDir -File -Filter '*.png')
      if ($pages.Count -lt 1) { Start-Sleep -Milliseconds 250 }
    }
    if ($pages.Count -lt 1) {
      throw 'PDF rendered no pages'
    }
    Copy-Item -LiteralPath $stagedPdf -Destination $outputPath -Force
    Require-File $outputPath 'PDF report' | Out-Null
  }

  $manifest = [ordered]@{
    run_id = $runId
    chart = $chartPath
    alternate_chart = if ($AlternateChartJson) { $alternateChartPath } else { $null }
    flow = $flowPath
    alternate_flow = if ($AlternateChartJson) { $alternateFlowPath } else { $null }
    report_markdown = $markdownPath
    analysis_manifest = $analysisManifestPath
    output_pdf = $outputPath
    render_dir = $renderDir
    brightness_source = $preparedChart.ziwei.brightnessMetadata.source
    resource_usage = $analysisManifestData.resources
    stages = $stages
    status = 'ok'
  }
  $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
  $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestOutput -Encoding UTF8
  Write-Output ($manifest | ConvertTo-Json -Depth 6)
} catch {
  $manifest = [ordered]@{
    run_id = $runId
    stages = $stages
    status = 'failed'
    error = $_.Exception.Message
    run_root = $runRoot
  }
  $manifest | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
  Write-Error ($manifest | ConvertTo-Json -Depth 6)
  exit 1
}

if ($CleanupIntermediates -and -not $KeepIntermediates -and (Test-Path -LiteralPath $runRoot)) {
  $manifestExists = Test-Path -LiteralPath $manifestPath
  $runStatus = 'failed'
  if ($manifestExists) {
    $runStatus = (Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json).status
  }
  if ($runStatus -eq 'ok') {
    Remove-Item -LiteralPath $runRoot -Recurse -Force
  }
}
