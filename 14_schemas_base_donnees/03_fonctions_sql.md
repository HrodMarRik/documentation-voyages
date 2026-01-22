# Fonctions SQL Stockées - Documentation Complète

## Vue d'Ensemble

Ce document présente toutes les fonctions SQL stockées et procédures stockées utiles pour le système de gestion de voyages. Ces fonctions permettent d'encapsuler la logique métier au niveau de la base de données, améliorant ainsi les performances et la cohérence des données.

## Introduction aux Fonctions MySQL

MySQL 8.0+ supporte les fonctions stockées (stored functions) et les procédures stockées (stored procedures). Les fonctions retournent une valeur et peuvent être utilisées dans les requêtes SQL, tandis que les procédures peuvent exécuter des opérations complexes et modifier l'état de la base de données.

### Caractéristiques

- **DETERMINISTIC** : La fonction retourne toujours le même résultat pour les mêmes paramètres d'entrée
- **NOT DETERMINISTIC** : La fonction peut retourner des résultats différents (par défaut)
- **READS SQL DATA** : La fonction lit des données mais ne les modifie pas
- **MODIFIES SQL DATA** : La fonction peut modifier les données
- **NO SQL** : La fonction ne contient pas d'instructions SQL
- **CONTAINS SQL** : La fonction contient des instructions SQL (par défaut)

### Syntaxe de Base

```sql
DELIMITER $$

CREATE FUNCTION function_name(param1 TYPE, param2 TYPE)
RETURNS RETURN_TYPE
[DETERMINISTIC | NOT DETERMINISTIC]
[READS SQL DATA | MODIFIES SQL DATA]
BEGIN
    -- Corps de la fonction
    RETURN value;
END$$

DELIMITER ;
```

## Organisation par Domaine

---

## Domaine 1 : Calculs de Prix

### 1.1 Calculs de Base

#### `calculate_transport_price(travel_id INT, participants INT)`

**Description** : Calcule le prix total du transport pour un voyage donné.

**Paramètres** :
- `travel_id` : ID du voyage
- `participants` : Nombre de participants

**Retour** : `DECIMAL(10,2)` - Prix total du transport

**Exemple d'utilisation** :
```sql
SELECT calculate_transport_price(123, 25) AS transport_price;
```

**Notes** :
- Utilise la table `transport_prices` pour chaque destination du voyage
- Prend en compte les dates du voyage
- Multiplie le prix par personne par le nombre de participants

---

#### `calculate_activities_price(travel_id INT, participants INT)`

**Description** : Calcule le prix total des activités pour un voyage.

**Paramètres** :
- `travel_id` : ID du voyage
- `participants` : Nombre de participants

**Retour** : `DECIMAL(10,2)` - Prix total des activités

**Exemple d'utilisation** :
```sql
SELECT calculate_activities_price(123, 25) AS activities_price;
```

**Notes** :
- Utilise la table `activities` liée au voyage
- Somme tous les `price_per_person` multipliés par le nombre de participants
- Retourne 0 si aucune activité n'est définie

---

#### `calculate_lodging_price(travel_id INT, participants INT)`

**Description** : Calcule le prix de l'hébergement pour un voyage.

**Paramètres** :
- `travel_id` : ID du voyage
- `participants` : Nombre de participants

**Retour** : `DECIMAL(10,2)` - Prix total de l'hébergement

**Exemple d'utilisation** :
```sql
SELECT calculate_lodging_price(123, 25) AS lodging_price;
```

**Notes** :
- Utilise `lodging_price_per_person` du voyage (si renseigné)
- Calcule : `lodging_price_per_person × participants × nombre_nuits`
- Retourne 0 si `lodging_price_per_person` n'est pas renseigné

---

#### `calculate_base_price(travel_id INT, participants INT)`

**Description** : Calcule le prix de base (transport + activités + hébergement).

**Paramètres** :
- `travel_id` : ID du voyage
- `participants` : Nombre de participants

**Retour** : `DECIMAL(10,2)` - Prix de base total

**Exemple d'utilisation** :
```sql
SELECT calculate_base_price(123, 25) AS base_price;
```

**Notes** :
- Appelle les fonctions `calculate_transport_price`, `calculate_activities_price`, et `calculate_lodging_price`
- Retourne la somme de ces trois composants

---

### 1.2 Réductions

#### `calculate_participant_discount(participants INT)`

**Description** : Calcule le pourcentage de réduction selon le nombre de participants.

**Paramètres** :
- `participants` : Nombre de participants

**Retour** : `DECIMAL(5,2)` - Pourcentage de réduction (0.00 à 0.10)

**Règles métier** :
- ≥ 30 participants : 10% de réduction (0.10)
- ≥ 20 participants : 5% de réduction (0.05)
- ≥ 10 participants : 3% de réduction (0.03)
- < 10 participants : 0% de réduction (0.00)

**Exemple d'utilisation** :
```sql
SELECT calculate_participant_discount(25) AS discount; -- Retourne 0.05
```

---

#### `is_early_bird(travel_id INT)`

**Description** : Vérifie si le voyage est éligible à la réduction early bird.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si éligible (> 90 jours avant le départ)

**Exemple d'utilisation** :
```sql
SELECT is_early_bird(123) AS is_early_bird;
```

**Notes** :
- Calcule la différence entre `start_date` et la date actuelle
- Retourne TRUE si la différence est > 90 jours

---

#### `calculate_early_bird_discount(travel_id INT)`

**Description** : Retourne le pourcentage de réduction early bird si applicable.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `DECIMAL(5,2)` - 0.05 si early bird, sinon 0.00

**Exemple d'utilisation** :
```sql
SELECT calculate_early_bird_discount(123) AS early_bird_discount;
```

---

#### `calculate_total_discount(travel_id INT, participants INT)`

**Description** : Calcule la réduction totale combinée (participants + early bird).

**Paramètres** :
- `travel_id` : ID du voyage
- `participants` : Nombre de participants

**Retour** : `DECIMAL(5,2)` - Pourcentage de réduction total

**Exemple d'utilisation** :
```sql
SELECT calculate_total_discount(123, 25) AS total_discount;
```

**Notes** :
- Combine les réductions de participants et early bird
- Les réductions sont appliquées séquentiellement (multiplicatif)

