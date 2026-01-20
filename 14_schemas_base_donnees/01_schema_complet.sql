-- Schéma SQL Complet - Système Intégré de Gestion
-- Base de données : MySQL 8.0+
-- Moteur : InnoDB
-- Charset : utf8mb4
-- Collation : utf8mb4_unicode_ci

-- Créer la base de données
CREATE DATABASE IF NOT EXISTS gestion_db 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;

USE gestion_db;

-- ============================================
-- AUTHENTIFICATION & AUTORISATION
-- ============================================

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

CREATE TABLE roles (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) UNIQUE NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_roles_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE permissions (
    id INT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    resource VARCHAR(100) NOT NULL,
    INDEX idx_permissions_code (code),
    INDEX idx_permissions_resource (resource)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE user_roles (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    INDEX idx_user_roles_user_id (user_id),
    INDEX idx_user_roles_role_id (role_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE user_permissions (
    user_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (user_id, permission_id),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    INDEX idx_user_permissions_user_id (user_id),
    INDEX idx_user_permissions_permission_id (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE role_permissions (
    role_id INT NOT NULL,
    permission_id INT NOT NULL,
    PRIMARY KEY (role_id, permission_id),
    FOREIGN KEY (role_id) REFERENCES roles(id) ON DELETE CASCADE,
    FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE,
    INDEX idx_role_permissions_role_id (role_id),
    INDEX idx_role_permissions_permission_id (permission_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE two_factor_auth (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNIQUE NOT NULL,
    secret VARCHAR(255) NOT NULL,
    is_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_two_factor_auth_user_id (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- ÉTABLISSEMENTS SCOLAIRES
-- ============================================

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
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_schools_email_primary (email_primary),
    INDEX idx_schools_whatsapp_phone_primary (whatsapp_phone_primary),
    INDEX idx_schools_email_marketing_consent (email_marketing_consent),
    INDEX idx_schools_whatsapp_consent (whatsapp_consent),
    INDEX idx_schools_email_opt_out (email_opt_out_date),
    INDEX idx_schools_whatsapp_opt_out (whatsapp_opt_out_date),
    INDEX idx_schools_city (city),
    INDEX idx_schools_is_active (is_active),
    INDEX idx_schools_odoo_partner_id (odoo_partner_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE school_contact_history (
    id INT AUTO_INCREMENT PRIMARY KEY,
    school_id INT NOT NULL,
    contact_type ENUM('email', 'whatsapp') NOT NULL,
    action ENUM('opt_in', 'opt_out', 'consent_given', 'consent_withdrawn', 'message_sent', 'bounce', 'verification') NOT NULL,
    details JSON,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE,
    INDEX idx_school_contact_history_school_id (school_id),
    INDEX idx_school_contact_history_contact_type (contact_type),
    INDEX idx_school_contact_history_created_at (created_at),
    INDEX idx_school_contact_history_school_type (school_id, contact_type, created_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ============================================
-- PROFESSEURS & VOYAGES
-- ============================================

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

-- ============================================
-- TRANSPORT & PRIX
-- ============================================

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

-- ============================================
-- DEVIS
-- ============================================

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

-- ============================================
-- FACTURES
-- ============================================

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

-- ============================================
-- RÉSERVATIONS & CONTACTS
-- ============================================

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

-- ============================================
-- DOCUMENTS
-- ============================================

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

-- ============================================
-- VOYAGES LINGUISTIQUES
-- ============================================

CREATE TABLE guests (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    first_name VARCHAR(100),
    last_name VARCHAR(100),
    phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_guests_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

-- ============================================
-- MIGRATION DES DONNÉES EXISTANTES
-- ============================================

-- Migration des établissements depuis teachers vers schools
-- Ce script crée des écoles à partir des champs texte de teachers
-- et met à jour les références

-- Étape 1 : Créer les écoles à partir des données teachers
INSERT INTO schools (name, city, postal_code, address, created_at)
SELECT DISTINCT
    t.school AS name,
    t.school_city AS city,
    t.school_postal_code AS postal_code,
    t.school_address AS address,
    MIN(t.created_at) AS created_at
FROM teachers t
WHERE t.school IS NOT NULL 
  AND t.school != ''
GROUP BY t.school, t.school_city, t.school_postal_code, t.school_address;

-- Étape 2 : Mettre à jour teachers.school_id avec les nouveaux IDs
UPDATE teachers t
INNER JOIN schools s ON 
    (t.school = s.name OR (t.school IS NULL AND s.name IS NULL))
    AND (t.school_city = s.city OR (t.school_city IS NULL AND s.city IS NULL))
    AND (t.school_postal_code = s.postal_code OR (t.school_postal_code IS NULL AND s.postal_code IS NULL))
SET t.school_id = s.id
WHERE t.school IS NOT NULL AND t.school != '';

-- Note : Après migration, les colonnes school, school_address, school_city, school_postal_code
-- peuvent être supprimées avec ALTER TABLE teachers DROP COLUMN school, etc.
