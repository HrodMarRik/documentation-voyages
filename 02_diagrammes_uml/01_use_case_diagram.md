# Diagramme de Cas d'Utilisation - Système Intégré de Gestion

## Vue d'Ensemble

Ce document présente les cas d'utilisation du système de gestion de voyages (scolaires et linguistiques) avec intégration Odoo. Le diagramme est organisé en modules pour une meilleure lisibilité.

## Acteurs

- **Admin** : Gestion complète du système
- **Commercial** : Gestion des voyages, devis, factures
- **Professeur** : Formulaire public, contacts parents
- **Comptable** : Validation des factures
- **Guest** : Inscription et paiement des voyages linguistiques

## Diagramme d'Ensemble (Vue Simplifiée)

```mermaid
graph LR
    Admin[Admin]
    Commercial[Commercial]
    Professeur[Professeur]
    Comptable[Comptable]
    Guest[Guest]
    
    Admin --> Users[Gestion Utilisateurs]
    Admin --> Auth[Authentification]
    Admin --> CRUD[Admin CRUD]
    
    Commercial --> Voyages[Gestion Voyages]
    Commercial --> Devis[Gestion Devis]
    Commercial --> Factures[Gestion Factures]
    Commercial --> Destinations[Destinations/Activités]
    Commercial --> Documents[Documents]
    
    Professeur --> Formulaire[Formulaire Public]
    Professeur --> Contacts[Contacts Parents]
    
    Comptable --> Factures
    
    Guest --> Linguistiques[Voyages Linguistiques]
    
    Voyages -.-> Odoo[Intégration Odoo]
    Factures -.-> Odoo
```

## Diagrammes Détaillés par Domaine

### 1. [Gestion Utilisateurs & Authentification](01_use_case_01_auth.md)
- Authentification (UC56-UC59)
- Gestion utilisateurs (UC1-UC5)
- Admin CRUD (UC55)

### 2. [Gestion Voyages](01_use_case_02_voyages.md)
- Voyages scolaires (UC19-UC23)
- Voyages linguistiques (UC24, UC52-UC54)
- Destinations et activités (UC25-UC29)
- Plannings (UC30-UC32)

### 3. [Gestion Devis & Factures](01_use_case_03_devis_factures.md)
- Devis (UC33-UC38)
- Factures (UC39-UC42)
- Formulaire public (UC43-UC45)

### 4. [Documents & Contacts](01_use_case_04_documents.md)
- Documents (UC46-UC48)
- Contacts parents (UC49-UC51)

### 5. [Intégration Odoo](01_use_case_05_odoo.md)
- Synchronisation contacts (UC60)
- Création leads (UC61)
- Création factures (UC62)

## Liste Complète des Cas d'Utilisation

### Gestion Utilisateurs (UC1-UC5)
- UC1 : Créer utilisateur
- UC2 : Modifier utilisateur
- UC3 : Supprimer utilisateur
- UC4 : Gérer rôles
- UC5 : Gérer permissions

### Gestion Voyages (UC19-UC24)
- UC19 : Créer voyage scolaire
- UC20 : Modifier voyage
- UC21 : Valider voyage
- UC22 : Annuler voyage
- UC23 : Suivre voyage
- UC24 : Créer voyage linguistique

### Gestion Destinations/Activités (UC25-UC29)
- UC25 : Créer destination
- UC26 : Modifier destination
- UC27 : Créer activité
- UC28 : Modifier activité
- UC29 : Créer programme préconstruit

### Gestion Plannings (UC30-UC32)
- UC30 : Générer planning préconstruit
- UC31 : Modifier planning
- UC32 : Valider planning

### Gestion Devis (UC33-UC38)
- UC33 : Saisir prix transport
- UC34 : Générer devis
- UC35 : Modifier devis
- UC36 : Envoyer devis
- UC37 : Valider devis
- UC38 : Recalculer devis

### Gestion Factures (UC39-UC42)
- UC39 : Générer facture
- UC40 : Valider facture
- UC41 : Exporter facture (XML/PDF)
- UC42 : Stocker facture

### Formulaire Public (UC43-UC45)
- UC43 : Remplir formulaire professeur
- UC44 : Recevoir devis
- UC45 : Recevoir facture

### Gestion Documents (UC46-UC48)
- UC46 : Uploader document
- UC47 : Télécharger document
- UC48 : Supprimer document

### Gestion Contacts Parents (UC49-UC51)
- UC49 : Ajouter contact parent
- UC50 : Modifier contact parent
- UC51 : Supprimer contact parent

### Voyages Linguistiques (UC52-UC54)
- UC52 : S'inscrire voyage linguistique
- UC53 : Payer en ligne
- UC54 : Consulter réservation

### Admin CRUD (UC55)
- UC55 : Accès CRUD base de données

### Authentification (UC56-UC59)
- UC56 : Se connecter
- UC57 : Activer 2FA
- UC58 : Vérifier 2FA
- UC59 : Se déconnecter

### Intégration Odoo (UC60-UC62)
- UC60 : Synchroniser contacts
- UC61 : Créer lead Odoo
- UC62 : Créer facture Odoo

---

**Version** : 1.0  
**Date** : 2025-01-20