---

### 1.3 Prix Finaux

#### `calculate_travel_price_with_discounts(travel_id INT, participants INT)`

**Description** : Calcule le prix total avec toutes les réductions appliquées.

**Paramètres** :
- `travel_id` : ID du voyage
- `participants` : Nombre de participants

**Retour** : `DECIMAL(10,2)` - Prix après réductions

**Exemple d'utilisation** :
```sql
SELECT calculate_travel_price_with_discounts(123, 25) AS price_with_discounts;
```

---

#### `calculate_travel_price_with_margin(travel_id INT, participants INT, margin_percent DECIMAL(5,2))`

**Description** : Calcule le prix final avec marge appliquée.

**Paramètres** :
- `travel_id` : ID du voyage
- `participants` : Nombre de participants
- `margin_percent` : Pourcentage de marge (ex: 10.00 pour 10%)

**Retour** : `DECIMAL(10,2)` - Prix final avec marge

**Exemple d'utilisation** :
```sql
SELECT calculate_travel_price_with_margin(123, 25, 10.00) AS final_price;
```

---

#### `calculate_final_travel_price(travel_id INT)`

**Description** : Calcule le prix final complet (base + réductions + marge).

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `DECIMAL(10,2)` - Prix final

**Exemple d'utilisation** :
```sql
SELECT calculate_final_travel_price(123) AS final_price;
```

**Notes** :
- Utilise `number_participants` du voyage
- Applique toutes les réductions et la marge si renseignée
- Fonction principale pour le calcul de prix

---

#### `calculate_linguistic_travel_price(linguistic_travel_id INT, participants INT)`

**Description** : Calcule le prix pour un voyage linguistique (prix fixe par personne).

**Paramètres** :
- `linguistic_travel_id` : ID du voyage linguistique
- `participants` : Nombre de participants

**Retour** : `DECIMAL(10,2)` - Prix total

**Exemple d'utilisation** :
```sql
SELECT calculate_linguistic_travel_price(456, 2) AS total_price;
```

**Notes** :
- Calcul simple : `price_per_person × participants`
- Pas de réductions ni de marge

---

### 1.4 Calculs TVA

#### `calculate_tax_amount(amount_ht DECIMAL(10,2), tax_rate DECIMAL(5,2))`

**Description** : Calcule le montant de TVA.

**Paramètres** :
- `amount_ht` : Montant HT
- `tax_rate` : Taux de TVA (ex: 20.00 pour 20%)

**Retour** : `DECIMAL(10,2)` - Montant de TVA

**Exemple d'utilisation** :
```sql
SELECT calculate_tax_amount(1000.00, 20.00) AS tax_amount; -- Retourne 200.00
```

---

#### `calculate_amount_ttc(amount_ht DECIMAL(10,2), tax_rate DECIMAL(5,2))`

**Description** : Calcule le montant TTC.

**Paramètres** :
- `amount_ht` : Montant HT
- `tax_rate` : Taux de TVA

**Retour** : `DECIMAL(10,2)` - Montant TTC

**Exemple d'utilisation** :
```sql
SELECT calculate_amount_ttc(1000.00, 20.00) AS amount_ttc; -- Retourne 1200.00
```

---

#### `calculate_invoice_total_with_tax(invoice_id INT)`

**Description** : Calcule le total TTC d'une facture.

**Paramètres** :
- `invoice_id` : ID de la facture

**Retour** : `DECIMAL(10,2)` - Total TTC

**Exemple d'utilisation** :
```sql
SELECT calculate_invoice_total_with_tax(789) AS total_ttc;
```

---

## Domaine 2 : Validations Métier

### 2.1 Validations de Voyages

#### `can_generate_quote(travel_id INT)`

**Description** : Vérifie si un devis peut être généré pour un voyage.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si le devis peut être généré

**Conditions** :
- Le voyage existe et est en statut DRAFT ou QUOTE_SENT
- Le voyage a au moins une destination
- Le nombre de participants est défini (ou min/max)
- Les prix de transport sont renseignés pour les dates

**Exemple d'utilisation** :
```sql
SELECT can_generate_quote(123) AS can_generate;
```

---

#### `can_validate_quote(quote_id INT)`

**Description** : Vérifie si un devis peut être validé.

**Paramètres** :
- `quote_id` : ID du devis

**Retour** : `BOOLEAN` - TRUE si le devis peut être validé

**Conditions** :
- Le devis est en statut SENT
- Le devis n'est pas expiré (si `expires_at` est renseigné)
- Le voyage est en statut QUOTE_SENT

**Exemple d'utilisation** :
```sql
SELECT can_validate_quote(456) AS can_validate;
```

---

#### `can_generate_invoice(travel_id INT)`

**Description** : Vérifie si une facture peut être générée depuis un devis.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si la facture peut être générée

**Conditions** :
- Le devis est en statut VALIDATED
- Le voyage a `parent_contacts_collected = TRUE`
- Le nombre exact de participants est connu

**Exemple d'utilisation** :
```sql
SELECT can_generate_invoice(123) AS can_generate;
```

---

#### `can_validate_invoice(invoice_id INT)`

**Description** : Vérifie si une facture peut être validée.

**Paramètres** :
- `invoice_id` : ID de la facture

**Retour** : `BOOLEAN` - TRUE si la facture peut être validée

**Conditions** :
- La facture est en statut DRAFT

**Exemple d'utilisation** :
```sql
SELECT can_validate_invoice(789) AS can_validate;
```

---

#### `is_travel_valid_for_confirmation(travel_id INT)`

**Description** : Vérifie si un voyage peut être confirmé.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si le voyage peut être confirmé

**Conditions** :
- Tous les prérequis sont remplis (devis validé, dossier validé, facture générée)

**Exemple d'utilisation** :
```sql
SELECT is_travel_valid_for_confirmation(123) AS can_confirm;
```

---

### 2.2 Validations de Plannings

#### `has_valid_planning(travel_id INT)`

**Description** : Vérifie si le planning a au moins une activité.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si le planning est valide

**Exemple d'utilisation** :
```sql
SELECT has_valid_planning(123) AS has_planning;
```

---

