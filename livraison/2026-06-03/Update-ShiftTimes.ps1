<#
.SYNOPSIS
    Correction des horaires de quarts (ShiftId 1) — livraison autonome.
.DESCRIPTION
    Lit les requêtes SQL depuis le sous-dossier sql\ (chemins relatifs au script).
    Affiche l'état actuel, propose la correction lundi 06:01 / mardi-vendredi 07:01, demande confirmation.
.PARAMETER Server
    Instance SQL Server.
.PARAMETER Database
    Nom de la base (défaut : fpusnr).
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
$SqlDir = Join-Path $ScriptDir "sql"

function Read-SqlFile {
    param ([string]$FileName)
    $path = Join-Path $SqlDir $FileName
    if (-not (Test-Path $path)) {
        throw "Fichier SQL introuvable : $path"
    }
    return (Get-Content -Path $path -Raw -Encoding UTF8)
}

function Format-Time ($dt) {
    if ([string]::IsNullOrWhiteSpace($dt) -or $dt -eq [DBNull]::Value) {
        return "NULL"
    }
    try {
        $dateObj = [datetime]$dt
        return $dateObj.ToString("HH:mm:ss")
    } catch {
        return $dt.ToString()
    }
}

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

$querySelect = Read-SqlFile "select_shifttimes_shift1.sql"
$queryUpdate = Read-SqlFile "20260508_fix_all_days_shift_start.sql"

$connectionString = "Server=$Server;Database=$Database;User Id=$Username;Password=$Password;TrustServerCertificate=True;"
$connection = $null

try {
    Write-Host "Connexion à $Server\$Database..." -ForegroundColor Gray
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()

    $command = $connection.CreateCommand()
    $command.CommandText = $querySelect
    $reader = $command.ExecuteReader()

    if ($reader.Read()) {
        Write-Host "`nSNAPSHOT DES VALEURS ACTUELLES (AVANT)" -ForegroundColor Cyan
        Write-Host "$('Jour'.PadRight(12)) | $('Debut'.PadRight(10)) | $('Fin'.PadRight(10))"
        Write-Host ("-" * 38)

        $days = @("Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche")
        $currentData = @()

        for ($i = 0; $i -lt 7; $i++) {
            $start = Format-Time $reader.GetValue($i * 2)
            $end = Format-Time $reader.GetValue($i * 2 + 1)
            $currentData += @{ Start = $start; End = $end }
            Write-Host "$($days[$i].PadRight(12)) | $($start.PadRight(10)) | $($end.PadRight(10))"
        }
        $reader.Close()

        Write-Host "`nPREPARATION DE LA CORRECTION (CIBLE)" -ForegroundColor Yellow
        Write-Host "$('Jour'.PadRight(12)) | $('Debut'.PadRight(10)) | $('Fin'.PadRight(10))"
        Write-Host ("-" * 38)

        for ($i = 0; $i -lt 7; $i++) {
            if ($i -eq 0) {
                Write-Host "$($days[$i].PadRight(12)) | $('06:01:00'.PadRight(10)) | $('16:00:00'.PadRight(10))"
            } elseif ($i -lt 5) {
                Write-Host "$($days[$i].PadRight(12)) | $('07:01:00'.PadRight(10)) | $('16:00:00'.PadRight(10))"
            } else {
                Write-Host "$($days[$i].PadRight(12)) | $($currentData[$i].Start.PadRight(10)) | $($currentData[$i].End.PadRight(10))"
            }
        }

        $title = "Confirmation"
        $message = "Appliquer ces changements sur $Server ? (sql\20260508_fix_all_days_shift_start.sql)"
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Oui", "Appliquer."
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&Non", "Annuler."
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $result = $host.ui.PromptForChoice($title, $message, $options, 1)

        if ($result -eq 0) {
            $transaction = $connection.BeginTransaction()
            $command.Transaction = $transaction
            try {
                $command.CommandText = $queryUpdate
                $rowsAffected = $command.ExecuteNonQuery()
                $transaction.Commit()
                Write-Host "`nCorrection appliquee ($rowsAffected ligne(s)).`n" -ForegroundColor Green
            } catch {
                $transaction.Rollback()
                throw $_
            }

            $command.Transaction = $null
            $command.CommandText = $querySelect
            $readerFinal = $command.ExecuteReader()
            if ($readerFinal.Read()) {
                Write-Host "SNAPSHOT DES VALEURS FINALES (APRES)" -ForegroundColor Cyan
                Write-Host "$('Jour'.PadRight(12)) | $('Debut'.PadRight(10)) | $('Fin'.PadRight(10))"
                Write-Host ("-" * 38)
                for ($i = 0; $i -lt 7; $i++) {
                    $start = Format-Time $readerFinal.GetValue($i * 2)
                    $end = Format-Time $readerFinal.GetValue($i * 2 + 1)
                    Write-Host "$($days[$i].PadRight(12)) | $($start.PadRight(10)) | $($end.PadRight(10))"
                }
            }
            $readerFinal.Close()
        } else {
            Write-Host "`nOperation annulee." -ForegroundColor Red
        }
    } else {
        Write-Host "Aucun enregistrement pour ShiftId = 1." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Erreur : $($_.Exception.Message)" -ForegroundColor Red
    exit 1
} finally {
    if ($connection -and $connection.State -eq 'Open') {
        $connection.Close()
    }
}
