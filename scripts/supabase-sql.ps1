<#
  Führt SQL gegen das Supabase-Projekt aus (Management API, Zugangsdaten aus .env).

  Beispiele:
    .\scripts\supabase-sql.ps1 -File supabase\highscores.sql
    .\scripts\supabase-sql.ps1 -Query "select * from public.highscores order by score desc limit 10"
#>
param(
  [string]$File,
  [string]$Query
)

$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot -Parent
$envFile = Join-Path $root '.env'
if (-not (Test-Path $envFile)) { throw ".env nicht gefunden: $envFile" }

$cfg = @{}
foreach ($line in Get-Content $envFile -Encoding UTF8) {
  if ($line -match '^\s*([A-Z0-9_]+)\s*=\s*(.*?)\s*$') { $cfg[$matches[1]] = $matches[2].Trim('"', "'") }
}

$ref = $cfg['SUPABASE_PROJECT_REF']
if (-not $ref -and $cfg['SUPABASE_URL'] -match 'https://([^.]+)\.supabase\.co') { $ref = $matches[1] }
$token = $cfg['SUPABASE_ACCESS_TOKEN']
if (-not $ref) { throw 'SUPABASE_PROJECT_REF bzw. SUPABASE_URL fehlt in .env' }
if (-not $token) { throw 'SUPABASE_ACCESS_TOKEN fehlt in .env (https://supabase.com/dashboard/account/tokens)' }

if ($File) { $sql = [IO.File]::ReadAllText((Resolve-Path $File), [Text.Encoding]::UTF8) }
elseif ($Query) { $sql = $Query }
else { throw 'Bitte -File <pfad.sql> oder -Query "<sql>" angeben.' }

$body = [System.Text.Encoding]::UTF8.GetBytes((@{ query = $sql } | ConvertTo-Json -Compress))
$result = Invoke-RestMethod -Method Post `
  -Uri "https://api.supabase.com/v1/projects/$ref/database/query" `
  -Headers @{ Authorization = "Bearer $token" } `
  -ContentType 'application/json; charset=utf-8' `
  -Body $body

if ($result) { $result | Format-Table -AutoSize } else { 'OK' }
