# Note de Livraison — Correction des quarts (Lundi 06:01 uniquement)

**Date :** 3 juin 2026
**Statut :** Prêt pour la Production

---

## Contexte

Cette livraison vise à corriger et valider la configuration des quarts de travail ainsi que les données d'arrêts historiques pour l'application USNR Downtime.

Conformément à la règle d'affaires :
* **Le lundi matin uniquement** : Le quart de jour commence à **06:01** (au lieu de 07:00).
* **Mardi à Vendredi** : Le quart de jour reste inchangé et commence à **07:01** (configuré à `07:01:00` en base de données).

Le dossier `livraison/2026-06-03/` contient tous les outils nécessaires pour valider et appliquer ces modifications de manière autonome sur le serveur de production.

---

## Contenu du dossier `livraison/2026-06-03/`

| Fichier | Rôle |
|:---|:---|
| `Update-ShiftTimes.ps1` | Script PowerShell principal pour configurer les horaires dans la base de données. |
| `Apply-Historical-Fixes.ps1` | Script PowerShell pour appliquer la correction des données historiques. |
| `sql/20260508_fix_all_days_shift_start.sql` | Requête SQL pour configurer les horaires (lundi à `06:01` et mardi-vendredi à `07:01`). |
| `sql/20260520_fix_historical_shifts.sql` | Requête SQL de migration pour corriger les arrêts passés du lundi matin (06:01 à 07:00). |
| `2026-06-03-correction-quarts-lundi.md` | Ce document d'instructions. |

---

## Prérequis

* Accès en écriture à la base de données SQL Server `fpusnr`.
* PowerShell 5.1+ sur le poste d'exécution.
* Identifiants de connexion SQL (ex: utilisateur `sa`).

---

## Instructions de déploiement en Production

### Étape 1 : Appliquer la configuration des quarts de travail (le futur)

Cette étape met à jour la table de configuration des quarts `fpusnr_shifttimes`.

1. Ouvrez une console PowerShell dans le dossier de livraison.
2. Exécutez le script suivant :
   ```powershell
   .\Update-ShiftTimes.ps1 -Server VM-WIN10-VEXCO -Database fpusnr -Username sa
   ```
   *(Modifiez le serveur et le nom d'utilisateur si nécessaire. Le mot de passe sera demandé de manière sécurisée).*
3. Le script affichera le snapshot **Avant** et la cible **Après** pour validation.
4. Confirmez par `O` (Oui) pour appliquer.

---

### Étape 2 : Appliquer la correction sur l'historique (le passé)

Cette étape corrige les arrêts passés des lundis matins (entre 06:01 et 07:00) qui étaient classés en `Nuit` par erreur de date, pour les affecter au quart de `Jour` du lundi.

1. Exécutez le script suivant :
   ```powershell
   .\Apply-Historical-Fixes.ps1 -Server VM-WIN10-VEXCO -Database fpusnr -Username sa
   ```
2. Le script exécutera les requêtes de correction et affichera le nombre de lignes mises à jour dans les tables de production et d'archive.

---

## Vérification après déploiement

* Les événements d'arrêts du **lundi** se produisant à partir de **06:01** doivent maintenant être classés sous le quart de **Jour**.
* Les événements se produisant le **mardi** (ou autre jour) à **06:29** doivent rester en **Nuit** (rattachés au lundi soir).
