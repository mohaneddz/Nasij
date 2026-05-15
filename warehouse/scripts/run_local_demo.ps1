$ErrorActionPreference = "Stop"

Set-Location (Join-Path $PSScriptRoot "..")

Write-Host "[1/3] Starting local app_db + warehouse containers..."
docker compose up -d

Write-Host "[2/3] Waiting for Postgres services..."
Start-Sleep -Seconds 4

Write-Host "[3/3] Running ETL sync..."
python .\scripts\sync_app_to_wh.py

Write-Host "Done. Local warehouse demo is ready."

