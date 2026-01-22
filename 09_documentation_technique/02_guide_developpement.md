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

## Utilisation des Fonctions SQL Stockées

Le système utilise des fonctions SQL stockées et des procédures stockées pour encapsuler la logique métier au niveau de la base de données. Cette approche améliore les performances et garantit la cohérence des calculs.

### Appel d'une Fonction SQL

#### Exemple 1 : Appel Direct d'une Fonction

```python
from sqlalchemy import text
from app.database import get_db

def calculate_travel_price(travel_id: int, db: Session) -> Decimal:
    """
    Calcule le prix final d'un voyage en utilisant la fonction SQL.
    
    Args:
        travel_id: ID du voyage
        db: Session de base de données
        
    Returns:
        Prix final calculé
    """
    result = db.execute(
        text("SELECT calculate_final_travel_price(:travel_id)"),
        {"travel_id": travel_id}
    ).scalar()
    
    return result
```

#### Exemple 2 : Utilisation dans une Requête SELECT

```python
def get_travels_with_prices(db: Session) -> List[Dict]:
    """
    Récupère les voyages avec leurs prix calculés.
    """
    travels = db.execute(
        text("""
            SELECT 
                id,
                name,
                status,
                calculate_final_travel_price(id) AS total_price
            FROM travels
            WHERE status = 'draft'
        """)
    ).fetchall()
    
    return [dict(travel) for travel in travels]
```

#### Exemple 3 : Utilisation dans un WHERE

```python
def get_travels_ready_for_quote(db: Session) -> List[Travel]:
    """
    Récupère les voyages prêts pour génération de devis.
    """
    travels = db.execute(
        text("""
            SELECT *
            FROM travels
            WHERE can_generate_quote(id) = TRUE
        """)
    ).fetchall()
    
    return travels
```

### Appel d'une Procédure Stockée

#### Exemple : Génération Automatique de Devis

```python
def generate_quote_for_travel(travel_id: int, db: Session) -> int:
    """
    Génère automatiquement un devis pour un voyage.
    
    Args:
        travel_id: ID du voyage
        db: Session de base de données
        
    Returns:
        ID du devis créé
    """
    # Appeler la procédure stockée
    db.execute(
        text("CALL sp_generate_quote_for_travel(:travel_id, @quote_id)"),
        {"travel_id": travel_id}
    )
    
    # Récupérer la valeur OUT
    quote_id = db.execute(text("SELECT @quote_id")).scalar()
    
    # Commit la transaction
    db.commit()
    
    return quote_id
```

### Intégration dans les Services

#### Exemple : TravelService avec Fonctions SQL

```python
from sqlalchemy import text
from app.database import get_db
from app.models.travel import Travel, TravelCreate

class TravelService:
    def __init__(self, db: Session):
        self.db = db
    
    def calculate_price(self, travel_id: int) -> Decimal:
        """
        Calcule le prix final d'un voyage.
        Utilise la fonction SQL calculate_final_travel_price().
        """
        return self.db.execute(
            text("SELECT calculate_final_travel_price(:travel_id)"),
            {"travel_id": travel_id}
        ).scalar()
    
    def can_generate_quote(self, travel_id: int) -> bool:
        """
        Vérifie si un devis peut être généré.
        Utilise la fonction SQL can_generate_quote().
        """
        return self.db.execute(
            text("SELECT can_generate_quote(:travel_id)"),
            {"travel_id": travel_id}
        ).scalar()
    
    def generate_quote(self, travel_id: int) -> Quote:
        """
        Génère automatiquement un devis.
        Utilise la procédure stockée sp_generate_quote_for_travel().
        """
        # Vérifier d'abord si c'est possible
        if not self.can_generate_quote(travel_id):
            raise ValueError("Le devis ne peut pas être généré pour ce voyage")
        
        # Appeler la procédure
        self.db.execute(
            text("CALL sp_generate_quote_for_travel(:travel_id, @quote_id)"),
            {"travel_id": travel_id}
        )
        
        quote_id = self.db.execute(text("SELECT @quote_id")).scalar()
        self.db.commit()
        
        # Récupérer le devis créé
        return self.db.query(Quote).filter(Quote.id == quote_id).first()
```

