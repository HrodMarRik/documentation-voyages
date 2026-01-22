# Guide Utilisateur - Commercial

## Vue d'Ensemble

Ce guide présente les fonctionnalités disponibles pour les utilisateurs avec le rôle **Commercial**. Les commerciaux sont responsables de la gestion des voyages, devis et factures.

## Connexion

1. Accéder à l'URL de l'application
2. Saisir votre email et mot de passe
3. Si la 2FA est activée, saisir le code à 6 chiffres
4. Cliquer sur "Se connecter"

## Tableau de Bord

Le tableau de bord affiche :
- **Voyages en cours** : Liste des voyages actifs
- **Devis en attente** : Devis envoyés en attente de validation
- **Factures à valider** : Factures en attente de validation
- **Statistiques** : Nombre de voyages, revenus, etc.

## Gestion des Voyages Scolaires

### Créer un Voyage

1. Aller dans **Voyages** → **Nouveau voyage**
2. Remplir les informations :
   - Nom du voyage
   - Type : Voyage scolaire
   - Dates (début et fin)
   - Destinations
   - Nombre de participants (min/max)
   - Professeur (créer si nouveau)
3. Cliquer sur **Créer**

### Générer un Planning

1. Ouvrir le voyage
2. Aller dans l'onglet **Planning**
3. Cliquer sur **Générer planning préconstruit**
4. Le système génère automatiquement un planning basé sur les destinations
5. Modifier le planning si nécessaire :
   - Ajouter/supprimer des activités
   - Modifier les horaires
   - Réorganiser les activités
6. Cliquer sur **Valider le planning**

### Saisir les Prix de Transport

1. Ouvrir le voyage
2. Aller dans l'onglet **Transport**
3. Pour chaque destination et date :
   - Cliquer sur **Ajouter prix transport**
   - Saisir le prix par personne
   - Saisir le type de transport
   - Cliquer sur **Enregistrer**

### Générer un Devis

1. Ouvrir le voyage
2. Vérifier que :
   - Le planning est validé (optionnel)
   - Les prix de transport sont renseignés
   - Le nombre de participants est défini
3. Aller dans l'onglet **Devis**
4. Cliquer sur **Générer devis**
5. Le système calcule automatiquement :
   - Transport
   - Activités (si planning validé)
   - Hébergement (si renseigné)
   - Réductions (selon nombre de participants)
   - Marge (si renseignée)
6. Vérifier le devis
7. Cliquer sur **Envoyer au professeur**

### Valider un Devis

1. Une fois le devis accepté par le professeur
2. Ouvrir le voyage → **Devis**
3. Cliquer sur **Valider le devis**
4. Le statut du voyage passe à **QUOTE_VALIDATED**

### Valider un Dossier

1. Vérifier que :
   - Le devis est validé
   - Les contacts parents sont collectés
   - Le nombre exact de participants est confirmé
2. Ouvrir le voyage → **Dossier**
3. Cliquer sur **Valider le dossier**

### Générer une Facture

1. Vérifier que :
   - Le devis est validé
   - Le dossier est validé
2. Ouvrir le voyage → **Factures**
3. Cliquer sur **Générer facture depuis devis**
4. Le système :
   - Convertit les lignes de devis en lignes de facture
   - Calcule la TVA (20%)
   - Génère le XML Factur-X
5. Vérifier la facture
6. Cliquer sur **Valider la facture**
7. La facture est envoyée au professeur et synchronisée avec Odoo

## Gestion des Voyages Linguistiques

### Créer un Voyage Linguistique

1. Aller dans **Voyages Linguistiques** → **Nouveau**
2. Remplir les informations :
   - Titre
   - Description
   - Destination
   - Dates
   - Prix par personne
   - Nombre maximum de participants
3. Cliquer sur **Publier** pour le rendre visible publiquement

### Suivre les Réservations

1. Aller dans **Voyages Linguistiques**
2. Ouvrir un voyage
3. Voir les réservations dans l'onglet **Réservations**
4. Statuts :
   - **PENDING** : En attente de paiement
   - **CONFIRMED** : Paiement effectué
   - **CANCELLED** : Annulé

## Gestion des Destinations et Activités

### Créer une Destination

1. Aller dans **Destinations** → **Nouveau**
2. Remplir :
   - Nom
   - Pays, Ville
   - Prix de base
   - Description
   - Images (optionnel)
3. Cliquer sur **Créer**

### Créer une Activité

1. Aller dans **Activités** → **Nouveau**
2. Sélectionner une destination
3. Remplir :
   - Nom
   - Description
   - Prix par personne
   - Durée (en heures)
   - Type d'activité
   - Localisation
4. Cocher **Réutilisable** si l'activité peut être réutilisée
5. Cliquer sur **Créer**

### Créer un Programme Préconstruit

1. Aller dans **Programmes** → **Nouveau**
2. Sélectionner une destination
3. Remplir :
   - Nom
   - Durée (en jours)
   - Prix par jour
   - Repas inclus (optionnel)
4. Ajouter des activités dans l'ordre souhaité
5. Cliquer sur **Créer**

## Suivi et Reporting

### Suivre un Voyage

1. Ouvrir le voyage
2. Voir l'historique des statuts dans l'onglet **Historique**
3. Voir les documents dans l'onglet **Documents**
4. Voir les contacts parents dans l'onglet **Contacts Parents**

### Statistiques

Le tableau de bord affiche :
- Nombre de voyages par statut
- Revenus par période
- Taux de conversion (devis → factures)
- Voyages à venir

## Astuces

- **Raccourcis clavier** : Utiliser `Ctrl+S` pour sauvegarder
- **Recherche** : Utiliser la barre de recherche pour trouver rapidement
- **Filtres** : Utiliser les filtres pour affiner les listes
- **Export** : Exporter les données en CSV/Excel depuis les listes