#### `has_overlapping_activities(travel_id INT)`

**Description** : Vérifie si des activités se chevauchent.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si des activités se chevauchent

**Exemple d'utilisation** :
```sql
SELECT has_overlapping_activities(123) AS has_overlap;
```

---

#### `planning_covers_travel_days(travel_id INT)`

**Description** : Vérifie si le planning couvre tous les jours du voyage.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si le planning couvre tous les jours

**Exemple d'utilisation** :
```sql
SELECT planning_covers_travel_days(123) AS covers_days;
```

---

#### `is_planning_valid(travel_id INT)`

**Description** : Validation complète du planning.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si le planning est valide

**Conditions** :
- Au moins une activité
- Pas de chevauchement
- Couvre tous les jours du voyage

**Exemple d'utilisation** :
```sql
SELECT is_planning_valid(123) AS is_valid;
```

---

### 2.3 Validations de Réservations

#### `has_available_spots(linguistic_travel_id INT)`

**Description** : Vérifie s'il reste des places disponibles.

**Paramètres** :
- `linguistic_travel_id` : ID du voyage linguistique

**Retour** : `BOOLEAN` - TRUE s'il reste des places

**Exemple d'utilisation** :
```sql
SELECT has_available_spots(456) AS has_spots;
```

---

#### `can_create_booking(linguistic_travel_id INT)`

**Description** : Vérifie si une réservation peut être créée.

**Paramètres** :
- `linguistic_travel_id` : ID du voyage linguistique

**Retour** : `BOOLEAN` - TRUE si la réservation peut être créée

**Conditions** :
- Le voyage est publié
- Il reste des places disponibles

**Exemple d'utilisation** :
```sql
SELECT can_create_booking(456) AS can_create;
```

---

#### `is_payment_overdue(booking_id INT)`

**Description** : Vérifie si le paiement est en retard (> 24h).

**Paramètres** :
- `booking_id` : ID de la réservation

**Retour** : `BOOLEAN` - TRUE si le paiement est en retard

**Exemple d'utilisation** :
```sql
SELECT is_payment_overdue(789) AS is_overdue;
```

---

#### `should_cancel_booking(booking_id INT)`

**Description** : Détermine si une réservation doit être annulée.

**Paramètres** :
- `booking_id` : ID de la réservation

**Retour** : `BOOLEAN` - TRUE si la réservation doit être annulée

**Conditions** :
- Paiement échoué ou en retard (> 24h)

**Exemple d'utilisation** :
```sql
SELECT should_cancel_booking(789) AS should_cancel;
```

---

### 2.4 Validations de Données

#### `is_email_valid(email VARCHAR(255))`

**Description** : Valide le format d'email.

**Paramètres** :
- `email` : Adresse email à valider

**Retour** : `BOOLEAN` - TRUE si l'email est valide

**Exemple d'utilisation** :
```sql
SELECT is_email_valid('user@example.com') AS is_valid;
```

---

#### `are_dates_valid(start_date DATETIME, end_date DATETIME)`

**Description** : Vérifie que les dates sont valides.

**Paramètres** :
- `start_date` : Date de début
- `end_date` : Date de fin

**Retour** : `BOOLEAN` - TRUE si les dates sont valides

**Conditions** :
- `end_date > start_date`
- Les dates sont dans le futur

**Exemple d'utilisation** :
```sql
SELECT are_dates_valid('2025-06-01', '2025-06-07') AS are_valid;
```

---

#### `is_participant_count_valid(min_participants INT, max_participants INT, number_participants INT)`

**Description** : Vérifie la cohérence des nombres de participants.

**Paramètres** :
- `min_participants` : Nombre minimum
- `max_participants` : Nombre maximum
- `number_participants` : Nombre actuel

**Retour** : `BOOLEAN` - TRUE si les nombres sont cohérents

**Conditions** :
- `max_participants ≥ min_participants`
- `number_participants` entre min et max (si défini)

**Exemple d'utilisation** :
```sql
SELECT is_participant_count_valid(10, 30, 25) AS is_valid;
```

---

## Domaine 3 : Génération de Numéros

#### `generate_quote_number()`

**Description** : Génère un numéro de devis unique.

**Retour** : `VARCHAR(100)` - Numéro de devis (format: DEV-YYYY-XXXX)

**Exemple d'utilisation** :
```sql
SELECT generate_quote_number() AS quote_number; -- Retourne "DEV-2025-0001"
```

**Notes** :
- Format : DEV-{année}-{séquence sur 4 chiffres}
- La séquence est incrémentée automatiquement
- Non déterministe (chaque appel génère un nouveau numéro)

---

#### `generate_invoice_number()`

**Description** : Génère un numéro de facture unique.

**Retour** : `VARCHAR(100)` - Numéro de facture (format: FAC-YYYY-XXXX)

**Exemple d'utilisation** :
```sql
SELECT generate_invoice_number() AS invoice_number; -- Retourne "FAC-2025-0001"
```

---

#### `generate_travel_reference(travel_id INT)`

**Description** : Génère une référence unique pour un voyage.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `VARCHAR(100)` - Référence du voyage

**Exemple d'utilisation** :
```sql
SELECT generate_travel_reference(123) AS travel_ref;
```

---

#### `generate_booking_number()`

**Description** : Génère un numéro de réservation unique.

**Retour** : `VARCHAR(100)` - Numéro de réservation

**Exemple d'utilisation** :
```sql
SELECT generate_booking_number() AS booking_number;
```

---

#### `generate_token()`

**Description** : Génère un token unique pour les formulaires.

**Retour** : `VARCHAR(255)` - Token unique

**Exemple d'utilisation** :
```sql
SELECT generate_token() AS token;
```

---

## Domaine 4 : Gestion des Contacts et Communication

### 4.1 Consentements

#### `can_send_marketing_email(contact_id INT)`

**Description** : Vérifie si on peut envoyer un email marketing.

**Paramètres** :
- `contact_id` : ID du contact

**Retour** : `BOOLEAN` - TRUE si on peut envoyer

**Conditions** :
- `email_marketing_consent = TRUE`
- `email_opt_out_date IS NULL`

**Exemple d'utilisation** :
```sql
SELECT can_send_marketing_email(123) AS can_send;
```

