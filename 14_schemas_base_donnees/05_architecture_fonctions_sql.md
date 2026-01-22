# Architecture des Fonctions SQL - Système Intégré de Gestion

## Vue d'Ensemble

Ce document présente l'architecture complète des fonctions SQL stockées et procédures stockées, leur organisation par domaine, les flux d'appels entre fonctions, et leur intégration avec la couche applicative.

## Architecture Globale

```mermaid
graph TB
    subgraph Application["Couche Application"]
        API[API REST FastAPI]
        Services[Services Métier]
        ORM[SQLAlchemy ORM]
    end
    
    subgraph SQLFunctions["Couche Fonctions SQL"]
        subgraph Pricing["Domaine: Calculs Prix"]
            F1[Fonctions Base]
            F2[Fonctions Réductions]
            F3[Fonctions Finales]
        end
        
        subgraph Validation["Domaine: Validations"]
            F4[Validations Voyages]
            F5[Validations Plannings]
            F6[Validations Réservations]
        end
        
        subgraph Generation["Domaine: Génération"]
            F7[Génération Numéros]
            F8[Génération Tokens]
        end
        
        subgraph Communication["Domaine: Communication"]
            F9[Gestion Consentements]
            F10[Statistiques Communication]
        end
        
        subgraph Statistics["Domaine: Statistiques"]
            F11[Statistiques Voyages]
            F12[Statistiques Financières]
        end
        
        subgraph Procedures["Procédures Stockées"]
            P1[Génération Automatique]
            P2[Maintenance]
            P3[Synchronisation]
        end
    end
    
    subgraph Database["Couche Base de Données"]
        Tables[Tables MySQL]
        Indexes[Index]
        Data[Données]
    end
    
    API --> Services
    Services --> ORM
    Services --> SQLFunctions
    ORM --> Tables
    
    SQLFunctions --> Tables
    SQLFunctions --> Indexes
    SQLFunctions --> Procedures
    
    Procedures --> SQLFunctions
    Procedures --> Tables
    
    F1 --> F2
    F2 --> F3
    F4 --> Procedures
    F5 --> Procedures
    F6 --> Procedures
    F7 --> Procedures
```

## Organisation par Domaine

### Domaine 1 : Calculs de Prix

```mermaid
graph TB
    subgraph Base["Fonctions de Base"]
        F1[calculate_transport_price]
        F2[calculate_activities_price]
        F3[calculate_lodging_price]
    end
    
    subgraph Composite["Fonctions Composites"]
        F4[calculate_base_price]
    end
    
    subgraph Discounts["Fonctions Réductions"]
        F5[calculate_participant_discount]
        F6[is_early_bird]
        F7[calculate_early_bird_discount]
        F8[calculate_total_discount]
    end
    
    subgraph Final["Fonctions Finales"]
        F9[calculate_travel_price_with_discounts]
        F10[calculate_travel_price_with_margin]
        F11[calculate_final_travel_price]
    end
    
    F1 --> F4
    F2 --> F4
    F3 --> F4
    F4 --> F9
    F5 --> F8
    F6 --> F7
    F7 --> F8
    F8 --> F9
    F9 --> F10
    F10 --> F11
```

**Hiérarchie d'appels** :
1. **Niveau 1** : `calculate_transport_price()`, `calculate_activities_price()`, `calculate_lodging_price()`
2. **Niveau 2** : `calculate_base_price()` (appelle niveau 1)
3. **Niveau 3** : `calculate_participant_discount()`, `is_early_bird()` (calculs indépendants)
4. **Niveau 4** : `calculate_total_discount()` (combine niveau 3)
5. **Niveau 5** : `calculate_travel_price_with_discounts()` (niveau 2 + niveau 4)
6. **Niveau 6** : `calculate_travel_price_with_margin()` (niveau 5 + marge)
7. **Niveau 7** : `calculate_final_travel_price()` (niveau 6, fonction principale)

### Domaine 2 : Validations Métier

