# Documentation Consolidée - Système de Gestion Intégré

## Vue d'Ensemble

Cette documentation présente un système intégré de gestion de voyages avec intégration Odoo :

- **travel-management-app** : Application complète de gestion de voyages (backend + frontend)
- **odoo-endpoints** : Bibliothèque d'intégration Odoo

## Organisation par Phase

> **Voir [Organisation par Phase](00_organisation_par_phase.md) pour savoir quels documents sont pertinents selon la phase du projet (Conception / Implémentation / Tests / Déploiement)**

## Structure de la Documentation

### Phase de CONCEPTION (Phase Actuelle) 

### 01_cahier_des_charges/
- **01_executif.md** : Vue d'ensemble exécutive du système
- **02_detaille.md** : Spécifications fonctionnelles détaillées
- **03_regles_metier.md** : Règles métier complètes
- **04_exigences_non_fonctionnelles.md** : Performance, sécurité, disponibilité
- **05_analyse_risques.md** : Analyse des risques et mitigation

#### 02_diagrammes_uml/
- **01_use_case_diagram.md** : Cas d'utilisation (Mermaid)
- **02_class_diagram_*.md** : Diagrammes de classes modulaires (Mermaid)
- **03_sequence_diagrams.md** : Diagrammes de séquence (Mermaid)
- **04_activity_diagrams.md** : Diagrammes d'activité (Mermaid)
- **05_state_diagrams.md** : Machines à états (Mermaid)

### 03_diagrammes_merise/
- **01_mcd.md** : Modèle Conceptuel de Données (Mermaid)
- **02_mld.md** : Modèle Logique de Données (MySQL)
- **03_mpd.md** : Modèle Physique de Données
- **04_dictionnaire_donnees.md** : Dictionnaire des données

#### 04_diagrammes_architecture/
- **01_architecture_systeme.md** : Vue globale du système (Mermaid) 
- **02_architecture_application.md** : Architecture applicative (Mermaid) 
- **03_architecture_deploiement.md** : Architecture de déploiement (Mermaid) - Plus tard

#### 05_diagrammes_workflow/
- **01_workflow_voyages_scolaires.md** : Workflow complet voyages scolaires (Mermaid)
- **02_workflow_voyages_linguistiques.md** : Workflow voyages linguistiques (Mermaid)
- **04_workflow_integration_odoo.md** : Workflow intégration Odoo (Mermaid)
- **05_workflow_paiements.md** : Workflow paiements (Mermaid)
- **06_workflow_facturation.md** : Workflow facturation (Mermaid)

#### 06_diagrammes_bpmn/
- Processus métier en notation BPMN 

#### 07_diagrammes_flux/
- Diagrammes de flux de données 

#### 14_schemas_base_donnees/
- **01_schema_complet.sql** : Schéma SQL complet MySQL 

#### 15_glossaire_et_references/
- Glossaire des termes techniques 
- Acronymes 

#### 09_documentation_technique/
- **03_plan_gantt_projet.md** : Plan temporel complet (Gantt) Peut être fait maintenant

> **Documents d'implémentation déplacés** : Les guides d'installation, développement, API, intégrations techniques, tests, guides utilisateur et optimisations SQL ont été déplacés dans `_a_venir/` (voir [Organisation par Phase](00_organisation_par_phase.md))

## Technologies Utilisées

- **Backend** : Python 3.9+, FastAPI
- **Frontend** : Vue.js 3, Element Plus
- **Base de données** : MySQL 8.0+ (InnoDB, utf8mb4)
- **ORM** : SQLAlchemy
- **Migrations** : Alembic
- **Authentification** : JWT + 2FA (TOTP)
- **Intégrations** : Odoo (XML-RPC), Stripe, SMTP

## Navigation Rapide

### Pour la Phase de Conception
1. **Commencer ici** : [Cahier des charges exécutif](01_cahier_des_charges/01_executif.md)
2. **Architecture** : [Diagrammes d'architecture](04_diagrammes_architecture/)
3. **Diagrammes UML** : [Cas d'utilisation](02_diagrammes_uml/01_use_case_diagram.md)
4. **Base de données** : [Schéma complet](14_schemas_base_donnees/01_schema_complet.sql)
5. **Organisation** : [Voir organisation par phase](00_organisation_par_phase.md)

### Pour l'Implémentation (Plus Tard)
> Les documents d'implémentation sont dans `_a_venir/` (ignoré par Git)

## Visualisation des Diagrammes

### Mermaid (.md)
- **VS Code** : Extension "Markdown Preview Mermaid Support"
- **GitHub/GitLab** : Rendu automatique dans les fichiers Markdown
- **En ligne** : https://mermaid.live/
- Les diagrammes sont intégrés directement dans les fichiers Markdown

### BPMN (.bpmn)
- Utiliser un éditeur BPMN (Camunda Modeler, bpmn.io)

## Contribution

Cette documentation est générée à partir des projets source :
- `travel-management-app/`
- `odoo-endpoints/`

Pour mettre à jour la documentation, modifier les fichiers source et régénérer la documentation consolidée.

