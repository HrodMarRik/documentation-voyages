-- ============================================
-- FONCTIONS SQL STOCKÉES - Implémentation Complète
-- Base de données : MySQL 8.0+
-- Version : 1.0
-- Date : 2025-01-20
-- ============================================
-- 
-- Ce fichier contient toutes les fonctions SQL stockées et procédures stockées
-- pour le système de gestion de voyages.
--
-- IMPORTANT : Exécuter ce fichier APRÈS la création du schéma (01_schema_complet.sql)
--
-- Usage :
--   SOURCE 01_schema_complet.sql;
--   SOURCE 04_fonctions_sql_implementation.sql;
--
-- ============================================

USE gestion_db;

-- ============================================
-- DOMAINE 1 : CALCULS DE PRIX
-- ============================================

DELIMITER $$

-- 1.1 Calculs de Base

CREATE FUNCTION calculate_transport_price(
    p_travel_id INT,
    p_participants INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10,2) DEFAULT 0;
    
    SELECT COALESCE(SUM(tp.price_per_person * p_participants), 0)
    INTO v_total
    FROM travel_destinations td
    JOIN transport_prices tp ON td.destination_id = tp.destination_id
    JOIN travels t ON td.travel_id = t.id
    WHERE td.travel_id = p_travel_id
      AND tp.date BETWEEN DATE(t.start_date) AND DATE(t.end_date);
    
    RETURN v_total;
END$$

CREATE FUNCTION calculate_activities_price(
    p_travel_id INT,
    p_participants INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10,2) DEFAULT 0;
    
    SELECT COALESCE(SUM(price_per_person * p_participants), 0)
    INTO v_total
    FROM activities
    WHERE travel_id = p_travel_id;
    
    RETURN v_total;
END$$

