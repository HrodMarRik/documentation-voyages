# Diagrammes d'Activité - Système Intégré de Gestion

## 1. Workflow Voyage Scolaire

![Diagram](images/04_activity_diagrams_mermaid_01.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' flowchart TD
'     Start([Start]) --> FillForm[Professeur remplit formulaire public]
'     FillForm --> CreateTravel[Créer Teacher + Travel DRAFT]
'     CreateTravel --> Notify[Commercial reçoit notification]
'     Notify --> GeneratePlanning[Commercial génère planning préconstruit]
'     GeneratePlanning --> ModifyPlanning[Commercial modifie/valide planning]
'     ModifyPlanning --> EnterTransport[Commercial saisit prix transport<br/>par destination/date]
'     EnterTransport --> GenerateQuote[Commercial génère devis]
'     
'     GenerateQuote --> ValidateGen[Appel: can_generate_quote(travel_id)]
'     ValidateGen --> DecisionGen{Devis générable?}
'     DecisionGen -->|Non| ErrorGen[Erreur: conditions non remplies]
'     ErrorGen --> End
'     
'     DecisionGen -->|Oui| CallProc[Appel: sp_generate_quote_for_travel()]
'     CallProc --> CalcPrice[Calcul prix avec fonctions SQL:<br/>- calculate_transport_price()<br/>- calculate_activities_price()<br/>- calculate_lodging_price()<br/>- calculate_participant_discount()<br/>- is_early_bird()<br/>- calculate_final_travel_price()]
'     
'     CalcPrice --> GenNumber[Génération numéro:<br/>generate_quote_number()]
'     GenNumber --> CreateQuote[Création Quote + QuoteLines]
'     CreateQuote --> SendQuote[Commercial envoie devis au professeur]
'     SendQuote --> Status1[Travel status → QUOTE_SENT]
'     Status1 --> Decision1{Professeur accepte devis?}
'     
'     Decision1 -->|Oui| ValidateQuote[Commercial valide devis]
'     ValidateQuote --> CheckValid[Appel: can_validate_quote(quote_id)]
'     CheckValid --> DecisionValid{Devis validable?}
'     DecisionValid -->|Non| ErrorValid[Erreur: devis expiré ou invalide]
'     ErrorValid --> End
'     DecisionValid -->|Oui| UpdateStatus[Appel: sp_update_travel_status()<br/>avec historique]
'     UpdateStatus --> Status2[Travel status → QUOTE_VALIDATED]
'     Status2 --> SendContacts[Professeur envoie contacts parents]
'     SendContacts --> ConfirmParticipants[Professeur confirme nombre exact participants]
'     ConfirmParticipants --> Decision2{Nombre participants changé?}
'     
'     Decision2 -->|Oui| Recalculate[Commercial recalcule devis transport]
'     Recalculate --> ValidateDossier
'     Decision2 -->|Non| ValidateDossier[Commercial valide dossier]
'     
'     ValidateDossier --> CheckContacts[Appel: are_all_parent_contacts_collected()]
'     CheckContacts --> DecisionContacts{Tous contacts collectés?}
'     DecisionContacts -->|Non| ErrorContacts[Erreur: contacts manquants]
'     ErrorContacts --> End
'     DecisionContacts -->|Oui| DossierValidated[Travel dossier_validated = True<br/>Appel: sp_collect_parent_contacts()]
'     
'     DossierValidated --> CheckInvoice[Appel: can_generate_invoice(travel_id)]
'     CheckInvoice --> DecisionInvoice{Facture générable?}
'     DecisionInvoice -->|Non| ErrorInvoice[Erreur: conditions non remplies]
'     ErrorInvoice --> End
'     DecisionInvoice -->|Oui| GenerateInvoice[Appel: sp_generate_invoice_from_quote()<br/>- generate_invoice_number()<br/>- calculate_tax_amount()<br/>- calculate_amount_ttc()]
'     
'     GenerateInvoice --> ValidateInvoice[Commercial valide facture]
'     ValidateInvoice --> CheckInvoiceValid[Appel: can_validate_invoice(invoice_id)]
'     CheckInvoiceValid --> DecisionInvoiceValid{Facture validable?}
'     DecisionInvoiceValid -->|Non| ErrorInvoiceValid[Erreur: facture non validable]
'     ErrorInvoiceValid --> End
'     DecisionInvoiceValid -->|Oui| InvoiceValidated[Facture validée]
'     ValidateInvoice --> SendInvoice[Envoi facture au professeur]
'     SendInvoice --> SyncOdoo[Synchronisation Odoo]
'     SyncOdoo --> Status3[Travel status → CONFIRMED]
'     Status3 --> InProgress[Voyage en cours]
'     InProgress --> Status4[Travel status → IN_PROGRESS]
'     Status4 --> Completed[Voyage terminé]
'     Completed --> Status5[Travel status → COMPLETED]
'     Status5 --> End([End])
'     
'     Decision1 -->|Non| Cancel[Commercial annule commande]
'     Cancel --> Status6[Travel status → CANCELLED]
'     Status6 --> End
```

## 2. Workflow Voyage Linguistique

![Diagram](images/04_activity_diagrams_mermaid_02.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' flowchart TD
'     Start([Start]) --> Consult[Guest consulte catalogue voyages]
'     Consult --> Select[Guest sélectionne voyage]
'     Select --> FillForm[Guest remplit formulaire inscription]
'     FillForm --> Create[Créer Guest + Booking PENDING]
'     Create --> Redirect[Redirection Stripe Checkout]
'     Redirect --> Decision{Paiement réussi?}
'     
'     Decision -->|Oui| Webhook[Stripe webhook payment_intent.succeeded]
'     Webhook --> Status1[Booking status → CONFIRMED]
'     Status1 --> Payment[Booking payment_status → PAID]
'     Payment --> Email[Envoi email confirmation]
'     Email --> Sync[Synchronisation Odoo création contact]
'     Sync --> TravelInProgress[Voyage en cours]
'     TravelInProgress --> TravelEnd[Voyage terminé]
'     TravelEnd --> End([End])
'     
'     Decision -->|Non| Status2[Booking status → CANCELLED]
'     Status2 --> PaymentFailed[Booking payment_status → FAILED]
'     PaymentFailed --> End
```

## 3. Génération Devis Automatique

### Vue d'Ensemble

![Diagram](images/04_activity_diagrams_mermaid_03.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' flowchart TD
'     Start([Start]) --> Init[Initialiser calcul]
'     Init --> CalcTransport[Calcul Transport]
'     CalcTransport --> CalcActivities[Calcul Activités]
'     CalcActivities --> CalcLodging[Calcul Hébergement]
'     CalcLodging --> ApplyReductions[Application Réductions]
'     ApplyReductions --> ApplyMargin[Application Marge]
'     ApplyMargin --> CreateQuote[Créer Quote]
'     CreateQuote --> End([End])
```

### Détails du Calcul

#### 3.1 Calcul Transport

![Diagram](images/04_activity_diagrams_mermaid_04.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' flowchart TD
'     Start([Start]) --> Loop[Pour chaque TravelDestination]
'     Loop --> GetPrice[Récupérer TransportPrice<br/>destination_id, date]
'     GetPrice --> Calc[Calculer: price × participants]
'     Calc --> Add[Ajouter à total_amount]
'     Add --> Next{Autre destination?}
'     Next -->|Oui| Loop
'     Next -->|Non| End([Fin])
```

#### 3.2 Calcul Activités

![Diagram](images/04_activity_diagrams_mermaid_05.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' flowchart TD
'     Start([Start]) --> Check{ProgramTemplate validé?}
'     Check -->|Non| End([Fin])
'     Check -->|Oui| Loop[Pour chaque ProgramTemplateActivity]
'     Loop --> GetPrice[Récupérer Activity.price]
'     GetPrice --> Calc[Calculer: price × participants]
'     Calc --> Add[Ajouter à total_amount]
'     Add --> Next{Autre activité?}
'     Next -->|Oui| Loop
'     Next -->|Non| End
```

#### 3.3 Calcul Hébergement

![Diagram](images/04_activity_diagrams_mermaid_06.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' flowchart TD
'     Start([Start]) --> Check{lodging_price_per_person renseigné?}
'     Check -->|Non| End([Fin])
'     Check -->|Oui| Calc[Calculer: lodging_price × participants × jours]
'     Calc --> Add[Ajouter à total_amount]
'     Add --> End
```

#### 3.4 Application Réductions

![Diagram](images/04_activity_diagrams_mermaid_07.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' flowchart TD
'     Start([Start]) --> Check30{participants ≥ 30?}
'     Check30 -->|Oui| Reduce10[total_amount × 0.90<br/>10% réduction]
'     Check30 -->|Non| Check20{participants ≥ 20?}
'     Check20 -->|Oui| Reduce5[total_amount × 0.95<br/>5% réduction]
'     Check20 -->|Non| Check10{participants ≥ 10?}
'     Check10 -->|Oui| Reduce3[total_amount × 0.97<br/>3% réduction]
'     Check10 -->|Non| CheckEarly
'     
'     Reduce10 --> CheckEarly
'     Reduce5 --> CheckEarly
'     Reduce3 --> CheckEarly
'     
'     CheckEarly{Réservation > 3 mois?}
'     CheckEarly -->|Oui| EarlyBird[total_amount × 0.95<br/>5% early bird]
'     CheckEarly -->|Non| End([Fin])
'     EarlyBird --> End
```

#### 3.5 Application Marge

![Diagram](images/04_activity_diagrams_mermaid_08.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' flowchart TD
'     Start([Start]) --> Check{margin_percent renseigné?}
'     Check -->|Non| End([Fin])
'     Check -->|Oui| Apply[total_amount × 1 + margin_percent/100]
'     Apply --> End
```

## 4. Validation Dossier → Facture

![Diagram](images/04_activity_diagrams_mermaid_09.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' flowchart TD
'     Start([Start]) --> QuoteValidated[Devis validé]
'     QuoteValidated --> Status[Travel status = QUOTE_VALIDATED]
'     Status --> SendContacts[Professeur envoie contacts parents]
'     SendContacts --> Confirm[Professeur confirme nombre exact participants]
'     Confirm --> Decision{Nombre participants changé?}
'     
'     Decision -->|Oui| Recalculate[Recalculer devis transport]
'     Recalculate --> Validate
'     Decision -->|Non| Validate[Commercial valide dossier]
'     
'     Validate --> DossierValidated[Travel dossier_validated = True]
'     DossierValidated --> GenerateInvoice[Commercial génère facture depuis devis]
'     
'     GenerateInvoice --> Conversion[Conversion Devis → Facture]
'     Conversion --> GetLines[Récupérer QuoteLines]
'     GetLines --> Convert[Convertir en InvoiceLines]
'     Convert --> CalcTVA[Calculer TVA 20%]
'     CalcTVA --> CreateInvoice[Créer Invoice]
'     
'     CreateInvoice --> ValidateInvoice[Commercial valide facture]
'     ValidateInvoice --> InvoiceStatus[Invoice status → validated]
'     InvoiceStatus --> Export[Export Factur-X XML]
'     Export --> Store[Stockage document]
'     Store --> SyncOdoo[Synchronisation Odoo]
'     SyncOdoo --> CreateOdoo[Création facture Odoo]
'     CreateOdoo --> SendInvoice[Envoi facture au professeur]
'     SendInvoice --> Confirmed[Travel status → CONFIRMED]
'     Confirmed --> End([End])
```

## 5. Authentification 2FA

![Diagram](images/04_activity_diagrams_mermaid_10.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' flowchart TD
'     Start([Start]) --> Input[Utilisateur saisit email/password]
'     Input --> Verify[Vérifier credentials]
'     Verify --> Decision1{Credentials valides?}
'     
'     Decision1 -->|Non| Error1[Erreur authentification]
'     Error1 --> End1([End])
'     
'     Decision1 -->|Oui| Decision2{2FA activé?}
'     
'     Decision2 -->|Oui| Return2FA[Retourner requires_2fa: true]
'     Return2FA --> InputCode[Utilisateur saisit code TOTP]
'     InputCode --> Decision3{Code TOTP valide?}
'     
'     Decision3 -->|Oui| GenerateTokens[Générer JWT tokens]
'     GenerateTokens --> ReturnTokens[Retourner access_token + refresh_token]
'     ReturnTokens --> End2([End])
'     
'     Decision3 -->|Non| Error2[Erreur code invalide]
'     Error2 --> End3([End])
'     
'     Decision2 -->|Non| GenerateTokens2[Générer JWT tokens]
'     GenerateTokens2 --> ReturnTokens2[Retourner access_token + refresh_token]
'     ReturnTokens2 --> End4([End])
```

## 6. Synchronisation Odoo

![Diagram](images/04_activity_diagrams_mermaid_11.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' flowchart TD
'     Start([Start]) --> Identify[Identifier entités à synchroniser]
'     
'     Identify --> SyncContacts[Synchronisation Contacts]
'     SyncContacts --> ContactLoop[Pour chaque Teacher/Guest]
'     ContactLoop --> Decision1{odoo_partner_id existe?}
'     Decision1 -->|Non| CreateContact[Créer contact Odoo]
'     CreateContact --> GetPartnerId[Récupérer odoo_partner_id]
'     GetPartnerId --> UpdateLocal[Mettre à jour entité locale]
'     UpdateLocal --> SyncInvoices
'     Decision1 -->|Oui| UpdateContact[Mettre à jour contact Odoo]
'     UpdateContact --> SyncInvoices[Synchronisation Factures]
'     
'     SyncInvoices --> InvoiceLoop[Pour chaque Invoice validée]
'     InvoiceLoop --> Decision2{odoo_invoice_id existe?}
'     Decision2 -->|Non| CreateInvoice[Créer facture Odoo]
'     CreateInvoice --> GetInvoiceId[Récupérer odoo_invoice_id]
'     GetInvoiceId --> SyncCRM
'     Decision2 -->|Oui| SyncCRM[Synchronisation CRM]
'     
'     SyncCRM --> CRMLoop[Pour chaque Travel nouveau]
'     CRMLoop --> Decision3{odoo_lead_id existe?}
'     Decision3 -->|Non| CreateLead[Créer lead Odoo]
'     CreateLead --> GetLeadId[Récupérer odoo_lead_id]
'     GetLeadId --> Log
'     Decision3 -->|Oui| Log[Logger résultats synchronisation]
'     
'     Log --> End([End])
```

## 7. Workflow Calcul de Prix avec Fonctions SQL

![Diagram](images/04_activity_diagrams_mermaid_12.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' flowchart TD
'     Start([Start]) --> GetTravel[Récupérer Travel]
'     GetTravel --> CallFinal[Appel: calculate_final_travel_price(travel_id)]
'     
'     CallFinal --> CalcTransport[calculate_transport_price()]
'     CalcTransport --> CalcActivities[calculate_activities_price()]
'     CalcActivities --> CalcLodging[calculate_lodging_price()]
'     CalcLodging --> CalcBase[calculate_base_price()<br/>Somme transport + activités + hébergement]
'     
'     CalcBase --> CalcParticipant[calculate_participant_discount()<br/>Selon nombre participants]
'     CalcParticipant --> CheckEarly[is_early_bird()<br/>Vérifier > 90 jours]
'     
'     CheckEarly --> CalcEarly{Early bird?}
'     CalcEarly -->|Oui| CalcEarlyDiscount[calculate_early_bird_discount()<br/>5% réduction]
'     CalcEarly -->|Non| CalcTotalDiscount
'     CalcEarlyDiscount --> CalcTotalDiscount[calculate_total_discount()<br/>Combiner réductions]
'     
'     CalcTotalDiscount --> ApplyDiscounts[calculate_travel_price_with_discounts()<br/>Appliquer réductions]
'     ApplyDiscounts --> CheckMargin{Marge renseignée?}
'     
'     CheckMargin -->|Oui| ApplyMargin[calculate_travel_price_with_margin()<br/>Appliquer marge]
'     CheckMargin -->|Non| ReturnPrice
'     ApplyMargin --> ReturnPrice[Retourner prix final]
'     
'     ReturnPrice --> End([End])
```

## 8. Workflow Validation avec Fonctions SQL

![Diagram](images/04_activity_diagrams_mermaid_13.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' flowchart TD
'     Start([Start]) --> ValidateQuote[Validation Devis]
'     ValidateQuote --> CheckExpired[is_quote_expired(quote_id)]
'     CheckExpired --> DecisionExpired{Expiré?}
'     DecisionExpired -->|Oui| ErrorExpired[Erreur: devis expiré]
'     ErrorExpired --> End
'     
'     DecisionExpired -->|Non| CheckStatus[can_validate_quote(quote_id)]
'     CheckStatus --> DecisionStatus{Validable?}
'     DecisionStatus -->|Non| ErrorStatus[Erreur: conditions non remplies]
'     ErrorStatus --> End
'     
'     DecisionStatus -->|Oui| ValidateInvoice[Validation Facture]
'     ValidateInvoice --> CheckInvoice[can_generate_invoice(travel_id)]
'     CheckInvoice --> DecisionInvoice{Facture générable?}
'     DecisionInvoice -->|Non| ErrorInvoice[Erreur: conditions non remplies]
'     ErrorInvoice --> End
'     
'     DecisionInvoice -->|Oui| CheckContacts[are_all_parent_contacts_collected(travel_id)]
'     CheckContacts --> DecisionContacts{Tous contacts collectés?}
'     DecisionContacts -->|Non| ErrorContacts[Erreur: contacts manquants]
'     ErrorContacts --> End
'     
'     DecisionContacts -->|Oui| CheckInvoiceValid[can_validate_invoice(invoice_id)]
'     CheckInvoiceValid --> DecisionInvoiceValid{Facture validable?}
'     DecisionInvoiceValid -->|Non| ErrorInvoiceValid[Erreur: facture non validable]
'     ErrorInvoiceValid --> End
'     
'     DecisionInvoiceValid -->|Oui| Success[Validation réussie]
'     Success --> End
```

## 9. Workflow Génération Automatique avec Procédures

![Diagram](images/04_activity_diagrams_mermaid_14.png)

```plantuml
!theme plain

' NOTE: Diagramme Mermaid - conversion manuelle nécessaire
' flowchart TD
'     Start([Start]) --> GenerateQuote[Génération Devis]
'     GenerateQuote --> CallProc[Appel: sp_generate_quote_for_travel()]
'     
'     CallProc --> Validate[can_generate_quote()]
'     Validate --> DecisionValid{Validable?}
'     DecisionValid -->|Non| Error[Erreur]
'     Error --> End
'     
'     DecisionValid -->|Oui| GenNumber[generate_quote_number()]
'     GenNumber --> CalcPrice[calculate_final_travel_price()]
'     CalcPrice --> CreateQuote[Créer Quote + QuoteLines]
'     CreateQuote --> UpdateStatus[UPDATE travels.status]
'     UpdateStatus --> ReturnQuote[Retourner quote_id]
'     ReturnQuote --> End
'     
'     Start2([Start]) --> GenerateInvoice[Génération Facture]
'     GenerateInvoice --> CallProc2[Appel: sp_generate_invoice_from_quote()]
'     
'     CallProc2 --> Validate2[can_create_invoice_from_quote()]
'     Validate2 --> DecisionValid2{Validable?}
'     DecisionValid2 -->|Non| Error2[Erreur]
'     Error2 --> End2
'     
'     DecisionValid2 -->|Oui| GenNumber2[generate_invoice_number()]
'     GenNumber2 --> CalcTax[calculate_tax_amount()]
'     CalcTax --> CreateInvoice[Créer Invoice + InvoiceLines]
'     CreateInvoice --> ReturnInvoice[Retourner invoice_id]
'     ReturnInvoice --> End2([End])
```

---

**Version** : 2.0  
**Date** : 2025-01-20  
**Mise à jour** : Ajout des workflows avec fonctions SQL
