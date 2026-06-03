<#
.SYNOPSIS
    Point d'entrée livraison — correction quarts 06:01.
.DESCRIPTION
    -Mode Interactive (défaut) : Update-ShiftTimes.ps1 (SELECT + UPDATE avec confirmation).
    -Mode Migrations : exécute les fichiers migrations dans sql\ (ordre documenté), sans ajuster les fins à 16:00.
.PARAMETER Mode
    Interactive | Migrations
#>

param (
    [ValidateSet("Interactive", "Migrations")]
    [string]$Mode = "Interactive",

    [string]$Server,
    [string]$Database = "fpusnr",
    [string]$Username,
    [string]$Password,

    [switch]$WhatIf
)

$ScriptDir = $PSScriptRoot

function Invoke-SqlBatches {
    param (
        [System.Data.SqlClient.SqlConnection]$Connection,
        [string]$SqlText
    )
    $batches = [regex]::Split($SqlText, '(?m)^\s*GO\s*$')
    foreach ($batch in $batches) {
        $trimmed = $batch.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed)) { continue }
        $cmd = $Connection.CreateCommand()
        $cmd.CommandText = $trimmed
        [void]$cmd.ExecuteNonQuery()
    }
}

if ($Mode -eq "Interactive") {
    $params = @{
        Database = $Database
    }
    if ($Server) { $params.Server = $Server }
    if ($Username) { $params.Username = $Username }
    if ($Password) { $params.Password = $Password }
    & (Join-Path $ScriptDir "Update-ShiftTimes.ps1") @params
    exit $LASTEXITCODE
}

# Mode Migrations : ordre des fichiers du dépôt migrations/
$migrationFiles = @(
    "20260508_fix_monday_shift_start.sql",
    "20260508_fix_all_days_shift_start.sql"
)

if ([string]::IsNullOrWhiteSpace($Server)) {
    $Server = Read-Host "Serveur SQL"
}
if ([string]::IsNullOrWhiteSpace($Username)) {
    $Username = Read-Host "Utilisateur SQL"
}
if ([string]::IsNullOrWhiteSpace($Password)) {
    $secure = Read-Host "Mot de passe SQL" -AsSecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        $Password = [Runtime.InteropServices.Marshal]::PtrToStringAuto($ptr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}

$sqlDir = Join-Path $ScriptDir "sql"
$connectionString = "Server=$Server;Database=$Database;User Id=$Username;Password=$Password;TrustServerCertificate=True;"

Write-Host "Mode Migrations — fichiers (dans l'ordre) :" -ForegroundColor Cyan
foreach ($f in $migrationFiles) {
    Write-Host "  - sql\$f"
}
Write-Host "Note : ce mode ne met pas les fins de quart à 16:00 (seulement les debuts 06:01)." -ForegroundColor Yellow

if ($WhatIf) {
    Write-Host "WhatIf : aucune execution." -ForegroundColor Gray
    exit 0
}

$confirm = Read-Host "Executer ces migrations sur $Server ? (O/N)"
if ($confirm -notmatch '^[Oo]') {
    Write-Host "Annule."
    exit 0
}

$connection = $null
try {
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()
    foreach ($file in $migrationFiles) {
        $path = Join-Path $sqlDir $file
        if (-not (Test-Path $path)) {
            throw "Fichier manquant : $path"
        }
        Write-Host "`n>> $file" -ForegroundColor Green
        $sql = Get-Content -Path $path -Raw -Encoding UTF8
        Invoke-SqlBatches -Connection $connection -SqlText $sql
    }
    Write-Host "`nMigrations terminees." -ForegroundColor Green
} catch {
    Write-Host "Erreur : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    if ($connection -and $connection.State -eq 'Open') {
        $connection.Close()
    }
}
