# Diagramme de Classes - Domaine Communication

## Vue d'Ensemble

Ce diagramme présente les classes et fonctions SQL du domaine de la communication (email et WhatsApp).

## Diagramme de Classes

![Diagram](images/02_class_diagram_communication_mermaid_01.png)

```plantuml
!theme plain

class Contact {
    +int id
    +int user_id
    +boolean email_marketing_consent
    +timestamp email_consent_date
    +timestamp email_opt_in_date
    +timestamp email_opt_out_date
    +int email_bounce_count
    +timestamp email_last_sent
    +boolean whatsapp_consent
    +timestamp whatsapp_consent_date
    +timestamp whatsapp_opt_in_date
    +timestamp whatsapp_opt_out_date
    +boolean whatsapp_verified
    +timestamp whatsapp_last_contact
}
class ContactHistory {
    +int id
    +int contact_id
    +enum contact_type
    +enum action
    +json details
}
class CommunicationFunctions {
    <<SQL Functions>>
    +can_send_marketing_email(contact_id) boolean
    +can_send_whatsapp(contact_id) boolean
    +has_email_consent(contact_id) boolean
    +has_whatsapp_consent(contact_id) boolean
    +is_contact_opted_out_email(contact_id) boolean
    +is_contact_opted_out_whatsapp(contact_id) boolean
    +get_email_bounce_rate(contact_id) decimal
    +days_since_last_email(contact_id) int
    +days_since_last_whatsapp(contact_id) int
    +get_contact_engagement_score(contact_id) int
}
class ContactService {
    +check_email_consent(contact_id) boolean
    +check_whatsapp_consent(contact_id) boolean
    +send_marketing_email(contact_id) void
    +send_whatsapp(contact_id) void
    +get_engagement_score(contact_id) int
}

Contact --> ContactHistory : génère
Contact --> CommunicationFunctions : utilise
ContactService --> CommunicationFunctions : appelle
ContactService --> Contact : modifie
```

## Flux de Validation des Consentements

![Diagram](images/02_class_diagram_communication_mermaid_02.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' graph TB
'     CheckEmail[can_send_marketing_email] --> HasConsent[has_email_consent]
'     CheckEmail --> NotOptOut[NOT is_contact_opted_out_email]
'     
'     CheckWhatsApp[can_send_whatsapp] --> HasWhatsAppConsent[has_whatsapp_consent]
'     CheckWhatsApp --> NotOptOutWhatsApp[NOT is_contact_opted_out_whatsapp]
'     CheckWhatsApp --> IsVerified[whatsapp_verified = TRUE]
```

---

**Version** : 1.0  
**Date** : 2025-01-20