### Gestion des Erreurs

#### Exemple : Gestion d'Erreurs SQL

```python
from sqlalchemy.exc import SQLAlchemyError

def safe_calculate_price(travel_id: int, db: Session) -> Optional[Decimal]:
    """
    Calcule le prix avec gestion d'erreurs.
    """
    try:
        result = db.execute(
            text("SELECT calculate_final_travel_price(:travel_id)"),
            {"travel_id": travel_id}
        ).scalar()
        
        return result
    except SQLAlchemyError as e:
        logger.error(f"Erreur calcul prix pour travel_id={travel_id}: {e}")
        return None
```

### Bonnes Pratiques

#### 1. Toujours Valider Avant d'Appeler une Procédure

```python
# ✅ BON : Valider avant d'appeler
if can_generate_quote(travel_id):
    generate_quote(travel_id)
else:
    raise ValueError("Conditions non remplies")

# ❌ MAUVAIS : Appeler directement sans validation
generate_quote(travel_id)  # Peut échouer avec SIGNAL SQLSTATE
```

#### 2. Utiliser les Transactions

```python
# ✅ BON : Utiliser une transaction
def create_quote_with_validation(travel_id: int, db: Session):
    try:
        # Validation
        can_generate = db.execute(
            text("SELECT can_generate_quote(:travel_id)"),
            {"travel_id": travel_id}
        ).scalar()
        
        if not can_generate:
            raise ValueError("Cannot generate quote")
        
        # Génération
        db.execute(
            text("CALL sp_generate_quote_for_travel(:travel_id, @quote_id)"),
            {"travel_id": travel_id}
        )
        
        db.commit()
    except Exception as e:
        db.rollback()
        raise
```

#### 3. Mettre en Cache les Résultats si Approprié

```python
from functools import lru_cache

@lru_cache(maxsize=100)
def get_travel_price_cached(travel_id: int) -> Decimal:
    """
    Version mise en cache du calcul de prix.
    Attention : Le cache doit être invalidé si le voyage est modifié.
    """
    # Appel à la fonction SQL
    pass
```

#### 4. Documenter l'Utilisation des Fonctions SQL

```python
def calculate_travel_price(travel_id: int) -> Decimal:
    """
    Calcule le prix final d'un voyage.
    
    Utilise la fonction SQL calculate_final_travel_price() qui :
    - Calcule le prix de base (transport + activités + hébergement)
    - Applique les réductions (participants + early bird)
    - Applique la marge si renseignée
    
    Voir : documentation/14_schemas_base_donnees/03_fonctions_sql.md
    
    Args:
        travel_id: ID du voyage
        
    Returns:
        Prix final calculé
        
    Raises:
        ValueError: Si le voyage n'existe pas ou n'a pas de participants
    """
    pass
```

### Débogage des Fonctions SQL

#### 1. Vérifier qu'une Fonction Existe

```python
def function_exists(function_name: str, db: Session) -> bool:
    """
    Vérifie si une fonction SQL existe.
    """
    result = db.execute(
        text("""
            SELECT COUNT(*) 
            FROM information_schema.routines 
            WHERE routine_schema = DATABASE()
            AND routine_name = :function_name
            AND routine_type = 'FUNCTION'
        """),
        {"function_name": function_name}
    ).scalar()
    
    return result > 0
```

#### 2. Voir le Code d'une Fonction

```python
def get_function_code(function_name: str, db: Session) -> str:
    """
    Récupère le code source d'une fonction SQL.
    """
    result = db.execute(
        text("SHOW CREATE FUNCTION :function_name"),
        {"function_name": function_name}
    ).fetchone()
    
    return result[2] if result else None
```

#### 3. Tester une Fonction avec des Données de Test

