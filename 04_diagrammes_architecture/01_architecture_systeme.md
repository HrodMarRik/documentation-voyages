# Architecture Système - Vue Globale

```mermaid
graph TB
    subgraph Frontend["Frontend"]
        VueJS[Vue.js SPA]
        UI[Element Plus UI]
    end
    
    subgraph Backend["Backend API"]
        FastAPI[FastAPI]
        Services[Services Métier]
        ORM[SQLAlchemy ORM]
    end
    
    subgraph Database["Base de Données"]
        MySQL[MySQL 8.0]
    end
    
    subgraph Integrations["Intégrations Externes"]
        Odoo[Odoo ERP]
        Stripe[Stripe]
        SMTP[SMTP Server]
    end
    
    VueJS -->|HTTP/REST API| FastAPI
    UI -->|HTTP/REST API| FastAPI
    FastAPI -->|Appels services| Services
    Services -->|Requêtes| ORM
    ORM -->|SQL| MySQL
    
    FastAPI -->|XML-RPC| Odoo
    FastAPI -->|REST API| Stripe
    FastAPI -->|SMTP Protocol| SMTP
```

## Notes

**Frontend** :
- Vue.js 3 + Vite
- Element Plus
- Responsive Design

**Backend** :
- FastAPI
- JWT Authentication
- 2FA Support

**MySQL** :
- InnoDB Engine
- utf8mb4 Charset
- Réplication possible
