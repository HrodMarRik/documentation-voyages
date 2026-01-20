# Diagrammes de Séquence - Système Intégré de Gestion

## 1. Formulaire Public → Devis

```mermaid
sequenceDiagram
    actor Professeur
    participant API as API Backend
    participant Notif as Service Notification
    participant DB as Base de Données
    participant Email as Service Email
    
    Professeur->>API: POST /api/public/teacher-form<br/>(dates, destinations, budget)
    activate API
    
    API->>DB: Créer/Update Teacher
    activate DB
    DB-->>API: Teacher créé
    deactivate DB
    
    API->>DB: Créer Travel (DRAFT)
    activate DB
    DB-->>API: Travel créé
    deactivate DB
    
    API->>DB: Créer TravelDestination
    activate DB
    DB-->>API: Destinations liées
    deactivate DB
    
    API->>DB: Créer TeacherForm (token)
    activate DB
    DB-->>API: Form créé
    deactivate DB
    
    API->>Notif: notify_commercials_new_prospect()
    activate Notif
    Notif->>DB: Récupérer emails commerciaux
    activate DB
    DB-->>Notif: Liste emails
    deactivate DB
    Notif->>Email: Envoyer notification
    activate Email
    Email-->>Notif: Email envoyé
    deactivate Email
    deactivate Notif
    
    API-->>Professeur: 201 Created (token)
    deactivate API
```

## 2. Génération Planning

```mermaid
sequenceDiagram
    actor Commercial
    participant API as API Backend
    participant Planning as Service Planning
    participant DB as Base de Données
    
    Commercial->>API: POST /api/program-templates/generate<br/>(travel_id)
    activate API
    
    API->>DB: Récupérer Travel + Destinations
    activate DB
    DB-->>API: Travel data
    deactivate DB
    
    API->>Planning: Générer planning préconstruit
    activate Planning
    Planning->>DB: Récupérer activités par destination
    activate DB
    DB-->>Planning: Liste activités
    deactivate DB
    Planning->>Planning: Calculer jours<br/>Distribuer activités
    Planning-->>API: ProgramTemplate créé
    deactivate Planning
    
    API->>DB: Sauvegarder ProgramTemplate
    activate DB
    DB-->>API: Template sauvegardé
    deactivate DB
    
    API->>DB: Créer ProgramTemplateActivity<br/>(pour chaque activité)
    activate DB
    DB-->>API: Activités liées
    deactivate DB
    
    API-->>Commercial: 201 Created (program_template)
    deactivate API
```

## 3. Génération Devis Automatique

```mermaid
sequenceDiagram
    actor Commercial
    participant API as API Backend
    participant QuoteService as Service Devis
    participant PricingService as Service Prix
    participant DB as Base de Données
    
    Commercial->>API: POST /api/quotes/generate/{travel_id}
    activate API
    
    API->>DB: Récupérer Travel + Destinations
    activate DB
    DB-->>API: Travel data
    deactivate DB
    
    API->>QuoteService: generate_quote_from_travel()
    activate QuoteService
    
    QuoteService->>DB: Récupérer TransportPrice par destination
    activate DB
    DB-->>QuoteService: Prix transport
    deactivate DB
    
    QuoteService->>DB: Récupérer ProgramTemplate (si validé)
    activate DB
    DB-->>QuoteService: Template + activités
    deactivate DB
    
    QuoteService->>PricingService: Calculer prix total
    activate PricingService
    PricingService->>PricingService: Calcul transport<br/>Calcul activités<br/>Calcul hébergement<br/>Application réductions
    PricingService-->>QuoteService: Prix total
    deactivate PricingService
    
    QuoteService->>DB: Créer Quote
    activate DB
    DB-->>QuoteService: Quote créé
    deactivate DB
    
    QuoteService->>DB: Créer QuoteLines<br/>(transport, activités, hébergement)
    activate DB
    DB-->>QuoteService: Lignes créées
    deactivate DB
    
    QuoteService-->>API: Quote créé
    deactivate QuoteService
    
    API-->>Commercial: 201 Created (quote)
    deactivate API
```

## 4. Génération Facture depuis Devis

```mermaid
sequenceDiagram
    actor Commercial
    participant API as API Backend
    participant InvoiceService as Service Facture
    participant DB as Base de Données
    participant Odoo as Odoo
    
    Commercial->>API: POST /api/invoices/generate-from-quote/{quote_id}
    activate API
    
    API->>DB: Récupérer Quote + Travel
    activate DB
    DB-->>API: Quote + Travel
    deactivate DB
    
    API->>InvoiceService: generate_invoice_from_quote()
    activate InvoiceService
    
    InvoiceService->>DB: Récupérer QuoteLines
    activate DB
    DB-->>InvoiceService: Lignes devis
    deactivate DB
    
    InvoiceService->>InvoiceService: Convertir QuoteLines en InvoiceLines<br/>Calculer TVA (20%)
    
    InvoiceService->>DB: Créer Invoice
    activate DB
    DB-->>InvoiceService: Invoice créé
    deactivate DB
    
    InvoiceService->>DB: Créer InvoiceLines
    activate DB
    DB-->>InvoiceService: Lignes créées
    deactivate DB
    
    InvoiceService->>Odoo: Créer facture Odoo
    activate Odoo
    Odoo-->>InvoiceService: Invoice Odoo créée
    deactivate Odoo
    
    InvoiceService->>DB: Mettre à jour Travel.odoo_invoice_id
    activate DB
    DB-->>InvoiceService: Mis à jour
    deactivate DB
    
    InvoiceService-->>API: Invoice créé
    deactivate InvoiceService
    
    API-->>Commercial: 201 Created (invoice)
    deactivate API
```

