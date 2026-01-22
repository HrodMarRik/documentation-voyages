# Architecture Déploiement

```mermaid
graph TB
    subgraph LB["Load Balancer"]
        Nginx[Nginx]
    end
    
    subgraph AppServers["Application Servers"]
        App1[FastAPI App 1]
        App2[FastAPI App 2]
        Gunicorn[Gunicorn]
    end
    
    subgraph Database["Base de Données"]
        MySQLMaster[MySQL Master]
        MySQLSlave[MySQL Slave]
    end
    
    subgraph Storage["Storage"]
        Docs[Documents]
        Backups[Backups]
    end
    
    subgraph External["External Services"]
        Odoo[Odoo Cloud]
        Stripe[Stripe API]
        SMTP[SMTP Server]
    end
    
    Nginx -->|HTTP| App1
    Nginx -->|HTTP| App2
    App1 --> Gunicorn
    App2 --> Gunicorn
    
    App1 -->|Read/Write| MySQLMaster
    App2 -->|Read/Write| MySQLMaster
    MySQLMaster -->|Replication| MySQLSlave
    
    App1 -->|File Storage| Docs
    App2 -->|File Storage| Docs
    MySQLMaster -->|Daily Backup| Backups
    
    App1 -->|XML-RPC| Odoo
    App2 -->|XML-RPC| Odoo
    App1 -->|REST API| Stripe
    App2 -->|REST API| Stripe
    App1 -->|SMTP| SMTP
    App2 -->|SMTP| SMTP
```

## Notes

**Load Balancer (Nginx)** :
- SSL Termination
- Static Files
- Reverse Proxy

**MySQL Master** :
- Primary Database
- Write Operations

**MySQL Slave** :
- Read Replica
- Backup Source