---

#### `can_send_whatsapp(contact_id INT)`

**Description** : Vérifie si on peut envoyer un WhatsApp.

**Paramètres** :
- `contact_id` : ID du contact

**Retour** : `BOOLEAN` - TRUE si on peut envoyer

**Conditions** :
- `whatsapp_consent = TRUE`
- `whatsapp_opt_out_date IS NULL`
- `whatsapp_verified = TRUE`

**Exemple d'utilisation** :
```sql
SELECT can_send_whatsapp(123) AS can_send;
```

---

#### `has_email_consent(contact_id INT)`

**Description** : Vérifie le consentement email.

**Paramètres** :
- `contact_id` : ID du contact

**Retour** : `BOOLEAN` - TRUE si consentement donné

**Exemple d'utilisation** :
```sql
SELECT has_email_consent(123) AS has_consent;
```

---

#### `has_whatsapp_consent(contact_id INT)`

**Description** : Vérifie le consentement WhatsApp.

**Paramètres** :
- `contact_id` : ID du contact

**Retour** : `BOOLEAN` - TRUE si consentement donné

**Exemple d'utilisation** :
```sql
SELECT has_whatsapp_consent(123) AS has_consent;
```

---

#### `is_contact_opted_out_email(contact_id INT)`

**Description** : Vérifie si le contact a opt-out pour les emails.

**Paramètres** :
- `contact_id` : ID du contact

**Retour** : `BOOLEAN` - TRUE si opt-out

**Exemple d'utilisation** :
```sql
SELECT is_contact_opted_out_email(123) AS is_opted_out;
```

---

#### `is_contact_opted_out_whatsapp(contact_id INT)`

**Description** : Vérifie si le contact a opt-out pour WhatsApp.

**Paramètres** :
- `contact_id` : ID du contact

**Retour** : `BOOLEAN` - TRUE si opt-out

**Exemple d'utilisation** :
```sql
SELECT is_contact_opted_out_whatsapp(123) AS is_opted_out;
```

---

### 4.2 Statistiques de Communication

#### `get_email_bounce_rate(contact_id INT)`

**Description** : Calcule le taux de bounce pour un contact.

**Paramètres** :
- `contact_id` : ID du contact

**Retour** : `DECIMAL(5,2)` - Taux de bounce (0.00 à 100.00)

**Exemple d'utilisation** :
```sql
SELECT get_email_bounce_rate(123) AS bounce_rate;
```

---

#### `days_since_last_email(contact_id INT)`

**Description** : Nombre de jours depuis le dernier email envoyé.

**Paramètres** :
- `contact_id` : ID du contact

**Retour** : `INT` - Nombre de jours

**Exemple d'utilisation** :
```sql
SELECT days_since_last_email(123) AS days_since;
```

---

#### `days_since_last_whatsapp(contact_id INT)`

**Description** : Nombre de jours depuis le dernier WhatsApp envoyé.

**Paramètres** :
- `contact_id` : ID du contact

**Retour** : `INT` - Nombre de jours

**Exemple d'utilisation** :
```sql
SELECT days_since_last_whatsapp(123) AS days_since;
```

---

#### `get_contact_engagement_score(contact_id INT)`

**Description** : Score d'engagement basé sur l'historique.

**Paramètres** :
- `contact_id` : ID du contact

**Retour** : `INT` - Score d'engagement (0 à 100)

**Exemple d'utilisation** :
```sql
SELECT get_contact_engagement_score(123) AS engagement_score;
```

---

## Domaine 5 : Gestion des Voyages

### 5.1 Informations Temporelles

#### `days_until_departure(travel_id INT)`

**Description** : Nombre de jours avant le départ.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `INT` - Nombre de jours

**Exemple d'utilisation** :
```sql
SELECT days_until_departure(123) AS days_until;
```

---

#### `days_until_return(travel_id INT)`

**Description** : Nombre de jours avant le retour.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `INT` - Nombre de jours

**Exemple d'utilisation** :
```sql
SELECT days_until_return(123) AS days_until;
```

---

#### `travel_duration_days(travel_id INT)`

**Description** : Durée du voyage en jours.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `INT` - Nombre de jours

**Exemple d'utilisation** :
```sql
SELECT travel_duration_days(123) AS duration_days;
```

---

#### `travel_duration_nights(travel_id INT)`

**Description** : Nombre de nuits du voyage.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `INT` - Nombre de nuits

**Exemple d'utilisation** :
```sql
SELECT travel_duration_nights(123) AS duration_nights;
```

---

#### `is_travel_in_past(travel_id INT)`

**Description** : Vérifie si le voyage est terminé.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si terminé

**Exemple d'utilisation** :
```sql
SELECT is_travel_in_past(123) AS is_past;
```

---

#### `is_travel_in_progress(travel_id INT)`

**Description** : Vérifie si le voyage est en cours.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si en cours

**Exemple d'utilisation** :
```sql
SELECT is_travel_in_progress(123) AS in_progress;
```

---

#### `is_travel_upcoming(travel_id INT)`

**Description** : Vérifie si le voyage est à venir.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si à venir

**Exemple d'utilisation** :
```sql
SELECT is_travel_upcoming(123) AS is_upcoming;
```

---

### 5.2 Participants

#### `get_travel_participant_count(travel_id INT)`

**Description** : Nombre actuel de participants confirmés.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `INT` - Nombre de participants

**Exemple d'utilisation** :
```sql
SELECT get_travel_participant_count(123) AS participant_count;
```

---

#### `get_available_spots(travel_id INT)`

**Description** : Nombre de places disponibles.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `INT` - Nombre de places disponibles

**Exemple d'utilisation** :
```sql
SELECT get_available_spots(123) AS available_spots;
```

---

#### `is_travel_full(travel_id INT)`

**Description** : Vérifie si le voyage est complet.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si complet

**Exemple d'utilisation** :
```sql
SELECT is_travel_full(123) AS is_full;
```

---

#### `get_participant_fill_rate(travel_id INT)`

**Description** : Taux de remplissage (participants / max_participants).

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `DECIMAL(5,2)` - Taux de remplissage (0.00 à 100.00)

**Exemple d'utilisation** :
```sql
SELECT get_participant_fill_rate(123) AS fill_rate;
```

