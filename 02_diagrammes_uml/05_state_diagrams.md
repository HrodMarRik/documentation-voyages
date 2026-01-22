# Diagrammes d'État - Système Intégré de Gestion

## 1. Travel Status

![Diagram](images/05_state_diagrams_mermaid_01.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' stateDiagram-v2
'     [*] --> DRAFT: Création voyage
'     
'     DRAFT --> QUOTE_SENT: Devis envoyé
'     QUOTE_SENT --> QUOTE_VALIDATED: Devis validé
'     QUOTE_SENT --> CANCELLED: Annulation
'     
'     QUOTE_VALIDATED --> CONFIRMED: Dossier validé + Facture générée
'     QUOTE_VALIDATED --> CANCELLED: Annulation
'     
'     CONFIRMED --> IN_PROGRESS: Début voyage
'     IN_PROGRESS --> COMPLETED: Fin voyage
'     
'     DRAFT --> CANCELLED: Annulation à tout moment
'     QUOTE_SENT --> CANCELLED: Annulation
'     QUOTE_VALIDATED --> CANCELLED: Annulation
'     CONFIRMED --> CANCELLED: Annulation rare
'     
'     COMPLETED --> [*]
'     CANCELLED --> [*]
'     
'     note right of DRAFT
'         État initial
'         Formulaire rempli
'         Fonction: can_generate_quote()
'     end note
'     
'     note right of QUOTE_SENT
'         Devis envoyé au professeur
'         En attente de réponse
'         Fonction: is_quote_expired()
'         Fonction: days_until_quote_expiry()
'     end note
'     
'     note right of QUOTE_VALIDATED
'         Devis accepté
'         Contacts parents collectés
'         Fonction: are_all_parent_contacts_collected()
'         Fonction: can_generate_invoice()
'     end note
'     
'     note right of CONFIRMED
'         Facture générée et validée
'         Voyage confirmé
'         Fonction: can_validate_invoice()
'         Procédure: sp_generate_invoice_from_quote()
'     end note
```

## 2. Booking Status

![Diagram](images/05_state_diagrams_mermaid_02.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' stateDiagram-v2
'     [*] --> PENDING: Inscription voyage linguistique
'     
'     PENDING --> CONFIRMED: Paiement réussi
'     PENDING --> CANCELLED: Paiement échoué ou timeout
'     
'     CONFIRMED --> CANCELLED: Annulation remboursement
'     
'     CONFIRMED --> [*]
'     CANCELLED --> [*]
'     
'     note right of PENDING
'         Réservation créée
'         En attente de paiement
'         Timeout: 24h
'     end note
'     
'     note right of CONFIRMED
'         Paiement effectué
'         Réservation confirmée
'     end note
```

## 3. Quote Status

![Diagram](images/05_state_diagrams_mermaid_03.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' stateDiagram-v2
'     [*] --> DRAFT: Création devis
'     
'     DRAFT --> SENT: Devis envoyé
'     SENT --> VALIDATED: Devis validé
'     SENT --> REJECTED: Devis refusé
'     
'     VALIDATED --> [*]: Facture générée
'     REJECTED --> [*]
'     DRAFT --> [*]: Suppression
'     
'     note right of DRAFT
'         Devis en cours de création
'         Modifiable
'         Fonction: can_send_quote()
'     end note
'     
'     note right of SENT
'         Devis envoyé au client
'         En attente de réponse
'         Expiration possible
'         Fonction: is_quote_expired()
'         Fonction: can_validate_quote()
'     end note
'     
'     note right of VALIDATED
'         Devis accepté
'         Peut générer facture
'         Fonction: can_create_invoice_from_quote()
'         Procédure: sp_generate_invoice_from_quote()
'     end note
```

## 4. Invoice Status

![Diagram](images/05_state_diagrams_mermaid_04.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' stateDiagram-v2
'     [*] --> DRAFT: Création facture
'     
'     DRAFT --> VALIDATED: Validation commercial/comptable
'     VALIDATED --> PAID: Paiement reçu
'     VALIDATED --> CANCELLED: Annulation
'     
'     PAID --> [*]
'     CANCELLED --> [*]
'     DRAFT --> [*]: Suppression
'     
'     note right of DRAFT
'         Facture en cours de création
'         Modifiable
'         Fonction: can_validate_invoice()
'     end note
'     
'     note right of VALIDATED
'         Facture validée
'         Export Factur-X possible
'         Synchronisation Odoo
'         Fonction: get_invoice_total_ttc()
'         Fonction: is_invoice_overdue()
'         Fonction: days_until_invoice_due()
'     end note
'     
'     note right of PAID
'         Facture payée
'         État final
'         Fonction: is_invoice_paid()
'     end note
```

## 5. Transitions avec Fonctions de Validation

### Diagramme des Validations par État

![Diagram](images/05_state_diagrams_mermaid_05.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' stateDiagram-v2
'     [*] --> DRAFT: Création
'     
'     DRAFT --> QUOTE_SENT: can_generate_quote() = TRUE<br/>sp_generate_quote_for_travel()
'     
'     QUOTE_SENT --> QUOTE_VALIDATED: can_validate_quote() = TRUE<br/>is_quote_expired() = FALSE<br/>sp_update_travel_status()
'     
'     QUOTE_VALIDATED --> CONFIRMED: can_generate_invoice() = TRUE<br/>are_all_parent_contacts_collected() = TRUE<br/>sp_generate_invoice_from_quote()
'     
'     CONFIRMED --> IN_PROGRESS: is_travel_upcoming() = FALSE<br/>is_travel_in_progress() = TRUE
'     
'     IN_PROGRESS --> COMPLETED: is_travel_in_past() = TRUE
'     
'     DRAFT --> CANCELLED: Annulation
'     QUOTE_SENT --> CANCELLED: Annulation
'     QUOTE_VALIDATED --> CANCELLED: Annulation
'     
'     COMPLETED --> [*]
'     CANCELLED --> [*]
'     
'     note right of DRAFT
'         Validation: can_generate_quote()
'         - Statut = draft ou quote_sent
'         - Au moins une destination
'         - Participants définis
'         - Prix transport renseignés
'     end note
'     
'     note right of QUOTE_VALIDATED
'         Validation: can_generate_invoice()
'         - Devis validé
'         - Tous contacts parents collectés
'         - Nombre exact participants connu
'     end note
```

## 6. États de Booking avec Validations

![Diagram](images/05_state_diagrams_mermaid_06.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' stateDiagram-v2
'     [*] --> PENDING: Création réservation
'     
'     PENDING --> CONFIRMED: Paiement réussi<br/>is_payment_overdue() = FALSE
'     
'     PENDING --> CANCELLED: is_payment_overdue() = TRUE<br/>should_cancel_booking() = TRUE<br/>sp_cancel_overdue_bookings()
'     
'     CONFIRMED --> CANCELLED: Annulation remboursement
'     
'     CONFIRMED --> [*]
'     CANCELLED --> [*]
'     
'     note right of PENDING
'         Validation: can_create_booking()
'         - Voyage publié
'         - Places disponibles
'         - has_available_spots() = TRUE
'     end note
'     
'     note right of PENDING
'         Timeout: 24h
'         Fonction: is_payment_overdue()
'         Procédure: sp_cancel_overdue_bookings()
'     end note
```

---

**Version** : 2.0  
**Date** : 2025-01-20  
**Mise à jour** : Ajout des fonctions de validation dans les transitions d'état
