# Livraison — Correction des horaires de quarts (06:01)

**Date :** 19 mai 2026

---

## Contexte / problème corrigé

L’application USNR Downtime détermine le quart actif à partir de la table **`fpusnr_shifttimes`**. Les débuts de quart en semaine étaient encore à **07:00** ; un événement vers 06h29 était donc classé en « Nuit » au lieu de « Jour ».

**Objectif :** fixer le début du quart de jour à **06:01** (lundi puis lundi–vendredi), fin de journée à **16:00** lorsque les scripts automatisés ajustent aussi les fins. Aucun redémarrage WinDev requis — effet immédiat après mise à jour SQL.

---

## Ce qui a été livré

| Artefact | Rôle |
|----------|------|
| `migrations/20260508_fix_monday_shift_start.sql` | Lundi : `MondayStart` → **06:01** (`ShiftId = 1`) |
| `migrations/20260508_fix_all_days_shift_start.sql` | Lun.–ven. : `*Start` → **06:01** (week-end non modifié) |
| `scripts/db_shift_manager.py` | Lecture / snapshot / correction via `.env` |
| `scripts/Update-ShiftTimes.ps1` | Même correction sans Python (serveur externe) |
| `package.json` | Scripts npm `verify-shifts`, `update-shifts`, `verify-and-fix-shifts`, `setup-db-tools` |
| `GUIDE_CORRECTION_QUARTS.md` | Procédure manuelle SQL / WDMap |
| `Classes/fpusnr_shifttimes.wdc.txt` | Structure WinDev alignée (dont `ThursdayStart`) |

**Cible SQL :** table `fpusnr_shifttimes`, en pratique **`ShiftId = 1`** (quart « Jour »). Vérifier l’ID en base avant exécution.

---

## Comment appliquer / tester

### Option A — Migrations SQL (SSMS / `sqlcmd`)

1. Sauvegarder la table ou la base.
2. Exécuter les `SELECT` de contrôle dans chaque fichier de `migrations/`.
3. Lancer d’abord `20260508_fix_monday_shift_start.sql`, puis `20260508_fix_all_days_shift_start.sql` si la correction doit couvrir toute la semaine.
4. Valider avec les `SELECT` post-mise à jour.

### Option B — npm + Python

```bash
npm run setup-db-tools          # pyodbc, python-dotenv
npm run verify-shifts           # état actuel (ShiftId 1)
npm run update-shifts           # applique 06:01 / 16:00 (--fix)
npm run verify-and-fix-shifts   # vérif + correction
```

Ajuster le chemin Python dans `package.json` si nécessaire sur le poste cible.

### Option C — PowerShell

```powershell
.\scripts\Update-ShiftTimes.ps1 -Server <serveur> -Database fpusnr -Username <user> -Password <pwd>
```

Le script affiche l’état, propose la correction semaine **06:01 → 16:00**, puis demande confirmation.

### Test métier

Après mise à jour : un événement vers **06:29** un jour ouvré doit être associé au quart **Jour**, pas Nuit.

---

## Prérequis

- **SQL Server** : accès lecture/écriture à la base contenant `fpusnr_shifttimes`.
- **Fichier `.env`** (non versionné) pour Python :
  - `DB_SERVER` ou `DB_HOST`
  - `DB_DATABASE` ou `DB_NAME`
  - `DB_USERNAME` ou `DB_USER`
  - `DB_PASSWORD` ou `DB_PASS`
- **Node.js** (scripts npm) et/ou **Python 3** avec `pyodbc` + `python-dotenv`, ou PowerShell seul.
- **Points d’attention :** confirmer `ShiftId` du quart Jour ; `Update-ShiftTimes.ps1` peut contenir des paramètres par défaut à adapter en production.

---

## Hors périmètre

Ce livrable ne couvre pas le déploiement WinDev complet, l’indexation RAG/Qdrant, la recréation des 33 classes/états, ni les autres domaines métier (downtime, production, audit). Voir `README.md` et `SPECIFICATIONS_FONCTIONNELLES.md` pour le reste du dépôt.
