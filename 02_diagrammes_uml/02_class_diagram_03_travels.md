# Diagramme de Classes - Teachers & Travels

```mermaid
classDiagram
    class Teacher {
        +Integer id
        +String name
        +String email
        +String phone
        +String school
        +String school_address
        +String school_city
        +String school_postal_code
        +Integer odoo_partner_id
        +Integer odoo_contact_id
        +JSON form_data
        +DateTime created_at
        +DateTime updated_at
    }
    
    class Travel {
        +Integer id
        +String name
        +TravelType travel_type
        +Integer destination_id
        +Integer program_template_id
        +DateTime start_date
        +DateTime end_date
        +Integer min_participants
        +Integer max_participants
        +Integer number_participants
        +TravelStatus status
        +Float total_price
        +Integer teacher_id
        +Integer odoo_lead_id
        +Integer odoo_quote_id
        +Integer odoo_invoice_id
        +Boolean parent_contacts_collected
        +DateTime created_at
        +DateTime updated_at
    }
    
    class TravelStatusHistory {
        +Integer id
        +Integer travel_id
        +TravelStatus from_status
        +TravelStatus to_status
        +DateTime changed_at
        +Integer changed_by
    }
    
    class TravelType {
        <<enumeration>>
        SCHOOL
        LINGUISTIC_GROUP
    }
    
    class TravelStatus {
        <<enumeration>>
        DRAFT
        QUOTE_SENT
        QUOTE_VALIDATED
        CONFIRMED
        IN_PROGRESS
        COMPLETED
        CANCELLED
    }
    
    Teacher "1" *-- "*" Travel
    Travel "1" *-- "*" TravelStatusHistory
    Travel --> TravelType
    Travel --> TravelStatus
    TravelStatusHistory --> TravelStatus
```

## Notes

**Workflow Travel Status** :
- DRAFT → QUOTE_SENT → QUOTE_VALIDATED → CONFIRMED → IN_PROGRESS → COMPLETED
- CANCELLED peut survenir à tout moment

---

**Version** : 1.0  
**Date** : 2025-01-20