---

### 5.3 Contacts Parents

#### `get_parent_contacts_count(travel_id INT)`

**Description** : Nombre de contacts parents collectés.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `INT` - Nombre de contacts

**Exemple d'utilisation** :
```sql
SELECT get_parent_contacts_count(123) AS contacts_count;
```

---

#### `get_expected_parent_contacts_count(travel_id INT)`

**Description** : Nombre attendu de contacts parents.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `INT` - Nombre attendu

**Exemple d'utilisation** :
```sql
SELECT get_expected_parent_contacts_count(123) AS expected_count;
```

---

#### `are_all_parent_contacts_collected(travel_id INT)`

**Description** : Vérifie si tous les contacts parents sont collectés.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si tous collectés

**Exemple d'utilisation** :
```sql
SELECT are_all_parent_contacts_collected(123) AS all_collected;
```

---

#### `get_missing_parent_contacts_count(travel_id INT)`

**Description** : Nombre de contacts parents manquants.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `INT` - Nombre manquant

**Exemple d'utilisation** :
```sql
SELECT get_missing_parent_contacts_count(123) AS missing_count;
```

---

## Domaine 6 : Gestion des Devis

### 6.1 Statuts et Validations

#### `is_quote_expired(quote_id INT)`

**Description** : Vérifie si un devis est expiré.

**Paramètres** :
- `quote_id` : ID du devis

**Retour** : `BOOLEAN` - TRUE si expiré

**Exemple d'utilisation** :
```sql
SELECT is_quote_expired(456) AS is_expired;
```

---

#### `days_until_quote_expiry(quote_id INT)`

**Description** : Jours restants avant expiration.

**Paramètres** :
- `quote_id` : ID du devis

**Retour** : `INT` - Nombre de jours (peut être négatif)

**Exemple d'utilisation** :
```sql
SELECT days_until_quote_expiry(456) AS days_until;
```

---

#### `get_quote_status(quote_id INT)`

**Description** : Retourne le statut actuel du devis.

**Paramètres** :
- `quote_id` : ID du devis

**Retour** : `VARCHAR(50)` - Statut du devis

**Exemple d'utilisation** :
```sql
SELECT get_quote_status(456) AS status;
```

---

#### `can_send_quote(quote_id INT)`

**Description** : Vérifie si un devis peut être envoyé.

**Paramètres** :
- `quote_id` : ID du devis

**Retour** : `BOOLEAN` - TRUE si peut être envoyé

**Exemple d'utilisation** :
```sql
SELECT can_send_quote(456) AS can_send;
```

---

### 6.2 Calculs de Devis

#### `get_quote_total(quote_id INT)`

**Description** : Calcule le total d'un devis (somme des lignes).

**Paramètres** :
- `quote_id` : ID du devis

**Retour** : `DECIMAL(10,2)` - Total du devis

**Exemple d'utilisation** :
```sql
SELECT get_quote_total(456) AS total;
```

---

#### `calculate_quote_line_total(quote_id INT, line_type VARCHAR(50))`

**Description** : Calcule le total pour un type de ligne.

**Paramètres** :
- `quote_id` : ID du devis
- `line_type` : Type de ligne (transport, activités, hébergement, etc.)

**Retour** : `DECIMAL(10,2)` - Total pour ce type

**Exemple d'utilisation** :
```sql
SELECT calculate_quote_line_total(456, 'transport') AS transport_total;
```

---

#### `get_quote_discount_amount(quote_id INT)`

**Description** : Montant de la réduction appliquée.

**Paramètres** :
- `quote_id` : ID du devis

**Retour** : `DECIMAL(10,2)` - Montant de la réduction

**Exemple d'utilisation** :
```sql
SELECT get_quote_discount_amount(456) AS discount_amount;
```

---

#### `get_quote_final_amount(quote_id INT)`

**Description** : Montant final après réductions.

**Paramètres** :
- `quote_id` : ID du devis

**Retour** : `DECIMAL(10,2)` - Montant final

**Exemple d'utilisation** :
```sql
SELECT get_quote_final_amount(456) AS final_amount;
```

---

## Domaine 7 : Gestion des Factures

### 7.1 Statuts et Paiements

#### `is_invoice_paid(invoice_id INT)`

**Description** : Vérifie si une facture est payée.

**Paramètres** :
- `invoice_id` : ID de la facture

**Retour** : `BOOLEAN` - TRUE si payée

**Exemple d'utilisation** :
```sql
SELECT is_invoice_paid(789) AS is_paid;
```

---

#### `is_invoice_overdue(invoice_id INT)`

**Description** : Vérifie si une facture est en retard.

**Paramètres** :
- `invoice_id` : ID de la facture

**Retour** : `BOOLEAN` - TRUE si en retard

**Exemple d'utilisation** :
```sql
SELECT is_invoice_overdue(789) AS is_overdue;
```

---

#### `days_until_invoice_due(invoice_id INT)`

**Description** : Jours restants avant échéance.

**Paramètres** :
- `invoice_id` : ID de la facture

**Retour** : `INT` - Nombre de jours (peut être négatif)

**Exemple d'utilisation** :
```sql
SELECT days_until_invoice_due(789) AS days_until;
```

---

#### `get_invoice_total_ht(invoice_id INT)`

**Description** : Total HT d'une facture.

**Paramètres** :
- `invoice_id` : ID de la facture

**Retour** : `DECIMAL(10,2)` - Total HT

**Exemple d'utilisation** :
```sql
SELECT get_invoice_total_ht(789) AS total_ht;
```

---

#### `get_invoice_total_ttc(invoice_id INT)`

**Description** : Total TTC d'une facture.

**Paramètres** :
- `invoice_id` : ID de la facture

**Retour** : `DECIMAL(10,2)` - Total TTC

**Exemple d'utilisation** :
```sql
SELECT get_invoice_total_ttc(789) AS total_ttc;
```

---

#### `get_invoice_tax_amount(invoice_id INT)`

**Description** : Montant de TVA d'une facture.

**Paramètres** :
- `invoice_id` : ID de la facture

**Retour** : `DECIMAL(10,2)` - Montant de TVA