```mermaid
graph TB
    subgraph TravelValidation["Validations Voyages"]
        V1[can_generate_quote]
        V2[can_generate_invoice]
        V3[is_travel_valid_for_confirmation]
    end
    
    subgraph PlanningValidation["Validations Plannings"]
        V4[has_valid_planning]
        V5[has_overlapping_activities]
        V6[planning_covers_travel_days]
        V7[is_planning_valid]
    end
    
    subgraph BookingValidation["Validations Réservations"]
        V8[has_available_spots]
        V9[can_create_booking]
        V10[is_payment_overdue]
        V11[should_cancel_booking]
    end
    
    V4 --> V7
    V5 --> V7
    V6 --> V7
    
    V8 --> V9
    V10 --> V11
```

**Relations** :
- `is_planning_valid()` combine `has_valid_planning()`, `has_overlapping_activities()`, et `planning_covers_travel_days()`
- `can_create_booking()` utilise `has_available_spots()`
- `should_cancel_booking()` utilise `is_payment_overdue()`

### Domaine 3 : Génération de Numéros

```mermaid
graph TB
    G1[generate_quote_number] --> P1[sp_generate_quote_for_travel]
    G2[generate_invoice_number] --> P2[sp_generate_invoice_from_quote]
    G3[generate_booking_number] --> Booking[Booking Creation]
    G4[generate_token] --> Form[Teacher Form]
    G5[generate_travel_reference] --> Travel[Travel Reference]
```

**Utilisation** :
- Les fonctions de génération sont appelées par les procédures stockées ou directement par les services
- Chaque fonction génère un numéro unique selon un format spécifique

### Domaine 4 : Communication

```mermaid
graph TB
    subgraph Consent["Gestion Consentements"]
        C1[can_send_marketing_email]
        C2[can_send_whatsapp]
        C3[has_email_consent]
        C4[has_whatsapp_consent]
        C5[is_contact_opted_out_email]
        C6[is_contact_opted_out_whatsapp]
    end
    
    subgraph Stats["Statistiques"]
        S1[get_email_bounce_rate]
        S2[days_since_last_email]
        S3[days_since_last_whatsapp]
        S4[get_contact_engagement_score]
    end
    
    C3 --> C1
    C5 --> C1
    C4 --> C2
    C6 --> C2
    
    S1 --> S4
    S2 --> S4
    S3 --> S4
```

## Flux d'Appels entre Fonctions

### Flux : Génération de Devis

```mermaid
sequenceDiagram
    participant Service as Service Métier
    participant Proc as sp_generate_quote_for_travel
    participant ValFunc as can_generate_quote
    participant GenFunc as generate_quote_number
    participant PriceFunc as calculate_final_travel_price
    participant BaseFunc as calculate_base_price
    participant TransFunc as calculate_transport_price
    participant ActFunc as calculate_activities_price
    participant LodgFunc as calculate_lodging_price
    participant DiscFunc as calculate_total_discount
    
    Service->>Proc: CALL sp_generate_quote_for_travel()
    Proc->>ValFunc: can_generate_quote()
    ValFunc-->>Proc: TRUE
    
    Proc->>GenFunc: generate_quote_number()
    GenFunc-->>Proc: "DEV-2025-0001"
    
    Proc->>PriceFunc: calculate_final_travel_price()
    PriceFunc->>BaseFunc: calculate_base_price()
    BaseFunc->>TransFunc: calculate_transport_price()
    BaseFunc->>ActFunc: calculate_activities_price()
    BaseFunc->>LodgFunc: calculate_lodging_price()
    BaseFunc-->>PriceFunc: Prix de base
    
    PriceFunc->>DiscFunc: calculate_total_discount()
    DiscFunc-->>PriceFunc: Réduction totale
    
    PriceFunc-->>Proc: Prix final
    Proc-->>Service: Quote créé
```

### Flux : Validation et Génération Facture

