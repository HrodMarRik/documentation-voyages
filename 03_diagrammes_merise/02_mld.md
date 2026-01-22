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

### Établissements Scolaires

#### schools
```sql
CREATE TABLE schools (
 id INT AUTO_INCREMENT PRIMARY KEY,
 name VARCHAR(255) NOT NULL,
 school_type ENUM('primary', 'middle', 'high', 'college', 'other') DEFAULT 'other',
 address VARCHAR(255),
 city VARCHAR(100),
 postal_code VARCHAR(20),
 country VARCHAR(100) DEFAULT 'France',
 phone VARCHAR(50),
 website VARCHAR(255),
 -- Intégration Odoo
 odoo_partner_id INT,
 odoo_contact_id INT,
 -- Métadonnées
 is_active BOOLEAN NOT NULL DEFAULT TRUE,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 INDEX idx_schools_city (city),
 INDEX idx_schools_is_active (is_active),
 INDEX idx_schools_odoo_partner_id (odoo_partner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### contacts
```sql
CREATE TABLE contacts (
 id INT AUTO_INCREMENT PRIMARY KEY,
 school_id INT,
 contact_name VARCHAR(255),
 contact_role VARCHAR(100),
 -- Mailing avancé
 email_primary VARCHAR(255),
 email_secondary VARCHAR(255),
 email_marketing_consent BOOLEAN NOT NULL DEFAULT FALSE,
 email_consent_date TIMESTAMP NULL,
 email_opt_in_date TIMESTAMP NULL,
 email_opt_out_date TIMESTAMP NULL,
 email_preferences JSON,
 email_bounce_count INT NOT NULL DEFAULT 0,
 email_last_sent TIMESTAMP NULL,
 -- WhatsApp avancé
 whatsapp_phone_primary VARCHAR(50),
 whatsapp_phone_secondary VARCHAR(50),
 whatsapp_consent BOOLEAN NOT NULL DEFAULT FALSE,
 whatsapp_consent_date TIMESTAMP NULL,
 whatsapp_opt_in_date TIMESTAMP NULL,
 whatsapp_opt_out_date TIMESTAMP NULL,
 whatsapp_verified BOOLEAN NOT NULL DEFAULT FALSE,
 whatsapp_verification_date TIMESTAMP NULL,
 whatsapp_template_preferences JSON,
 whatsapp_last_contact TIMESTAMP NULL,
 -- Intégration Odoo
 odoo_partner_id INT,
 odoo_contact_id INT,
 -- Métadonnées
 is_active BOOLEAN NOT NULL DEFAULT TRUE,
 is_primary BOOLEAN NOT NULL DEFAULT FALSE,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE SET NULL,
 INDEX idx_contacts_school_id (school_id),
 INDEX idx_contacts_email_primary (email_primary),
 INDEX idx_contacts_whatsapp_phone_primary (whatsapp_phone_primary),
 INDEX idx_contacts_email_marketing_consent (email_marketing_consent),
 INDEX idx_contacts_whatsapp_consent (whatsapp_consent),
 INDEX idx_contacts_email_opt_out (email_opt_out_date),
 INDEX idx_contacts_whatsapp_opt_out (whatsapp_opt_out_date),
 INDEX idx_contacts_is_active (is_active),
 INDEX idx_contacts_is_primary (is_primary),
 INDEX idx_contacts_odoo_partner_id (odoo_partner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

#### contact_history
```sql
CREATE TABLE contact_history (
 id INT AUTO_INCREMENT PRIMARY KEY,
 contact_id INT NOT NULL,
 contact_type ENUM('email', 'whatsapp') NOT NULL,
 action ENUM('opt_in', 'opt_out', 'consent_given', 'consent_withdrawn', 'message_sent', 'bounce', 'verification') NOT NULL,
 details JSON,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 FOREIGN KEY (contact_id) REFERENCES contacts(id) ON DELETE CASCADE,
 INDEX idx_contact_history_contact_id (contact_id),
 INDEX idx_contact_history_contact_type (contact_type),
 INDEX idx_contact_history_created_at (created_at),
 INDEX idx_contact_history_contact_type_date (contact_id, contact_type, created_at)
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
 school_id INT,
 odoo_partner_id INT,
 odoo_contact_id INT,
 form_data JSON,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
 FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE SET NULL,
 INDEX idx_teachers_email (email),
 INDEX idx_teachers_school_id (school_id),
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
 school_id INT,
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
 FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE SET NULL,
 INDEX idx_bookings_travel_id (travel_id),
 INDEX idx_bookings_school_id (school_id),
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

## Fonctions SQL Stockées

Le modèle logique inclut des fonctions SQL stockées et des procédures stockées qui encapsulent la logique métier. Ces fonctions sont organisées par domaine et sont associées aux tables correspondantes.

### Fonctions par Table/Domaine

#### Table `travels`

**Fonctions de calcul de prix** :
```sql
-- Calcul du prix de transport
calculate_transport_price(travel_id INT, participants INT) RETURNS DECIMAL(10,2)

-- Calcul du prix des activités
calculate_activities_price(travel_id INT, participants INT) RETURNS DECIMAL(10,2)

-- Calcul du prix de l'hébergement
calculate_lodging_price(travel_id INT, participants INT) RETURNS DECIMAL(10,2)

-- Calcul du prix de base (transport + activités + hébergement)
calculate_base_price(travel_id INT, participants INT) RETURNS DECIMAL(10,2)

-- Calcul du prix final avec réductions et marge
calculate_final_travel_price(travel_id INT) RETURNS DECIMAL(10,2)
```

**Fonctions de validation** :
```sql
-- Vérifie si un devis peut être généré
can_generate_quote(travel_id INT) RETURNS BOOLEAN

-- Vérifie si une facture peut être générée
can_generate_invoice(travel_id INT) RETURNS BOOLEAN

-- Vérifie si le voyage peut être confirmé
is_travel_valid_for_confirmation(travel_id INT) RETURNS BOOLEAN
```

**Fonctions temporelles** :
```sql
-- Jours avant le départ
days_until_departure(travel_id INT) RETURNS INT

-- Durée du voyage en jours
travel_duration_days(travel_id INT) RETURNS INT

-- Durée du voyage en nuits
travel_duration_nights(travel_id INT) RETURNS INT

-- Vérifie si le voyage est terminé
is_travel_in_past(travel_id INT) RETURNS BOOLEAN

-- Vérifie si le voyage est en cours
is_travel_in_progress(travel_id INT) RETURNS BOOLEAN

-- Vérifie si le voyage est à venir
is_travel_upcoming(travel_id INT) RETURNS BOOLEAN
```

**Fonctions de participants** :
```sql
-- Nombre actuel de participants
get_travel_participant_count(travel_id INT) RETURNS INT

-- Nombre de places disponibles
get_available_spots(travel_id INT) RETURNS INT

-- Vérifie si le voyage est complet
is_travel_full(travel_id INT) RETURNS BOOLEAN

-- Taux de remplissage
get_participant_fill_rate(travel_id INT) RETURNS DECIMAL(5,2)
```

**Fonctions de contacts parents** :
```sql
-- Nombre de contacts parents collectés
get_parent_contacts_count(travel_id INT) RETURNS INT

-- Nombre attendu de contacts parents
get_expected_parent_contacts_count(travel_id INT) RETURNS INT

-- Vérifie si tous les contacts sont collectés
are_all_parent_contacts_collected(travel_id INT) RETURNS BOOLEAN

-- Nombre de contacts manquants
get_missing_parent_contacts_count(travel_id INT) RETURNS INT
```

**Procédures** :
```sql
-- Met à jour le statut avec historique
sp_update_travel_status(IN travel_id INT, IN new_status VARCHAR(50), IN user_id INT)

-- Marque les contacts parents comme collectés
sp_collect_parent_contacts(IN travel_id INT)

-- Recalcule tous les totaux
sp_update_travel_totals(IN travel_id INT)
```

#### Table `quotes`

**Fonctions de validation** :
```sql
-- Vérifie si un devis peut être validé
can_validate_quote(quote_id INT) RETURNS BOOLEAN

-- Vérifie si un devis est expiré
is_quote_expired(quote_id INT) RETURNS BOOLEAN

-- Jours restants avant expiration
days_until_quote_expiry(quote_id INT) RETURNS INT

-- Retourne le statut actuel
get_quote_status(quote_id INT) RETURNS VARCHAR(50)

-- Vérifie si le devis peut être envoyé
can_send_quote(quote_id INT) RETURNS BOOLEAN
```

**Fonctions de calcul** :
```sql
-- Total du devis (somme des lignes)
get_quote_total(quote_id INT) RETURNS DECIMAL(10,2)

-- Total pour un type de ligne
calculate_quote_line_total(quote_id INT, line_type VARCHAR(50)) RETURNS DECIMAL(10,2)

-- Montant de la réduction
get_quote_discount_amount(quote_id INT) RETURNS DECIMAL(10,2)

-- Montant final après réductions
get_quote_final_amount(quote_id INT) RETURNS DECIMAL(10,2)
```

**Fonctions de génération** :
```sql
-- Génère un numéro de devis unique
generate_quote_number() RETURNS VARCHAR(100)
```

**Procédures** :
```sql
-- Génère automatiquement un devis complet
sp_generate_quote_for_travel(IN travel_id INT, OUT quote_id INT)
```

#### Table `invoices`

**Fonctions de statut** :
```sql
-- Vérifie si une facture est payée
is_invoice_paid(invoice_id INT) RETURNS BOOLEAN

-- Vérifie si une facture est en retard
is_invoice_overdue(invoice_id INT) RETURNS BOOLEAN

-- Jours restants avant échéance
days_until_invoice_due(invoice_id INT) RETURNS INT

-- Vérifie si une facture peut être validée
can_validate_invoice(invoice_id INT) RETURNS BOOLEAN
```

**Fonctions de calcul** :
```sql
-- Total HT
get_invoice_total_ht(invoice_id INT) RETURNS DECIMAL(10,2)

-- Total TTC
get_invoice_total_ttc(invoice_id INT) RETURNS DECIMAL(10,2)

-- Montant de TVA
get_invoice_tax_amount(invoice_id INT) RETURNS DECIMAL(10,2)

-- Total TTC (avec calcul)
calculate_invoice_total_with_tax(invoice_id INT) RETURNS DECIMAL(10,2)
```

**Fonctions de génération** :
```sql
-- Génère un numéro de facture unique
generate_invoice_number() RETURNS VARCHAR(100)
```

**Fonctions de relation** :
```sql
-- Retourne l'ID du devis source
get_quote_for_invoice(invoice_id INT) RETURNS INT

-- Vérifie si on peut créer une facture depuis un devis
can_create_invoice_from_quote(quote_id INT) RETURNS BOOLEAN
```

**Procédures** :
```sql
-- Génère une facture depuis un devis validé
sp_generate_invoice_from_quote(IN quote_id INT, OUT invoice_id INT)
```

#### Table `contacts`

**Fonctions de consentement** :
```sql
-- Vérifie si on peut envoyer un email marketing
can_send_marketing_email(contact_id INT) RETURNS BOOLEAN

-- Vérifie si on peut envoyer un WhatsApp
can_send_whatsapp(contact_id INT) RETURNS BOOLEAN

-- Vérifie le consentement email
has_email_consent(contact_id INT) RETURNS BOOLEAN

-- Vérifie le consentement WhatsApp
has_whatsapp_consent(contact_id INT) RETURNS BOOLEAN

-- Vérifie si opt-out email
is_contact_opted_out_email(contact_id INT) RETURNS BOOLEAN

-- Vérifie si opt-out WhatsApp
is_contact_opted_out_whatsapp(contact_id INT) RETURNS BOOLEAN
```

**Fonctions de statistiques** :
```sql
-- Taux de bounce
get_email_bounce_rate(contact_id INT) RETURNS DECIMAL(5,2)

-- Jours depuis dernier email
days_since_last_email(contact_id INT) RETURNS INT

-- Jours depuis dernier WhatsApp
days_since_last_whatsapp(contact_id INT) RETURNS INT

-- Score d'engagement
get_contact_engagement_score(contact_id INT) RETURNS INT
```

#### Table `activities`

**Fonctions de validation de planning** :
```sql
-- Vérifie si le planning a au moins une activité
has_valid_planning(travel_id INT) RETURNS BOOLEAN

-- Vérifie si des activités se chevauchent
has_overlapping_activities(travel_id INT) RETURNS BOOLEAN

-- Vérifie si le planning couvre tous les jours
planning_covers_travel_days(travel_id INT) RETURNS BOOLEAN

-- Validation complète du planning
is_planning_valid(travel_id INT) RETURNS BOOLEAN
```

#### Table `bookings`

**Fonctions de validation** :
```sql
-- Vérifie s'il reste des places
has_available_spots(linguistic_travel_id INT) RETURNS BOOLEAN

-- Vérifie si une réservation peut être créée
can_create_booking(linguistic_travel_id INT) RETURNS BOOLEAN

-- Vérifie si le paiement est en retard
is_payment_overdue(booking_id INT) RETURNS BOOLEAN

-- Détermine si la réservation doit être annulée
should_cancel_booking(booking_id INT) RETURNS BOOLEAN
```

**Fonctions de génération** :
```sql
-- Génère un numéro de réservation
generate_booking_number() RETURNS VARCHAR(100)
```

**Procédures** :
```sql
-- Annule les réservations en retard
sp_cancel_overdue_bookings()
```

#### Table `transport_prices`

Utilisée par les fonctions de calcul de prix :
- `calculate_transport_price()` : Utilise cette table pour calculer le prix du transport

#### Table `quote_lines`

Utilisée par les fonctions de calcul de devis :
- `get_quote_total()` : Somme toutes les lignes
- `calculate_quote_line_total()` : Calcule le total par type de ligne

#### Table `invoice_lines`

Utilisée par les fonctions de calcul de factures :
- `get_invoice_total_ht()` : Somme toutes les lignes HT
- `calculate_invoice_total_with_tax()` : Calcule le total TTC

### Exemples d'Utilisation dans les Requêtes

#### Exemple 1 : Calcul du prix d'un voyage

```sql
-- Utiliser la fonction dans une requête SELECT
SELECT 
 id,
 name,
 calculate_final_travel_price(id) AS total_price
FROM travels
WHERE status = 'draft';
```

#### Exemple 2 : Validation avant génération de devis

```sql
-- Vérifier si on peut générer un devis
SELECT 
 id,
 name,
 can_generate_quote(id) AS can_generate
FROM travels
WHERE status = 'draft';
```

#### Exemple 3 : Utilisation dans un WHERE

```sql
-- Filtrer les voyages éligibles à la génération de devis
SELECT *
FROM travels
WHERE can_generate_quote(id) = TRUE;
```

#### Exemple 4 : Appel de procédure stockée

```sql
-- Générer un devis automatiquement
CALL sp_generate_quote_for_travel(123, @quote_id);
SELECT @quote_id AS quote_id;
```

#### Exemple 5 : Calcul avec réductions

```sql
-- Calculer le prix avec toutes les réductions
SELECT 
 id,
 name,
 calculate_base_price(id, number_participants) AS base_price,
 calculate_participant_discount(number_participants) AS discount_rate,
 calculate_travel_price_with_discounts(id, number_participants) AS price_with_discounts
FROM travels
WHERE number_participants IS NOT NULL;
```

### Index Utilisés par les Fonctions

Les fonctions SQL utilisent les index suivants pour optimiser leurs performances :

- **`idx_travels_status`** : Utilisé par `can_generate_quote()`, `can_generate_invoice()`
- **`idx_travels_dates`** : Utilisé par `days_until_departure()`, `is_travel_in_past()`, `is_early_bird()`
- **`idx_travel_destinations_travel_id`** : Utilisé par `calculate_transport_price()`
- **`idx_activities_travel_id`** : Utilisé par `calculate_activities_price()`, `has_valid_planning()`
- **`idx_quotes_travel_id`** : Utilisé par `can_generate_invoice()`
- **`idx_quote_lines_quote_id`** : Utilisé par `get_quote_total()`
- **`idx_contacts_email_marketing_consent`** : Utilisé par `can_send_marketing_email()`
- **`idx_contacts_whatsapp_consent`** : Utilisé par `can_send_whatsapp()`

### Caractéristiques des Fonctions

- **DETERMINISTIC** : Les fonctions de calcul sont déterministes (même résultat pour mêmes paramètres)
- **NOT DETERMINISTIC** : Les fonctions de génération de numéros sont non déterministes
- **READS SQL DATA** : Toutes les fonctions lisent des données (sauf les utilitaires)
- **NO SQL** : Les fonctions utilitaires (formatage, dates) ne contiennent pas de SQL

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