## 5. Authentification avec 2FA

```mermaid
sequenceDiagram
    actor Utilisateur
    participant API as API Backend
    participant AuthService as Service Auth
    participant DB as Base de Données
    participant TOTP as TOTP
    
    Utilisateur->>API: POST /api/auth/login<br/>(email, password)
    activate API
    
    API->>AuthService: verify_credentials()
    activate AuthService
    AuthService->>DB: Récupérer User
    activate DB
    DB-->>AuthService: User
    deactivate DB
    AuthService->>AuthService: Vérifier password_hash
    AuthService-->>API: User valide
    deactivate AuthService
    
    API->>DB: Récupérer TwoFactorAuth
    activate DB
    DB-->>API: 2FA config
    deactivate DB
    
    alt 2FA activé
        API-->>Utilisateur: 200 OK (requires_2fa: true)
        Utilisateur->>API: POST /api/auth/2fa/verify<br/>(token, code)
        activate API
        API->>TOTP: Vérifier code TOTP
        activate TOTP
        TOTP-->>API: Code valide
        deactivate TOTP
        API->>AuthService: Générer JWT tokens
        activate AuthService
        AuthService-->>API: access_token + refresh_token
        deactivate AuthService
        API-->>Utilisateur: 200 OK (tokens)
    else 2FA non activé
        API->>AuthService: Générer JWT tokens
        activate AuthService
        AuthService-->>API: access_token + refresh_token
        deactivate AuthService
        API-->>Utilisateur: 200 OK (tokens)
    end
    
    deactivate API
```

## 6. Paiement en Ligne Stripe (Voyage Linguistique)

```mermaid
sequenceDiagram
    actor Guest
    participant Frontend as Frontend
    participant API as API Backend
    participant PaymentService as Service Paiement
    participant Stripe as Stripe API
    participant DB as Base de Données
    
    Guest->>Frontend: S'inscrire voyage linguistique
    Frontend->>API: POST /api/guests<br/>(inscription data)
    activate API
    
    API->>DB: Créer Guest + Booking
    activate DB
    DB-->>API: Booking créé (status: PENDING)
    deactivate DB
    
    API->>PaymentService: create_payment_intent()
    activate PaymentService
    PaymentService->>Stripe: Créer PaymentIntent
    activate Stripe
    Stripe-->>PaymentService: client_secret
    deactivate Stripe
    PaymentService-->>API: client_secret
    deactivate PaymentService
    
    API-->>Frontend: 201 Created (booking_id, client_secret)
    Frontend-->>Guest: Redirection Stripe Checkout
    
    Guest->>Stripe: Paiement
    Stripe->>API: Webhook payment_intent.succeeded
    activate API
    
    API->>DB: Mettre à jour Booking<br/>(status: CONFIRMED, payment_status: PAID)
    activate DB
    DB-->>API: Mis à jour
    deactivate DB
    
    API->>PaymentService: Envoyer email confirmation
    activate PaymentService
    PaymentService-->>API: Email envoyé
    deactivate PaymentService
    
    API-->>Stripe: 200 OK
    deactivate API
    
    Stripe-->>Guest: Confirmation paiement
    Frontend->>API: GET /api/bookings/{id}
    API-->>Frontend: Booking confirmé
```

## 7. Synchronisation Odoo

```mermaid
sequenceDiagram
    participant SyncService as Service Sync
    participant DB as Base de Données
    participant Odoo as Odoo API
    
    SyncService->>DB: Récupérer données à synchroniser
    activate DB
    DB-->>SyncService: Invoices, Teachers, Guests
    deactivate DB
    
    loop Pour chaque entité
        SyncService->>Odoo: Créer/Mettre à jour entité
        activate Odoo
        
        alt Succès
            Odoo-->>SyncService: ID Odoo
            SyncService->>DB: Mettre à jour odoo_*_id
            activate DB
            DB-->>SyncService: Mis à jour
            deactivate DB
        else Erreur
            Odoo-->>SyncService: Erreur
            SyncService->>DB: Logger erreur
            activate DB
            DB-->>SyncService: Erreur loggée
            deactivate DB
        end
        
        deactivate Odoo
    end
    
    SyncService->>SyncService: Rapport de synchronisation
```

---

**Version** : 1.0  
**Date** : 2025-01-20