```mermaid
sequenceDiagram
    participant Service as Service Métier
    participant ValFunc1 as can_generate_invoice
    participant ValFunc2 as are_all_parent_contacts_collected
    participant Proc as sp_generate_invoice_from_quote
    participant GenFunc as generate_invoice_number
    participant TaxFunc as calculate_tax_amount
    participant TTCFunc as calculate_amount_ttc
    
    Service->>ValFunc1: can_generate_invoice()
    ValFunc1->>ValFunc2: are_all_parent_contacts_collected()
    ValFunc2-->>ValFunc1: TRUE
    ValFunc1-->>Service: TRUE
    
    Service->>Proc: CALL sp_generate_invoice_from_quote()
    Proc->>GenFunc: generate_invoice_number()
    GenFunc-->>Proc: "FAC-2025-0001"
    
    Proc->>TaxFunc: calculate_tax_amount()
    TaxFunc-->>Proc: Montant TVA
    
    Proc->>TTCFunc: calculate_amount_ttc()
    TTCFunc-->>Proc: Total TTC
    
    Proc-->>Service: Invoice créé
```

## Hiérarchie des Fonctions

### Niveau 1 : Fonctions Atomiques (Pas de dépendances)

```mermaid
graph TB
    subgraph Atomic["Fonctions Atomiques"]
        A1[calculate_transport_price]
        A2[calculate_activities_price]
        A3[calculate_lodging_price]
        A4[calculate_participant_discount]
        A5[is_early_bird]
        A6[is_email_valid]
        A7[are_dates_valid]
        A8[generate_quote_number]
        A9[generate_invoice_number]
    end
```

**Caractéristiques** :
- Pas de dépendances vers d'autres fonctions SQL
- Calculs simples ou validations basiques
- Peuvent être utilisées indépendamment

### Niveau 2 : Fonctions Composites (Dépendent du Niveau 1)

```mermaid
graph TB
    subgraph Composite["Fonctions Composites"]
        C1[calculate_base_price]
        C2[calculate_early_bird_discount]
        C3[calculate_total_discount]
        C4[is_planning_valid]
        C5[can_send_marketing_email]
    end
    
    subgraph Atomic["Niveau 1"]
        A1[calculate_transport_price]
        A2[calculate_activities_price]
        A3[calculate_lodging_price]
        A4[calculate_participant_discount]
        A5[is_early_bird]
    end
    
    A1 --> C1
    A2 --> C1
    A3 --> C1
    A5 --> C2
    A4 --> C3
    C2 --> C3
```

### Niveau 3 : Fonctions Métier (Dépendent des Niveaux 1-2)

```mermaid
graph TB
    subgraph Business["Fonctions Métier"]
        B1[calculate_travel_price_with_discounts]
        B2[calculate_final_travel_price]
        B3[can_generate_quote]
        B4[can_generate_invoice]
        B5[can_validate_quote]
    end
    
    subgraph Composite["Niveau 2"]
        C1[calculate_base_price]
        C3[calculate_total_discount]
        C4[is_planning_valid]
    end
    
    C1 --> B1
    C3 --> B1
    B1 --> B2
    C4 --> B3
```

### Niveau 4 : Procédures Stockées (Orchestrent tous les niveaux)

```mermaid
graph TB
    subgraph Procedures["Procédures Stockées"]
        P1[sp_generate_quote_for_travel]
        P2[sp_generate_invoice_from_quote]
        P3[sp_update_travel_status]
        P4[sp_collect_parent_contacts]
    end
    
    subgraph Business["Niveau 3"]
        B1[calculate_final_travel_price]
        B3[can_generate_quote]
        B4[can_generate_invoice]
    end
    
    subgraph Generation["Génération"]
        G1[generate_quote_number]
        G2[generate_invoice_number]
    end
    
    B3 --> P1
    B1 --> P1
    G1 --> P1
    
    B4 --> P2
    G2 --> P2
```

## Intégration avec la Couche Applicative

### Architecture en Couches