**Exemple d'utilisation** :
```sql
SELECT get_invoice_tax_amount(789) AS tax_amount;
```

---

### 7.2 Génération depuis Devis

#### `can_create_invoice_from_quote(quote_id INT)`

**Description** : Vérifie si on peut créer une facture depuis un devis.

**Paramètres** :
- `quote_id` : ID du devis

**Retour** : `BOOLEAN` - TRUE si possible

**Exemple d'utilisation** :
```sql
SELECT can_create_invoice_from_quote(456) AS can_create;
```

---

#### `get_quote_for_invoice(invoice_id INT)`

**Description** : Retourne l'ID du devis source d'une facture.

**Paramètres** :
- `invoice_id` : ID de la facture

**Retour** : `INT` - ID du devis source (ou NULL)

**Exemple d'utilisation** :
```sql
SELECT get_quote_for_invoice(789) AS quote_id;
```

---

## Domaine 8 : Statistiques et Rapports

### 8.1 Statistiques de Voyages

#### `get_travels_count_by_status(status VARCHAR(50))`

**Description** : Nombre de voyages par statut.

**Paramètres** :
- `status` : Statut du voyage

**Retour** : `INT` - Nombre de voyages

**Exemple d'utilisation** :
```sql
SELECT get_travels_count_by_status('confirmed') AS count;
```

---

#### `get_travels_count_by_type(travel_type VARCHAR(50))`

**Description** : Nombre de voyages par type.

**Paramètres** :
- `travel_type` : Type de voyage ('school' ou 'linguistic_group')

**Retour** : `INT` - Nombre de voyages

**Exemple d'utilisation** :
```sql
SELECT get_travels_count_by_type('school') AS count;
```

---

#### `get_total_revenue_by_period(start_date DATE, end_date DATE)`

**Description** : Chiffre d'affaires sur une période.

**Paramètres** :
- `start_date` : Date de début
- `end_date` : Date de fin

**Retour** : `DECIMAL(10,2)` - Chiffre d'affaires

**Exemple d'utilisation** :
```sql
SELECT get_total_revenue_by_period('2025-01-01', '2025-12-31') AS revenue;
```

---

#### `get_average_travel_price(travel_type VARCHAR(50))`

**Description** : Prix moyen des voyages.

**Paramètres** :
- `travel_type` : Type de voyage (optionnel, NULL pour tous)

**Retour** : `DECIMAL(10,2)` - Prix moyen

**Exemple d'utilisation** :
```sql
SELECT get_average_travel_price('school') AS avg_price;
```

---

#### `get_travel_conversion_rate()`

**Description** : Taux de conversion (devis → factures).

**Retour** : `DECIMAL(5,2)` - Taux de conversion (0.00 à 100.00)

**Exemple d'utilisation** :
```sql
SELECT get_travel_conversion_rate() AS conversion_rate;
```

---

### 8.2 Statistiques de Participants

#### `get_total_participants_by_period(start_date DATE, end_date DATE)`

**Description** : Nombre total de participants sur une période.

**Paramètres** :
- `start_date` : Date de début
- `end_date` : Date de fin

**Retour** : `INT` - Nombre de participants

**Exemple d'utilisation** :
```sql
SELECT get_total_participants_by_period('2025-01-01', '2025-12-31') AS total;
```

---

#### `get_average_participants_per_travel()`

**Description** : Nombre moyen de participants par voyage.

**Retour** : `DECIMAL(5,2)` - Nombre moyen

**Exemple d'utilisation** :
```sql
SELECT get_average_participants_per_travel() AS avg_participants;
```

---

#### `get_most_popular_destination()`

**Description** : ID de la destination la plus populaire.

**Retour** : `INT` - ID de la destination

**Exemple d'utilisation** :
```sql
SELECT get_most_popular_destination() AS destination_id;
```

---

### 8.3 Statistiques Financières

#### `get_total_quotes_amount_by_period(start_date DATE, end_date DATE)`

**Description** : Montant total des devis sur une période.

**Paramètres** :
- `start_date` : Date de début
- `end_date` : Date de fin

**Retour** : `DECIMAL(10,2)` - Montant total

**Exemple d'utilisation** :
```sql
SELECT get_total_quotes_amount_by_period('2025-01-01', '2025-12-31') AS total;
```

---

#### `get_total_invoices_amount_by_period(start_date DATE, end_date DATE)`

**Description** : Montant total des factures sur une période.

**Paramètres** :
- `start_date` : Date de début
- `end_date` : Date de fin

**Retour** : `DECIMAL(10,2)` - Montant total

**Exemple d'utilisation** :
```sql
SELECT get_total_invoices_amount_by_period('2025-01-01', '2025-12-31') AS total;
```

---

#### `get_pending_invoices_amount()`

**Description** : Montant total des factures en attente.

**Retour** : `DECIMAL(10,2)` - Montant total

**Exemple d'utilisation** :
```sql
SELECT get_pending_invoices_amount() AS pending_amount;
```

---

#### `get_overdue_invoices_amount()`

**Description** : Montant total des factures en retard.

**Retour** : `DECIMAL(10,2)` - Montant total

**Exemple d'utilisation** :
```sql
SELECT get_overdue_invoices_amount() AS overdue_amount;
```

---

#### `get_paid_invoices_amount_by_period(start_date DATE, end_date DATE)`

**Description** : Montant total des factures payées sur une période.

**Paramètres** :
- `start_date` : Date de début
- `end_date` : Date de fin

**Retour** : `DECIMAL(10,2)` - Montant total

**Exemple d'utilisation** :
```sql
SELECT get_paid_invoices_amount_by_period('2025-01-01', '2025-12-31') AS total;
```

---

## Domaine 9 : Intégration Odoo

#### `needs_odoo_sync_contact(user_id INT)`

**Description** : Vérifie si un contact doit être synchronisé avec Odoo.

**Paramètres** :
- `user_id` : ID de l'utilisateur

**Retour** : `BOOLEAN` - TRUE si synchronisation nécessaire

**Exemple d'utilisation** :
```sql
SELECT needs_odoo_sync_contact(123) AS needs_sync;
```

---

#### `needs_odoo_sync_travel(travel_id INT)`

