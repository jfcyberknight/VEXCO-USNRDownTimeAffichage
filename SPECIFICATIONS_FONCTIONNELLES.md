# Spécifications Fonctionnelles : USNR Downtime Affichage

Ce document synthétise l'intelligence métier extraite de l'analyse du projet legacy. Il sert de fondation pour la compréhension des flux de données et des règles d'affaires.

## 1. Vision du Projet
L'application **USNR Downtime Affichage** est un système de monitoring et d'analyse de la productivité industrielle. Son but principal est de capturer, classifier et valider les temps d'arrêt (Downtime) des machines de sciage (USNR) pour optimiser le rendement global.

## 2. Domaines Métier (Bounded Contexts)

### A. Gestion des Arrêts (Downtime Management)
C'est le cœur du système. Il gère l'interruption des processus de production.
*   **Entités clés :** `fpusnr_downtime_view`, `fpusnr_Arc_downtime_view`, `fpusnr_DowntimeStatusConfig`.
*   **Fonction :** Identifier chaque arrêt par machine, lui assigner un code de raison (`DowntimeCode`) et calculer la perte de productivité.

### B. Analyse de Production (Yield Analysis)
Analyse ce qui est produit entre les arrêts.
*   **Entités clés :** `fpusnr_log_view`, `fpusnr_shift_logdetail`, `fpusnr_shift_logdetailArc`.
*   **Fonction :** Suivi granulaire de chaque bille (`Log`) : essence (`Species`), diamètre, longueur, volume et qualité (`Grade`). Il lie la performance de l'optimiseur (`OptTime`) aux résultats réels.

### C. Organisation Temporelle (Shift & Crew Logistics)
Gère la structure du temps de travail.
*   **Entités clés :** `fpusnr_shifttimes`, `fpusnr_zlk_shift`, `tbl_periode`.
*   **Fonction :** Définition des quarts de travail (`Shift`), des horaires de début/fin par jour de la semaine et affectation des équipes (`Crew`).

### D. Audit et Gouvernance (Validation & Audit)
Assure l'intégrité des données rapportées.
*   **Entités clés :** `tbl_VerificationUsnr`, `tbl_Trace`.
*   **Fonction :** Processus d'approbation des rapports journaliers par les responsables et traçabilité complète des modifications manuelles.

## 3. Règles d'Affaire (Business Rules)

### R1 : Calcul de la Durée d'Arrêt
La durée (`Duration`) est une propriété calculée : `EndTime - StartTime`. Le système doit gérer les arrêts à cheval sur deux quarts de travail.

### R2 : Classification des Arrêts
Un arrêt ne peut être validé que s'il est associé à un `DowntimeCode` et un `GroupType`. Certains arrêts peuvent être marqués comme "Pas un arrêt" (`tbl_PasTempsArret`) s'ils correspondent à des pauses planifiées ou des maintenances préventives.

### R3 : Workflow d'Approbation
Un rapport de Downtime suit un cycle de vie strict :
1.  **Saisie/Capture automatique** via les automates (PLC).
2.  **Révision manuelle** par les opérateurs (ajout de commentaires via `fld_Commentaire`).
3.  **Approbation finale** (`fld_EnvoiFinal`) par un responsable, déclenchant le verrouillage des données pour la période.

### R4 : Hiérarchie de l'Équipement
Chaque événement de downtime doit être lié à une machine spécifique (`MachineDescription`). Les données de production (`LogView`) sont agrégées par machine pour calculer le rendement global.

### R5 : Gestion des Unités
Le système supporte le mode métrique et impérial (`IsMetric`). Toutes les conversions de volume (`LogVolume`, `LumberVolume`) doivent respecter ce flag pour garantir la précision des rapports.

## 4. Glossaire Technique
*   **Bille (Log) :** L'unité brute de bois entrant dans l'usine.
*   **Downtime :** Temps durant lequel une machine est capable de produire mais ne produit pas pour une raison x ou y.
*   **PLC (Automate) :** Source de données primaire pour les temps de cycle et les arrêts machine.
*   **Shift (Quart) :** Période de travail (ex: Jour, Soir, Nuit).
