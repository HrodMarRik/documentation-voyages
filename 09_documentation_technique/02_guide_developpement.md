# Guide de Développement

## Structure du Code

### Backend (Python/FastAPI)

```
backend/
├── app/
│   ├── api/              # Endpoints API
│   │   ├── auth.py
│   │   ├── travels.py
│   │   └── ...
│   ├── core/             # Configuration, sécurité
│   │   ├── config.py
│   │   ├── security.py
│   │   └── permissions.py
│   ├── database/         # Modèles SQLAlchemy
│   │   ├── models/
│   │   └── base.py
│   ├── services/         # Logique métier
│   │   ├── travel_service.py
│   │   ├── pricing_service.py
│   │   └── ...
│   └── main.py          # Point d'entrée
├── alembic/             # Migrations
└── requirements.txt
```

### Frontend (Vue.js)

```
frontend/
├── src/
│   ├── components/      # Composants réutilisables
│   ├── views/           # Pages
│   ├── stores/          # Pinia stores
│   ├── router/          # Routes
│   └── api/             # Clients API
├── package.json
└── vite.config.js
```

## Standards de Codage

### Python

- **PEP 8** : Respecter les conventions PEP 8
- **Type hints** : Utiliser les annotations de type
- **Docstrings** : Documenter toutes les fonctions et classes
- **Linting** : Utiliser `black`, `flake8`, `mypy`

**Exemple** :
```python
def calculate_travel_price(
    travel_id: int,
    number_participants: int
) -> float:
    """
    Calcule le prix total d'un voyage.
    
    Args:
        travel_id: ID du voyage
        number_participants: Nombre de participants
        
    Returns:
        Prix total calculé
    """
    # Implementation
    pass
```

### JavaScript/Vue.js

- **ESLint** : Utiliser ESLint avec règles Vue
- **Prettier** : Formatage automatique
- **Composition API** : Préférer Composition API à Options API

## Architecture et Patterns

### Pattern Repository (Optionnel)

Pour les accès base de données complexes :

```python
class TravelRepository:
    def __init__(self, db: Session):
        self.db = db
    
    def get_by_status(self, status: TravelStatus) -> List[Travel]:
        return self.db.query(Travel).filter(
            Travel.status == status
        ).all()
```

### Pattern Service

Toute la logique métier dans les services :

```python
class TravelService:
    def __init__(self, db: Session):
        self.db = db
        self.pricing_service = PricingService(db)
    
    def create_travel(self, data: TravelCreate) -> Travel:
        # Logique métier
        pass
```

### Dependency Injection

Utiliser la dépendance injection de FastAPI :

```python
from fastapi import Depends
from app.database import get_db

@router.get("/travels")
def get_travels(db: Session = Depends(get_db)):
    # Utiliser db
    pass
```

## Utilisation des Fonctions SQL

### Appel d'une Fonction

```python
from sqlalchemy import text

# Appel direct
result = db.execute(
    text("SELECT calculate_final_travel_price(:travel_id)"),
    {"travel_id": travel_id}
).scalar()

# Dans une requête SELECT
travels = db.execute(
    text("SELECT id, name, calculate_final_travel_price(id) AS total_price FROM travels")
).fetchall()
```

### Appel d'une Procédure

```python
# Appeler la procédure
db.execute(
    text("CALL sp_generate_quote_for_travel(:travel_id, @quote_id)"),
    {"travel_id": travel_id}
)

# Récupérer la valeur OUT
quote_id = db.execute(text("SELECT @quote_id")).scalar()
db.commit()
```

### Exemple dans un Service

```python
class TravelService:
    def calculate_price(self, travel_id: int) -> Decimal:
        return self.db.execute(
            text("SELECT calculate_final_travel_price(:travel_id)"),
            {"travel_id": travel_id}
        ).scalar()
    
    def generate_quote(self, travel_id: int) -> Quote:
        if not self.can_generate_quote(travel_id):
            raise ValueError("Le devis ne peut pas être généré")
        
        self.db.execute(
            text("CALL sp_generate_quote_for_travel(:travel_id, @quote_id)"),
            {"travel_id": travel_id}
        )
        quote_id = self.db.execute(text("SELECT @quote_id")).scalar()
        self.db.commit()
        return self.db.query(Quote).filter(Quote.id == quote_id).first()
```

### Bonnes Pratiques

- Valider avant d'appeler une procédure
- Utiliser les transactions pour les opérations complexes
- Mettre en cache les résultats si approprié
- Documenter l'utilisation des fonctions SQL dans les docstrings

## Ajout de Nouvelles Fonctionnalités

