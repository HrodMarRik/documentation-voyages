# Cas d'Utilisation - Authentification & Gestion Utilisateurs

## Diagramme

```mermaid
graph TB
    Admin[Admin]
    
    subgraph Auth["Authentification"]
        UC56[UC56: Se connecter]
        UC57[UC57: Activer 2FA]
        UC58[UC58: Vérifier 2FA]
        UC59[UC59: Se déconnecter]
    end
    
    subgraph Users["Gestion Utilisateurs"]
        UC1[UC1: Créer utilisateur]
        UC2[UC2: Modifier utilisateur]
        UC3[UC3: Supprimer utilisateur]
        UC4[UC4: Gérer rôles]
        UC5[UC5: Gérer permissions]
    end
    
    subgraph CRUD["Admin CRUD"]
        UC55[UC55: Accès CRUD base de données]
    end
    
    Admin --> UC1
    Admin --> UC2
    Admin --> UC3
    Admin --> UC4
    Admin --> UC5
    Admin --> UC55
    Admin --> UC56
    Admin --> UC57
    Admin --> UC58
    Admin --> UC59
```

## Description des Cas d'Utilisation

### Authentification (UC56-UC59)
- **UC56** : Se connecter - Authentification avec email/password, support 2FA
- **UC57** : Activer 2FA - Configuration de l'authentification à deux facteurs
- **UC58** : Vérifier 2FA - Validation du code TOTP lors de la connexion
- **UC59** : Se déconnecter - Déconnexion et invalidation du token

### Gestion Utilisateurs (UC1-UC5)
- **UC1** : Créer utilisateur - Création d'un nouvel utilisateur avec email et mot de passe
- **UC2** : Modifier utilisateur - Modification des informations utilisateur
- **UC3** : Supprimer utilisateur - Suppression d'un utilisateur (avec vérifications)
- **UC4** : Gérer rôles - Attribution et retrait de rôles aux utilisateurs
- **UC5** : Gérer permissions - Gestion des permissions granulaires

### Admin CRUD (UC55)
- **UC55** : Accès CRUD base de données - Interface d'administration pour toutes les tables

---

**Voir aussi** : [Diagramme principal](01_use_case_diagram.md)
