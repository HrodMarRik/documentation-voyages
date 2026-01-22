# Documentation API REST Complète

## Vue d'Ensemble

L'API REST du système de gestion intégré expose plus de 100 endpoints organisés par domaine fonctionnel. Tous les endpoints utilisent le protocole HTTP/HTTPS et retournent des réponses au format JSON.

## Base URL

```
http://localhost:8000/api
```

## Authentification

Tous les endpoints (sauf `/api/public/*`) nécessitent une authentification JWT.

### Headers Requis

```
Authorization: Bearer {access_token}
Content-Type: application/json
```

### Obtenir un Token

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password"
}
```

**Réponse** :
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer",
  "requires_2fa": false
}
```

## Endpoints par Domaine

### Authentification (`/api/auth`)

#### POST /api/auth/login
Connexion utilisateur

**Body** :
```json
{
  "email": "string",
  "password": "string"
}
```

**Réponse** : Tokens JWT ou `requires_2fa: true`

#### POST /api/auth/logout
Déconnexion utilisateur

#### POST /api/auth/refresh
Rafraîchir le token d'accès

**Body** :
```json
{
  "refresh_token": "string"
}
```

#### POST /api/auth/2fa/enable
Activer l'authentification à deux facteurs

#### POST /api/auth/2fa/verify
Vérifier le code 2FA

**Body** :
```json
{
  "code": "123456"
}
```

#### GET /api/auth/me
Récupérer les informations de l'utilisateur connecté

### Utilisateurs (`/api/users`)

#### GET /api/users
Liste des utilisateurs (Admin uniquement)

**Query params** :
- `skip`: int (pagination)
- `limit`: int (pagination)

#### POST /api/users
Créer un utilisateur (Admin uniquement)

**Body** :
```json
{
  "email": "string",
  "password": "string",
  "first_name": "string",
  "last_name": "string",
  "role_ids": [1, 2]
}
```

#### GET /api/users/{id}
Récupérer un utilisateur

#### PUT /api/users/{id}
Modifier un utilisateur

#### DELETE /api/users/{id}
Supprimer un utilisateur (Admin uniquement)

#### GET /api/users/{id}/roles
Récupérer les rôles d'un utilisateur

#### POST /api/users/{id}/roles
Ajouter un rôle à un utilisateur

### Rôles (`/api/roles`)

#### GET /api/roles
Liste des rôles

#### POST /api/roles
Créer un rôle (Admin uniquement)

#### GET /api/roles/{id}
Récupérer un rôle

#### PUT /api/roles/{id}
Modifier un rôle (Admin uniquement)

#### DELETE /api/roles/{id}
Supprimer un rôle (Admin uniquement)

#### GET /api/roles/{id}/permissions
Récupérer les permissions d'un rôle

#### POST /api/roles/{id}/permissions
Ajouter une permission à un rôle

### Voyages (`/api/travels`)

#### GET /api/travels
Liste des voyages

**Query params** :
- `status`: string
- `travel_type`: string (school, linguistic_group)
- `teacher_id`: int

#### POST /api/travels
Créer un voyage (Commercial)

**Body** :
```json
{
  "name": "string",
  "travel_type": "school",
  "destination_id": 0,
  "start_date": "2025-01-01T00:00:00",
  "end_date": "2025-01-07T00:00:00",
  "min_participants": 0,
  "max_participants": 0,
  "teacher_id": 0
}
```

#### GET /api/travels/{id}
Récupérer un voyage

#### PUT /api/travels/{id}
Modifier un voyage

#### DELETE /api/travels/{id}
Supprimer un voyage

#### POST /api/travels/{id}/validate
Valider un voyage

#### POST /api/travels/{id}/cancel
Annuler un voyage

### Destinations (`/api/destinations`)

#### GET /api/destinations
Liste des destinations

#### POST /api/destinations
Créer une destination (Commercial)

#### GET /api/destinations/{id}
Récupérer une destination

#### PUT /api/destinations/{id}
Modifier une destination

#### DELETE /api/destinations/{id}
Supprimer une destination

### Activités (`/api/activities`)

#### GET /api/activities
Liste des activités

**Query params** :
- `destination_id`: int
- `travel_id`: int

#### POST /api/activities
Créer une activité (Commercial)

#### GET /api/activities/{id}
Récupérer une activité

#### PUT /api/activities/{id}
Modifier une activité

#### DELETE /api/activities/{id}
Supprimer une activité

### Plannings (`/api/program-templates`)

#### GET /api/program-templates
Liste des plannings

**Query params** :
- `travel_id`: int

#### POST /api/program-templates
Créer un planning (Commercial)

#### POST /api/program-templates/generate
Générer un planning préconstruit (Commercial)

**Body** :
```json
{
  "travel_id": 0
}
```

#### PUT /api/program-templates/{id}
Modifier un planning

#### POST /api/program-templates/{id}/validate
Valider un planning (Commercial)

### Devis (`/api/quotes`)

#### GET /api/quotes
Liste des devis

**Query params** :
- `travel_id`: int
- `status`: string

#### POST /api/quotes
Créer un devis (Commercial)

#### POST /api/quotes/generate/{travel_id}
Générer un devis automatique (Commercial)

#### GET /api/quotes/{id}
Récupérer un devis

#### PUT /api/quotes/{id}
Modifier un devis

