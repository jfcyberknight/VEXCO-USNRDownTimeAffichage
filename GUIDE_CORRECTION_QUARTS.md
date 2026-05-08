# Guide de Correction : Horaires des Quarts de Travail
**Date :** Vendredi 8 mai 2026

Ce guide explique comment modifier l'heure de début du quart de travail du lundi matin pour passer de 07h00 à **06h01** dans l'application USNR Downtime.

## 1. Diagnostic du Problème
L'application utilise une table de configuration pour déterminer quel quart de travail est actif. Si un événement se produit à 06h29 et affiche "Nuit" au lieu de "Jour", c'est que la "frontière" temporelle dans la base de données est encore fixée à 07h00.

## 2. Solution via SQL Server (Recommandé)
Le moyen le plus direct est d'exécuter une requête SQL sur la base de données de production.

### Emplacement :
*   **Table :** `fpusnr_shifttimes`
*   **Colonne :** `MondayStart`

### Requête de mise à jour :
```sql
-- 1. Identifier le ShiftId du quart de "Jour" (souvent 1)
-- SELECT ShiftId, MondayStart FROM fpusnr_shifttimes;

-- 2. Appliquer la modification
UPDATE fpusnr_shifttimes
SET MondayStart = '1900-01-01 06:01:00.000'
WHERE ShiftId = 1; -- Remplacez par l'ID correct si nécessaire
```

## 3. Solution via WinDev (WDMap)
Si vous préférez utiliser les outils WinDev :
1.  Lancez **WDMap** (ou l'éditeur de données intégré).
2.  Ouvrez le fichier `fpusnr_shifttimes.fic`.
3.  Localisez l'enregistrement du quart de jour.
4.  Modifiez la colonne `MondayStart` :
    *   Saisissez : `060100` (Heure: 06, Minute: 01, Seconde: 00).
5.  Enregistrez les modifications.

## 4. Pourquoi cette modification est nécessaire ?
Le logiciel fonctionne en mode **"Data-Driven"** (piloté par les données). Il compare l'heure actuelle aux valeurs stockées dans `fpusnr_shifttimes` :
*   **Avant :** L'intervalle de Nuit se terminait à 07h00. À 06h29, on était encore en "Nuit".
*   **Après :** L'intervalle de Jour commence à 06h01. À 06h29, le système identifie correctement le quart de "Jour".

---
**Note technique :** Aucun redémarrage ou recompilation du programme n'est requis. Le changement est effectif dès que la base de données est sauvegardée.
