# Cahier des Charges Détaillé

## Table des Matières

1. [Spécifications Fonctionnelles par Domaine](#spécifications-fonctionnelles-par-domaine)
2. [Règles Métier](#règles-métier)
3. [Modèles de Données](#modèles-de-données)
4. [APIs et Intégrations](#apis-et-intégrations)
5. [Contraintes Techniques](#contraintes-techniques)
6. [Exigences Non-Fonctionnelles](#exigences-non-fonctionnelles)

---

## Spécifications Fonctionnelles par Domaine

### Domaine 1 : Gestion de Voyages

#### 1.1 Voyages Scolaires

**Fonctionnalité** : Gestion complète des voyages scolaires

**Acteurs** : Commercial, Professeur

##### 1.1.1 Formulaire Public Professeur

**Fonctionnalités** :
- **Formulaire accessible sans authentification**
 - Dates souhaitées
 - Destinations souhaitées (multiples)
 - Budget approximatif
 - Nombre approximatif de participants
 - Informations du professeur (nom, email, téléphone, école)
 
- **Traitement du formulaire**
 - Création automatique d'un Teacher (si nouveau)
 - Création d'un Travel en statut DRAFT
 - Création des TravelDestination
 - Génération d'un token unique
 - Envoi d'un email au professeur avec lien de suivi
 - Notification aux commerciaux (nouveau prospect)

**Règles métier** :
- L'email du professeur doit être valide
- Les dates doivent être dans le futur
- Le nombre de participants doit être > 0

##### 1.1.2 Génération de Planning

**Fonctionnalités** :
- **Génération automatique préconstruite**
 - Basée sur les destinations du voyage
 - Utilisation des activités disponibles par destination
 - Répartition sur les jours du voyage
 - Ordre logique des activités
 
- **Modification manuelle**
 - Ajout/suppression d'activités
 - Modification des horaires
 - Réorganisation des activités
 
- **Validation du planning**
 - Validation par le commercial
 - Le planning validé est utilisé pour le calcul du devis

**Règles métier** :
- Un planning doit avoir au moins une activité
- Les horaires ne doivent pas se chevaucher
- Le planning doit couvrir les jours du voyage

##### 1.1.3 Génération de Devis

**Fonctionnalités** :
- **Calcul automatique du prix**
 - Transport : Prix par destination et date (TransportPrice × nombre participants)
 - Activités : Si planning validé, somme des prix des activités × participants
 - Hébergement : Si renseigné, prix par personne × participants × nombre de nuits
 - Marge : Si renseignée, application d'une marge en pourcentage
 
- **Création du devis**
 - Numéro de devis unique
 - Lignes de devis détaillées (transport, activités, hébergement)
 - Total HT et TTC
 - Date d'expiration (optionnelle)
 
- **Envoi du devis**
 - Envoi par email au professeur
 - Lien de consultation dans l'email
 - Statut du voyage → QUOTE_SENT

**Règles métier** :
- Un devis ne peut être généré que si :
 - Le voyage a au moins une destination
 - Le nombre de participants est défini (ou min/max)
 - Les prix de transport sont renseignés pour les dates
- Le total du devis = somme des lignes
- Les réductions sont appliquées selon le nombre de participants :
 - ≥ 30 participants : 10% de réduction
 - ≥ 20 participants : 5% de réduction
 - ≥ 10 participants : 3% de réduction
- Early bird : 5% de réduction si réservation > 3 mois à l'avance

##### 1.1.4 Validation et Facturation

**Fonctionnalités** :
- **Validation du devis**
 - Acceptation par le professeur (via lien email)
 - Validation par le commercial
 - Statut du voyage → QUOTE_VALIDATED
 
- **Collecte des contacts parents**
 - Interface pour le professeur
 - Ajout des contacts parents (nom, email, téléphone, nom de l'élève)
 - Confirmation du nombre exact de participants
 
- **Validation du dossier**
 - Vérification que tous les contacts parents sont collectés
 - Vérification du nombre exact de participants
 - Recalcul du devis si nombre de participants changé
 - Validation par le commercial
 - Statut dossier_validated = True
 
- **Génération de la facture**
 - Depuis le devis validé
 - Conversion des lignes de devis en lignes de facture
 - Calcul de la TVA (20% par défaut)
 - Numéro de facture unique
 - Statut du voyage → CONFIRMED
 
- **Validation de la facture**
 - Validation par le commercial ou comptable
 - Export Factur-X (XML)
 - Envoi par email au professeur
 - Synchronisation avec Odoo

**Règles métier** :
- Une facture ne peut être générée que si :
 - Le devis est validé
 - Le dossier est validé (dossier_validated = True)
 - Le nombre exact de participants est connu
- La facture reprend les montants du devis validé
- La TVA est calculée sur le total HT

#### 1.2 Voyages Linguistiques

**Fonctionnalité** : Gestion des voyages linguistiques avec inscription en ligne

**Acteurs** : Commercial, Guest (invité)

##### 1.2.1 Création de Voyage Linguistique

**Fonctionnalités** :
- **Création par le commercial**
 - Titre, description
 - Destination
 - Dates (début et fin)
 - Prix par personne
 - Nombre maximum de participants
 - Statut (publié, brouillon)
 
- **Publication**
 - Le voyage publié est visible sur le site public
 - Les invités peuvent s'inscrire

**Règles métier** :
- Les dates doivent être dans le futur
- Le prix par personne doit être > 0
- Le nombre maximum de participants doit être > 0

##### 1.2.2 Inscription en Ligne

**Fonctionnalités** :
- **Formulaire d'inscription public**
 - Informations du participant (nom, prénom, email, téléphone, âge)
 - Sélection du voyage
 - Acceptation des conditions générales
 
- **Création de la réservation**
 - Création d'un Guest (si nouveau)
 - Création d'une Booking
 - Statut PENDING (en attente de paiement)
 
- **Paiement en ligne**
 - Redirection vers Stripe Checkout
 - Paiement sécurisé
 - Webhook Stripe pour confirmation
 
- **Confirmation**
 - Mise à jour du statut de la Booking → CONFIRMED
 - Envoi d'un email de confirmation
 - Synchronisation avec Odoo (création contact)

**Règles métier** :
- Une réservation ne peut être créée que si :
 - Le voyage est publié
 - Il reste des places disponibles
- Le paiement doit être effectué dans les 24h
- Après paiement, la réservation est confirmée

#### 2.3 Destinations et Activités

**Fonctionnalité** : Gestion du catalogue de destinations et activités

**Acteurs** : Commercial

**Fonctionnalités** :
- **CRUD Destinations**
 - Nom, pays, ville
 - Description
 - Images (JSON array)
 - Prix de base
 - Statut (actif, inactif)
 
- **CRUD Activités**
 - Nom, description
 - Destination associée
 - Prix par personne
 - Durée (en heures)
 - Type d'activité
 - Localisation
 - Réutilisable (template)
 
- **Programmes préconstruits**
 - Combinaison destination + activités
 - Ordre des activités
 - Prix par jour
 - Repas inclus (optionnel)

**Règles métier** :
- Une activité doit être associée à une destination
- Le prix de base d'une destination doit être ≥ 0
- Le prix d'une activité doit être ≥ 0

### Domaine 2 : Intégration Odoo

#### 3.1 Synchronisation Contacts

**Fonctionnalité** : Synchronisation des contacts avec Odoo

**Acteurs** : Système (automatique)

**Fonctionnalités** :
- **Création de contact dans Odoo**
 - Lors de la création d'un Teacher
 - Lors de l'inscription d'un Guest
 
- **Mise à jour de contact**
 - Synchronisation des modifications
 - Gestion des conflits (dernière modification gagne)
 
- **Récupération depuis Odoo**
 - Import de contacts existants
 - Mise à jour des données locales

**Règles métier** :
- Un contact Odoo est identifié par `odoo_partner_id`
- La synchronisation est bidirectionnelle
- En cas de conflit, la dernière modification gagne

#### 3.2 Synchronisation CRM

**Fonctionnalité** : Création de leads dans Odoo

**Acteurs** : Système (automatique)

**Fonctionnalités** :
- **Création de lead**
 - Lors de la soumission du formulaire professeur
 - Lead avec toutes les informations du voyage
 - Statut "Nouveau"
 - Attribution au commercial responsable
 
- **Mise à jour du lead**
 - Lors de la validation du devis
 - Lors de la génération de la facture
 - Conversion en opportunité

**Règles métier** :
- Un lead est créé pour chaque nouveau voyage scolaire
- Le lead est lié au contact Teacher dans Odoo

#### 3.3 Synchronisation Facturation

**Fonctionnalité** : Génération de factures dans Odoo

**Acteurs** : Système (automatique)

**Fonctionnalités** :
- **Création de facture Odoo**
 - Lors de la validation d'une facture dans le système
 - Facture avec toutes les lignes
 - Lien avec le contact client
 - Numéro de facture synchronisé
 
- **Validation dans Odoo**
 - La facture est créée en brouillon
 - Validation manuelle dans Odoo (optionnelle)
 
- **Export comptable**
 - Export des écritures comptables
 - Conformité avec la comptabilité Odoo

**Règles métier** :
- Une facture Odoo est créée pour chaque facture validée
- Le numéro de facture doit être unique dans Odoo

### Domaine 3 : Infrastructure

#### 4.1 Authentification et Autorisation

**Fonctionnalité** : Système d'authentification sécurisé

**Acteurs** : Tous les utilisateurs authentifiés

**Fonctionnalités** :
- **Authentification JWT**
 - Login avec email/password
 - Génération de tokens (access + refresh)
 - Expiration des tokens (15 min access, 7 jours refresh)
 
- **2FA (Two-Factor Authentication)**
 - Activation optionnelle
 - TOTP (Time-based One-Time Password)
 - QR code pour configuration
 - Codes de récupération
 
- **Gestion des rôles**
 - Rôles prédéfinis (Admin, Commercial, Comptable)
 - Rôles personnalisés
 - Attribution de rôles aux utilisateurs
 
- **Gestion des permissions**
 - Permissions granulaires par ressource
 - Permissions par rôle
 - Permissions directes par utilisateur
 - Vérification des permissions sur chaque endpoint

**Règles métier** :
- Un utilisateur doit avoir au moins un rôle
- Les permissions sont vérifiées à chaque requête API
- L'admin a tous les droits

#### 4.2 Interface Admin

**Fonctionnalité** : Interface d'administration complète

**Acteurs** : Admin

**Fonctionnalités** :
- **CRUD générique**
 - Accès à toutes les tables de la base de données
 - Édition en ligne (AJAX)
 - Filtres et recherche
 - Export des données
 
- **Gestion des utilisateurs**
 - Création, modification, suppression
 - Attribution de rôles
 - Activation/désactivation
 
- **Monitoring**
 - Statistiques d'utilisation
 - Logs des actions
 - État du système

---

## Règles Métier

### Règles de Calcul de Prix

#### Voyages

1. **Prix de base** = Prix de la destination
2. **Prix activités** = Somme (prix activité × nombre participants)
3. **Prix transport** = Prix transport par personne × nombre participants
4. **Prix hébergement** = Prix par personne × nombre participants × nombre de nuits
5. **Total avant réductions** = Prix de base + Prix activités + Prix transport + Prix hébergement
6. **Réductions** :
 - ≥ 30 participants : -10%
 - ≥ 20 participants : -5%
 - ≥ 10 participants : -3%
 - Early bird (> 3 mois) : -5%
7. **Marge** : Si renseignée, application après réductions
8. **Total final** = (Total avant réductions × (1 - réduction)) × (1 + marge%)

### Règles de Validation

#### Devis

- Un devis ne peut être généré que si :
 - Le voyage a au moins une destination
 - Le nombre de participants est défini
 - Les prix de transport sont renseignés
- Un devis ne peut être validé que s'il est envoyé
- Un devis expiré ne peut plus être validé

#### Factures

- Une facture ne peut être générée que si :
 - Le devis est validé
 - Le dossier est validé
 - Le nombre exact de participants est connu
- Une facture ne peut être validée que par un commercial ou comptable
- Une facture validée ne peut plus être modifiée

### Règles de Paiement

#### Voyages Linguistiques

- Le paiement doit être effectué dans les 24h suivant l'inscription
- Le paiement est traité via Stripe
- En cas d'échec, la réservation est annulée

### Règles de Synchronisation Odoo

- La synchronisation est automatique pour :
 - Création de contacts (Teacher, Guest)
 - Création de leads (nouveaux voyages)
 - Création de factures (factures validées)
- En cas d'erreur de synchronisation, un log est créé
- La synchronisation peut être relancée manuellement

---

## Modèles de Données

Voir la documentation Merise :
- [MCD](03_diagrammes_merise/01_mcd.md)
- [MLD](03_diagrammes_merise/02_mld.md)

---

## APIs et Intégrations

### API REST

Voir la documentation complète : [Documentation API](08_documentation_api/)

**Endpoints principaux** :
- `/api/auth/*` : Authentification
- `/api/users/*` : Gestion utilisateurs
- `/api/travels/*` : Gestion voyages
- `/api/quotes/*` : Gestion devis
- `/api/invoices/*` : Gestion factures
- `/api/odoo/*` : Intégration Odoo

### Intégrations Externes

#### Odoo
- **Protocole** : XML-RPC
- **Modules utilisés** : CRM, Facturation, Comptabilité, Contacts, Email Marketing, Documents

#### Stripe
- **API REST** : Paiements en ligne
- **Webhooks** : Confirmation de paiement
- **Mode test** : Disponible pour les tests

#### Email (SMTP)
- **Protocole** : SMTP
- **Templates** : Devis, factures, notifications
- **Notifications** : Nouveaux prospects, validations

---

## Contraintes Techniques

### Technologies

- **Backend** : Python 3.9+, FastAPI
- **Frontend** : Vue.js 3, Element Plus, Vite
- **Base de données** : MySQL 8.0+ (InnoDB, utf8mb4)
- **ORM** : SQLAlchemy
- **Migrations** : Alembic
- **Authentification** : JWT (PyJWT), 2FA (pyotp)
- **Intégrations** : 
 - Odoo (xmlrpc)
 - Stripe (stripe)
 - Email (smtplib)

### Limitations

- **Taille des fichiers** : 10 MB maximum par document
- **Nombre de participants** : 1000 maximum par voyage
- **Taille de la base** : Optimisée pour < 1M d'enregistrements
- **Concurrence** : 1000 utilisateurs simultanés

---

## Exigences Non-Fonctionnelles

Voir le document dédié : [Exigences Non-Fonctionnelles](04_exigences_non_fonctionnelles.md)

### Résumé

- **Performance** : < 200ms pour 95% des requêtes
- **Sécurité** : TLS 1.3, 2FA pour admins, audit trail
- **Disponibilité** : SLA 99.5%
- **Scalabilité** : Architecture horizontale
- **Maintenabilité** : Code documenté, tests > 80%
