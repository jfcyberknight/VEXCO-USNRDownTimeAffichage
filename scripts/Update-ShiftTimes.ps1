<#
.SYNOPSIS
    Script autonome pour mettre à jour les horaires des quarts (Shift ID 1) sur SQL Server.
.DESCRIPTION
    Ce script se connecte à la base de données, affiche l'état actuel des horaires (Début et Fin),
    propose de corriger la semaine à 06:01 -> 16:00, et attend une confirmation avant d'appliquer.
    Idéal pour exécution sur un serveur externe sans dépendance (Python, Node, etc.).
#>

param (
    [string]$Server = "VM-WIN10-VEXCO",
    [string]$Database = "fpusnr",
    [string]$Username = "sa",
    [string]$Password = "sygif"
)

# Configuration de la connexion
$connectionString = "Server=$Server;Database=$Database;User Id=$Username;Password=$Password;TrustServerCertificate=True;"

$querySelect = @"
SELECT 
    MondayStart, MondayEnd, 
    TuesdayStart, TuesdayEnd, 
    WednesdayStart, WednesdayEnd, 
    ThursdayStart, ThursdayEnd, 
    FridayStart, FridayEnd, 
    SaturdayStart, SaturdayEnd, 
    SundayStart, SundayEnd 
FROM fpusnr_shifttimes 
WHERE ShiftId = 1
"@

$queryUpdate = @"
UPDATE fpusnr_shifttimes
SET 
    MondayStart = CAST(CONVERT(VARCHAR(10), MondayStart, 120) + ' 06:01:00' AS DATETIME2),
    MondayEnd   = CAST(CONVERT(VARCHAR(10), MondayEnd, 120)   + ' 16:00:00' AS DATETIME2),
    TuesdayStart = CAST(CONVERT(VARCHAR(10), TuesdayStart, 120) + ' 06:01:00' AS DATETIME2),
    TuesdayEnd   = CAST(CONVERT(VARCHAR(10), TuesdayEnd, 120)   + ' 16:00:00' AS DATETIME2),
    WednesdayStart = CAST(CONVERT(VARCHAR(10), WednesdayStart, 120) + ' 06:01:00' AS DATETIME2),
    WednesdayEnd   = CAST(CONVERT(VARCHAR(10), WednesdayEnd, 120)   + ' 16:00:00' AS DATETIME2),
    ThursdayStart = CAST(CONVERT(VARCHAR(10), ThursdayStart, 120) + ' 06:01:00' AS DATETIME2),
    ThursdayEnd   = CAST(CONVERT(VARCHAR(10), ThursdayEnd, 120)   + ' 16:00:00' AS DATETIME2),
    FridayStart = CAST(CONVERT(VARCHAR(10), FridayStart, 120) + ' 06:01:00' AS DATETIME2),
    FridayEnd   = CAST(CONVERT(VARCHAR(10), FridayEnd, 120)   + ' 16:00:00' AS DATETIME2)
WHERE ShiftId = 1
"@

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

try {
    Write-Host "Tentative de connexion à $Server\$Database..." -ForegroundColor Gray
    $connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
    $connection.Open()

    $command = $connection.CreateCommand()
    $command.CommandText = $querySelect
    $reader = $command.ExecuteReader()

    if ($reader.Read()) {
        Write-Host "`n📸 SNAPSHOT DES VALEURS ACTUELLES (AVANT)" -ForegroundColor Cyan
        Write-Host "$('Jour'.PadRight(12)) | $('Début'.PadRight(10)) | $('Fin'.PadRight(10))"
        Write-Host ("-" * 38)

        $days = @("Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche")
        $currentData = @()

        for ($i = 0; $i -lt 7; $i++) {
            $start = Format-Time $reader.GetValue($i*2)
            $end = Format-Time $reader.GetValue($i*2+1)
            $currentData += @{ Start = $start; End = $end }
            Write-Host "$($days[$i].PadRight(12)) | $($start.PadRight(10)) | $($end.PadRight(10))"
        }
        $reader.Close()

        Write-Host "`n🛠️ PRÉPARATION DE LA CORRECTION (CIBLE)" -ForegroundColor Yellow
        Write-Host "$('Jour'.PadRight(12)) | $('Début'.PadRight(10)) | $('Fin'.PadRight(10))"
        Write-Host ("-" * 38)
        
        for ($i = 0; $i -lt 7; $i++) {
            if ($i -lt 5) {
                Write-Host "$($days[$i].PadRight(12)) | $('06:01:00'.PadRight(10)) | $('16:00:00'.PadRight(10))"
            } else {
                Write-Host "$($days[$i].PadRight(12)) | $($currentData[$i].Start.PadRight(10)) | $($currentData[$i].End.PadRight(10))"
            }
        }

        $title = "Confirmation"
        $message = "Voulez-vous appliquer ces changements sur le serveur $Server ?"
        $yes = New-Object System.Management.Automation.Host.ChoiceDescription "&Oui", "Appliquer les changements."
        $no = New-Object System.Management.Automation.Host.ChoiceDescription "&Non", "Annuler."
        $options = [System.Management.Automation.Host.ChoiceDescription[]]($yes, $no)
        $result = $host.ui.PromptForChoice($title, $message, $options, 1)

        if ($result -eq 0) {
            $command.CommandText = $queryUpdate
            $rowsAffected = $command.ExecuteNonQuery()
            Write-Host "`n✅ Correction appliquée ! ($rowsAffected ligne(s) modifiée(s))`n" -ForegroundColor Green

            # Snapshot Final
            $command.CommandText = $querySelect
            $readerFinal = $command.ExecuteReader()
            if ($readerFinal.Read()) {
                Write-Host "📸 SNAPSHOT DES VALEURS FINALES (APRÈS)" -ForegroundColor Cyan
                Write-Host "$('Jour'.PadRight(12)) | $('Début'.PadRight(10)) | $('Fin'.PadRight(10))"
                Write-Host ("-" * 38)
                for ($i = 0; $i -lt 7; $i++) {
                    $start = Format-Time $readerFinal.GetValue($i*2)
                    $end = Format-Time $readerFinal.GetValue($i*2+1)
                    Write-Host "$($days[$i].PadRight(12)) | $($start.PadRight(10)) | $($end.PadRight(10))"
                }
            }
            $readerFinal.Close()
        } else {
            Write-Host "`n🛑 Opération annulée." -ForegroundColor Red
        }

    } else {
        Write-Host "⚠️ Aucun enregistrement trouvé pour ShiftId = 1." -ForegroundColor Yellow
    }

} catch {
    Write-Host "❌ Erreur : $($_.Exception.Message)" -ForegroundColor Red
} finally {
    if ($connection -and $connection.State -eq 'Open') {
        $connection.Close()
    }
}