**Description** : Vérifie si un voyage doit être synchronisé avec Odoo.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si synchronisation nécessaire

**Exemple d'utilisation** :
```sql
SELECT needs_odoo_sync_travel(123) AS needs_sync;
```

---

#### `needs_odoo_sync_invoice(invoice_id INT)`

**Description** : Vérifie si une facture doit être synchronisée avec Odoo.

**Paramètres** :
- `invoice_id` : ID de la facture

**Retour** : `BOOLEAN` - TRUE si synchronisation nécessaire

**Exemple d'utilisation** :
```sql
SELECT needs_odoo_sync_invoice(789) AS needs_sync;
```

---

#### `has_odoo_lead(travel_id INT)`

**Description** : Vérifie si un voyage a un lead Odoo.

**Paramètres** :
- `travel_id` : ID du voyage

**Retour** : `BOOLEAN` - TRUE si lead existe

**Exemple d'utilisation** :
```sql
SELECT has_odoo_lead(123) AS has_lead;
```

---

#### `has_odoo_partner(user_id INT)`

**Description** : Vérifie si un utilisateur a un partenaire Odoo.

**Paramètres** :
- `user_id` : ID de l'utilisateur

**Retour** : `BOOLEAN` - TRUE si partenaire existe

**Exemple d'utilisation** :
```sql
SELECT has_odoo_partner(123) AS has_partner;
```

---

## Domaine 10 : Utilitaires Généraux

### 10.1 Dates et Temps

#### `get_current_fiscal_year()`

**Description** : Retourne l'année fiscale en cours.

**Retour** : `INT` - Année fiscale

**Exemple d'utilisation** :
```sql
SELECT get_current_fiscal_year() AS fiscal_year;
```

---

#### `get_fiscal_year_for_date(date DATE)`

**Description** : Retourne l'année fiscale pour une date.

**Paramètres** :
- `date` : Date

**Retour** : `INT` - Année fiscale

**Exemple d'utilisation** :
```sql
SELECT get_fiscal_year_for_date('2025-06-15') AS fiscal_year;
```

---

#### `is_weekend(date DATE)`

**Description** : Vérifie si une date est un weekend.

**Paramètres** :
- `date` : Date à vérifier

**Retour** : `BOOLEAN` - TRUE si weekend

**Exemple d'utilisation** :
```sql
SELECT is_weekend('2025-01-18') AS is_weekend; -- Retourne TRUE (samedi)
```

---

#### `is_business_day(date DATE)`

**Description** : Vérifie si une date est un jour ouvrable.

**Paramètres** :
- `date` : Date à vérifier

**Retour** : `BOOLEAN` - TRUE si jour ouvrable

**Exemple d'utilisation** :
```sql
SELECT is_business_day('2025-01-20') AS is_business; -- Retourne TRUE (lundi)
```

---

### 10.2 Formatage

#### `format_price(amount DECIMAL(10,2))`

**Description** : Formate un prix avec séparateurs.

**Paramètres** :
- `amount` : Montant à formater

**Retour** : `VARCHAR(50)` - Prix formaté (ex: "1 234,56 €")

**Exemple d'utilisation** :
```sql
SELECT format_price(1234.56) AS formatted_price;
```

---

#### `format_percentage(value DECIMAL(5,2))`

**Description** : Formate un pourcentage.

**Paramètres** :
- `value` : Valeur à formater

**Retour** : `VARCHAR(10)` - Pourcentage formaté (ex: "15,50 %")

**Exemple d'utilisation** :
```sql
SELECT format_percentage(15.50) AS formatted_percent;
```

---

#### `format_date_fr(date DATE)`

**Description** : Formate une date en français.

**Paramètres** :
- `date` : Date à formater

**Retour** : `VARCHAR(50)` - Date formatée (ex: "20 janvier 2025")

**Exemple d'utilisation** :
```sql
SELECT format_date_fr('2025-01-20') AS formatted_date;
```

---

### 10.3 Recherche et Filtrage

#### `search_users_by_role(role_name VARCHAR(100))`

**Description** : Retourne les utilisateurs ayant un rôle spécifique.

**Paramètres** :
- `role_name` : Nom du rôle

**Retour** : Table (résultat de requête)

**Exemple d'utilisation** :
```sql
SELECT * FROM (SELECT search_users_by_role('commercial') AS user_id) AS users;
```

**Notes** : Cette fonction retourne un résultat de requête, utilisation dans une sous-requête

---

#### `get_active_travels_by_teacher(teacher_id INT)`

**Description** : Retourne les voyages actifs d'un professeur.

**Paramètres** :
- `teacher_id` : ID du professeur

**Retour** : Table (résultat de requête)

**Exemple d'utilisation** :
```sql
SELECT * FROM (SELECT get_active_travels_by_teacher(123) AS travel_id) AS travels;
```

---

#### `get_travels_by_destination(destination_id INT)`

**Description** : Retourne les voyages pour une destination.

**Paramètres** :
- `destination_id` : ID de la destination

**Retour** : Table (résultat de requête)

**Exemple d'utilisation** :
```sql
SELECT * FROM (SELECT get_travels_by_destination(456) AS travel_id) AS travels;
```

---

## Domaine 11 : Procédures Stockées

### 11.1 Génération Automatique

#### `sp_generate_quote_for_travel(IN travel_id INT, OUT quote_id INT)`

**Description** : Génère automatiquement un devis complet pour un voyage.

**Paramètres** :
- `IN travel_id` : ID du voyage
- `OUT quote_id` : ID du devis créé

**Exemple d'utilisation** :
```sql
CALL sp_generate_quote_for_travel(123, @quote_id);
SELECT @quote_id AS quote_id;
```

**Notes** :
- Valide les prérequis avant génération
- Calcule automatiquement tous les prix
- Crée les lignes de devis
- Met à jour le statut du voyage

---

#### `sp_generate_invoice_from_quote(IN quote_id INT, OUT invoice_id INT)`

**Description** : Génère une facture depuis un devis validé.

**Paramètres** :
- `IN quote_id` : ID du devis
- `OUT invoice_id` : ID de la facture créée

**Exemple d'utilisation** :
```sql
CALL sp_generate_invoice_from_quote(456, @invoice_id);
SELECT @invoice_id AS invoice_id;
```

