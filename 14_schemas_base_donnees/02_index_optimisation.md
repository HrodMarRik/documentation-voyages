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
CREATE INDEX idx_schools_city ON schools(city);
CREATE INDEX idx_schools_is_active ON schools(is_active);

-- Index pour contacts (mailing et WhatsApp)
CREATE INDEX idx_contacts_school_id ON contacts(school_id);
CREATE INDEX idx_contacts_email_primary ON contacts(email_primary);
CREATE INDEX idx_contacts_whatsapp_phone_primary ON contacts(whatsapp_phone_primary);
CREATE INDEX idx_contacts_email_marketing_consent ON contacts(email_marketing_consent);
CREATE INDEX idx_contacts_whatsapp_consent ON contacts(whatsapp_consent);
CREATE INDEX idx_contacts_email_opt_out ON contacts(email_opt_out_date);
CREATE INDEX idx_contacts_whatsapp_opt_out ON contacts(whatsapp_opt_out_date);
CREATE INDEX idx_contacts_is_active ON contacts(is_active);
CREATE INDEX idx_contacts_is_primary ON contacts(is_primary);

-- Index pour historique des contacts
CREATE INDEX idx_contact_history_contact_id ON contact_history(contact_id);
CREATE INDEX idx_contact_history_contact_type ON contact_history(contact_type);
CREATE INDEX idx_contact_history_created_at ON contact_history(created_at);
CREATE INDEX idx_contact_history_contact_type_date ON contact_history(contact_id, contact_type, created_at);
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

### Mailing - Contacts avec Consentement

```sql
-- Contacts actifs avec consentement email et pas d'opt-out, liés à des écoles
SELECT 
    c.*,
    s.name as school_name,
    s.city as school_city,
    COUNT(t.id) as teacher_count
FROM contacts c
INNER JOIN schools s ON s.id = c.school_id
LEFT JOIN teachers t ON t.school_id = s.id
WHERE c.is_active = TRUE
  AND s.is_active = TRUE
  AND c.email_marketing_consent = TRUE
  AND c.email_opt_out_date IS NULL
  AND c.email_primary IS NOT NULL
  AND c.email_primary != ''
GROUP BY c.id, s.name, s.city
ORDER BY teacher_count DESC;

-- Contacts par ville avec consentement
SELECT s.city, COUNT(DISTINCT c.id) as contact_count
FROM contacts c
INNER JOIN schools s ON s.id = c.school_id
WHERE c.is_active = TRUE
  AND s.is_active = TRUE
  AND c.email_marketing_consent = TRUE
  AND c.email_opt_out_date IS NULL
GROUP BY s.city
ORDER BY contact_count DESC;
```

### WhatsApp - Contacts avec Consentement

```sql
-- Contacts actifs avec consentement WhatsApp et vérifiés, liés à des écoles
SELECT 
    c.*,
    s.name as school_name,
    s.city as school_city,
    COUNT(t.id) as teacher_count
FROM contacts c
INNER JOIN schools s ON s.id = c.school_id
LEFT JOIN teachers t ON t.school_id = s.id
WHERE c.is_active = TRUE
  AND s.is_active = TRUE
  AND c.whatsapp_consent = TRUE
  AND c.whatsapp_verified = TRUE
  AND c.whatsapp_opt_out_date IS NULL
  AND c.whatsapp_phone_primary IS NOT NULL
  AND c.whatsapp_phone_primary != ''
GROUP BY c.id, s.name, s.city
ORDER BY teacher_count DESC;

-- Contacts avec numéro WhatsApp mais non vérifiés
SELECT 
    c.id,
    c.contact_name,
    c.whatsapp_phone_primary,
    s.name as school_name,
    s.city
FROM contacts c
INNER JOIN schools s ON s.id = c.school_id
WHERE c.is_active = TRUE
  AND s.is_active = TRUE
  AND c.whatsapp_phone_primary IS NOT NULL
  AND c.whatsapp_phone_primary != ''
  AND c.whatsapp_verified = FALSE
ORDER BY c.created_at DESC;
```

### Statistiques de Prospection

```sql
-- Statistiques globales de prospection (par contacts)
SELECT 
    COUNT(DISTINCT s.id) as total_schools,
    COUNT(DISTINCT c.id) as total_contacts,
    SUM(CASE WHEN c.email_marketing_consent = TRUE AND c.email_opt_out_date IS NULL THEN 1 ELSE 0 END) as email_consent_count,
    SUM(CASE WHEN c.whatsapp_consent = TRUE AND c.whatsapp_opt_out_date IS NULL THEN 1 ELSE 0 END) as whatsapp_consent_count,
    SUM(CASE WHEN c.whatsapp_verified = TRUE THEN 1 ELSE 0 END) as whatsapp_verified_count,
    SUM(CASE WHEN c.email_bounce_count > 0 THEN 1 ELSE 0 END) as email_bounce_count
FROM schools s
LEFT JOIN contacts c ON c.school_id = s.id
WHERE s.is_active = TRUE
  AND (c.is_active = TRUE OR c.id IS NULL);

-- Historique des actions de contact par type
SELECT 
    ch.contact_type,
    ch.action,
    COUNT(*) as action_count,
    DATE(ch.created_at) as action_date
FROM contact_history ch
INNER JOIN contacts c ON c.id = ch.contact_id
WHERE ch.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY ch.contact_type, ch.action, DATE(ch.created_at)
ORDER BY action_date DESC, ch.contact_type, ch.action;
```

### Requêtes Optimisées avec Jointures

```sql
-- Établissements avec leurs contacts, professeurs et voyages
SELECT 
    s.id as school_id,
    s.name as school_name,
    s.city,
    c.contact_name,
    c.email_primary,
    c.whatsapp_phone_primary,
    COUNT(DISTINCT t.id) as teacher_count,
    COUNT(DISTINCT tr.id) as travel_count,
    COUNT(DISTINCT b.id) as booking_count
FROM schools s
LEFT JOIN contacts c ON c.school_id = s.id AND c.is_active = TRUE AND c.is_primary = TRUE
LEFT JOIN teachers t ON t.school_id = s.id
LEFT JOIN travels tr ON tr.teacher_id = t.id
LEFT JOIN bookings b ON b.school_id = s.id
WHERE s.is_active = TRUE
  AND (c.email_marketing_consent = TRUE AND c.email_opt_out_date IS NULL OR c.id IS NULL)
GROUP BY s.id, s.name, s.city, c.contact_name, c.email_primary, c.whatsapp_phone_primary
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
ANALYZE TABLE contacts;
ANALYZE TABLE contact_history;
```

### OPTIMIZE TABLE

Optimiser les tables après suppressions importantes :

```sql
OPTIMIZE TABLE travels;
OPTIMIZE TABLE schools;
OPTIMIZE TABLE contacts;
OPTIMIZE TABLE contact_history;
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
