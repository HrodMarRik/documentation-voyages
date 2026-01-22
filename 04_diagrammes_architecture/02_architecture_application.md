# Architecture Application - Couches

```mermaid
graph TB
    subgraph Presentation["Couche Présentation"]
        VueComponents[Vue.js Components]
        Router[Router]
        Stores[Stores Pinia]
    end
    
    subgraph API["Couche API"]
        Routers[FastAPI Routers]
        Middleware[Middleware]
        Auth[Authentication]
    end
    
    subgraph Business["Couche Logique Métier"]
        Services[Services]
        Pricing[PricingService]
        Quote[QuoteService]
        Invoice[InvoiceService]
        Travel[TravelService]
        OdooSync[OdooSyncService]
    end
    
    subgraph Data["Couche Données"]
        Models[SQLAlchemy Models]
        Repos[Repositories]
        Migrations[Alembic Migrations]
    end
    
    subgraph Integrations["Couche Intégrations"]
        OdooConn[Odoo Connector]
        StripeClient[Stripe Client]
        EmailService[Email Service]
    end
    
    VueComponents -->|HTTP Requests| Routers
    Router --> Routers
    Stores --> Routers
    
    Routers --> Middleware
    Middleware --> Auth
    Auth --> Services
    
    Services --> Pricing
    Services --> Quote
    Services --> Invoice
    Services --> Travel
    Services --> OdooSync
    
    Services --> Models
    Models --> Repos
    Repos --> Migrations
    
    OdooSync --> OdooConn
    Services --> StripeClient
    Services --> EmailService
```

## Notes

**Services Métier** :
- Calculs de prix
- Génération devis/factures
- Gestion voyages
- Synchronisation Odoo

**Modèles** :
- Modèles SQLAlchemy
- Relations ORM
- Validations