**Notes** :
- Valide que le devis peut générer une facture
- Convertit les lignes de devis en lignes de facture
- Calcule la TVA
- Génère le numéro de facture

---

#### `sp_update_travel_status(IN travel_id INT, IN new_status VARCHAR(50), IN user_id INT)`

**Description** : Met à jour le statut d'un voyage avec historique.

**Paramètres** :
- `IN travel_id` : ID du voyage
- `IN new_status` : Nouveau statut
- `IN user_id` : ID de l'utilisateur effectuant le changement

**Exemple d'utilisation** :
```sql
CALL sp_update_travel_status(123, 'confirmed', 1);
```

**Notes** :
- Valide la transition de statut
- Enregistre dans `travel_status_history`
- Met à jour `travels.status`

---

#### `sp_collect_parent_contacts(IN travel_id INT)`

**Description** : Marque les contacts parents comme collectés.

**Paramètres** :
- `IN travel_id` : ID du voyage

**Exemple d'utilisation** :
```sql
CALL sp_collect_parent_contacts(123);
```

**Notes** :
- Met à jour `travels.parent_contacts_collected = TRUE`
- Vérifie que tous les contacts sont présents

---

### 11.2 Nettoyage et Maintenance

#### `sp_cancel_overdue_bookings()`

**Description** : Annule automatiquement les réservations en retard de paiement.

**Exemple d'utilisation** :
```sql
CALL sp_cancel_overdue_bookings();
```

**Notes** :
- Trouve les réservations avec paiement en retard (> 24h)
- Met à jour le statut à CANCELLED
- Met à jour le payment_status à FAILED

---

#### `sp_expire_old_quotes()`

**Description** : Marque les devis expirés comme REJECTED.

**Exemple d'utilisation** :
```sql
CALL sp_expire_old_quotes();
```

**Notes** :
- Trouve les devis avec `expires_at < NOW()`
- Met à jour le statut à REJECTED

---

#### `sp_archive_completed_travels()`

**Description** : Archive les voyages terminés.

**Exemple d'utilisation** :
```sql
CALL sp_archive_completed_travels();
```

**Notes** :
- Trouve les voyages avec statut COMPLETED
- Peut créer des archives ou marquer comme archivés

---

#### `sp_update_travel_totals(IN travel_id INT)`

**Description** : Recalcule tous les totaux d'un voyage.

**Paramètres** :
- `IN travel_id` : ID du voyage

**Exemple d'utilisation** :
```sql
CALL sp_update_travel_totals(123);
```

**Notes** :
- Recalcule le prix total
- Met à jour `travels.total_price`

---

### 11.3 Synchronisation Odoo

#### `sp_sync_contact_to_odoo(IN user_id INT)`

**Description** : Synchronise un contact avec Odoo.

**Paramètres** :
- `IN user_id` : ID de l'utilisateur

**Exemple d'utilisation** :
```sql
CALL sp_sync_contact_to_odoo(123);
```

**Notes** :
- Marque le contact pour synchronisation
- L'implémentation réelle de la synchronisation se fait côté application

---

#### `sp_sync_travel_lead_to_odoo(IN travel_id INT)`

**Description** : Crée/met à jour un lead Odoo pour un voyage.

**Paramètres** :
- `IN travel_id` : ID du voyage

**Exemple d'utilisation** :
```sql
CALL sp_sync_travel_lead_to_odoo(123);
```

---

#### `sp_sync_invoice_to_odoo(IN invoice_id INT)`

**Description** : Synchronise une facture avec Odoo.

**Paramètres** :
- `IN invoice_id` : ID de la facture

**Exemple d'utilisation** :
```sql
CALL sp_sync_invoice_to_odoo(789);
```

---

## Utilisation depuis Python (SQLAlchemy)

### Exemple 1 : Appeler une fonction

```python
from sqlalchemy import text

# Appeler une fonction qui retourne une valeur
result = db.execute(
    text("SELECT calculate_final_travel_price(:travel_id)"),
    {"travel_id": 123}
).scalar()

print(f"Prix final : {result}")
```

### Exemple 2 : Utiliser une fonction dans une requête

```python
# Utiliser une fonction dans une requête SELECT
travels = db.execute(
    text("""
        SELECT 
            id,
            name,
            calculate_final_travel_price(id) AS total_price
        FROM travels
        WHERE status = 'draft'
    """)
).fetchall()
```

### Exemple 3 : Appeler une procédure stockée

```python
# Appeler une procédure avec paramètres IN/OUT
db.execute(
    text("CALL sp_generate_quote_for_travel(:travel_id, @quote_id)"),
    {"travel_id": 123}
)

# Récupérer la valeur OUT
quote_id = db.execute(text("SELECT @quote_id")).scalar()
print(f"Devis créé : {quote_id}")
```

### Exemple 4 : Utiliser une fonction de validation

```python
# Vérifier si on peut générer un devis
can_generate = db.execute(
    text("SELECT can_generate_quote(:travel_id)"),
    {"travel_id": 123}
).scalar()

if can_generate:
    # Générer le devis
    pass
```

## Bonnes Pratiques

1. **Performance** : Les fonctions sont exécutées côté serveur, ce qui améliore les performances
2. **Cohérence** : La logique métier est centralisée dans la base de données
3. **Réutilisabilité** : Les fonctions peuvent être utilisées dans plusieurs contextes
4. **Maintenance** : Les modifications de logique se font en un seul endroit

## Limitations MySQL

1. **Débogage** : Plus difficile à déboguer que le code applicatif
2. **Versioning** : Nécessite des migrations pour les modifications
3. **Tests** : Plus complexe à tester que les fonctions applicatives
4. **Portabilité** : Syntaxe spécifique à MySQL

## Migration et Déploiement

Les fonctions doivent être créées après la création des tables. Utiliser le fichier `04_fonctions_sql_implementation.sql` pour créer toutes les fonctions en une seule fois.

```sql
-- Exemple d'ordre d'exécution
SOURCE 01_schema_complet.sql;
SOURCE 04_fonctions_sql_implementation.sql;
```

---

**Version** : 1.0  
**Date** : 2025-01-20  
**Auteur** : Équipe de développement
