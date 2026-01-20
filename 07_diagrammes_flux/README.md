# Diagrammes de Flux de Données (DFD)

Ce dossier contient les diagrammes de flux de données représentant les flux d'information dans le système.

## Niveaux de Détail

### Niveau 0 : Contexte
- **Fichier** : `00_dfd_contexte.md`
- **Description** : Vue d'ensemble du système et de ses interactions avec les entités externes

### Niveau 1 : Vue Fonctionnelle
- **Fichier** : `01_dfd_niveau1.md`
- **Description** : Décomposition des processus principaux

### Niveau 2 : Vue Détaillée
- **Fichier** : `02_dfd_niveau2_voyages.md` : Flux détaillés pour la gestion des voyages
- **Fichier** : `02_dfd_niveau2_facturation.md` : Flux détaillés pour la facturation
- **Fichier** : `02_dfd_niveau2_odoo.md` : Flux détaillés pour l'intégration Odoo

## Entités Externes

- **Professeur** : Utilisateur externe soumettant des demandes
- **Guest** : Participant aux voyages linguistiques
- **Odoo** : Système ERP externe
- **Stripe** : Plateforme de paiement
- **SMTP Server** : Serveur email

## Stockages de Données

- **Base de données MySQL** : Stockage principal
- **Stockage fichiers** : Documents (devis, factures)

## Format

Les diagrammes sont créés en Mermaid pour une visualisation directe dans Markdown.

---

**Note** : Les diagrammes de flux de données détaillés seront ajoutés dans une phase ultérieure du projet.
