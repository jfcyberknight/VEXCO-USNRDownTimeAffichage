# Livraison — Correction des horaires de quarts (06:01)

**Date :** 19 mai 2026

---

## Contexte / problème corrigé

L’application USNR Downtime détermine le quart actif à partir de la table **`fpusnr_shifttimes`**. Les débuts de quart en semaine étaient encore à **07:00** ; un événement vers 06h29 était donc classé en « Nuit » au lieu de « Jour ».

**Objectif :** fixer le début du quart de jour à **06:01** (lundi puis lundi–vendredi), fin de journée à **16:00** lorsque la correction automatisée PowerShell est utilisée. Aucun redémarrage WinDev requis — effet immédiat après mise à jour SQL.

---

## Contenu du dossier `livraison/2026-05-19/` (autonome)

Ce dossier peut être **zippé et déployé seul** sur un serveur (sans cloner tout le dépôt ; inclure au minimum `2026-05-19/` et ses fichiers).

| Fichier | Rôle |
|---------|------|
| `sql/20260508_fix_monday_shift_start.sql` | Migration 1 — lundi : `MondayStart` → **06:01** |
| `sql/20260508_fix_all_days_shift_start.sql` | Migration 2 — lun.–ven. : `*Start` → **06:01** (sans modifier les fins) |
| `sql/select_shifttimes_shift1.sql` | Lecture snapshot `ShiftId = 1` (script PowerShell) |
| `sql/update_shifttimes_weekdays_0601_1600.sql` | Correction complète lun.–ven. **06:01** / **16:00** (équivalent `scripts/Update-ShiftTimes.ps1` du repo) |
| `Update-ShiftTimes.ps1` | Exécution interactive : lit les SQL **locaux** dans `sql\` |
| `Apply-Livraison.ps1` | Point d’entrée : mode **Interactive** (défaut) ou **Migrations** |
| `2026-05-19-correction-quarts.md` | Ce document |

**Note :** le script d’origine `scripts/Update-ShiftTimes.ps1` **n’appelle pas** de fichiers `.sql` externes ; il embarque les requêtes en dur. La livraison les externalise dans `sql\` pour une exécution reproductible et auditable.

**Cible SQL :** table `fpusnr_shifttimes`, en pratique **`ShiftId = 1`** (quart « Jour »). Vérifier l’ID en base avant exécution.

---

## Comment appliquer depuis `livraison/2026-05-19/`

### Prérequis

- **SQL Server** : accès lecture/écriture à la base contenant `fpusnr_shifttimes`.
- **PowerShell** 5.1+ (module .NET `System.Data.SqlClient`).
- **Identifiants** : passer en paramètres ou à l’invite — **aucun secret n’est inclus** dans ce dossier.

### Option recommandée — PowerShell interactif (06:01 + 16:00)

```powershell
cd chemin\vers\livraison\2026-05-19
.\Apply-Livraison.ps1 -Server <serveur> -Database fpusnr -Username <user>
# Mot de passe demandé à l'invite si -Password omis
```

Équivalent direct :

```powershell
.\Update-ShiftTimes.ps1 -Server <serveur> -Database fpusnr -Username <user>
```

Le script affiche l’état, la cible semaine **06:01 → 16:00**, puis demande confirmation avant d’exécuter `sql\update_shifttimes_weekdays_0601_1600.sql`.

### Option — Migrations SQL seules (débuts 06:01, sans 16:00)

Ordre identique au dossier `migrations/` du dépôt :

1. `sql/20260508_fix_monday_shift_start.sql`
2. `sql/20260508_fix_all_days_shift_start.sql`

Via PowerShell :

```powershell
.\Apply-Livraison.ps1 -Mode Migrations -Server <serveur> -Database fpusnr -Username <user>
```

Ou manuellement dans SSMS / `sqlcmd` (sauvegarde préalable, exécuter les `SELECT` de contrôle dans chaque fichier).

### Option — Depuis la racine du dépôt (hors zip livraison)

- Migrations : `migrations/*.sql`
- Python / npm : `scripts/db_shift_manager.py`, `package.json`
- PowerShell d’origine : `scripts/Update-ShiftTimes.ps1` (SQL inline, paramètres à adapter en production)

### Test métier

Après mise à jour : un événement vers **06:29** un jour ouvré doit être associé au quart **Jour**, pas Nuit.

---

## Différences entre les modes

| Mode | Fichiers SQL | Débuts 06:01 | Fins 16:00 (lun.–ven.) |
|------|----------------|--------------|-------------------------|
| `Apply-Livraison.ps1` (Interactive) | `select_*` + `update_shifttimes_weekdays_*` | Oui | Oui |
| `Apply-Livraison.ps1 -Mode Migrations` | `20260508_fix_*` (×2) | Oui | Non |
| SSMS manuel sur les migrations | idem migrations | Oui | Non |

---

## Hors périmètre

Ce livrable ne couvre pas le déploiement WinDev complet, l’indexation RAG/Qdrant, ni les autres domaines métier. Voir `README.md` à la racine du dépôt pour le reste.
