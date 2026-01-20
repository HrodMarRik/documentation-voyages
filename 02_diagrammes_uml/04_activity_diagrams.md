# Diagrammes d'Activité - Système Intégré de Gestion

## 1. Workflow Voyage Scolaire

```mermaid
flowchart TD
    Start([Start]) --> FillForm[Professeur remplit formulaire public]
    FillForm --> CreateTravel[Créer Teacher + Travel DRAFT]
    CreateTravel --> Notify[Commercial reçoit notification]
    Notify --> GeneratePlanning[Commercial génère planning préconstruit]
    GeneratePlanning --> ModifyPlanning[Commercial modifie/valide planning]
    ModifyPlanning --> EnterTransport[Commercial saisit prix transport<br/>par destination/date]
    EnterTransport --> GenerateQuote[Commercial génère devis]
    
    GenerateQuote --> Note1[Calcul automatique:<br/>- Transport × participants<br/>- Activités si planning validé<br/>- Hébergement si renseigné<br/>- Marge si renseignée<br/>- Réductions selon participants]
    
    Note1 --> SendQuote[Commercial envoie devis au professeur]
    SendQuote --> Status1[Travel status → QUOTE_SENT]
    Status1 --> Decision1{Professeur accepte devis?}
    
    Decision1 -->|Oui| ValidateQuote[Commercial valide devis]
    ValidateQuote --> Status2[Travel status → QUOTE_VALIDATED]
    Status2 --> SendContacts[Professeur envoie contacts parents]
    SendContacts --> ConfirmParticipants[Professeur confirme nombre exact participants]
    ConfirmParticipants --> Decision2{Nombre participants changé?}
    
    Decision2 -->|Oui| Recalculate[Commercial recalcule devis transport]
    Recalculate --> ValidateDossier
    Decision2 -->|Non| ValidateDossier[Commercial valide dossier]
    
    ValidateDossier --> DossierValidated[Travel dossier_validated = True]
    DossierValidated --> GenerateInvoice[Commercial génère facture depuis devis]
    
    GenerateInvoice --> Note2[Conditions:<br/>- Quote status = validated<br/>- Travel dossier_validated = True]
    
    Note2 --> ValidateInvoice[Commercial valide facture]
    ValidateInvoice --> SendInvoice[Envoi facture au professeur]
    SendInvoice --> SyncOdoo[Synchronisation Odoo]
    SyncOdoo --> Status3[Travel status → CONFIRMED]
    Status3 --> InProgress[Voyage en cours]
    InProgress --> Status4[Travel status → IN_PROGRESS]
    Status4 --> Completed[Voyage terminé]
    Completed --> Status5[Travel status → COMPLETED]
    Status5 --> End([End])
    
    Decision1 -->|Non| Cancel[Commercial annule commande]
    Cancel --> Status6[Travel status → CANCELLED]
    Status6 --> End
```

## 2. Workflow Voyage Linguistique

```mermaid
flowchart TD
    Start([Start]) --> Consult[Guest consulte catalogue voyages]
    Consult --> Select[Guest sélectionne voyage]
    Select --> FillForm[Guest remplit formulaire inscription]
    FillForm --> Create[Créer Guest + Booking PENDING]
    Create --> Redirect[Redirection Stripe Checkout]
    Redirect --> Decision{Paiement réussi?}
    
    Decision -->|Oui| Webhook[Stripe webhook payment_intent.succeeded]
    Webhook --> Status1[Booking status → CONFIRMED]
    Status1 --> Payment[Booking payment_status → PAID]
    Payment --> Email[Envoi email confirmation]
    Email --> Sync[Synchronisation Odoo création contact]
    Sync --> TravelInProgress[Voyage en cours]
    TravelInProgress --> TravelEnd[Voyage terminé]
    TravelEnd --> End([End])
    
    Decision -->|Non| Status2[Booking status → CANCELLED]
    Status2 --> PaymentFailed[Booking payment_status → FAILED]
    PaymentFailed --> End
```

## 3. Génération Devis Automatique

```mermaid
flowchart TD
    Start([Start]) --> Receive[Recevoir travel_id]
    Receive --> GetTravel[Récupérer Travel + Destinations]
    GetTravel --> GetTemplate[Récupérer ProgramTemplate si validé]
    GetTemplate --> Init[Initialiser total_amount = 0]
    
    Init --> TransportCalc[Calcul Transport]
    TransportCalc --> TransportLoop[Pour chaque TravelDestination]
    TransportLoop --> GetPrice[Récupérer TransportPrice<br/>destination_id, date]
    GetPrice --> CalcTransport[Calculer: price × participants]
    CalcTransport --> AddTransport[Ajouter à total_amount]
    
    AddTransport --> ActivityCalc[Calcul Activités]
    ActivityCalc --> Decision1{ProgramTemplate validé?}
    Decision1 -->|Oui| ActivityLoop[Pour chaque ProgramTemplateActivity]
    ActivityLoop --> GetActivityPrice[Récupérer Activity.price]
    GetActivityPrice --> CalcActivity[Calculer: price × participants]
    CalcActivity --> AddActivity[Ajouter à total_amount]
    AddActivity --> LodgingCalc
    Decision1 -->|Non| LodgingCalc[Calcul Hébergement]
    
    AddActivity --> LodgingCalc
    LodgingCalc --> Decision2{lodging_price_per_person renseigné?}
    Decision2 -->|Oui| CalcLodging[Calculer: lodging_price × participants × jours]
    CalcLodging --> AddLodging[Ajouter à total_amount]
    AddLodging --> Reductions
    Decision2 -->|Non| Reductions[Application Réductions]
    
    Reductions --> Decision3{participants ≥ 30?}
    Decision3 -->|Oui| Reduce10[total_amount × 0.90 10% réduction]
    Decision3 -->|Non| Decision4{participants ≥ 20?}
    Decision4 -->|Oui| Reduce5[total_amount × 0.95 5% réduction]
    Decision4 -->|Non| Decision5{participants ≥ 10?}
    Decision5 -->|Oui| Reduce3[total_amount × 0.97 3% réduction]
    Decision5 -->|Non| EarlyBird
    
    Reduce10 --> EarlyBird
    Reduce5 --> EarlyBird
    Reduce3 --> EarlyBird
    
    EarlyBird --> Decision6{Réservation > 3 mois?}
    Decision6 -->|Oui| EarlyBird5[total_amount × 0.95 5% early bird]
    EarlyBird5 --> Margin
    Decision6 -->|Non| Margin[Application Marge]
    
    Margin --> Decision7{margin_percent renseigné?}
    Decision7 -->|Oui| ApplyMargin[total_amount × 1 + margin_percent/100]
    ApplyMargin --> CreateQuote
    Decision7 -->|Non| CreateQuote[Créer Quote avec total_amount]
    
    CreateQuote --> CreateLines[Créer QuoteLines détaillées]
    CreateLines --> End([End])
```