```python
def test_calculate_price_function(db: Session):
    """
    Teste la fonction calculate_final_travel_price avec des données de test.
    """
    # Créer un voyage de test
    test_travel = Travel(
        name="Test Travel",
        start_date=datetime(2025, 6, 1),
        end_date=datetime(2025, 6, 7),
        number_participants=25,
        status="draft"
    )
    db.add(test_travel)
    db.flush()
    
    # Tester la fonction
    price = db.execute(
        text("SELECT calculate_final_travel_price(:travel_id)"),
        {"travel_id": test_travel.id}
    ).scalar()
    
    assert price is not None
    assert price >= 0
    
    # Nettoyer
    db.delete(test_travel)
    db.commit()
```

### Migration des Fonctions SQL

#### Créer une Migration pour une Fonction

```python
# alembic/versions/xxxx_add_new_function.py
from alembic import op
import sqlalchemy as sa

def upgrade():
    # Créer la nouvelle fonction
    op.execute("""
        DELIMITER $$
        CREATE FUNCTION new_function(param INT)
        RETURNS DECIMAL(10,2)
        READS SQL DATA
        DETERMINISTIC
        BEGIN
            -- Code de la fonction
            RETURN 0;
        END$$
        DELIMITER ;
    """)

def downgrade():
    # Supprimer la fonction
    op.execute("DROP FUNCTION IF EXISTS new_function")
```

### Performance et Optimisation

#### 1. Éviter les Appels Multiples

```python
# ❌ MAUVAIS : Appels multiples
for travel in travels:
    price = calculate_final_travel_price(travel.id)  # N appels

# ✅ BON : Un seul appel avec sous-requête
travels_with_prices = db.execute(
    text("""
        SELECT 
            id,
            name,
            calculate_final_travel_price(id) AS price
        FROM travels
        WHERE id IN :travel_ids
    """),
    {"travel_ids": tuple(travel.id for travel in travels)}
).fetchall()
```

#### 2. Utiliser les Index

Les fonctions SQL utilisent automatiquement les index. Vérifier que les index nécessaires existent :

```sql
-- Vérifier les index utilisés par une fonction
EXPLAIN SELECT calculate_final_travel_price(123);
```

#### 3. Monitorer les Performances

```python
import time
from sqlalchemy import text

def calculate_price_with_timing(travel_id: int, db: Session):
    """
    Calcule le prix et mesure le temps d'exécution.
    """
    start_time = time.time()
    
    result = db.execute(
        text("SELECT calculate_final_travel_price(:travel_id)"),
        {"travel_id": travel_id}
    ).scalar()
    
    execution_time = time.time() - start_time
    
    logger.info(f"calculate_final_travel_price({travel_id}) took {execution_time:.3f}s")
    
    return result
```

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

### Optimisations

- **Index base de données** : Index sur tous les champs de recherche
- **Pagination** : Toujours paginer les listes
- **Lazy loading** : Charger les relations à la demande
- **Cache** : Mettre en cache les données fréquentes

### Profiling

Utiliser `cProfile` pour profiler le code :

```python
import cProfile

profiler = cProfile.Profile()
profiler.enable()
# Code à profiler
profiler.disable()
profiler.print_stats()
```

## Documentation du Code

### Docstrings

Format Google style :

```python
def calculate_price(
    travel_id: int,
    participants: int
) -> float:
    """
    Calcule le prix d'un voyage.
    
    Args:
        travel_id: Identifiant du voyage
        participants: Nombre de participants
        
    Returns:
        Prix total calculé
        
    Raises:
        ValueError: Si le voyage n'existe pas
    """
    pass
```

### Commentaires

- Expliquer le **pourquoi**, pas le **comment**
- Éviter les commentaires redondants
- Utiliser des commentaires pour la logique complexe

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

---

**Version** : 2.0  
**Date** : 2025-01-20  
**Mise à jour** : Ajout de la section sur l'utilisation des fonctions SQL
