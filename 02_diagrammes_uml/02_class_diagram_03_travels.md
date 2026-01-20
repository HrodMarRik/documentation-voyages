# Diagramme de Classes - Teachers & Travels

```mermaid
classDiagram
    class School {
        +Integer id
        +String name
        +SchoolType school_type
        +String address
        +String city
        +String postal_code
        +String country
        +String phone
        +String website
        +String email_primary
        +String email_secondary
        +Boolean email_marketing_consent
        +DateTime email_consent_date
        +DateTime email_opt_in_date
        +DateTime email_opt_out_date
        +JSON email_preferences
        +Integer email_bounce_count
        +DateTime email_last_sent
        +String whatsapp_phone_primary
        +String whatsapp_phone_secondary
        +Boolean whatsapp_consent
        +DateTime whatsapp_consent_date
        +DateTime whatsapp_opt_in_date
        +DateTime whatsapp_opt_out_date
        +Boolean whatsapp_verified
        +DateTime whatsapp_verification_date
        +JSON whatsapp_template_preferences
        +DateTime whatsapp_last_contact
        +Integer odoo_partner_id
        +Integer odoo_contact_id
        +Boolean is_active
        +DateTime created_at
        +DateTime updated_at
    }
    
    class SchoolContactHistory {
        +Integer id
        +Integer school_id
        +ContactType contact_type
        +Action action
        +JSON details
        +DateTime created_at
    }
    
    class SchoolType {
        <<enumeration>>
        PRIMARY
        MIDDLE
        HIGH
        COLLEGE
        OTHER
    }
    
    class ContactType {
        <<enumeration>>
        EMAIL
        WHATSAPP
    }
    
    class Action {
        <<enumeration>>
        OPT_IN
        OPT_OUT
        CONSENT_GIVEN
        CONSENT_WITHDRAWN
        MESSAGE_SENT
        BOUNCE
        VERIFICATION
    }
    
    class Teacher {
        +Integer id
        +String name
        +String email
        +String phone
        +Integer school_id
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
    
    class Booking {
        +Integer id
        +Integer travel_id
        +Integer school_id
        +String participant_name
        +Integer age
        +String email
        +String phone
        +Float price
        +BookingStatus status
        +PaymentStatus payment_status
        +String payment_id
        +Integer odoo_partner_id
        +DateTime created_at
        +DateTime updated_at
    }
    
    class BookingStatus {
        <<enumeration>>
        PENDING
        CONFIRMED
        CANCELLED
    }
    
    class PaymentStatus {
        <<enumeration>>
        PENDING
        PAID
        FAILED
        REFUNDED
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
    
    School "1" *-- "*" Teacher
    School "1" *-- "*" Booking
    School "1" *-- "*" SchoolContactHistory
    Teacher "1" *-- "*" Travel
    Travel "1" *-- "*" TravelStatusHistory
    Travel "1" *-- "*" Booking
    School --> SchoolType
    SchoolContactHistory --> ContactType
    SchoolContactHistory --> Action
    Travel --> TravelType
    Travel --> TravelStatus
    TravelStatusHistory --> TravelStatus
    Booking --> BookingStatus
    Booking --> PaymentStatus
```

## Notes

**Workflow Travel Status** :
- DRAFT → QUOTE_SENT → QUOTE_VALIDATED → CONFIRMED → IN_PROGRESS → COMPLETED
- CANCELLED peut survenir à tout moment

---

**Version** : 1.0  
**Date** : 2025-01-20
