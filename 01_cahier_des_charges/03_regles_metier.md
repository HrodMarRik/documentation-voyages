# Règles Métier

## Règles de Calcul de Prix

### Voyages Scolaires

#### Formule de Calcul

```
Prix Total = (Prix Transport + Prix Activités + Prix Hébergement) × Réductions × Marge
```

#### Détail des Composants

1. **Prix Transport**
 ```
 Prix Transport = Σ (TransportPrice.price_per_person × nombre_participants)
 ```
 - Pour chaque destination du voyage
 - Prix par destination et date (table `transport_prices`)
 - Multiplié par le nombre de participants

2. **Prix Activités**
 ```
 Prix Activités = Σ (Activity.price_per_person × nombre_participants)
 ```
 - Si le planning (ProgramTemplate) est validé
 - Pour chaque activité du planning
 - Prix par personne multiplié par le nombre de participants

3. **Prix Hébergement**
 ```
 Prix Hébergement = lodging_price_per_person × nombre_participants × nombre_nuits
 ```
 - Si `lodging_price_per_person` est renseigné
 - Nombre de nuits = (end_date - start_date).days

4. **Réductions**

 Réductions selon nombre de participants :
 - **≥ 30 participants** : 10% de réduction
 - **≥ 20 participants** : 5% de réduction
 - **≥ 10 participants** : 3% de réduction
 
 Réduction early bird :
 - **Réservation > 3 mois à l'avance** : 5% de réduction supplémentaire
 - Calcul : jours_avant_depart = (start_date - date_aujourd'hui).days
 - Si jours_avant_depart > 90 : application de la réduction

5. **Marge**
 ```
 Prix Final = Prix Avant Réductions × (1 - réduction%) × (1 + marge%)
 ```
 - Si `margin_percent` est renseigné
 - Application après les réductions

#### Exemple de Calcul

```
Voyage : 25 participants, départ dans 4 mois
- Transport : 100€ × 25 = 2 500€
- Activités : 50€ × 25 = 1 250€
- Hébergement : 30€ × 25 × 5 nuits = 3 750€
- Total avant réductions : 7 500€
- Réduction 20+ participants (5%) : 7 500€ × 0.95 = 7 125€
- Réduction early bird (5%) : 7 125€ × 0.95 = 6 768.75€
- Marge 10% : 6 768.75€ × 1.10 = 7 445.63€
- Prix final : 7 445.63€
```

### Voyages Linguistiques

```
Prix Total = price_per_person × nombre_participants
```

- Prix fixe par personne
- Pas de réductions
- Pas de marge supplémentaire

- Prorata = (16 / 31) × 800€ = 412.90€

## Règles de Validation

### Devis

#### Conditions de Génération

Un devis ne peut être généré que si :
1. Le voyage existe et est en statut DRAFT ou QUOTE_SENT
2. Le voyage a au moins une destination (`travel_destinations`)
3. Le nombre de participants est défini (ou min/max)
4. Les prix de transport sont renseignés pour les dates du voyage

#### Conditions de Validation

Un devis ne peut être validé que si :
1. Le devis est en statut SENT
2. Le devis n'est pas expiré (si `expires_at` est renseigné)
3. Le voyage est en statut QUOTE_SENT

#### Workflow

```
DRAFT → SENT → VALIDATED
 ↓
 REJECTED
```

### Factures

#### Conditions de Génération

Une facture peut être générée depuis un devis si :
1. Le devis est en statut VALIDATED
2. Le voyage a `dossier_validated = True`
3. Le nombre exact de participants est connu (`number_participants`)

#### Conditions de Validation

Une facture ne peut être validée que par :
- Un utilisateur avec rôle Commercial ou Comptable
- La facture doit être en statut DRAFT

#### Workflow

```
DRAFT → VALIDATED → PAID
 ↓
 CANCELLED
```

### Plannings

#### Conditions de Validation

Un planning (ProgramTemplate) peut être validé si :
1. Le planning a au moins une activité
2. Les horaires ne se chevauchent pas
3. Le planning couvre les jours du voyage

## Règles de Paiement

### Voyages Linguistiques

#### Conditions

- Le paiement doit être effectué dans les **24 heures** suivant l'inscription
- Le paiement est traité via **Stripe**
- En cas d'échec, la réservation est automatiquement annulée

#### Workflow

```
Booking créé (PENDING) → Paiement Stripe → 
 Succès → CONFIRMED + PAID
 Échec → CANCELLED + FAILED
```

## Règles de Synchronisation Odoo

### Quand Synchroniser

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

### Gestion des Conflits

- **Stratégie** : Dernière modification gagne
- **Logs** : Toutes les erreurs de synchronisation sont loggées
- **Relance** : Possibilité de relancer manuellement la synchronisation

### Identifiants Odoo

- Chaque entité locale stocke son identifiant Odoo :
 - `odoo_partner_id` : Pour Teacher, Guest
 - `odoo_lead_id` : Pour Travel
 - `odoo_quote_id` : Pour Quote
 - `odoo_invoice_id` : Pour Invoice

## Règles de Sécurité

### Authentification

- **JWT Tokens** :
 - Access token : Expiration 15 minutes
 - Refresh token : Expiration 7 jours
 - Rotation automatique des tokens

- **2FA** :
 - Obligatoire pour les utilisateurs Admin
 - Optionnel pour les autres rôles
 - TOTP (Time-based One-Time Password)
 - Codes de récupération en cas de perte

### Autorisation

- **Vérification des permissions** :
 - Sur chaque endpoint API
 - Basée sur les rôles et permissions de l'utilisateur
 - Logs d'audit pour les accès refusés

- **Rôles prédéfinis** :
 - **Admin** : Tous les droits
 - **Commercial** : Gestion voyages, devis, factures
 - **Comptable** : Validation factures, export comptable
 - **Professeur** : Consultation devis/factures, envoi contacts
 - **Guest** : Inscription voyages linguistiques

### Audit Trail

- **Actions tracées** :
 - Création, modification, suppression d'entités
 - Changements de statut
 - Validations (devis, factures)
 - Connexions utilisateurs

- **Stockage** :
 - Table `travel_status_history` pour les changements de statut
 - Logs système pour les autres actions

## Règles de Données

### Contraintes d'Intégrité

- **Clés étrangères** : Toutes les relations sont contraintes
- **Unicité** : 
 - Email unique pour User, Teacher, Guest
 - Numéro unique pour Quote, Invoice
 - Token unique pour TeacherForm

### Validation des Données

- **Email** : Format valide requis
- **Dates** : 
 - Date de fin > date de début
 - Dates de voyage dans le futur
- **Prix** : 
 - Tous les prix doivent être ≥ 0
 - Loyer mensuel > 0
- **Participants** : 
 - Nombre de participants > 0
 - max_participants ≥ min_participants

### Données Optionnelles vs Obligatoires

Voir le MLD pour la liste complète des champs obligatoires (`NOT NULL`) et optionnels.