```mermaid
graph TB
    subgraph Presentation["Couche Présentation"]
        Frontend[Vue.js Frontend]
    end
    
    subgraph API["Couche API"]
        REST[FastAPI REST]
        Auth[Authentication]
    end
    
    subgraph Service["Couche Service"]
        TravelSvc[TravelService]
        QuoteSvc[QuoteService]
        InvoiceSvc[InvoiceService]
        PricingSvc[PricingService]
    end
    
    subgraph SQLFunctions["Couche Fonctions SQL"]
        PricingFuncs[Fonctions Prix]
        ValidationFuncs[Fonctions Validation]
        GenerationFuncs[Fonctions Génération]
        Procedures[Procédures Stockées]
    end
    
    subgraph Database["Couche Base de Données"]
        MySQL[MySQL InnoDB]
        Tables[Tables]
        Indexes[Index]
    end
    
    Frontend --> REST
    REST --> Auth
    Auth --> TravelSvc
    Auth --> QuoteSvc
    Auth --> InvoiceSvc
    
    TravelSvc --> PricingFuncs
    TravelSvc --> ValidationFuncs
    QuoteSvc --> GenerationFuncs
    QuoteSvc --> Procedures
    InvoiceSvc --> Procedures
    PricingSvc --> PricingFuncs
    
    PricingFuncs --> MySQL
    ValidationFuncs --> MySQL
    GenerationFuncs --> MySQL
    Procedures --> MySQL
    
    MySQL --> Tables
    MySQL --> Indexes
```

### Points d'Intégration

#### 1. Services → Fonctions SQL

```python
# Exemple : TravelService utilise les fonctions SQL
class TravelService:
    def calculate_price(self, travel_id: int) -> Decimal:
        # Appel direct à la fonction SQL
        result = db.execute(
            text("SELECT calculate_final_travel_price(:travel_id)"),
            {"travel_id": travel_id}
        ).scalar()
        return result
    
    def can_generate_quote(self, travel_id: int) -> bool:
        # Appel à la fonction de validation
        result = db.execute(
            text("SELECT can_generate_quote(:travel_id)"),
            {"travel_id": travel_id}
        ).scalar()
        return result
```

#### 2. Services → Procédures Stockées

```python
# Exemple : QuoteService utilise les procédures
class QuoteService:
    def generate_quote(self, travel_id: int) -> Quote:
        # Appel à la procédure stockée
        db.execute(
            text("CALL sp_generate_quote_for_travel(:travel_id, @quote_id)"),
            {"travel_id": travel_id}
        )
        quote_id = db.execute(text("SELECT @quote_id")).scalar()
        return self.get_quote(quote_id)
```

## Performance et Optimisation

### Stratégie d'Appel

1. **Fonctions atomiques** : Appelées directement, résultats mis en cache si possible
2. **Fonctions composites** : Appelées une fois, réutilisent les résultats des fonctions atomiques
3. **Procédures stockées** : Orchestrent plusieurs fonctions en une seule transaction

### Cache des Résultats

```mermaid
graph TB
    Service[Service] --> CheckCache{Cache existe?}
    CheckCache -->|Oui| ReturnCache[Retourner cache]
    CheckCache -->|Non| CallFunction[Appeler fonction SQL]
    CallFunction --> StoreCache[Stocker en cache]
    StoreCache --> ReturnResult[Retourner résultat]
    ReturnCache --> End[Fin]
    ReturnResult --> End
```

### Index Utilisés

Chaque fonction utilise des index spécifiques pour optimiser ses performances :

- **Fonctions de calcul** : Index sur clés étrangères et dates
- **Fonctions de validation** : Index sur statuts et flags
- **Fonctions statistiques** : Index composites sur dates et statuts

## Maintenance et Évolution

### Gestion des Versions

Les fonctions sont versionnées et peuvent être mises à jour indépendamment :

```sql
-- Version 1.0
CREATE FUNCTION calculate_final_travel_price(...)

-- Version 1.1 (avec nouvelles réductions)
DROP FUNCTION IF EXISTS calculate_final_travel_price;
CREATE FUNCTION calculate_final_travel_price(...)
```

### Impact des Modifications

```mermaid
graph TB
    Modify[Modification Fonction] --> Analyze[Analyser dépendances]
    Analyze --> Impact[Identifier impact]
    Impact --> Test[Tester fonctions dépendantes]
    Test --> Deploy[Déployer]
    Deploy --> Monitor[Monitorer performance]
```

---

**Version** : 1.0  
**Date** : 2025-01-20  
**Architecture** : Fonctions SQL organisées par domaine et hiérarchie
