# Guide d'Intégration Odoo

## Vue d'Ensemble

L'intégration avec Odoo permet de synchroniser les données entre le système de gestion et l'ERP Odoo. Cette intégration utilise la bibliothèque `odoo-endpoints` qui fournit des endpoints spécialisés pour chaque module Odoo.

## Configuration

### 1. Création d'une Clé API Odoo

1. Se connecter à votre instance Odoo
2. Aller dans **Mon Profil** (avatar en haut à droite)
3. Onglet **Sécurité**
4. Section **Clé API** → **Nouvelle clé API**
5. Donner un nom à la clé (ex: "Application Gestion")
6. **Copier immédiatement la clé** (elle ne sera affichée qu'une fois)

### 2. Configuration dans l'Application

Ajouter dans le fichier `.env` :

```env
ODOO_URL=https://votre-instance.odoo.com
ODOO_DB=votre_base_de_donnees
ODOO_USERNAME=votre_utilisateur
ODOO_API_KEY=votre_cle_api
```

### 3. Permissions Odoo

L'utilisateur Odoo doit avoir les permissions suivantes :
- **Contacts** : Groupe "Ventes / Utilisateur" ou "CRM / Utilisateur"
- **Facturation** : Groupe "Comptabilité / Utilisateur"
- **CRM** : Groupe "CRM / Utilisateur"
- **Comptabilité** : Groupe "Comptabilité / Utilisateur"

**Recommandation** : Créer un utilisateur dédié "API" avec uniquement les permissions nécessaires.

## Modules Utilisés

### Contacts (`res.partner`)

Synchronisation des contacts :
- **Teachers** → Clients Odoo
- **Tenants** → Contacts Odoo
- **Guests** → Contacts Odoo

**Champs synchronisés** :
- Nom, email, téléphone
- Adresse
- Type (client, fournisseur)

### CRM (`crm.lead`)

Création de leads depuis les demandes de voyage :
- **Travel** (nouveau) → Lead Odoo
- Mise à jour du lead lors de la validation du devis
- Conversion en opportunité lors de la génération de la facture

### Facturation (`account.move`)

Génération de factures Odoo :
- **Invoice** (validée) → Facture Odoo
- Lignes de facture synchronisées
- Lien avec le contact client

### Comptabilité (`account.account`, `account.journal`)

Export des écritures comptables :
- Export des factures validées
- Conformité avec la comptabilité Odoo

### Email Marketing (`mailing.mailing`, `mailing.list`)

Gestion des campagnes email :
- Création de listes de diffusion
- Envoi de campagnes

### Documents (`ir.attachment`)

Stockage des documents :
- Factures PDF/XML
- Contrats
- Documents de voyage

### WhatsApp (via modules Odoo tiers)

Envoi de messages WhatsApp :
- Notifications
- Confirmations

## Synchronisation

### Synchronisation Automatique

#### Contacts

- **Création** : Lors de la création d'un Teacher ou Guest
- **Mise à jour** : Lors de la modification des informations
- **Fréquence** : Immédiate (synchronisation en temps réel)

#### Factures

- **Création** : Lors de la validation d'une facture
- **Fréquence** : Immédiate

#### Leads CRM

- **Création** : Lors de la soumission du formulaire professeur
- **Mise à jour** : Lors de la validation du devis, génération de la facture
- **Fréquence** : Immédiate

### Synchronisation Manuelle

Possibilité de relancer manuellement la synchronisation via l'API :

```bash
POST /api/sync/contacts
POST /api/sync/apartments
POST /api/sync/invoices
```

### Gestion des Conflits

- **Stratégie** : Dernière modification gagne
- **Logs** : Toutes les erreurs de synchronisation sont loggées
- **Relance** : Possibilité de relancer manuellement la synchronisation

## Utilisation de la Bibliothèque odoo-endpoints

### Exemple : Créer un Contact

```python
from contacts.endpoints import ContactsEndpoint
from config import OdooConfig

config = OdooConfig.get_config()
contacts = ContactsEndpoint(**config)

# Créer un client
customer_id = contacts.create_customer(
    name="Jean Dupont",
    email="jean.dupont@example.com",
    phone="+33123456789"
)
```

### Exemple : Créer une Facture

```python
from facturation.endpoints import FacturationEndpoint
from config import OdooConfig

config = OdooConfig.get_config()
facturation = FacturationEndpoint(**config)

# Créer une facture
invoice_id = facturation.create_customer_invoice(
    partner_id=customer_id,
    invoice_lines=[
        {
            'product_id': 1,
            'quantity': 2,
            'price_unit': 100.0
        }
    ]
)

# Valider la facture
facturation.validate_invoice(invoice_id)
```

### Exemple : Créer un Lead

```python
from crm.endpoints import CRMEndpoint
from config import OdooConfig

config = OdooConfig.get_config()
crm = CRMEndpoint(**config)

# Créer un lead
lead_id = crm.create_lead(
    name="Nouvelle opportunité voyage",
    email="professeur@example.com",
    phone="+33123456789"
)
```

## Gestion des Erreurs

### Erreurs Courantes

#### Erreur d'Authentification

```
Erreur: Invalid credentials
```

**Solution** : Vérifier `ODOO_USERNAME` et `ODOO_API_KEY` dans `.env`

#### Erreur de Permissions

```
Erreur: Access denied
```

**Solution** : Vérifier les permissions de l'utilisateur Odoo

#### Erreur de Connexion

```
Erreur: Connection refused
```

**Solution** : Vérifier `ODOO_URL` et que l'instance Odoo est accessible

### Logs de Synchronisation

Toutes les erreurs de synchronisation sont loggées dans :
- **Base de données** : Table `sync_logs` (si créée)
- **Fichiers logs** : Fichiers de log de l'application

## Tests

### Mode Test

Pour tester l'intégration sans affecter les données Odoo de production :

1. Utiliser une instance Odoo de test
2. Configurer les variables d'environnement avec les identifiants de test
3. Tester toutes les synchronisations

### Vérification

Après chaque synchronisation, vérifier dans Odoo :
- Les contacts créés
- Les factures générées
- Les leads créés

---

**Version** : 1.0  
**Date** : 2025-01-20