### 1. Créer un Modèle

```python
# app/database/models/new_model.py
from sqlalchemy import Column, Integer, String
from app.database.base import Base

class NewModel(Base):
    __tablename__ = "new_models"
    
    id = Column(Integer, primary_key=True)
    name = Column(String(255), nullable=False)
```

### 2. Créer une Migration

```bash
alembic revision --autogenerate -m "Add new_model table"
alembic upgrade head
```

### 3. Créer un Service

```python
# app/services/new_service.py
class NewService:
    def __init__(self, db: Session):
        self.db = db
    
    def create(self, data: NewModelCreate) -> NewModel:
        # Logique métier
        pass
```

### 4. Créer un Endpoint API

```python
# app/api/new.py
from fastapi import APIRouter, Depends
from app.services.new_service import NewService
from app.database import get_db

router = APIRouter()

@router.post("/new")
def create_new(
    data: NewModelCreate,
    db: Session = Depends(get_db)
):
    service = NewService(db)
    return service.create(data)
```

### 5. Enregistrer le Router

```python
# app/main.py
from app.api import new

app.include_router(new.router, prefix="/api/new", tags=["new"])
```

## Tests

### Tests Unitaires

```python
# tests/test_pricing_service.py
import pytest
from app.services.pricing_service import PricingService

def test_calculate_travel_price():
    # Arrange
    service = PricingService(db)
    
    # Act
    price = service.calculate_travel_price(travel_id=1)
    
    # Assert
    assert price > 0
```

### Tests d'Intégration

```python
# tests/test_api_travels.py
from fastapi.testclient import TestClient

def test_create_travel(client: TestClient, auth_headers):
    response = client.post(
        "/api/travels",
        json={"name": "Test", ...},
        headers=auth_headers
    )
    assert response.status_code == 201
```

### Exécuter les Tests

```bash
# Tous les tests
pytest

# Tests spécifiques
pytest tests/test_pricing_service.py

# Avec couverture
pytest --cov=app --cov-report=html
```

## Debugging

### Logs

Utiliser le module `logging` :

```python
import logging

logger = logging.getLogger(__name__)

def my_function():
    logger.info("Function called")
    logger.error("Error occurred", exc_info=True)
```

### Debugger

Utiliser le debugger intégré de VS Code ou `pdb` :

```python
import pdb; pdb.set_trace()  # Point d'arrêt
```

## Git Workflow

### Branches

- **main** : Code de production
- **develop** : Code de développement
- **feature/*** : Nouvelles fonctionnalités
- **bugfix/*** : Corrections de bugs
- **hotfix/*** : Corrections urgentes

### Commits

Format des messages de commit :

```
type(scope): description

[body optionnel]

[footer optionnel]
```

Types :
- `feat` : Nouvelle fonctionnalité
- `fix` : Correction de bug
- `docs` : Documentation
- `refactor` : Refactorisation
- `test` : Tests
- `chore` : Tâches de maintenance

Exemple :
```
feat(travels): add multi-destination support

Add ability to create travels with multiple destinations.
Update pricing calculation to handle multiple destinations.
```

## Performance

- Index sur tous les champs de recherche
- Paginer les listes
- Lazy loading pour les relations
- Cache pour les données fréquentes

## Documentation du Code

Format Google style pour les docstrings :

```python
def calculate_price(travel_id: int, participants: int) -> float:
    """
    Calcule le prix d'un voyage.
    
    Args:
        travel_id: Identifiant du voyage
        participants: Nombre de participants
        
    Returns:
        Prix total calculé
    """
    pass
```

## Références

### Documentation des Fonctions SQL

- **Documentation complète** : `documentation/14_schemas_base_donnees/03_fonctions_sql.md`
- **Implémentation SQL** : `documentation/14_schemas_base_donnees/04_fonctions_sql_implementation.sql`
- **Architecture** : `documentation/14_schemas_base_donnees/05_architecture_fonctions_sql.md`
- **Dépendances** : `documentation/14_schemas_base_donnees/06_dependances_fonctions_sql.md`
- **Utilisation par workflow** : `documentation/14_schemas_base_donnees/07_fonctions_par_workflow.md`

### Commandes Utiles

```sql
-- Lister toutes les fonctions
SHOW FUNCTION STATUS WHERE Db = 'gestion_db';

-- Voir le code d'une fonction
SHOW CREATE FUNCTION calculate_final_travel_price;

-- Tester une fonction
SELECT calculate_final_travel_price(123);

-- Vérifier les dépendances (via EXPLAIN)
EXPLAIN SELECT calculate_final_travel_price(123);
```
