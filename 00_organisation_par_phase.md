# Organisation de la Documentation par Phase du Projet

## Phase de CONCEPTION (Phase Actuelle) ✅

Ces documents sont **essentiels** pour la phase de conception et doivent être complétés maintenant :

### 01_cahier_des_charges/
- ✅ **01_executif.md** : Vision globale, objectifs
- ✅ **02_detaille.md** : Spécifications fonctionnelles détaillées
- ✅ **03_regles_metier.md** : Règles métier à implémenter
- ✅ **04_exigences_non_fonctionnelles.md** : Performance, sécurité (conceptuelle)
- ✅ **05_analyse_risques.md** : Identification des risques

### 02_diagrammes_uml/
- ✅ **Tous les diagrammes UML** : Use cases, classes, séquences, activités, états
- **Raison** : Modélisation du système avant implémentation

### 03_diagrammes_merise/
- ✅ **01_mcd.md** : Modèle Conceptuel de Données
- ✅ **02_mld.md** : Modèle Logique de Données
- ✅ **03_mpd.md** : Modèle Physique de Données
- **Raison** : Conception de la base de données

### 04_diagrammes_architecture/
- ✅ **01_architecture_systeme.md** : Vue globale du système
- ✅ **02_architecture_application.md** : Architecture applicative
- ⚠️ **03_architecture_deploiement.md** : Peut attendre (détails techniques)
- **Raison** : Définition de l'architecture avant développement

### 05_diagrammes_workflow/
- ✅ **Tous les workflows** : Voyages scolaires, linguistiques, intégrations
- **Raison** : Définition des processus métier

### 06_diagrammes_bpmn/
- ✅ **Processus métier** : Si nécessaire pour la modélisation

### 07_diagrammes_flux/
- ✅ **Diagrammes de flux de données** : Si nécessaire