## 4. Validation Dossier → Facture

```mermaid
flowchart TD
    Start([Start]) --> QuoteValidated[Devis validé]
    QuoteValidated --> Status[Travel status = QUOTE_VALIDATED]
    Status --> SendContacts[Professeur envoie contacts parents]
    SendContacts --> Confirm[Professeur confirme nombre exact participants]
    Confirm --> Decision{Nombre participants changé?}
    
    Decision -->|Oui| Recalculate[Recalculer devis transport]
    Recalculate --> Validate
    Decision -->|Non| Validate[Commercial valide dossier]
    
    Validate --> DossierValidated[Travel dossier_validated = True]
    DossierValidated --> GenerateInvoice[Commercial génère facture depuis devis]
    
    GenerateInvoice --> Conversion[Conversion Devis → Facture]
    Conversion --> GetLines[Récupérer QuoteLines]
    GetLines --> Convert[Convertir en InvoiceLines]
    Convert --> CalcTVA[Calculer TVA 20%]
    CalcTVA --> CreateInvoice[Créer Invoice]
    
    CreateInvoice --> ValidateInvoice[Commercial valide facture]
    ValidateInvoice --> InvoiceStatus[Invoice status → validated]
    InvoiceStatus --> Export[Export Factur-X XML]
    Export --> Store[Stockage document]
    Store --> SyncOdoo[Synchronisation Odoo]
    SyncOdoo --> CreateOdoo[Création facture Odoo]
    CreateOdoo --> SendInvoice[Envoi facture au professeur]
    SendInvoice --> Confirmed[Travel status → CONFIRMED]
    Confirmed --> End([End])
```

## 5. Authentification 2FA

```mermaid
flowchart TD
    Start([Start]) --> Input[Utilisateur saisit email/password]
    Input --> Verify[Vérifier credentials]
    Verify --> Decision1{Credentials valides?}
    
    Decision1 -->|Non| Error1[Erreur authentification]
    Error1 --> End1([End])
    
    Decision1 -->|Oui| Decision2{2FA activé?}
    
    Decision2 -->|Oui| Return2FA[Retourner requires_2fa: true]
    Return2FA --> InputCode[Utilisateur saisit code TOTP]
    InputCode --> Decision3{Code TOTP valide?}
    
    Decision3 -->|Oui| GenerateTokens[Générer JWT tokens]
    GenerateTokens --> ReturnTokens[Retourner access_token + refresh_token]
    ReturnTokens --> End2([End])
    
    Decision3 -->|Non| Error2[Erreur code invalide]
    Error2 --> End3([End])
    
    Decision2 -->|Non| GenerateTokens2[Générer JWT tokens]
    GenerateTokens2 --> ReturnTokens2[Retourner access_token + refresh_token]
    ReturnTokens2 --> End4([End])
```

## 6. Synchronisation Odoo

```mermaid
flowchart TD
    Start([Start]) --> Identify[Identifier entités à synchroniser]
    
    Identify --> SyncContacts[Synchronisation Contacts]
    SyncContacts --> ContactLoop[Pour chaque Teacher/Guest]
    ContactLoop --> Decision1{odoo_partner_id existe?}
    Decision1 -->|Non| CreateContact[Créer contact Odoo]
    CreateContact --> GetPartnerId[Récupérer odoo_partner_id]
    GetPartnerId --> UpdateLocal[Mettre à jour entité locale]
    UpdateLocal --> SyncInvoices
    Decision1 -->|Oui| UpdateContact[Mettre à jour contact Odoo]
    UpdateContact --> SyncInvoices[Synchronisation Factures]
    
    SyncInvoices --> InvoiceLoop[Pour chaque Invoice validée]
    InvoiceLoop --> Decision2{odoo_invoice_id existe?}
    Decision2 -->|Non| CreateInvoice[Créer facture Odoo]
    CreateInvoice --> GetInvoiceId[Récupérer odoo_invoice_id]
    GetInvoiceId --> SyncCRM
    Decision2 -->|Oui| SyncCRM[Synchronisation CRM]
    
    SyncCRM --> CRMLoop[Pour chaque Travel nouveau]
    CRMLoop --> Decision3{odoo_lead_id existe?}
    Decision3 -->|Non| CreateLead[Créer lead Odoo]
    CreateLead --> GetLeadId[Récupérer odoo_lead_id]
    GetLeadId --> Log
    Decision3 -->|Oui| Log[Logger résultats synchronisation]
    
    Log --> End([End])
```

---

**Version** : 1.0  
**Date** : 2025-01-20