CREATE FUNCTION calculate_lodging_price(
    p_travel_id INT,
    p_participants INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_lodging_price DECIMAL(10,2);
    DECLARE v_nights INT;
    
    SELECT 
        COALESCE(lodging_price_per_person, 0),
        DATEDIFF(end_date, start_date)
    INTO v_lodging_price, v_nights
    FROM travels
    WHERE id = p_travel_id;
    
    IF v_lodging_price = 0 THEN
        RETURN 0;
    END IF;
    
    RETURN v_lodging_price * p_participants * v_nights;
END$$

CREATE FUNCTION calculate_base_price(
    p_travel_id INT,
    p_participants INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_transport DECIMAL(10,2);
    DECLARE v_activities DECIMAL(10,2);
    DECLARE v_lodging DECIMAL(10,2);
    
    SET v_transport = calculate_transport_price(p_travel_id, p_participants);
    SET v_activities = calculate_activities_price(p_travel_id, p_participants);
    SET v_lodging = calculate_lodging_price(p_travel_id, p_participants);
    
    RETURN v_transport + v_activities + v_lodging;
END$$

-- 1.2 Réductions

CREATE FUNCTION calculate_participant_discount(
    p_participants INT
) RETURNS DECIMAL(5,2)
DETERMINISTIC
NO SQL
BEGIN
    IF p_participants >= 30 THEN
        RETURN 0.10;  -- 10%
    ELSEIF p_participants >= 20 THEN
        RETURN 0.05;  -- 5%
    ELSEIF p_participants >= 10 THEN
        RETURN 0.03;  -- 3%
    ELSE
        RETURN 0.00;
    END IF;
END$$

CREATE FUNCTION is_early_bird(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_days INT;
    
    SELECT DATEDIFF(start_date, CURRENT_DATE)
    INTO v_days
    FROM travels
    WHERE id = p_travel_id;
    
    RETURN v_days > 90;
END$$

CREATE FUNCTION calculate_early_bird_discount(
    p_travel_id INT
) RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    IF is_early_bird(p_travel_id) THEN
        RETURN 0.05;  -- 5%
    ELSE
        RETURN 0.00;
    END IF;
END$$

CREATE FUNCTION calculate_total_discount(
    p_travel_id INT,
    p_participants INT
) RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_participant_discount DECIMAL(5,2);
    DECLARE v_early_bird_discount DECIMAL(5,2);
    DECLARE v_total_discount DECIMAL(5,2);
    
    SET v_participant_discount = calculate_participant_discount(p_participants);
    SET v_early_bird_discount = calculate_early_bird_discount(p_travel_id);
    
    -- Application séquentielle des réductions
    SET v_total_discount = 1 - ((1 - v_participant_discount) * (1 - v_early_bird_discount));
    
    RETURN v_total_discount;
END$$

-- 1.3 Prix Finaux

CREATE FUNCTION calculate_travel_price_with_discounts(
    p_travel_id INT,
    p_participants INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_base_price DECIMAL(10,2);
    DECLARE v_discount DECIMAL(5,2);
    
    SET v_base_price = calculate_base_price(p_travel_id, p_participants);
    SET v_discount = calculate_total_discount(p_travel_id, p_participants);
    
    RETURN v_base_price * (1 - v_discount);
END$$

CREATE FUNCTION calculate_travel_price_with_margin(
    p_travel_id INT,
    p_participants INT,
    p_margin_percent DECIMAL(5,2)
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_price_with_discounts DECIMAL(10,2);
    
    SET v_price_with_discounts = calculate_travel_price_with_discounts(p_travel_id, p_participants);
    
    IF p_margin_percent IS NULL OR p_margin_percent = 0 THEN
        RETURN v_price_with_discounts;
    END IF;
    
    RETURN v_price_with_discounts * (1 + p_margin_percent / 100);
END$$

CREATE FUNCTION calculate_final_travel_price(
    p_travel_id INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_participants INT;
    DECLARE v_margin_percent DECIMAL(5,2);
    
    SELECT number_participants, COALESCE(margin_percent, 0)
    INTO v_participants, v_margin_percent
    FROM travels
    WHERE id = p_travel_id;
    
    IF v_participants IS NULL OR v_participants <= 0 THEN
        RETURN 0;
    END IF;
    
    RETURN calculate_travel_price_with_margin(p_travel_id, v_participants, v_margin_percent);
END$$

CREATE FUNCTION calculate_linguistic_travel_price(
    p_linguistic_travel_id INT,
    p_participants INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_price_per_person DECIMAL(10,2);
    
    SELECT price_per_person
    INTO v_price_per_person
    FROM linguistic_travels
    WHERE id = p_linguistic_travel_id;
    
    IF v_price_per_person IS NULL THEN
        RETURN 0;
    END IF;
    
    RETURN v_price_per_person * p_participants;
END$$

-- 1.4 Calculs TVA

CREATE FUNCTION calculate_tax_amount(
    p_amount_ht DECIMAL(10,2),
    p_tax_rate DECIMAL(5,2)
) RETURNS DECIMAL(10,2)
DETERMINISTIC
NO SQL
BEGIN
    RETURN p_amount_ht * (p_tax_rate / 100);
END$$

CREATE FUNCTION calculate_amount_ttc(
    p_amount_ht DECIMAL(10,2),
    p_tax_rate DECIMAL(5,2)
) RETURNS DECIMAL(10,2)
DETERMINISTIC
NO SQL
BEGIN
    RETURN p_amount_ht + calculate_tax_amount(p_amount_ht, p_tax_rate);
END$$

CREATE FUNCTION calculate_invoice_total_with_tax(
    p_invoice_id INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total_ht DECIMAL(10,2);
    DECLARE v_tax_amount DECIMAL(10,2);
    
    SELECT total_amount, tax_amount
    INTO v_total_ht, v_tax_amount
    FROM invoices
    WHERE id = p_invoice_id;
    
    IF v_total_ht IS NULL THEN
        RETURN 0;
    END IF;
    
    RETURN v_total_ht + COALESCE(v_tax_amount, 0);
END$$

-- ============================================
-- DOMAINE 2 : VALIDATIONS MÉTIER
-- ============================================

-- 2.1 Validations de Voyages

CREATE FUNCTION can_generate_quote(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_status VARCHAR(50);
    DECLARE v_has_destination BOOLEAN;
    DECLARE v_has_participants BOOLEAN;
    DECLARE v_has_transport_price BOOLEAN;
    
    -- Vérifier le statut
    SELECT status
    INTO v_status
    FROM travels
    WHERE id = p_travel_id;
    
    IF v_status NOT IN ('draft', 'quote_sent') THEN
        RETURN FALSE;
    END IF;
    
    -- Vérifier qu'il y a au moins une destination
    SELECT COUNT(*) > 0
    INTO v_has_destination
    FROM travel_destinations
    WHERE travel_id = p_travel_id;
    
    IF NOT v_has_destination THEN
        RETURN FALSE;
    END IF;
    
    -- Vérifier le nombre de participants
    SELECT (number_participants IS NOT NULL AND number_participants > 0) 
        OR (min_participants IS NOT NULL AND max_participants IS NOT NULL)
    INTO v_has_participants
    FROM travels
    WHERE id = p_travel_id;
    
    IF NOT v_has_participants THEN
        RETURN FALSE;
    END IF;
    
    -- Vérifier les prix de transport
    SELECT COUNT(*) > 0
    INTO v_has_transport_price
    FROM travel_destinations td
    JOIN transport_prices tp ON td.destination_id = tp.destination_id
    JOIN travels t ON td.travel_id = t.id
    WHERE td.travel_id = p_travel_id
      AND tp.date BETWEEN DATE(t.start_date) AND DATE(t.end_date);
    
    RETURN v_has_transport_price;
END$$

CREATE FUNCTION can_validate_quote(
    p_quote_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_quote_status VARCHAR(50);
    DECLARE v_travel_status VARCHAR(50);
    DECLARE v_expires_at TIMESTAMP;
    DECLARE v_quote_travel_id INT;
    
    SELECT status, expires_at, travel_id
    INTO v_quote_status, v_expires_at, v_quote_travel_id
    FROM quotes
    WHERE id = p_quote_id;
    
    IF v_quote_status != 'sent' THEN
        RETURN FALSE;
    END IF;
    
    -- Vérifier expiration
    IF v_expires_at IS NOT NULL AND v_expires_at < NOW() THEN
        RETURN FALSE;
    END IF;
    
    -- Vérifier statut du voyage
    SELECT status
    INTO v_travel_status
    FROM travels
    WHERE id = v_quote_travel_id;
    
    RETURN v_travel_status = 'quote_sent';
END$$

CREATE FUNCTION can_generate_invoice(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_has_validated_quote BOOLEAN;
    DECLARE v_parent_contacts_collected BOOLEAN;
    DECLARE v_number_participants INT;
    
    -- Vérifier qu'il y a un devis validé
    SELECT COUNT(*) > 0
    INTO v_has_validated_quote
    FROM quotes
    WHERE travel_id = p_travel_id AND status = 'validated';
    
    IF NOT v_has_validated_quote THEN
        RETURN FALSE;
    END IF;
    
    -- Vérifier les contacts parents
    SELECT parent_contacts_collected
    INTO v_parent_contacts_collected
    FROM travels
    WHERE id = p_travel_id;
    
    IF NOT v_parent_contacts_collected THEN
        RETURN FALSE;
    END IF;
    
    -- Vérifier le nombre exact de participants
    SELECT number_participants
    INTO v_number_participants
    FROM travels
    WHERE id = p_travel_id;
    
    RETURN v_number_participants IS NOT NULL AND v_number_participants > 0;
END$$

CREATE FUNCTION can_validate_invoice(
    p_invoice_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_status VARCHAR(50);
    
    SELECT status
    INTO v_status
    FROM invoices
    WHERE id = p_invoice_id;
    
    RETURN v_status = 'draft';
END$$

CREATE FUNCTION is_travel_valid_for_confirmation(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN can_generate_invoice(p_travel_id);
END$$

-- 2.2 Validations de Plannings

CREATE FUNCTION has_valid_planning(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_count INT;
    
    SELECT COUNT(*)
    INTO v_count
    FROM activities
    WHERE travel_id = p_travel_id;
    
    RETURN v_count > 0;
END$$

CREATE FUNCTION has_overlapping_activities(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_count INT;
    
    SELECT COUNT(*)
    INTO v_count
    FROM activities a1
    JOIN activities a2 ON a1.travel_id = a2.travel_id
    WHERE a1.travel_id = p_travel_id
      AND a1.id != a2.id
      AND DATE(a1.date) = DATE(a2.date)
      AND (
          (a1.start_time <= a2.start_time AND a1.end_time > a2.start_time)
          OR (a2.start_time <= a1.start_time AND a2.end_time > a1.start_time)
      );
    
    RETURN v_count > 0;
END$$

CREATE FUNCTION planning_covers_travel_days(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_travel_days INT;
    DECLARE v_covered_days INT;
    
    SELECT DATEDIFF(end_date, start_date) + 1
    INTO v_travel_days
    FROM travels
    WHERE id = p_travel_id;
    
    SELECT COUNT(DISTINCT DATE(date))
    INTO v_covered_days
    FROM activities
    WHERE travel_id = p_travel_id;
    
    RETURN v_covered_days >= v_travel_days;
END$$

CREATE FUNCTION is_planning_valid(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN has_valid_planning(p_travel_id)
        AND NOT has_overlapping_activities(p_travel_id)
        AND planning_covers_travel_days(p_travel_id);
END$$

-- 2.3 Validations de Réservations

CREATE FUNCTION has_available_spots(
    p_linguistic_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_max_participants INT;
    DECLARE v_current_participants INT;
    
    SELECT max_participants
    INTO v_max_participants
    FROM linguistic_travels
    WHERE id = p_linguistic_travel_id;
    
    SELECT COUNT(*)
    INTO v_current_participants
    FROM linguistic_travel_registrations
    WHERE linguistic_travel_id = p_linguistic_travel_id
      AND status = 'confirmed';
    
    RETURN v_current_participants < v_max_participants;
END$$

CREATE FUNCTION can_create_booking(
    p_linguistic_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN has_available_spots(p_linguistic_travel_id);
END$$

CREATE FUNCTION is_payment_overdue(
    p_booking_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_hours_since_creation INT;
    
    SELECT TIMESTAMPDIFF(HOUR, created_at, NOW())
    INTO v_hours_since_creation
    FROM bookings
    WHERE id = p_booking_id
      AND payment_status = 'pending';
    
    RETURN v_hours_since_creation > 24;
END$$

CREATE FUNCTION should_cancel_booking(
    p_booking_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_payment_status VARCHAR(50);
    
    SELECT payment_status
    INTO v_payment_status
    FROM bookings
    WHERE id = p_booking_id;
    
    RETURN v_payment_status = 'failed' OR is_payment_overdue(p_booking_id);
END$$

-- 2.4 Validations de Données

CREATE FUNCTION is_email_valid(
    p_email VARCHAR(255)
) RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    -- Validation basique d'email
    RETURN p_email REGEXP '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$';
END$$

CREATE FUNCTION are_dates_valid(
    p_start_date DATETIME,
    p_end_date DATETIME
) RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    RETURN p_end_date > p_start_date 
        AND p_start_date > NOW();
END$$

CREATE FUNCTION is_participant_count_valid(
    p_min_participants INT,
    p_max_participants INT,
    p_number_participants INT
) RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    IF p_max_participants < p_min_participants THEN
        RETURN FALSE;
    END IF;
    
    IF p_number_participants IS NOT NULL THEN
        RETURN p_number_participants >= p_min_participants 
            AND p_number_participants <= p_max_participants;
    END IF;
    
    RETURN TRUE;
END$$

-- ============================================
-- DOMAINE 3 : GÉNÉRATION DE NUMÉROS
-- ============================================

CREATE FUNCTION generate_quote_number() RETURNS VARCHAR(100)
READS SQL DATA
NOT DETERMINISTIC
BEGIN
    DECLARE v_year INT;
    DECLARE v_sequence INT;
    DECLARE v_quote_number VARCHAR(100);
    
    SET v_year = YEAR(CURRENT_DATE);
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(quote_number, -4) AS UNSIGNED)), 0) + 1
    INTO v_sequence
    FROM quotes
    WHERE quote_number LIKE CONCAT('DEV-', v_year, '-%');
    
    SET v_quote_number = CONCAT('DEV-', v_year, '-', LPAD(v_sequence, 4, '0'));
    
    RETURN v_quote_number;
END$$

CREATE FUNCTION generate_invoice_number() RETURNS VARCHAR(100)
READS SQL DATA
NOT DETERMINISTIC
BEGIN
    DECLARE v_year INT;
    DECLARE v_sequence INT;
    DECLARE v_invoice_number VARCHAR(100);
    
    SET v_year = YEAR(CURRENT_DATE);
    
    SELECT COALESCE(MAX(CAST(SUBSTRING(invoice_number, -4) AS UNSIGNED)), 0) + 1
    INTO v_sequence
    FROM invoices
    WHERE invoice_number LIKE CONCAT('FAC-', v_year, '-%');
    
    SET v_invoice_number = CONCAT('FAC-', v_year, '-', LPAD(v_sequence, 4, '0'));
    
    RETURN v_invoice_number;
END$$

CREATE FUNCTION generate_travel_reference(
    p_travel_id INT
) RETURNS VARCHAR(100)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_reference VARCHAR(100);
    
    SET v_reference = CONCAT('TRAV-', LPAD(p_travel_id, 6, '0'));
    
    RETURN v_reference;
END$$

CREATE FUNCTION generate_booking_number() RETURNS VARCHAR(100)
READS SQL DATA
NOT DETERMINISTIC
BEGIN
    DECLARE v_year INT;
    DECLARE v_sequence INT;
    DECLARE v_booking_number VARCHAR(100);
    
    SET v_year = YEAR(CURRENT_DATE);
    
    SELECT COALESCE(MAX(id), 0) + 1
    INTO v_sequence
    FROM bookings;
    
    SET v_booking_number = CONCAT('BOOK-', v_year, '-', LPAD(v_sequence, 6, '0'));
    
    RETURN v_booking_number;
END$$

CREATE FUNCTION generate_token() RETURNS VARCHAR(255)
NOT DETERMINISTIC
NO SQL
BEGIN
    RETURN CONCAT(
        SUBSTRING(MD5(RAND()), 1, 8), '-',
        SUBSTRING(MD5(RAND()), 1, 4), '-',
        SUBSTRING(MD5(RAND()), 1, 4), '-',
        SUBSTRING(MD5(RAND()), 1, 4), '-',
        SUBSTRING(MD5(RAND()), 1, 12)
    );
END$$

-- ============================================
-- DOMAINE 4 : GESTION DES CONTACTS ET COMMUNICATION
-- ============================================

-- 4.1 Consentements

CREATE FUNCTION can_send_marketing_email(
    p_contact_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_consent BOOLEAN;
    DECLARE v_opt_out_date TIMESTAMP;
    
    SELECT email_marketing_consent, email_opt_out_date
    INTO v_consent, v_opt_out_date
    FROM contacts
    WHERE id = p_contact_id;
    
    RETURN v_consent = TRUE AND v_opt_out_date IS NULL;
END$$

CREATE FUNCTION can_send_whatsapp(
    p_contact_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_consent BOOLEAN;
    DECLARE v_opt_out_date TIMESTAMP;
    DECLARE v_verified BOOLEAN;
    
    SELECT whatsapp_consent, whatsapp_opt_out_date, whatsapp_verified
    INTO v_consent, v_opt_out_date, v_verified
    FROM contacts
    WHERE id = p_contact_id;
    
    RETURN v_consent = TRUE AND v_opt_out_date IS NULL AND v_verified = TRUE;
END$$

CREATE FUNCTION has_email_consent(
    p_contact_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_consent BOOLEAN;
    
    SELECT email_marketing_consent
    INTO v_consent
    FROM contacts
    WHERE id = p_contact_id;
    
    RETURN v_consent = TRUE;
END$$

CREATE FUNCTION has_whatsapp_consent(
    p_contact_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_consent BOOLEAN;
    
    SELECT whatsapp_consent
    INTO v_consent
    FROM contacts
    WHERE id = p_contact_id;
    
    RETURN v_consent = TRUE;
END$$

CREATE FUNCTION is_contact_opted_out_email(
    p_contact_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_opt_out_date TIMESTAMP;
    
    SELECT email_opt_out_date
    INTO v_opt_out_date
    FROM contacts
    WHERE id = p_contact_id;
    
    RETURN v_opt_out_date IS NOT NULL;
END$$

CREATE FUNCTION is_contact_opted_out_whatsapp(
    p_contact_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_opt_out_date TIMESTAMP;
    
    SELECT whatsapp_opt_out_date
    INTO v_opt_out_date
    FROM contacts
    WHERE id = p_contact_id;
    
    RETURN v_opt_out_date IS NOT NULL;
END$$

-- 4.2 Statistiques de Communication

CREATE FUNCTION get_email_bounce_rate(
    p_contact_id INT
) RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_bounce_count INT;
    DECLARE v_total_sent INT;
    DECLARE v_rate DECIMAL(5,2);
    
    SELECT email_bounce_count
    INTO v_bounce_count
    FROM contacts
    WHERE id = p_contact_id;
    
    SELECT COUNT(*)
    INTO v_total_sent
    FROM contact_history
    WHERE contact_id = p_contact_id
      AND contact_type = 'email'
      AND action = 'message_sent';
    
    IF v_total_sent = 0 THEN
        RETURN 0;
    END IF;
    
    SET v_rate = (v_bounce_count / v_total_sent) * 100;
    
    RETURN LEAST(v_rate, 100.00);
END$$

CREATE FUNCTION days_since_last_email(
    p_contact_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_last_sent TIMESTAMP;
    DECLARE v_days INT;
    
    SELECT email_last_sent
    INTO v_last_sent
    FROM contacts
    WHERE id = p_contact_id;
    
    IF v_last_sent IS NULL THEN
        RETURN NULL;
    END IF;
    
    SET v_days = DATEDIFF(CURRENT_DATE, DATE(v_last_sent));
    
    RETURN v_days;
END$$

CREATE FUNCTION days_since_last_whatsapp(
    p_contact_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_last_contact TIMESTAMP;
    DECLARE v_days INT;
    
    SELECT whatsapp_last_contact
    INTO v_last_contact
    FROM contacts
    WHERE id = p_contact_id;
    
    IF v_last_contact IS NULL THEN
        RETURN NULL;
    END IF;
    
    SET v_days = DATEDIFF(CURRENT_DATE, DATE(v_last_contact));
    
    RETURN v_days;
END$$

CREATE FUNCTION get_contact_engagement_score(
    p_contact_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_score INT DEFAULT 0;
    DECLARE v_email_consent BOOLEAN;
    DECLARE v_whatsapp_consent BOOLEAN;
    DECLARE v_bounce_rate DECIMAL(5,2);
    
    SELECT email_marketing_consent, whatsapp_consent
    INTO v_email_consent, v_whatsapp_consent
    FROM contacts
    WHERE id = p_contact_id;
    
    -- Score de base selon consentements
    IF v_email_consent THEN
        SET v_score = v_score + 30;
    END IF;
    
    IF v_whatsapp_consent THEN
        SET v_score = v_score + 20;
    END IF;
    
    -- Ajustement selon bounce rate
    SET v_bounce_rate = get_email_bounce_rate(p_contact_id);
    SET v_score = v_score - (v_bounce_rate / 2);
    
    -- Score final entre 0 et 100
    RETURN GREATEST(0, LEAST(100, v_score));
END$$

-- ============================================
-- DOMAINE 5 : GESTION DES VOYAGES
-- ============================================

-- 5.1 Informations Temporelles

CREATE FUNCTION days_until_departure(
    p_travel_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_days INT;
    
    SELECT DATEDIFF(start_date, CURRENT_DATE)
    INTO v_days
    FROM travels
    WHERE id = p_travel_id;
    
    RETURN v_days;
END$$

CREATE FUNCTION days_until_return(
    p_travel_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_days INT;
    
    SELECT DATEDIFF(end_date, CURRENT_DATE)
    INTO v_days
    FROM travels
    WHERE id = p_travel_id;
    
    RETURN v_days;
END$$

CREATE FUNCTION travel_duration_days(
    p_travel_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_days INT;
    
    SELECT DATEDIFF(end_date, start_date) + 1
    INTO v_days
    FROM travels
    WHERE id = p_travel_id;
    
    RETURN v_days;
END$$

CREATE FUNCTION travel_duration_nights(
    p_travel_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_nights INT;
    
    SELECT DATEDIFF(end_date, start_date)
    INTO v_nights
    FROM travels
    WHERE id = p_travel_id;
    
    RETURN v_nights;
END$$

CREATE FUNCTION is_travel_in_past(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_end_date DATETIME;
    
    SELECT end_date
    INTO v_end_date
    FROM travels
    WHERE id = p_travel_id;
    
    RETURN v_end_date < NOW();
END$$

CREATE FUNCTION is_travel_in_progress(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_start_date DATETIME;
    DECLARE v_end_date DATETIME;
    
    SELECT start_date, end_date
    INTO v_start_date, v_end_date
    FROM travels
    WHERE id = p_travel_id;
    
    RETURN NOW() BETWEEN v_start_date AND v_end_date;
END$$

CREATE FUNCTION is_travel_upcoming(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_start_date DATETIME;
    
    SELECT start_date
    INTO v_start_date
    FROM travels
    WHERE id = p_travel_id;
    
    RETURN v_start_date > NOW();
END$$

-- 5.2 Participants

CREATE FUNCTION get_travel_participant_count(
    p_travel_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_count INT;
    
    SELECT number_participants
    INTO v_count
    FROM travels
    WHERE id = p_travel_id;
    
    RETURN COALESCE(v_count, 0);
END$$

CREATE FUNCTION get_available_spots(
    p_travel_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_max_participants INT;
    DECLARE v_current_participants INT;
    
    SELECT max_participants, number_participants
    INTO v_max_participants, v_current_participants
    FROM travels
    WHERE id = p_travel_id;
    
    IF v_max_participants IS NULL THEN
        RETURN NULL;
    END IF;
    
    RETURN GREATEST(0, v_max_participants - COALESCE(v_current_participants, 0));
END$$

CREATE FUNCTION is_travel_full(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN get_available_spots(p_travel_id) = 0;
END$$

CREATE FUNCTION get_participant_fill_rate(
    p_travel_id INT
) RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_max_participants INT;
    DECLARE v_current_participants INT;
    DECLARE v_rate DECIMAL(5,2);
    
    SELECT max_participants, number_participants
    INTO v_max_participants, v_current_participants
    FROM travels
    WHERE id = p_travel_id;
    
    IF v_max_participants IS NULL OR v_max_participants = 0 THEN
        RETURN NULL;
    END IF;
    
    SET v_rate = (COALESCE(v_current_participants, 0) / v_max_participants) * 100;
    
    RETURN LEAST(v_rate, 100.00);
END$$

-- 5.3 Contacts Parents

CREATE FUNCTION get_parent_contacts_count(
    p_travel_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_count INT;
    
    SELECT COUNT(DISTINCT pc.id)
    INTO v_count
    FROM parent_contacts pc
    JOIN bookings b ON pc.booking_id = b.id
    WHERE b.travel_id = p_travel_id;
    
    RETURN v_count;
END$$

CREATE FUNCTION get_expected_parent_contacts_count(
    p_travel_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_participants INT;
    
    SELECT number_participants
    INTO v_participants
    FROM travels
    WHERE id = p_travel_id;
    
    RETURN COALESCE(v_participants, 0);
END$$

CREATE FUNCTION are_all_parent_contacts_collected(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_collected INT;
    DECLARE v_expected INT;
    
    SET v_collected = get_parent_contacts_count(p_travel_id);
    SET v_expected = get_expected_parent_contacts_count(p_travel_id);
    
    RETURN v_collected >= v_expected;
END$$

CREATE FUNCTION get_missing_parent_contacts_count(
    p_travel_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_collected INT;
    DECLARE v_expected INT;
    
    SET v_collected = get_parent_contacts_count(p_travel_id);
    SET v_expected = get_expected_parent_contacts_count(p_travel_id);
    
    RETURN GREATEST(0, v_expected - v_collected);
END$$

-- ============================================
-- DOMAINE 6 : GESTION DES DEVIS
-- ============================================

-- 6.1 Statuts et Validations

CREATE FUNCTION is_quote_expired(
    p_quote_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_expires_at TIMESTAMP;
    
    SELECT expires_at
    INTO v_expires_at
    FROM quotes
    WHERE id = p_quote_id;
    
    RETURN v_expires_at IS NOT NULL AND v_expires_at < NOW();
END$$

CREATE FUNCTION days_until_quote_expiry(
    p_quote_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_expires_at TIMESTAMP;
    DECLARE v_days INT;
    
    SELECT expires_at
    INTO v_expires_at
    FROM quotes
    WHERE id = p_quote_id;
    
    IF v_expires_at IS NULL THEN
        RETURN NULL;
    END IF;
    
    SET v_days = DATEDIFF(v_expires_at, NOW());
    
    RETURN v_days;
END$$

CREATE FUNCTION get_quote_status(
    p_quote_id INT
) RETURNS VARCHAR(50)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_status VARCHAR(50);
    
    SELECT status
    INTO v_status
    FROM quotes
    WHERE id = p_quote_id;
    
    RETURN v_status;
END$$

CREATE FUNCTION can_send_quote(
    p_quote_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_status VARCHAR(50);
    
    SELECT status
    INTO v_status
    FROM quotes
    WHERE id = p_quote_id;
    
    RETURN v_status = 'draft';
END$$

-- 6.2 Calculs de Devis

CREATE FUNCTION get_quote_total(
    p_quote_id INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(line_total), 0)
    INTO v_total
    FROM quote_lines
    WHERE quote_id = p_quote_id;
    
    RETURN v_total;
END$$

CREATE FUNCTION calculate_quote_line_total(
    p_quote_id INT,
    p_line_type VARCHAR(50)
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(line_total), 0)
    INTO v_total
    FROM quote_lines
    WHERE quote_id = p_quote_id
      AND line_type = p_line_type;
    
    RETURN v_total;
END$$

CREATE FUNCTION get_quote_discount_amount(
    p_quote_id INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total_before DECIMAL(10,2);
    DECLARE v_total_after DECIMAL(10,2);
    
    SET v_total_before = get_quote_total(p_quote_id);
    
    SELECT total_amount
    INTO v_total_after
    FROM quotes
    WHERE id = p_quote_id;
    
    RETURN GREATEST(0, v_total_before - COALESCE(v_total_after, 0));
END$$

CREATE FUNCTION get_quote_final_amount(
    p_quote_id INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_amount DECIMAL(10,2);
    
    SELECT total_amount
    INTO v_amount
    FROM quotes
    WHERE id = p_quote_id;
    
    RETURN COALESCE(v_amount, 0);
END$$

-- ============================================
-- DOMAINE 7 : GESTION DES FACTURES
-- ============================================

-- 7.1 Statuts et Paiements

CREATE FUNCTION is_invoice_paid(
    p_invoice_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_status VARCHAR(50);
    
    SELECT status
    INTO v_status
    FROM invoices
    WHERE id = p_invoice_id;
    
    RETURN v_status = 'paid';
END$$

CREATE FUNCTION is_invoice_overdue(
    p_invoice_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_due_date TIMESTAMP;
    DECLARE v_status VARCHAR(50);
    
    SELECT due_date, status
    INTO v_due_date, v_status
    FROM invoices
    WHERE id = p_invoice_id;
    
    RETURN v_due_date IS NOT NULL 
        AND v_due_date < NOW()
        AND v_status != 'paid';
END$$

CREATE FUNCTION days_until_invoice_due(
    p_invoice_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_due_date TIMESTAMP;
    DECLARE v_days INT;
    
    SELECT due_date
    INTO v_due_date
    FROM invoices
    WHERE id = p_invoice_id;
    
    IF v_due_date IS NULL THEN
        RETURN NULL;
    END IF;
    
    SET v_days = DATEDIFF(v_due_date, NOW());
    
    RETURN v_days;
END$$

CREATE FUNCTION get_invoice_total_ht(
    p_invoice_id INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10,2);
    
    SELECT total_amount
    INTO v_total
    FROM invoices
    WHERE id = p_invoice_id;
    
    RETURN COALESCE(v_total, 0);
END$$

CREATE FUNCTION get_invoice_total_ttc(
    p_invoice_id INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    RETURN calculate_invoice_total_with_tax(p_invoice_id);
END$$

CREATE FUNCTION get_invoice_tax_amount(
    p_invoice_id INT
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_tax DECIMAL(10,2);
    
    SELECT tax_amount
    INTO v_tax
    FROM invoices
    WHERE id = p_invoice_id;
    
    RETURN COALESCE(v_tax, 0);
END$$

-- 7.2 Génération depuis Devis

CREATE FUNCTION can_create_invoice_from_quote(
    p_quote_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_quote_status VARCHAR(50);
    DECLARE v_travel_id INT;
    
    SELECT status, travel_id
    INTO v_quote_status, v_travel_id
    FROM quotes
    WHERE id = p_quote_id;
    
    IF v_quote_status != 'validated' THEN
        RETURN FALSE;
    END IF;
    
    RETURN can_generate_invoice(v_travel_id);
END$$

CREATE FUNCTION get_quote_for_invoice(
    p_invoice_id INT
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_travel_id INT;
    DECLARE v_quote_id INT;
    
    SELECT travel_id
    INTO v_travel_id
    FROM invoices
    WHERE id = p_invoice_id;
    
    SELECT id
    INTO v_quote_id
    FROM quotes
    WHERE travel_id = v_travel_id
      AND status = 'validated'
    ORDER BY validated_at DESC
    LIMIT 1;
    
    RETURN v_quote_id;
END$$

-- ============================================
-- DOMAINE 8 : STATISTIQUES ET RAPPORTS
-- ============================================

-- 8.1 Statistiques de Voyages

CREATE FUNCTION get_travels_count_by_status(
    p_status VARCHAR(50)
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_count INT;
    
    SELECT COUNT(*)
    INTO v_count
    FROM travels
    WHERE status = p_status;
    
    RETURN v_count;
END$$

CREATE FUNCTION get_travels_count_by_type(
    p_travel_type VARCHAR(50)
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_count INT;
    
    SELECT COUNT(*)
    INTO v_count
    FROM travels
    WHERE travel_type = p_travel_type;
    
    RETURN v_count;
END$$

CREATE FUNCTION get_total_revenue_by_period(
    p_start_date DATE,
    p_end_date DATE
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_revenue DECIMAL(10,2);
    
    SELECT COALESCE(SUM(total_amount), 0)
    INTO v_revenue
    FROM invoices
    WHERE status = 'paid'
      AND issued_at BETWEEN p_start_date AND p_end_date;
    
    RETURN v_revenue;
END$$

CREATE FUNCTION get_average_travel_price(
    p_travel_type VARCHAR(50)
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_avg_price DECIMAL(10,2);
    
    IF p_travel_type IS NULL THEN
        SELECT AVG(total_price)
        INTO v_avg_price
        FROM travels
        WHERE total_price > 0;
    ELSE
        SELECT AVG(total_price)
        INTO v_avg_price
        FROM travels
        WHERE travel_type = p_travel_type
          AND total_price > 0;
    END IF;
    
    RETURN COALESCE(v_avg_price, 0);
END$$

CREATE FUNCTION get_travel_conversion_rate() RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total_quotes INT;
    DECLARE v_validated_quotes INT;
    DECLARE v_rate DECIMAL(5,2);
    
    SELECT COUNT(*)
    INTO v_total_quotes
    FROM quotes
    WHERE status IN ('sent', 'validated');
    
    SELECT COUNT(*)
    INTO v_validated_quotes
    FROM quotes
    WHERE status = 'validated';
    
    IF v_total_quotes = 0 THEN
        RETURN 0;
    END IF;
    
    SET v_rate = (v_validated_quotes / v_total_quotes) * 100;
    
    RETURN v_rate;
END$$

-- 8.2 Statistiques de Participants

CREATE FUNCTION get_total_participants_by_period(
    p_start_date DATE,
    p_end_date DATE
) RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total INT;
    
    SELECT COALESCE(SUM(number_participants), 0)
    INTO v_total
    FROM travels
    WHERE start_date BETWEEN p_start_date AND p_end_date
      AND number_participants IS NOT NULL;
    
    RETURN v_total;
END$$

CREATE FUNCTION get_average_participants_per_travel() RETURNS DECIMAL(5,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_avg DECIMAL(5,2);
    
    SELECT AVG(number_participants)
    INTO v_avg
    FROM travels
    WHERE number_participants IS NOT NULL;
    
    RETURN COALESCE(v_avg, 0);
END$$

CREATE FUNCTION get_most_popular_destination() RETURNS INT
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_destination_id INT;
    
    SELECT td.destination_id
    INTO v_destination_id
    FROM travel_destinations td
    GROUP BY td.destination_id
    ORDER BY COUNT(*) DESC
    LIMIT 1;
    
    RETURN v_destination_id;
END$$

-- 8.3 Statistiques Financières

CREATE FUNCTION get_total_quotes_amount_by_period(
    p_start_date DATE,
    p_end_date DATE
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(total_amount), 0)
    INTO v_total
    FROM quotes
    WHERE created_at BETWEEN p_start_date AND p_end_date;
    
    RETURN v_total;
END$$

CREATE FUNCTION get_total_invoices_amount_by_period(
    p_start_date DATE,
    p_end_date DATE
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(total_amount), 0)
    INTO v_total
    FROM invoices
    WHERE issued_at BETWEEN p_start_date AND p_end_date;
    
    RETURN v_total;
END$$

CREATE FUNCTION get_pending_invoices_amount() RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(total_amount), 0)
    INTO v_total
    FROM invoices
    WHERE status = 'validated'
      AND (status != 'paid' OR status IS NULL);
    
    RETURN v_total;
END$$

CREATE FUNCTION get_overdue_invoices_amount() RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(total_amount), 0)
    INTO v_total
    FROM invoices
    WHERE status != 'paid'
      AND due_date < NOW();
    
    RETURN v_total;
END$$

CREATE FUNCTION get_paid_invoices_amount_by_period(
    p_start_date DATE,
    p_end_date DATE
) RETURNS DECIMAL(10,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_total DECIMAL(10,2);
    
    SELECT COALESCE(SUM(total_amount), 0)
    INTO v_total
    FROM invoices
    WHERE status = 'paid'
      AND issued_at BETWEEN p_start_date AND p_end_date;
    
    RETURN v_total;
END$$

-- ============================================
-- DOMAINE 9 : INTÉGRATION ODOO
-- ============================================

CREATE FUNCTION needs_odoo_sync_contact(
    p_user_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_odoo_partner_id INT;
    
    SELECT c.odoo_partner_id
    INTO v_odoo_partner_id
    FROM contacts c
    WHERE c.user_id = p_user_id;
    
    RETURN v_odoo_partner_id IS NULL;
END$$

CREATE FUNCTION needs_odoo_sync_travel(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_odoo_lead_id INT;
    
    SELECT odoo_lead_id
    INTO v_odoo_lead_id
    FROM travels
    WHERE id = p_travel_id;
    
    RETURN v_odoo_lead_id IS NULL;
END$$

CREATE FUNCTION needs_odoo_sync_invoice(
    p_invoice_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_odoo_invoice_id INT;
    DECLARE v_status VARCHAR(50);
    
    SELECT i.odoo_invoice_id, i.status
    INTO v_odoo_invoice_id, v_status
    FROM invoices i
    WHERE i.id = p_invoice_id;
    
    RETURN v_odoo_invoice_id IS NULL AND v_status = 'validated';
END$$

CREATE FUNCTION has_odoo_lead(
    p_travel_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_odoo_lead_id INT;
    
    SELECT odoo_lead_id
    INTO v_odoo_lead_id
    FROM travels
    WHERE id = p_travel_id;
    
    RETURN v_odoo_lead_id IS NOT NULL;
END$$

CREATE FUNCTION has_odoo_partner(
    p_user_id INT
) RETURNS BOOLEAN
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE v_odoo_partner_id INT;
    
    SELECT c.odoo_partner_id
    INTO v_odoo_partner_id
    FROM contacts c
    WHERE c.user_id = p_user_id;
    
    RETURN v_odoo_partner_id IS NOT NULL;
END$$

-- ============================================
-- DOMAINE 10 : UTILITAIRES GÉNÉRAUX
-- ============================================

-- 10.1 Dates et Temps

CREATE FUNCTION get_current_fiscal_year() RETURNS INT
DETERMINISTIC
NO SQL
BEGIN
    RETURN YEAR(CURRENT_DATE);
END$$

CREATE FUNCTION get_fiscal_year_for_date(
    p_date DATE
) RETURNS INT
DETERMINISTIC
NO SQL
BEGIN
    RETURN YEAR(p_date);
END$$

CREATE FUNCTION is_weekend(
    p_date DATE
) RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    DECLARE v_day_of_week INT;
    
    SET v_day_of_week = DAYOFWEEK(p_date);
    
    RETURN v_day_of_week = 1 OR v_day_of_week = 7;  -- Dimanche ou Samedi
END$$

CREATE FUNCTION is_business_day(
    p_date DATE
) RETURNS BOOLEAN
DETERMINISTIC
NO SQL
BEGIN
    RETURN NOT is_weekend(p_date);
END$$

-- 10.2 Formatage

CREATE FUNCTION format_price(
    p_amount DECIMAL(10,2)
) RETURNS VARCHAR(50)
DETERMINISTIC
NO SQL
BEGIN
    RETURN CONCAT(
        FORMAT(p_amount, 2, 'fr_FR'),
        ' €'
    );
END$$

CREATE FUNCTION format_percentage(
    p_value DECIMAL(5,2)
) RETURNS VARCHAR(10)
DETERMINISTIC
NO SQL
BEGIN
    RETURN CONCAT(
        FORMAT(p_value, 2, 'fr_FR'),
        ' %'
    );
END$$

CREATE FUNCTION format_date_fr(
    p_date DATE
) RETURNS VARCHAR(50)
DETERMINISTIC
NO SQL
BEGIN
    DECLARE v_month_names VARCHAR(200) DEFAULT 'janvier,février,mars,avril,mai,juin,juillet,août,septembre,octobre,novembre,décembre';
    DECLARE v_month_name VARCHAR(20);
    DECLARE v_month INT;
    DECLARE v_day INT;
    DECLARE v_year INT;
    
    SET v_day = DAY(p_date);
    SET v_month = MONTH(p_date);
    SET v_year = YEAR(p_date);
    
    SET v_month_name = SUBSTRING_INDEX(SUBSTRING_INDEX(v_month_names, ',', v_month), ',', -1);
    
    RETURN CONCAT(v_day, ' ', v_month_name, ' ', v_year);
END$$

-- 10.3 Recherche et Filtrage
-- Note: Ces fonctions retournent des résultats de requête
-- Elles sont utilisées dans des sous-requêtes ou vues

-- ============================================
-- DOMAINE 11 : PROCÉDURES STOCKÉES
-- ============================================

-- 11.1 Génération Automatique

CREATE PROCEDURE sp_generate_quote_for_travel(
    IN p_travel_id INT,
    OUT p_quote_id INT
)
BEGIN
    DECLARE v_quote_number VARCHAR(100);
    DECLARE v_total_amount DECIMAL(10,2);
    DECLARE v_participants INT;
    DECLARE v_travel_status VARCHAR(50);
    DECLARE v_created_by INT;
    
    -- Vérifier que le devis peut être généré
    IF NOT can_generate_quote(p_travel_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Le devis ne peut pas être généré pour ce voyage';
    END IF;
    
    -- Récupérer les informations du voyage
    SELECT status, number_participants, created_by_user_id
    INTO v_travel_status, v_participants, v_created_by
    FROM travels
    WHERE id = p_travel_id;
    
    -- Générer le numéro de devis
    SET v_quote_number = generate_quote_number();
    
    -- Calculer le total
    SET v_total_amount = calculate_final_travel_price(p_travel_id);
    
    -- Créer le devis
    INSERT INTO quotes (
        travel_id,
        quote_number,
        status,
        total_amount,
        created_by_user_id,
        created_at
    ) VALUES (
        p_travel_id,
        v_quote_number,
        'draft',
        v_total_amount,
        v_created_by,
        CURRENT_TIMESTAMP
    );
    
    SET p_quote_id = LAST_INSERT_ID();
    
    -- Mettre à jour le statut du voyage
    UPDATE travels
    SET status = 'quote_sent',
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_travel_id;
END$$

CREATE PROCEDURE sp_generate_invoice_from_quote(
    IN p_quote_id INT,
    OUT p_invoice_id INT
)
BEGIN
    DECLARE v_travel_id INT;
    DECLARE v_invoice_number VARCHAR(100);
    DECLARE v_total_amount DECIMAL(10,2);
    DECLARE v_tax_amount DECIMAL(10,2);
    DECLARE v_tax_rate DECIMAL(5,2) DEFAULT 20.00;
    DECLARE v_validated_by INT;
    
    -- Vérifier que la facture peut être créée
    IF NOT can_create_invoice_from_quote(p_quote_id) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'La facture ne peut pas être créée depuis ce devis';
    END IF;
    
    -- Récupérer le travel_id
    SELECT travel_id
    INTO v_travel_id
    FROM quotes
    WHERE id = p_quote_id;
    
    -- Générer le numéro de facture
    SET v_invoice_number = generate_invoice_number();
    
    -- Calculer les montants
    SELECT total_amount
    INTO v_total_amount
    FROM quotes
    WHERE id = p_quote_id;
    
    SET v_tax_amount = calculate_tax_amount(v_total_amount, v_tax_rate);
    
    -- Créer la facture
    INSERT INTO invoices (
        travel_id,
        invoice_number,
        status,
        total_amount,
        tax_amount,
        created_at
    ) VALUES (
        v_travel_id,
        v_invoice_number,
        'draft',
        v_total_amount,
        v_tax_amount,
        CURRENT_TIMESTAMP
    );
    
    SET p_invoice_id = LAST_INSERT_ID();
    
    -- Copier les lignes du devis vers la facture
    INSERT INTO invoice_lines (
        invoice_id,
        description,
        quantity,
        unit_price,
        line_total,
        tax_rate
    )
    SELECT 
        p_invoice_id,
        description,
        quantity,
        unit_price,
        line_total,
        v_tax_rate
    FROM quote_lines
    WHERE quote_id = p_quote_id;
END$$

CREATE PROCEDURE sp_update_travel_status(
    IN p_travel_id INT,
    IN p_new_status VARCHAR(50),
    IN p_user_id INT
)
BEGIN
    DECLARE v_old_status VARCHAR(50);
    
    -- Récupérer l'ancien statut
    SELECT status
    INTO v_old_status
    FROM travels
    WHERE id = p_travel_id;
    
    -- Enregistrer dans l'historique
    INSERT INTO travel_status_history (
        travel_id,
        from_status,
        to_status,
        changed_at,
        changed_by
    ) VALUES (
        p_travel_id,
        v_old_status,
        p_new_status,
        CURRENT_TIMESTAMP,
        p_user_id
    );
    
    -- Mettre à jour le statut
    UPDATE travels
    SET status = p_new_status,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_travel_id;
END$$

CREATE PROCEDURE sp_collect_parent_contacts(
    IN p_travel_id INT
)
BEGIN
    DECLARE v_all_collected BOOLEAN;
    
    SET v_all_collected = are_all_parent_contacts_collected(p_travel_id);
    
    IF v_all_collected THEN
        UPDATE travels
        SET parent_contacts_collected = TRUE,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = p_travel_id;
    END IF;
END$$

-- 11.2 Nettoyage et Maintenance

CREATE PROCEDURE sp_cancel_overdue_bookings()
BEGIN
    UPDATE bookings
    SET status = 'cancelled',
        payment_status = 'failed',
        updated_at = CURRENT_TIMESTAMP
    WHERE payment_status = 'pending'
      AND TIMESTAMPDIFF(HOUR, created_at, NOW()) > 24;
END$$

CREATE PROCEDURE sp_expire_old_quotes()
BEGIN
    UPDATE quotes
    SET status = 'rejected',
        updated_at = CURRENT_TIMESTAMP
    WHERE status = 'sent'
      AND expires_at IS NOT NULL
      AND expires_at < NOW();
END$$

CREATE PROCEDURE sp_archive_completed_travels()
BEGIN
    -- Pour l'instant, on ne fait que marquer comme archivés
    -- Une table d'archive peut être créée plus tard
    UPDATE travels
    SET updated_at = CURRENT_TIMESTAMP
    WHERE status = 'completed'
      AND updated_at < DATE_SUB(NOW(), INTERVAL 1 YEAR);
END$$

CREATE PROCEDURE sp_update_travel_totals(
    IN p_travel_id INT
)
BEGIN
    DECLARE v_total_price DECIMAL(10,2);
    
    SET v_total_price = calculate_final_travel_price(p_travel_id);
    
    UPDATE travels
    SET total_price = v_total_price,
        updated_at = CURRENT_TIMESTAMP
    WHERE id = p_travel_id;
END$$

-- 11.3 Synchronisation Odoo

CREATE PROCEDURE sp_sync_contact_to_odoo(
    IN p_user_id INT
)
BEGIN
    -- Marquer pour synchronisation
    -- L'implémentation réelle se fait côté application
    UPDATE contacts
    SET updated_at = CURRENT_TIMESTAMP
    WHERE user_id = p_user_id;
END$$

CREATE PROCEDURE sp_sync_travel_lead_to_odoo(
    IN p_travel_id INT
)
BEGIN
    -- Marquer pour synchronisation
    UPDATE travels
    SET updated_at = CURRENT_TIMESTAMP
    WHERE id = p_travel_id;
END$$

CREATE PROCEDURE sp_sync_invoice_to_odoo(
    IN p_invoice_id INT
)
BEGIN
    -- Marquer pour synchronisation
    UPDATE invoices
    SET updated_at = CURRENT_TIMESTAMP
    WHERE id = p_invoice_id;
END$$

DELIMITER ;

-- ============================================
-- FIN DU FICHIER
-- ============================================
-- 
-- Toutes les fonctions et procédures ont été créées.
-- 
-- Pour vérifier la création :
--   SHOW FUNCTION STATUS WHERE Db = 'gestion_db';
--   SHOW PROCEDURE STATUS WHERE Db = 'gestion_db';
--
-- Pour supprimer toutes les fonctions (en cas de besoin) :
--   DROP FUNCTION IF EXISTS function_name;
--   DROP PROCEDURE IF EXISTS procedure_name;
--
-- ============================================
