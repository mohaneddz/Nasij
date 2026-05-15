param(
    [string]$InputDir,
    [string]$OutputDir,
    [switch]$AllMarkdown,
    [string[]]$Files
)

$ErrorActionPreference = "Stop"

function Resolve-ExistingPath {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        throw "Path does not exist: $Path"
    }
    return (Resolve-Path -LiteralPath $Path).Path
}

function Normalize-MarkdownName {
    param([Parameter(Mandatory = $true)][string]$Name)
    if ([string]::IsNullOrWhiteSpace($Name)) {
        throw "File name cannot be empty."
    }

    $trimmed = $Name.Trim()
    if ($trimmed.ToLowerInvariant().EndsWith('.md')) {
        return $trimmed
    }

    return "$trimmed.md"
}

function Convert-MarkdownToHtmlFile {
    param(
        [Parameter(Mandatory = $true)][string]$MarkdownPath,
        [Parameter(Mandatory = $true)][string]$HtmlPath
    )

    $pythonCode = @'
import sys
from pathlib import Path

src = Path(sys.argv[1])
dst = Path(sys.argv[2])

try:
    import markdown
except Exception as exc:
    print(f"Python package 'markdown' is required: {exc}", file=sys.stderr)
    raise SystemExit(2)

text = src.read_text(encoding="utf-8")
body = markdown.markdown(text, extensions=["tables", "fenced_code", "sane_lists"])

html_doc = """<!doctype html>
<html>
<head>
<meta charset="utf-8" />
<style>
body { font-family: Calibri, Arial, sans-serif; font-size: 11pt; line-height: 1.35; margin: 24px; }
h1 { font-size: 24pt; margin: 0 0 10px 0; }
h2 { font-size: 18pt; margin: 18px 0 8px 0; }
h3 { font-size: 14pt; margin: 14px 0 6px 0; }
p, li { margin: 0 0 6px 0; }
ul, ol { margin: 0 0 8px 22px; }
table { border-collapse: collapse; margin: 8px 0 12px 0; width: 100%; }
th, td { border: 1px solid #9a9a9a; padding: 4px 6px; vertical-align: top; }
code { font-family: Consolas, "Courier New", monospace; font-size: 10pt; }
pre { background: #f6f6f6; border: 1px solid #d2d2d2; padding: 8px; overflow-x: auto; }
</style>
</head>
<body>
""" + body + """
</body>
</html>
"""

dst.write_text(html_doc, encoding="utf-8")
'@

    $output = $pythonCode | python - $MarkdownPath $HtmlPath 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to convert markdown to HTML for '$MarkdownPath'. Ensure Python and markdown are installed. Details: $output"
    }
}

if ([string]::IsNullOrWhiteSpace($InputDir)) {
    $InputDir = Join-Path $PSScriptRoot ".."
}
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path (Join-Path $PSScriptRoot "..") "pdf"
}

$inputPath = Resolve-ExistingPath -Path $InputDir
if (-not (Test-Path -LiteralPath $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}
$outputPath = (Resolve-Path -LiteralPath $OutputDir).Path

$coreDocs = @(
    'business-plan.md',
    'bmc.md',
    'porter.md',
    'pestel.md',
    'empathy-card.md'
)

$targets = @()
if ($AllMarkdown.IsPresent) {
    $targets = Get-ChildItem -LiteralPath $inputPath -File -Filter '*.md' |
        Sort-Object -Property Name |
        Select-Object -ExpandProperty FullName
}
elseif ($Files -and $Files.Count -gt 0) {
    $requestedNames = @()
    foreach ($token in $Files) {
        $requestedNames += ($token -split ',')
    }
    $requestedNames = $requestedNames | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }

    foreach ($fileName in $requestedNames) {
        $normalized = Normalize-MarkdownName -Name $fileName
        $candidate = Join-Path $inputPath $normalized
        if (-not (Test-Path -LiteralPath $candidate)) {
            throw "Requested markdown file not found: $normalized"
        }
        $targets += (Resolve-Path -LiteralPath $candidate).Path
    }
}
else {
    foreach ($coreDoc in $coreDocs) {
        $candidate = Join-Path $inputPath $coreDoc
        if (-not (Test-Path -LiteralPath $candidate)) {
            throw "Core markdown file not found: $coreDoc"
        }
        $targets += (Resolve-Path -LiteralPath $candidate).Path
    }
}

if (-not $targets -or $targets.Count -eq 0) {
    throw "No markdown files selected for conversion."
}

$word = $null
$tempDir = Join-Path $env:TEMP ("nasij-mdpdf-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
try {
    $word = New-Object -ComObject Word.Application
}
catch {
    throw "Microsoft Word COM automation is unavailable. Install Microsoft Word desktop and re-run this script. Original error: $($_.Exception.Message)"
}

$word.Visible = $false
$word.DisplayAlerts = 0

$generated = @()
try {
    foreach ($mdFile in $targets) {
        $doc = $null
        try {
            $baseName = [System.IO.Path]::GetFileNameWithoutExtension($mdFile)
            $pdfName = "{0}.pdf" -f $baseName
            $pdfPath = Join-Path $outputPath $pdfName
            $htmlPath = Join-Path $tempDir ("{0}.html" -f $baseName)

            Convert-MarkdownToHtmlFile -MarkdownPath $mdFile -HtmlPath $htmlPath
            $doc = $word.Documents.Open($htmlPath, $false, $true)
            # wdFormatPDF = 17
            $doc.SaveAs2([string]$pdfPath, 17)
            $generated += $pdfPath
            Write-Host "Generated: $pdfPath"
        }
        finally {
            if ($doc -ne $null) {
                $doc.Close($false) | Out-Null
                [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($doc)
            }
        }
    }
}
finally {
    if ($word -ne $null) {
        $word.Quit() | Out-Null
        [void][System.Runtime.InteropServices.Marshal]::FinalReleaseComObject($word)
    }
    if (Test-Path -LiteralPath $tempDir) {
        Remove-Item -LiteralPath $tempDir -Recurse -Force
    }
    [gc]::Collect()
    [gc]::WaitForPendingFinalizers()
}

Write-Host "Completed. PDFs generated: $($generated.Count)"
