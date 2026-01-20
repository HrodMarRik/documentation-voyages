# Cas d'Utilisation - Intégration Odoo

## Diagramme

```mermaid
graph TB
    System[Système]
    
    subgraph Odoo["Intégration Odoo"]
        UC60[UC60: Synchroniser contacts]
        UC61[UC61: Créer lead Odoo]
        UC62[UC62: Créer facture Odoo]
    end
    
    System --> UC60
    System --> UC61
    System --> UC62
    
    UC19[UC19: Créer voyage] -.->|include| UC61
    UC39[UC39: Générer facture] -.->|include| UC62
```

## Description des Cas d'Utilisation

### Synchronisation Contacts (UC60)
- **UC60** : Synchroniser contacts - Synchronisation automatique des contacts (Teacher, Guest) avec Odoo
  - Création de contact dans Odoo si nouveau
  - Mise à jour si modification
  - Récupération depuis Odoo si nécessaire

### Création Lead CRM (UC61)
- **UC61** : Créer lead Odoo - Création automatique d'un lead dans Odoo lors de la création d'un voyage scolaire
  - Déclenché par UC19 (Créer voyage scolaire)
  - Lead avec toutes les informations du voyage
  - Attribution au commercial responsable

### Création Facture Odoo (UC62)
- **UC62** : Créer facture Odoo - Création automatique d'une facture dans Odoo lors de la validation
  - Déclenché par UC39 (Générer facture)
  - Facture avec toutes les lignes
  - Lien avec le contact client
  - Synchronisation du numéro de facture

## Relations avec Autres Cas d'Utilisation

- **UC19** (Créer voyage scolaire) → **UC61** (Créer lead Odoo) : Relation `<<include>>`
- **UC39** (Générer facture) → **UC62** (Créer facture Odoo) : Relation `<<include>>`

---

**Voir aussi** : [Diagramme principal](01_use_case_diagram.md)
