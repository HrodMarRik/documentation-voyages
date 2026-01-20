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

### Vue d'Ensemble

```mermaid
flowchart TD
    Start([Start]) --> Init[Initialiser calcul]
    Init --> CalcTransport[Calcul Transport]
    CalcTransport --> CalcActivities[Calcul Activités]
    CalcActivities --> CalcLodging[Calcul Hébergement]
    CalcLodging --> ApplyReductions[Application Réductions]
    ApplyReductions --> ApplyMargin[Application Marge]
    ApplyMargin --> CreateQuote[Créer Quote]
    CreateQuote --> End([End])
```

### Détails du Calcul

#### 3.1 Calcul Transport

```mermaid
flowchart TD
    Start([Start]) --> Loop[Pour chaque TravelDestination]
    Loop --> GetPrice[Récupérer TransportPrice<br/>destination_id, date]
    GetPrice --> Calc[Calculer: price × participants]
    Calc --> Add[Ajouter à total_amount]
    Add --> Next{Autre destination?}
    Next -->|Oui| Loop
    Next -->|Non| End([Fin])
```

#### 3.2 Calcul Activités

```mermaid
flowchart TD
    Start([Start]) --> Check{ProgramTemplate validé?}
    Check -->|Non| End([Fin])
    Check -->|Oui| Loop[Pour chaque ProgramTemplateActivity]
    Loop --> GetPrice[Récupérer Activity.price]
    GetPrice --> Calc[Calculer: price × participants]
    Calc --> Add[Ajouter à total_amount]
    Add --> Next{Autre activité?}
    Next -->|Oui| Loop
    Next -->|Non| End
```

#### 3.3 Calcul Hébergement

```mermaid
flowchart TD
    Start([Start]) --> Check{lodging_price_per_person renseigné?}
    Check -->|Non| End([Fin])
    Check -->|Oui| Calc[Calculer: lodging_price × participants × jours]
    Calc --> Add[Ajouter à total_amount]
    Add --> End
```

#### 3.4 Application Réductions

```mermaid
flowchart TD
    Start([Start]) --> Check30{participants ≥ 30?}
    Check30 -->|Oui| Reduce10[total_amount × 0.90<br/>10% réduction]
    Check30 -->|Non| Check20{participants ≥ 20?}
    Check20 -->|Oui| Reduce5[total_amount × 0.95<br/>5% réduction]
    Check20 -->|Non| Check10{participants ≥ 10?}
    Check10 -->|Oui| Reduce3[total_amount × 0.97<br/>3% réduction]
    Check10 -->|Non| CheckEarly
    
    Reduce10 --> CheckEarly
    Reduce5 --> CheckEarly
    Reduce3 --> CheckEarly
    
    CheckEarly{Réservation > 3 mois?}
    CheckEarly -->|Oui| EarlyBird[total_amount × 0.95<br/>5% early bird]
    CheckEarly -->|Non| End([Fin])
    EarlyBird --> End
```

#### 3.5 Application Marge

```mermaid
flowchart TD
    Start([Start]) --> Check{margin_percent renseigné?}
    Check -->|Non| End([Fin])
    Check -->|Oui| Apply[total_amount × 1 + margin_percent/100]
    Apply --> End
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
