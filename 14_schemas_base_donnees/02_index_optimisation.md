# Index et Optimisation MySQL

## Index Existants

### Index sur Clés Étrangères

Tous les index sur les clés étrangères sont créés automatiquement pour optimiser les jointures :

```sql
-- Exemples
CREATE INDEX idx_travels_teacher_id ON travels(teacher_id);
CREATE INDEX idx_travels_destination_id ON travels(destination_id);
```

### Index sur Champs de Recherche

```sql
-- Recherche par email
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_teachers_email ON teachers(email);
CREATE INDEX idx_guests_email ON guests(email);

-- Recherche par statut
CREATE INDEX idx_travels_status ON travels(status);
CREATE INDEX idx_quotes_status ON quotes(status);
CREATE INDEX idx_invoices_status ON invoices(status);
```

### Index sur Dates

```sql
-- Requêtes temporelles
CREATE INDEX idx_travels_dates ON travels(start_date, end_date);
CREATE INDEX idx_transport_prices_date ON transport_prices(date);
```

### Index Composites

```sql
-- Recherches fréquentes
CREATE INDEX idx_travel_status_type ON travels(status, travel_type);
CREATE INDEX idx_quote_travel_status ON quotes(travel_id, status);
```

## Stratégies d'Optimisation

### 1. Analyse des Requêtes Lentes

Utiliser `EXPLAIN` pour analyser les requêtes :

```sql
EXPLAIN SELECT * FROM travels 
WHERE status = 'draft' 
AND travel_type = 'school';
```

### 2. Index Manquants

Identifier les index manquants avec `EXPLAIN` :

```sql
-- Si "Using filesort" ou "Using temporary" apparaît
-- Créer un index approprié
CREATE INDEX idx_travels_status_type ON travels(status, travel_type);
```

### 3. Optimisation des Jointures

- Toujours avoir des index sur les clés étrangères
- Utiliser `INNER JOIN` plutôt que `WHERE` pour les jointures
- Éviter les `SELECT *`, sélectionner uniquement les colonnes nécessaires

### 4. Pagination Efficace

```sql
-- Utiliser LIMIT avec OFFSET pour la pagination
SELECT * FROM travels 
ORDER BY created_at DESC 
LIMIT 50 OFFSET 0;

-- Pour de grandes paginations, utiliser WHERE id > last_id
SELECT * FROM travels 
WHERE id > 100 
ORDER BY id 
LIMIT 50;
```

## Configuration MySQL

### my.cnf Recommandé

```ini
[mysqld]
# Charset
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci

# Moteur
default-storage-engine=InnoDB

# Buffer Pool (ajuster selon RAM disponible)
innodb_buffer_pool_size=1G

# Connexions
max_connections=200
max_connect_errors=10

# Timeouts
wait_timeout=28800
interactive_timeout=28800

# Logs
slow_query_log=1
slow_query_log_file=/var/log/mysql/slow.log
long_query_time=2

# Performance
innodb_flush_log_at_trx_commit=2
innodb_log_file_size=256M
```

### Variables à Ajuster

- **innodb_buffer_pool_size** : 70-80% de la RAM disponible
- **max_connections** : Selon le nombre d'utilisateurs simultanés
- **query_cache_size** : Désactivé sur MySQL 8.0+ (remplacé par cache applicatif)

## Requêtes Lentes et Solutions

### Problème 1 : Liste des Voyages Lente

**Requête** :
```sql
SELECT * FROM travels ORDER BY created_at DESC;
```

**Solution** :
```sql
CREATE INDEX idx_travels_created_at ON travels(created_at DESC);
```

### Problème 2 : Recherche par Statut Lente

**Requête** :
```sql
SELECT * FROM travels WHERE status = 'draft';
```

**Solution** :
```sql
-- Index déjà créé
-- Vérifier avec EXPLAIN
EXPLAIN SELECT * FROM travels WHERE status = 'draft';
```

### Problème 3 : Jointures Multiples

**Requête** :
```sql
SELECT t.*, d.name, te.name 
FROM travels t
JOIN destinations d ON t.destination_id = d.id
JOIN teachers te ON t.teacher_id = te.id;
```

**Solution** :
- Vérifier que les index existent sur les clés étrangères
- Utiliser `EXPLAIN` pour vérifier l'utilisation des index

## Maintenance

### ANALYZE TABLE

Analyser les tables régulièrement pour optimiser les index :

```sql
ANALYZE TABLE travels;
ANALYZE TABLE invoices;
ANALYZE TABLE quotes;
```

### OPTIMIZE TABLE

Optimiser les tables après suppressions importantes :

```sql
OPTIMIZE TABLE travels;
```

### Vérification des Index

```sql
-- Voir tous les index d'une table
SHOW INDEX FROM travels;

-- Voir les index non utilisés
SELECT * FROM sys.schema_unused_indexes;
```

## Monitoring

### Requêtes Lentes

Activer le log des requêtes lentes :

```sql
SET GLOBAL slow_query_log = 'ON';
SET GLOBAL long_query_time = 2;
```

### Performance Schema

Utiliser Performance Schema pour analyser les performances :

```sql
-- Activer Performance Schema
UPDATE performance_schema.setup_instruments 
SET ENABLED = 'YES' 
WHERE NAME LIKE 'statement/%';
```

---

**Version** : 1.0  
**Date** : 2025-01-20
