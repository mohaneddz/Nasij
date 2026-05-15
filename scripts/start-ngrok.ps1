param(
    [int]$Port = 8000,
    [string]$EnvFile = ".env"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-EnvValueFromFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [Parameter(Mandatory = $true)]
        [string]$Key
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return ""
    }

    $line = Get-Content -LiteralPath $Path | Where-Object {
        $_ -match "^\s*$Key\s*="
    } | Select-Object -First 1

    if (-not $line) {
        return ""
    }

    return ($line -split "=", 2)[1].Trim()
}

if (-not (Get-Command ngrok -ErrorAction SilentlyContinue)) {
    throw "ngrok is not installed or not in PATH."
}

$resolvedEnvFile = if ([System.IO.Path]::IsPathRooted($EnvFile)) {
    $EnvFile
} else {
    Join-Path (Get-Location) $EnvFile
}

$authtoken = Get-EnvValueFromFile -Path $resolvedEnvFile -Key "NGROK_AUTHTOKEN"
$domain = Get-EnvValueFromFile -Path $resolvedEnvFile -Key "NGROK_DOMAIN"

if ($authtoken) {
    ngrok config add-authtoken $authtoken | Out-Null
}

$args = @("http", "$Port")
if ($domain) {
    $args += @("--domain", $domain)
}

Write-Host "Starting ngrok tunnel on port $Port..."
if ($domain) {
    Write-Host "Requested domain: $domain"
}

& ngrok @args