#### POST /api/quotes/{id}/send
Envoyer un devis (Commercial)

#### POST /api/quotes/{id}/validate
Valider un devis (Commercial)

#### POST /api/quotes/{id}/recalculate
Recalculer un devis (Commercial)

#### GET /api/quotes/{id}/lines
Récupérer les lignes d'un devis

### Factures (`/api/invoices`)

#### GET /api/invoices
Liste des factures

**Query params** :
- `travel_id`: int
- `status`: string

#### POST /api/invoices
Créer une facture (Commercial)

#### POST /api/invoices/generate-from-quote/{quote_id}
Générer une facture depuis un devis (Commercial)

#### GET /api/invoices/{id}
Récupérer une facture

#### PUT /api/invoices/{id}
Modifier une facture

#### POST /api/invoices/{id}/validate
Valider une facture (Commercial, Comptable)

#### GET /api/invoices/{id}/download
Télécharger une facture (PDF)

#### GET /api/invoices/{id}/export
Exporter une facture (XML Factur-X)

#### POST /api/invoices/{id}/export-and-store
Exporter et stocker une facture

### Documents (`/api/documents`)

#### GET /api/documents
Liste des documents

**Query params** :
- `travel_id`: int
- `document_type`: string

#### POST /api/documents/upload
Uploader un document

**Content-Type**: `multipart/form-data`

#### GET /api/documents/{id}/download
Télécharger un document

#### DELETE /api/documents/{id}
Supprimer un document

### Contacts Parents (`/api/parent-contacts`)

#### GET /api/parent-contacts
Liste des contacts parents

**Query params** :
- `travel_id`: int
- `booking_id`: int

#### POST /api/parent-contacts
Ajouter un contact parent (Teacher)

#### PUT /api/parent-contacts/{id}
Modifier un contact parent

#### DELETE /api/parent-contacts/{id}
Supprimer un contact parent

### Voyages Linguistiques (`/api/linguistic-travels`)

#### GET /api/linguistic-travels
Liste des voyages linguistiques (public)

#### POST /api/linguistic-travels
Créer un voyage linguistique (Commercial)

#### GET /api/linguistic-travels/{id}
Récupérer un voyage linguistique

#### PUT /api/linguistic-travels/{id}
Modifier un voyage linguistique

#### POST /api/linguistic-travels/registrations
S'inscrire à un voyage linguistique (Guest)

**Body** :
```json
{
  "linguistic_travel_id": 0,
  "guest_email": "string",
  "guest_name": "string",
  "phone": "string"
}
```

### Invités (`/api/guests`)

#### GET /api/guests
Liste des invités

#### POST /api/guests
Créer un invité

### Formulaire Public (`/api/public`)

#### POST /api/public/teacher-form
Soumettre le formulaire professeur (public, pas d'authentification)

**Body** :
```json
{
  "teacher_email": "string",
  "contact_email": "string",
  "dates": {
    "start": "2025-01-01",
    "end": "2025-01-07"
  },
  "destinations": [1, 2],
  "budget": 0.0,
  "participants": 0
}
```

#### GET /api/public/teacher-form/{token}
Récupérer un formulaire par token (public)

### Admin CRUD (`/api/admin`)

#### GET /api/admin/tables
Liste des tables disponibles (Admin)

#### GET /api/admin/{table}
Lister les enregistrements d'une table (Admin)

**Query params** :
- `skip`: int
- `limit`: int
- `filter`: string (JSON)

#### POST /api/admin/{table}
Créer un enregistrement (Admin)

#### PUT /api/admin/{table}/{id}
Modifier un enregistrement (Admin)

#### DELETE /api/admin/{table}/{id}
Supprimer un enregistrement (Admin)

### Synchronisation Odoo (`/api/sync`)

#### POST /api/sync/contacts
Synchroniser les contacts avec Odoo

#### POST /api/sync/apartments
Synchroniser les appartements avec Odoo

#### POST /api/sync/invoices
Synchroniser les factures avec Odoo

#### POST /api/sync/all
Synchroniser tout avec Odoo

## Codes de Réponse HTTP

- **200 OK** : Requête réussie
- **201 Created** : Ressource créée
- **400 Bad Request** : Erreur de validation
- **401 Unauthorized** : Non authentifié
- **403 Forbidden** : Permissions insuffisantes
- **404 Not Found** : Ressource non trouvée
- **500 Internal Server Error** : Erreur serveur

## Format des Erreurs

```json
{
  "detail": "Message d'erreur",
  "error_code": "ERROR_CODE",
  "field": "nom_du_champ" // Si erreur de validation
}
```

## Pagination

Toutes les listes supportent la pagination :

**Query params** :
- `skip`: int (défaut: 0)
- `limit`: int (défaut: 50, max: 100)

**Réponse** :
```json
{
  "items": [...],
  "total": 100,
  "skip": 0,
  "limit": 50
}
```

## Filtres et Recherche

Certains endpoints supportent les filtres :

**Query params** :
- `filter`: string (JSON encodé)

**Exemple** :
```
GET /api/travels?filter={"status":"draft","travel_type":"school"}
```

## Tri

**Query params** :
- `sort`: string (nom du champ)
- `order`: string (asc, desc)

**Exemple** :
```
GET /api/travels?sort=created_at&order=desc
```
