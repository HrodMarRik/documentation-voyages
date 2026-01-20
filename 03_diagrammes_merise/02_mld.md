# Merise MLD (Modèle Logique de Données) - Système Intégré de Gestion

## Base de Données MySQL

### Configuration

- **Moteur** : InnoDB
- **Charset** : utf8mb4
- **Collation** : utf8mb4_unicode_ci
- **Version MySQL** : 8.0+

## Tables Principales

### Authentification & Autorisation

#### users
```sql
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    last_login TIMESTAMP NULL,
    INDEX idx_users_email (email),
    INDEX idx_users_is_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### roles
```sql
CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_roles_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### permissions
```sql
CREATE TABLE permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    resource VARCHAR(100) NOT NULL,
    INDEX idx_permissions_code (code),
    INDEX idx_permissions_resource (resource)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### user_roles
```sql
CREATE TABLE user_roles (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    INDEX idx_user_roles_user_id (user_id),
    INDEX idx_user_roles_role_id (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### user_permissions
```sql
CREATE TABLE user_permissions (
    user_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (user_id, permission_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    INDEX idx_user_permissions_user_id (user_id),
    INDEX idx_user_permissions_permission_id (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### role_permissions
```sql
CREATE TABLE role_permissions (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    INDEX idx_role_permissions_role_id (role_id),
    INDEX idx_role_permissions_permission_id (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### two_factor_auth
```sql
CREATE TABLE two_factor_auth (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE NOT NULL,
    secret VARCHAR(255) NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_two_factor_auth_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Professeurs & Voyages

#### teachers
```sql
CREATE TABLE teachers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone VARCHAR(50),
    school VARCHAR(255),
    school_address VARCHAR(255),
    school_city VARCHAR(100),
    school_postal_code VARCHAR(20),
    odoo_partner_id INT,
    odoo_contact_id INT,
    form_data JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_teachers_email (email),
    INDEX idx_teachers_odoo_partner_id (odoo_partner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### travels
```sql
CREATE TABLE travels (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    travel_type ENUM('school', 'linguistic_group') NOT NULL,
    destination_id INT,
    program_template_id INT,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    min_participants INT,
    max_participants INT,
    number_participants INT,
    status ENUM('draft', 'quote_sent', 'quote_validated', 'confirmed', 'in_progress', 'completed', 'cancelled') NOT NULL DEFAULT 'draft',
    total_price DECIMAL(10,2) NOT NULL DEFAULT 0.0,
    teacher_id INT,
    odoo_lead_id INT,
    odoo_quote_id INT,
    odoo_invoice_id INT,
    parent_contacts_collected BOOLEAN NOT NULL DEFAULT FALSE,
    created_by_user_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE SET NULL,
    FOREIGN KEY (program_template_id) REFERENCES program_templates(id) ON DELETE SET NULL,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE SET NULL,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_travels_teacher_id (teacher_id),
    INDEX idx_travels_created_by_user_id (created_by_user_id),
    INDEX idx_travels_status (status),
    INDEX idx_travels_travel_type (travel_type),
    INDEX idx_travels_dates (start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### travel_status_history
```sql
CREATE TABLE travel_status_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    travel_id INT NOT NULL,
    from_status VARCHAR(50),
    to_status VARCHAR(50) NOT NULL,
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    changed_by INT,
    FOREIGN KEY (travel_id) REFERENCES travels(id) ON DELETE CASCADE,
    FOREIGN KEY (changed_by) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_travel_status_history_travel_id (travel_id),
    INDEX idx_travel_status_history_changed_at (changed_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### teacher_forms
```sql
CREATE TABLE teacher_forms (
    id INT AUTO_INCREMENT PRIMARY KEY,
    token VARCHAR(255) UNIQUE NOT NULL,
    teacher_email VARCHAR(255),
    contact_email VARCHAR(255),
    source VARCHAR(50) NOT NULL,
    form_data JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_teacher_forms_token (token)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Destinations & Activités

#### destinations
```sql
CREATE TABLE destinations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    country VARCHAR(100),
    city VARCHAR(100),
    base_price DECIMAL(10,2) NOT NULL,
    description TEXT,
    images JSON,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_destinations_is_active (is_active),
    INDEX idx_destinations_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### activity_templates
```sql
CREATE TABLE activity_templates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    duration_hours FLOAT,
    base_price DECIMAL(10,2) NOT NULL,
    activity_type VARCHAR(100),
    location VARCHAR(255),
    is_reusable BOOLEAN NOT NULL DEFAULT TRUE,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_activity_templates_is_reusable (is_reusable)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### activities
```sql
CREATE TABLE activities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    travel_id INT NOT NULL,
    activity_template_id INT,
    date DATETIME NOT NULL,
    start_time VARCHAR(10),
    end_time VARCHAR(10),
    location VARCHAR(255),
    price_per_person DECIMAL(10,2) DEFAULT 0.0,
    activity_type VARCHAR(100),
    custom_name VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (travel_id) REFERENCES travels(id) ON DELETE CASCADE,
    FOREIGN KEY (activity_template_id) REFERENCES activity_templates(id) ON DELETE SET NULL,
    INDEX idx_activities_travel_id (travel_id),
    INDEX idx_activities_date (date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### travel_destinations
```sql
CREATE TABLE travel_destinations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    travel_id INT NOT NULL,
    destination_id INT NOT NULL,
    quote_price DECIMAL(10,2),
    FOREIGN KEY (travel_id) REFERENCES travels(id) ON DELETE CASCADE,
    FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE CASCADE,
    INDEX idx_travel_destinations_travel_id (travel_id),
    INDEX idx_travel_destinations_destination_id (destination_id),
    UNIQUE KEY unique_travel_destination (travel_id, destination_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Plannings

#### program_templates
```sql
CREATE TABLE program_templates (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    destination_id INT NOT NULL,
    duration_days INT,
    description TEXT,
    base_price_per_day DECIMAL(10,2),
    meals_included BOOLEAN NOT NULL DEFAULT FALSE,
    created_by INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE CASCADE,
    INDEX idx_program_templates_destination_id (destination_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### program_activities
```sql
CREATE TABLE program_activities (
    id INT AUTO_INCREMENT PRIMARY KEY,
    program_id INT NOT NULL,
    activity_template_id INT NOT NULL,
    order_index INT DEFAULT 0,
    FOREIGN KEY (program_id) REFERENCES program_templates(id) ON DELETE CASCADE,
    FOREIGN KEY (activity_template_id) REFERENCES activity_templates(id) ON DELETE CASCADE,
    INDEX idx_program_activities_program_id (program_id),
    INDEX idx_program_activities_order (program_id, order_index)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Transport & Prix

#### transport_prices
```sql
CREATE TABLE transport_prices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    destination_id INT NOT NULL,
    date DATE NOT NULL,
    price_per_person DECIMAL(10,2) NOT NULL,
    transport_type VARCHAR(100),
    min_participants INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE CASCADE,
    INDEX idx_transport_prices_destination_id (destination_id),
    INDEX idx_transport_prices_date (date),
    UNIQUE KEY unique_destination_date (destination_id, date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Devis

#### quotes
```sql
CREATE TABLE quotes (
    id INT AUTO_INCREMENT PRIMARY KEY,
    travel_id INT NOT NULL,
    quote_number VARCHAR(100) UNIQUE NOT NULL,
    status VARCHAR(50) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    created_by_user_id INT,
    validated_by_user_id INT,
    sent_at TIMESTAMP NULL,
    validated_at TIMESTAMP NULL,
    expires_at TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (travel_id) REFERENCES travels(id) ON DELETE CASCADE,
    FOREIGN KEY (created_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    FOREIGN KEY (validated_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_quotes_travel_id (travel_id),
    INDEX idx_quotes_status (status),
    INDEX idx_quotes_quote_number (quote_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### quote_lines
```sql
CREATE TABLE quote_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    quote_id INT NOT NULL,
    description VARCHAR(255) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(10,2) NOT NULL,
    line_type VARCHAR(50),
    FOREIGN KEY (quote_id) REFERENCES quotes(id) ON DELETE CASCADE,
    INDEX idx_quote_lines_quote_id (quote_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Factures

#### invoices
```sql
CREATE TABLE invoices (
    id INT AUTO_INCREMENT PRIMARY KEY,
    travel_id INT NOT NULL,
    invoice_number VARCHAR(100) UNIQUE NOT NULL,
    status VARCHAR(50) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) NOT NULL,
    e_invoice_data JSON,
    validated_by_user_id INT,
    validated_at TIMESTAMP NULL,
    issued_at TIMESTAMP NULL,
    due_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (travel_id) REFERENCES travels(id) ON DELETE CASCADE,
    FOREIGN KEY (validated_by_user_id) REFERENCES users(id) ON DELETE SET NULL,
    INDEX idx_invoices_travel_id (travel_id),
    INDEX idx_invoices_status (status),
    INDEX idx_invoices_invoice_number (invoice_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### invoice_lines
```sql
CREATE TABLE invoice_lines (
    id INT AUTO_INCREMENT PRIMARY KEY,
    invoice_id INT NOT NULL,
    description VARCHAR(255) NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    line_total DECIMAL(10,2) NOT NULL,
    tax_rate DECIMAL(5,2),
    FOREIGN KEY (invoice_id) REFERENCES invoices(id) ON DELETE CASCADE,
    INDEX idx_invoice_lines_invoice_id (invoice_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Réservations & Contacts

#### bookings
```sql
CREATE TABLE bookings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    travel_id INT NOT NULL,
    participant_name VARCHAR(255) NOT NULL,
    age INT,
    email VARCHAR(255),
    phone VARCHAR(50),
    price DECIMAL(10,2) NOT NULL,
    status ENUM('pending', 'confirmed', 'cancelled') NOT NULL DEFAULT 'pending',
    payment_status ENUM('pending', 'paid', 'failed', 'refunded') NOT NULL DEFAULT 'pending',
    payment_id VARCHAR(255),
    odoo_partner_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (travel_id) REFERENCES travels(id) ON DELETE CASCADE,
    INDEX idx_bookings_travel_id (travel_id),
    INDEX idx_bookings_status (status),
    INDEX idx_bookings_payment_status (payment_status)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### parent_contacts
```sql
CREATE TABLE parent_contacts (
    id INT AUTO_INCREMENT PRIMARY KEY,
    booking_id INT NOT NULL,
    parent_name VARCHAR(255) NOT NULL,
    parent_email VARCHAR(255),
    parent_phone VARCHAR(50),
    relationship_type VARCHAR(50),
    is_optional BOOLEAN DEFAULT TRUE,
    collected_date TIMESTAMP NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (booking_id) REFERENCES bookings(id) ON DELETE CASCADE,
    INDEX idx_parent_contacts_booking_id (booking_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Documents

#### travel_documents
```sql
CREATE TABLE travel_documents (
    id INT AUTO_INCREMENT PRIMARY KEY,
    travel_id INT NOT NULL,
    filename VARCHAR(255) NOT NULL,
    mime_type VARCHAR(100) NOT NULL,
    file_size INT NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    document_type VARCHAR(100),
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (travel_id) REFERENCES travels(id) ON DELETE CASCADE,
    INDEX idx_travel_documents_travel_id (travel_id),
    INDEX idx_travel_documents_document_type (document_type)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

### Voyages Linguistiques

#### guests
```sql
CREATE TABLE guests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_guests_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### linguistic_travels
```sql
CREATE TABLE linguistic_travels (
    id INT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(255) NOT NULL,
    description TEXT,
    destination_id INT,
    start_date DATETIME NOT NULL,
    end_date DATETIME NOT NULL,
    price_per_person DECIMAL(10,2) NOT NULL,
    max_participants INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (destination_id) REFERENCES destinations(id) ON DELETE SET NULL,
    INDEX idx_linguistic_travels_destination_id (destination_id),
    INDEX idx_linguistic_travels_dates (start_date, end_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### linguistic_travel_registrations
```sql
CREATE TABLE linguistic_travel_registrations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    guest_id INT NOT NULL,
    linguistic_travel_id INT NOT NULL,
    status VARCHAR(50) NOT NULL,
    registered_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (guest_id) REFERENCES guests(id) ON DELETE CASCADE,
    FOREIGN KEY (linguistic_travel_id) REFERENCES linguistic_travels(id) ON DELETE CASCADE,
    INDEX idx_linguistic_travel_registrations_guest_id (guest_id),
    INDEX idx_linguistic_travel_registrations_linguistic_travel_id (linguistic_travel_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

## Contraintes d'Intégrité Référentielle

Toutes les clés étrangères sont définies avec :
- `ON DELETE CASCADE` : Pour les relations où la suppression du parent doit supprimer les enfants
- `ON DELETE SET NULL` : Pour les relations optionnelles

## Index pour Optimisation

Les index suivants sont créés pour optimiser les requêtes fréquentes :
- Index sur les clés étrangères
- Index sur les champs de recherche (email, nom, statut)
- Index sur les dates pour les requêtes temporelles
- Index composites pour les requêtes complexes

## Types de Données MySQL

- **INT** : Entiers (auto-increment pour PK)
- **VARCHAR(n)** : Chaînes de caractères de longueur variable
- **TEXT** : Texte long
- **DECIMAL(p,s)** : Nombres décimaux précis (p=précision, s=échelle)
- **FLOAT** : Nombres à virgule flottante
- **BOOLEAN** : Booléen (stocké comme TINYINT(1))
- **ENUM** : Énumération de valeurs
- **JSON** : Données JSON (MySQL 5.7+)
- **TIMESTAMP** : Date et heure
- **DATE** : Date uniquement
- **DATETIME** : Date et heure (plus flexible que TIMESTAMP)

---

**Version** : 1.0  
**Date** : 2025-01-20  
**Base de données** : MySQL 8.0+
