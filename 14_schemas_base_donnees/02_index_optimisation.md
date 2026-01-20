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

### Index pour Prospection Mailing et WhatsApp

```sql
-- Index pour établissements scolaires
CREATE INDEX idx_schools_email_primary ON schools(email_primary);
CREATE INDEX idx_schools_whatsapp_phone_primary ON schools(whatsapp_phone_primary);
CREATE INDEX idx_schools_email_marketing_consent ON schools(email_marketing_consent);
CREATE INDEX idx_schools_whatsapp_consent ON schools(whatsapp_consent);
CREATE INDEX idx_schools_email_opt_out ON schools(email_opt_out_date);
CREATE INDEX idx_schools_whatsapp_opt_out ON schools(whatsapp_opt_out_date);
CREATE INDEX idx_schools_city ON schools(city);
CREATE INDEX idx_schools_is_active ON schools(is_active);

-- Index pour historique des contacts
CREATE INDEX idx_school_contact_history_school_id ON school_contact_history(school_id);
CREATE INDEX idx_school_contact_history_contact_type ON school_contact_history(contact_type);
CREATE INDEX idx_school_contact_history_created_at ON school_contact_history(created_at);
CREATE INDEX idx_school_contact_history_school_type ON school_contact_history(school_id, contact_type, created_at);
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

## Requêtes de Prospection

### Mailing - Établissements avec Consentement

```sql
-- Établissements actifs avec consentement email et pas d'opt-out
SELECT s.*, COUNT(t.id) as teacher_count
FROM schools s
LEFT JOIN teachers t ON t.school_id = s.id
WHERE s.is_active = TRUE
  AND s.email_marketing_consent = TRUE
  AND s.email_opt_out_date IS NULL
  AND s.email_primary IS NOT NULL
  AND s.email_primary != ''
GROUP BY s.id
ORDER BY teacher_count DESC;

-- Établissements par ville avec consentement
SELECT s.city, COUNT(*) as school_count
FROM schools s
WHERE s.is_active = TRUE
  AND s.email_marketing_consent = TRUE
  AND s.email_opt_out_date IS NULL
GROUP BY s.city
ORDER BY school_count DESC;
```

### WhatsApp - Établissements avec Consentement

```sql
-- Établissements actifs avec consentement WhatsApp et vérifiés
SELECT s.*, COUNT(t.id) as teacher_count
FROM schools s
LEFT JOIN teachers t ON t.school_id = s.id
WHERE s.is_active = TRUE
  AND s.whatsapp_consent = TRUE
  AND s.whatsapp_verified = TRUE
  AND s.whatsapp_opt_out_date IS NULL
  AND s.whatsapp_phone_primary IS NOT NULL
  AND s.whatsapp_phone_primary != ''
GROUP BY s.id
ORDER BY teacher_count DESC;

-- Établissements avec numéro WhatsApp mais non vérifiés
SELECT s.id, s.name, s.whatsapp_phone_primary, s.city
FROM schools s
WHERE s.is_active = TRUE
  AND s.whatsapp_phone_primary IS NOT NULL
  AND s.whatsapp_phone_primary != ''
  AND s.whatsapp_verified = FALSE
ORDER BY s.created_at DESC;
```

### Statistiques de Prospection

```sql
-- Statistiques globales de prospection
SELECT 
    COUNT(*) as total_schools,
    SUM(CASE WHEN email_marketing_consent = TRUE AND email_opt_out_date IS NULL THEN 1 ELSE 0 END) as email_consent_count,
    SUM(CASE WHEN whatsapp_consent = TRUE AND whatsapp_opt_out_date IS NULL THEN 1 ELSE 0 END) as whatsapp_consent_count,
    SUM(CASE WHEN whatsapp_verified = TRUE THEN 1 ELSE 0 END) as whatsapp_verified_count,
    SUM(CASE WHEN email_bounce_count > 0 THEN 1 ELSE 0 END) as email_bounce_count
FROM schools
WHERE is_active = TRUE;

-- Historique des actions de contact par type
SELECT 
    contact_type,
    action,
    COUNT(*) as action_count,
    DATE(created_at) as action_date
FROM school_contact_history
WHERE created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY contact_type, action, DATE(created_at)
ORDER BY action_date DESC, contact_type, action;
```

### Requêtes Optimisées avec Jointures

```sql
-- Établissements avec leurs professeurs et voyages
SELECT 
    s.id as school_id,
    s.name as school_name,
    s.city,
    s.email_primary,
    s.whatsapp_phone_primary,
    COUNT(DISTINCT t.id) as teacher_count,
    COUNT(DISTINCT tr.id) as travel_count,
    COUNT(DISTINCT b.id) as booking_count
FROM schools s
LEFT JOIN teachers t ON t.school_id = s.id
LEFT JOIN travels tr ON tr.teacher_id = t.id
LEFT JOIN bookings b ON b.school_id = s.id
WHERE s.is_active = TRUE
  AND s.email_marketing_consent = TRUE
  AND s.email_opt_out_date IS NULL
GROUP BY s.id, s.name, s.city, s.email_primary, s.whatsapp_phone_primary
HAVING teacher_count > 0
ORDER BY teacher_count DESC, travel_count DESC;
```

## Maintenance

### ANALYZE TABLE

Analyser les tables régulièrement pour optimiser les index :

```sql
ANALYZE TABLE travels;
ANALYZE TABLE invoices;
ANALYZE TABLE quotes;
ANALYZE TABLE schools;
ANALYZE TABLE school_contact_history;
```

### OPTIMIZE TABLE

Optimiser les tables après suppressions importantes :

```sql
OPTIMIZE TABLE travels;
OPTIMIZE TABLE schools;
OPTIMIZE TABLE school_contact_history;
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
