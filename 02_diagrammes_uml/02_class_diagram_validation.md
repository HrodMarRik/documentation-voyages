# Diagramme de Classes - Domaine Validations

## Vue d'Ensemble

Ce diagramme présente les classes et fonctions SQL du domaine des validations métier.

## Diagramme de Classes

![Diagram](images/02_class_diagram_validation_mermaid_01.png)

```plantuml
!theme plain

class Travel {
    +int id
    +enum status
    +boolean parent_contacts_collected
    +int number_participants
}
class Quote {
    +int id
    +int travel_id
    +enum status
    +datetime expires_at
}
class Invoice {
    +int id
    +int travel_id
    +enum status
    +datetime due_date
}
class Activity {
    +int id
    +int travel_id
    +datetime date
    +string start_time
    +string end_time
}
class Booking {
    +int id
    +enum status
    +enum payment_status
    +datetime created_at
}
class ValidationFunctions {
    <<SQL Functions>>
    +can_generate_quote(travel_id) boolean
    +can_validate_quote(quote_id) boolean
    +can_generate_invoice(travel_id) boolean
    +can_validate_invoice(invoice_id) boolean
    +is_planning_valid(travel_id) boolean
    +has_valid_planning(travel_id) boolean
    +has_overlapping_activities(travel_id) boolean
    +planning_covers_travel_days(travel_id) boolean
    +has_available_spots(linguistic_travel_id) boolean
    +can_create_booking(linguistic_travel_id) boolean
    +is_payment_overdue(booking_id) boolean
    +should_cancel_booking(booking_id) boolean
    +are_all_parent_contacts_collected(travel_id) boolean
}
class ValidationService {
    +validate_quote_generation(travel_id) boolean
    +validate_invoice_generation(travel_id) boolean
    +validate_planning(travel_id) boolean
}

Travel --> ValidationFunctions : utilise
Quote --> ValidationFunctions : utilise
Invoice --> ValidationFunctions : utilise
Activity --> ValidationFunctions : utilise
Booking --> ValidationFunctions : utilise
ValidationService --> ValidationFunctions : appelle
```

## Relations de Validation

![Diagram](images/02_class_diagram_validation_mermaid_02.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' graph TB
'     V1[can_generate_quote] --> V2[Vérifie statut]
'     V1 --> V3[Vérifie destinations]
'     V1 --> V4[Vérifie participants]
'     V1 --> V5[Vérifie prix transport]
'     
'     V6[can_generate_invoice] --> V7[Vérifie devis validé]
'     V6 --> V8[are_all_parent_contacts_collected]
'     V6 --> V9[Vérifie participants exacts]
'     
'     V10[is_planning_valid] --> V11[has_valid_planning]
'     V10 --> V12[has_overlapping_activities]
'     V10 --> V13[planning_covers_travel_days]
```

---

**Version** : 1.0  
**Date** : 2025-01-20
