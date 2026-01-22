# Cahier des Charges Exécutif

## Vision Globale du Système

Ce document présente un système intégré de gestion qui combine deux domaines fonctionnels principaux :

1. **Gestion de Voyages** : Voyages scolaires et linguistiques, devis, factures
2. **Intégration Odoo** : Synchronisation complète avec l'ERP Odoo (CRM, facturation, comptabilité)

## Objectifs Métier

### Objectifs Stratégiques

- **Digitalisation complète** des processus de gestion de voyages
- **Automatisation** des tâches répétitives (génération de devis, factures)
- **Intégration ERP** pour une gestion unifiée avec Odoo
- **Amélioration de la productivité** des équipes commerciales et comptables
- **Réduction des erreurs** grâce à l'automatisation des calculs

### Objectifs Opérationnels

- **Workflow complet** pour les voyages scolaires (de la demande à la facture)
- **Inscription en ligne** pour les voyages linguistiques avec paiement Stripe
- **Synchronisation automatique** avec Odoo (contacts, factures, leads)
- **Interface moderne** et intuitive pour tous les utilisateurs

## Périmètre Fonctionnel

### Domaine 1 : Gestion de Voyages

#### Voyages Scolaires
- **Formulaire public** pour les professeurs
- **Génération automatique** de plannings préconstruits
- **Création de devis** avec calcul automatique des prix
- **Gestion des contacts parents**
- **Génération de factures** depuis les devis validés
- **Export Factur-X** pour conformité 2027

#### Voyages Linguistiques
- **Catalogue public** des voyages disponibles
- **Inscription en ligne** pour les participants
- **Paiement en ligne** via Stripe
- **Gestion des réservations** et confirmations

#### Fonctionnalités Transverses
- **Destinations et activités** réutilisables
- **Programmes préconstruits** par destination
- **Calcul de prix dynamique** selon nombre de participants
- **Gestion des documents** (devis, factures, contrats)

### Domaine 2 : Intégration Odoo

- **Contacts** : Synchronisation clients, fournisseurs
- **CRM** : Création automatique de leads depuis les demandes
- **Facturation** : Génération de factures Odoo depuis le système
- **Comptabilité** : Export des écritures comptables
- **Email Marketing** : Campagnes et listes de diffusion
- **Documents** : Stockage et gestion des fichiers
- **WhatsApp** : Envoi de messages (via modules Odoo)

### Domaine 3 : Infrastructure

- **Authentification** : JWT + 2FA (TOTP)
- **Autorisation** : Système de rôles et permissions granulaires
- **Interface Admin** : CRUD complet sur toutes les tables
- **API REST** : 100+ endpoints documentés
- **Frontend moderne** : Vue.js 3 avec Element Plus

## Acteurs Principaux

### Admin
- Gestion complète des utilisateurs, rôles et permissions
- Accès CRUD sur toutes les tables de la base de données
- Configuration système
- Monitoring et statistiques

### Commercial
- Création et gestion des voyages
- Gestion des destinations et activités
- Génération et modification des plannings
- Création et envoi de devis
- Création et validation de factures
- Suivi des dossiers

### Professeur
- Remplissage du formulaire de demande de voyage
- Consultation des devis et factures
- Envoi des contacts parents
- Suivi de l'avancement du dossier

### Comptable
- Validation des factures
- Export des documents comptables (Factur-X)
- Suivi des paiements
- Rapports comptables

### Guest (Invité)
- Inscription aux voyages linguistiques
- Paiement en ligne
- Consultation de la réservation

## Bénéfices Attendus

### Gains de Productivité

- **Réduction de 70%** du temps de création de devis (automatisation)
- **Élimination des erreurs** de calcul manuel
- **Synchronisation automatique** avec Odoo

### Amélioration de la Qualité

- **Traçabilité complète** de tous les processus
- **Conformité** avec les normes de facturation électronique (Factur-X 2027)
- **Audit trail** pour toutes les actions importantes
- **Validation automatique** des données

## Architecture Générale

### Stack Technologique

- **Backend** : Python 3.9+, FastAPI
- **Frontend** : Vue.js 3, Element Plus, Vite
- **Base de données** : MySQL 8.0+ (InnoDB, utf8mb4)
- **ORM** : SQLAlchemy
- **Migrations** : Alembic
- **Authentification** : JWT + 2FA (TOTP via pyotp)
- **Intégrations** : 
 - Odoo (XML-RPC)
 - Stripe (API REST)
 - SMTP (emails transactionnels)

### Architecture en Couches

1. **Présentation** : Frontend Vue.js (SPA)
2. **API** : Backend FastAPI (REST)
3. **Logique Métier** : Services Python
4. **Données** : MySQL avec SQLAlchemy
5. **Intégrations** : Odoo, Stripe, Email

## Conclusion

Ce système intégré offre une solution complète pour la gestion de voyages (scolaires et linguistiques), avec une intégration native à Odoo. Il permet d'automatiser les processus répétitifs, de réduire les erreurs et d'améliorer significativement la productivité des équipes.

La documentation complète dans ce dossier détaille tous les aspects techniques, fonctionnels et métier du système.
