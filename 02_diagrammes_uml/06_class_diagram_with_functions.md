# Diagramme de Classes avec Fonctions SQL - Système Intégré de Gestion

## Vue d'Ensemble

Ce diagramme de classes présente l'architecture orientée objet du système, incluant les entités du modèle de données, les services applicatifs, et les fonctions SQL stockées qui encapsulent la logique métier.

## Diagramme Principal - Architecture en Couches

![Class Diagram - Architecture Couches](images/ClassDiagram_ArchitectureCouches.png)

## Diagramme Détaillé - Entités et Fonctions SQL

![Class Diagram - Entités et Fonctions SQL](images/ClassDiagram_EntitesFonctionsDetaille.png)

## Diagramme - Services et Fonctions SQL

![Diagram](images/ClassDiagram_ServicesFonctions.png)

## Diagramme - Modèle de Données avec Fonctions

![Diagram](images/06_class_diagram_with_functions_mermaid_03.png)

## Relations entre Classes et Fonctions SQL

### Travel et Fonctions de Prix

![Diagram](images/06_class_diagram_with_functions_mermaid_04.png)

### Quote et Fonctions de Validation

![Diagram](images/06_class_diagram_with_functions_mermaid_05.png)

### Invoice et Fonctions de Calcul

![Diagram](images/06_class_diagram_with_functions_mermaid_06.png)

## Architecture Complète avec Toutes les Couches

![Diagram](images/06_class_diagram_with_functions_mermaid_07.png)

## Détail des Fonctions SQL par Classe

### Classe Travel

**Fonctions de calcul** :
- `calculate_final_travel_price(travel_id)` : Prix final complet
- `calculate_transport_price(travel_id, participants)` : Prix transport
- `calculate_activities_price(travel_id, participants)` : Prix activités
- `calculate_lodging_price(travel_id, participants)` : Prix hébergement

**Fonctions de validation** :
- `can_generate_quote(travel_id)` : Peut générer un devis
- `can_generate_invoice(travel_id)` : Peut générer une facture
- `is_travel_valid_for_confirmation(travel_id)` : Peut être confirmé

**Fonctions temporelles** :
- `days_until_departure(travel_id)` : Jours avant départ
- `is_early_bird(travel_id)` : Éligible early bird
- `is_travel_in_past(travel_id)` : Voyage terminé
- `is_travel_in_progress(travel_id)` : Voyage en cours

**Fonctions de participants** :
- `get_travel_participant_count(travel_id)` : Nombre participants
- `get_available_spots(travel_id)` : Places disponibles
- `are_all_parent_contacts_collected(travel_id)` : Contacts collectés

### Classe Quote

**Fonctions de validation** :
- `can_validate_quote(quote_id)` : Peut être validé
- `is_quote_expired(quote_id)` : Est expiré
- `can_send_quote(quote_id)` : Peut être envoyé

**Fonctions de calcul** :
- `get_quote_total(quote_id)` : Total du devis
- `calculate_quote_line_total(quote_id, line_type)` : Total par type
- `get_quote_final_amount(quote_id)` : Montant final

**Fonctions de génération** :
- `generate_quote_number()` : Génère numéro unique

### Classe Invoice

**Fonctions de validation** :
- `can_validate_invoice(invoice_id)` : Peut être validé
- `is_invoice_paid(invoice_id)` : Est payée
- `is_invoice_overdue(invoice_id)` : Est en retard

**Fonctions de calcul** :
- `get_invoice_total_ht(invoice_id)` : Total HT
- `get_invoice_total_ttc(invoice_id)` : Total TTC
- `get_invoice_tax_amount(invoice_id)` : Montant TVA

**Fonctions de génération** :
- `generate_invoice_number()` : Génère numéro unique

### Classe Contact

**Fonctions de consentement** :
- `can_send_marketing_email(contact_id)` : Peut envoyer email
- `can_send_whatsapp(contact_id)` : Peut envoyer WhatsApp
- `has_email_consent(contact_id)` : A consentement email
- `has_whatsapp_consent(contact_id)` : A consentement WhatsApp

**Fonctions de statistiques** :
- `get_email_bounce_rate(contact_id)` : Taux de bounce
- `get_contact_engagement_score(contact_id)` : Score engagement

### Classe Booking

**Fonctions de validation** :
- `has_available_spots(linguistic_travel_id)` : Places disponibles
- `can_create_booking(linguistic_travel_id)` : Peut créer réservation
- `is_payment_overdue(booking_id)` : Paiement en retard
- `should_cancel_booking(booking_id)` : Doit être annulé

## Intégration Services ↔ Fonctions SQL

### Exemple : TravelService

![Diagram](images/06_class_diagram_with_functions_mermaid_08.png)

### Exemple : QuoteService

![Diagram](images/06_class_diagram_with_functions_mermaid_09.png)

## Avantages de l'Architecture avec Fonctions SQL

1. **Séparation des responsabilités** : Logique métier dans la base de données, logique applicative dans les services
2. **Performance** : Exécution côté serveur, réduction de la charge réseau
3. **Cohérence** : Calculs centralisés, mêmes résultats partout
4. **Réutilisabilité** : Fonctions utilisables depuis plusieurs services
5. **Maintenance** : Modifications de logique en un seul endroit
