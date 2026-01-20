# Documentation Tests

Ce dossier contient la documentation complète sur les stratégies et procédures de test du système.

## Structure

### 01_strategie_tests.md
Stratégie globale de tests, couverture cible, types de tests

### 02_tests_unitaires.md
Tests unitaires des services et fonctions métier

### 03_tests_integration.md
Tests d'intégration API, base de données, services externes

### 04_tests_acceptation.md
Tests d'acceptation utilisateur (UAT), scénarios métier

### 05_tests_performance.md
Tests de charge, performance, stress testing

### 06_tests_securite.md
Tests de sécurité, authentification, autorisation

## Outils de Test

### Backend (Python)
- **pytest** : Framework de tests
- **pytest-cov** : Couverture de code
- **httpx** : Tests API (client HTTP async)
- **faker** : Génération de données de test

### Frontend (Vue.js)
- **Vitest** : Framework de tests unitaires
- **Vue Test Utils** : Utilitaires de test Vue
- **Playwright** : Tests end-to-end

### Base de Données
- **pytest-mysql** : Tests avec base de données de test
- **Alembic** : Migrations de test

## Couverture Cible

- **Code Backend** : ≥ 80%
- **Services métier** : ≥ 90%
- **API Endpoints** : 100% des endpoints testés
- **Frontend Components** : ≥ 70%

## Exécution des Tests

```bash
# Tests backend
cd backend
pytest tests/ -v --cov=app

# Tests frontend
cd frontend
npm run test

# Tests E2E
npm run test:e2e
```

---

**Note** : La documentation détaillée des tests sera ajoutée lors de l'implémentation des tests.