### 14_schemas_base_donnees/
- ✅ **01_schema_complet.sql** : Schéma de base (structure des tables)
- ⚠️ **02_index_optimisation.md** : Peut attendre (optimisation = implémentation)
- ⚠️ **03_fonctions_sql.md** : Peut attendre (détails d'implémentation)
- ⚠️ **04_fonctions_sql_implementation.sql** : À faire pendant l'implémentation

### 15_glossaire_et_references/
- ✅ **Glossaire et acronymes** : Utile pour la compréhension

---

## Phase d'IMPLÉMENTATION (Plus Tard) ⏳

Ces documents doivent être créés **pendant ou après** le développement :

### 08_documentation_api/
- ❌ **01_api_rest_complete.md** : À créer après implémentation des endpoints
- **Raison** : Documente l'API une fois qu'elle existe

### 09_documentation_technique/
- ❌ **01_guide_installation.md** : À créer quand le projet est prêt à être installé
- ❌ **02_guide_developpement.md** : À créer pendant l'implémentation
- ⚠️ **03_plan_gantt_projet.md** : Peut être fait maintenant (planification)

### 10_documentation_integrations/
- ⚠️ **01_integration_odoo.md** : Spécifications = conception, détails techniques = implémentation
- ⚠️ **02_integration_stripe.md** : Idem
- ❌ **03_integration_odoo_webhooks.md** : Détails techniques d'implémentation

### 14_schemas_base_donnees/
- ❌ **02_index_optimisation.md** : Optimisations = après avoir testé les performances
- ❌ **03_fonctions_sql.md** : Détails d'implémentation des fonctions
- ❌ **04_fonctions_sql_implementation.sql** : Code SQL à écrire pendant l'implémentation

---

## Phase de TESTS (Plus Tard) ⏳

### 13_documentation_tests/
- ❌ **01_strategie_tests.md** : À créer avant les tests, mais après la conception
- **Raison** : On ne peut pas planifier les tests sans connaître l'implémentation

---

## Phase de DÉPLOIEMENT / PRODUCTION (Plus Tard) ⏳

### 04_diagrammes_architecture/
- ❌ **03_architecture_deploiement.md** : Détails techniques de déploiement

### 11_documentation_metier/
- ❌ **02_guide_utilisateur_commercial.md** : Guides utilisateur finaux
- **Raison** : Nécessite que l'application soit fonctionnelle

### 12_documentation_securite/
- ⚠️ **01_politique_securite.md** : Politique générale = conception, détails techniques = implémentation

---

## Recommandations

### Pour la Phase de Conception (Maintenant)

**Focus sur** :
1. ✅ Cahier des charges complet
2. ✅ Tous les diagrammes UML
3. ✅ Diagrammes Merise (MCD, MLD, MPD)
4. ✅ Architecture système et application
5. ✅ Workflows métier
6. ✅ Schéma de base de données (structure, pas optimisations)

**À éviter maintenant** :
- ❌ Guides d'installation (rien à installer encore)
- ❌ Documentation API détaillée (pas d'API implémentée)
- ❌ Guides utilisateur (pas d'interface à documenter)
- ❌ Optimisations SQL (pas de données à optimiser)
- ❌ Détails techniques d'intégration (spécifications OK, code non)

### Structure Recommandée

```
documentation/
├── 00_organisation_par_phase.md (ce fichier)
├── 01_cahier_des_charges/ ✅
├── 02_diagrammes_uml/ ✅
├── 03_diagrammes_merise/ ✅
├── 04_diagrammes_architecture/
│   ├── 01_architecture_systeme.md ✅
│   ├── 02_architecture_application.md ✅
│   └── 03_architecture_deploiement.md ⏳ (plus tard)
├── 05_diagrammes_workflow/ ✅
├── 06_diagrammes_bpmn/ ✅
├── 07_diagrammes_flux/ ✅
├── 14_schemas_base_donnees/
│   ├── 01_schema_complet.sql ✅
│   ├── 02_index_optimisation.md ⏳
│   ├── 03_fonctions_sql.md ⏳
│   └── 04_fonctions_sql_implementation.sql ⏳
└── 15_glossaire_et_references/ ✅

À créer plus tard :
├── 08_documentation_api/ ⏳
├── 09_documentation_technique/ ⏳
├── 10_documentation_integrations/ ⏳ (détails techniques)
├── 11_documentation_metier/ ⏳
├── 12_documentation_securite/ ⏳ (détails techniques)
└── 13_documentation_tests/ ⏳
```

---

## Action Réalisée ✅

Les documents non pertinents pour la phase de conception ont été déplacés dans le dossier `_a_venir/` qui est ignoré par Git (`.gitignore`).

### Documents Déplacés

- `08_documentation_api/` → `_a_venir/08_documentation_api/`
- `09_documentation_technique/01_guide_installation.md` → `_a_venir/09_documentation_technique/`
- `09_documentation_technique/02_guide_developpement.md` → `_a_venir/09_documentation_technique/`
- `10_documentation_integrations/` → `_a_venir/10_documentation_integrations/`
- `11_documentation_metier/` → `_a_venir/11_documentation_metier/`
- `12_documentation_securite/` → `_a_venir/12_documentation_securite/`
- `13_documentation_tests/` → `_a_venir/13_documentation_tests/`
- `14_schemas_base_donnees/02_index_optimisation.md` → `_a_venir/14_schemas_base_donnees/`
- `14_schemas_base_donnees/03_fonctions_sql.md` → `_a_venir/14_schemas_base_donnees/`
- `14_schemas_base_donnees/04_fonctions_sql_implementation.sql` → `_a_venir/14_schemas_base_donnees/`
- `04_diagrammes_architecture/03_architecture_deploiement.md` → `_a_venir/04_diagrammes_architecture/`

### Documents Conservés (Phase de Conception)

- `09_documentation_technique/03_plan_gantt_projet.md` : Planification (peut être fait maintenant)
- `14_schemas_base_donnees/01_schema_complet.sql` : Schéma de base (structure)
