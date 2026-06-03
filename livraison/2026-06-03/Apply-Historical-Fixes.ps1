<#
.SYNOPSIS
    Application des corrections historiques d'arrêts — livraison autonome.
.DESCRIPTION
    Exécute la migration SQL sql\20260520_fix_historical_shifts.sql sur la base de données de production.
.PARAMETER Server
    Instance SQL Server.
.PARAMETER Database
    Nom de la base.
.PARAMETER Username
    Utilisateur SQL.
.PARAMETER Password
    Mot de passe SQL.
#>

param (
    [Parameter(Mandatory = $false)]
    [string]$Server,

    [string]$Database = "fpusnr",

    [Parameter(Mandatory = $false)]
    [string]$Username,

    [Parameter(Mandatory = $false)]
    [string]$Password
)

$ErrorActionPreference = "Stop"
$ScriptDir = $PSScriptRoot
$SqlFile = Join-Path $ScriptDir "sql\20260520_fix_historical_shifts.sql"

if (-not (Test-Path $SqlFile)) {
    throw "Fichier SQL introuvable : $SqlFile"
}

$sqlContent = Get-Content -Path $SqlFile -Raw -Encoding UTF8
# Découpage par bloc d'exécution GO (insensible à la casse)
$statements = [regex]::Split($sqlContent, "(?i)\bGO\b")

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

$connectionString = "Server=$Server;Database=$Database;User Id=$Username;Password=$Password;TrustServerCertificate=True;"
$connection = $null

try {
    Write-Host "Connexion à $Server\$Database..." -ForegroundColor Gray
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()

    $transaction = $connection.BeginTransaction()
    try {
        $command = $connection.CreateCommand()
        $command.Transaction = $transaction
        
        foreach ($stmt in $statements) {
            $stmtClean = $stmt.Trim()
            if ([string]::IsNullOrWhiteSpace($stmtClean)) { continue }
            
            Write-Host "Exécution du bloc SQL..." -ForegroundColor Gray
            $command.CommandText = $stmtClean
            $rows = $command.ExecuteNonQuery()
            if ($rows -gt 0) {
                Write-Host "✅ $rows lignes modifiées." -ForegroundColor Green
            } else {
                Write-Host "✅ Exécuté." -ForegroundColor Green
            }
        }
        
        $transaction.Commit()
        Write-Host "`n🎉 Migration historique appliquée avec succès !" -ForegroundColor Green
    } catch {
        if ($transaction) { $transaction.Rollback() }
        throw $_
    }
} catch {
    Write-Host "`n❌ Erreur lors de l'application de la migration : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    if ($connection -and $connection.State -eq 'Open') {
        $connection.Close()
    }
}
