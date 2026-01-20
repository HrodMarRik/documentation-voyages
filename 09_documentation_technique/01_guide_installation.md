# Guide d'Installation

## Prérequis Système

### Système d'Exploitation

- **Windows** : Windows 10/11 ou Windows Server 2019+
- **Linux** : Ubuntu 20.04+, Debian 11+, CentOS 8+
- **macOS** : macOS 11+

### Logiciels Requis

- **Python** : 3.9 ou supérieur
- **Node.js** : 18.x ou supérieur
- **MySQL** : 8.0 ou supérieur
- **Git** : Pour cloner les dépôts

## Installation des Dépendances

### 1. Python et Dépendances Backend

```bash
# Vérifier la version Python
python --version  # Doit être 3.9+

# Créer un environnement virtuel
python -m venv venv

# Activer l'environnement virtuel
# Windows:
venv\Scripts\activate
# Linux/macOS:
source venv/bin/activate

# Installer les dépendances
pip install -r requirements.txt
```

**Dépendances principales** :
- FastAPI
- SQLAlchemy
- Alembic
- PyMySQL (driver MySQL)
- PyJWT (authentification)
- pyotp (2FA)
- python-dotenv (variables d'environnement)

### 2. Node.js et Dépendances Frontend

```bash
# Vérifier la version Node.js
node --version  # Doit être 18.x+

# Installer les dépendances
cd frontend
npm install
```

**Dépendances principales** :
- Vue.js 3
- Element Plus
- Vite
- Axios
- Pinia
- Vue Router

### 3. MySQL

#### Installation MySQL

**Windows** :
- Télécharger MySQL Installer depuis https://dev.mysql.com/downloads/installer/
- Installer MySQL Server 8.0+
- Noter le mot de passe root

**Linux (Ubuntu/Debian)** :
```bash
sudo apt update
sudo apt install mysql-server
sudo mysql_secure_installation
```

**macOS** :
```bash
brew install mysql
brew services start mysql
```

#### Configuration MySQL

```sql
-- Se connecter à MySQL
mysql -u root -p

-- Créer la base de données
CREATE DATABASE gestion_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Créer un utilisateur dédié
CREATE USER 'gestion_user'@'localhost' IDENTIFIED BY 'votre_mot_de_passe';
GRANT ALL PRIVILEGES ON gestion_db.* TO 'gestion_user'@'localhost';
FLUSH PRIVILEGES;
```

#### Configuration my.cnf (Optionnel)

Pour optimiser les performances, ajouter dans `/etc/mysql/my.cnf` :

```ini
[mysqld]
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default-storage-engine=InnoDB
innodb_buffer_pool_size=1G
max_connections=200
```

## Configuration de l'Application

### 1. Variables d'Environnement

Créer un fichier `.env` à la racine du projet :

```env
# Base de données MySQL
DATABASE_URL=mysql+pymysql://gestion_user:password@localhost:3306/gestion_db

# Sécurité
SECRET_KEY=votre_secret_key_tres_long_et_aleatoire
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

# 2FA
TOTP_ISSUER=Gestion App

# CORS
CORS_ORIGINS=http://localhost:5173,http://localhost:3000

# Email (SMTP)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=votre_email@gmail.com
SMTP_PASSWORD=votre_mot_de_passe_app
SMTP_FROM_EMAIL=noreply@gestion-app.com

# Odoo
ODOO_URL=https://votre-instance.odoo.com
ODOO_DB=votre_base
ODOO_USERNAME=votre_utilisateur
ODOO_API_KEY=votre_cle_api

# Stripe (pour voyages linguistiques)
STRIPE_PUBLIC_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...

# Application
APP_NAME=Gestion de Voyages
APP_ENV=development
DEBUG=True

# Company (pour factures)
COMPANY_NAME=Votre Entreprise
COMPANY_VAT=FR00000000000
COMPANY_ADDRESS=1 rue Exemple, 75000 Paris, France
```

### 2. Génération de la Clé Secrète

```python
# Générer une clé secrète
import secrets
print(secrets.token_urlsafe(32))
```

Copier le résultat dans `SECRET_KEY` du fichier `.env`.

### 3. Initialisation de la Base de Données

```bash
# Activer l'environnement virtuel
source venv/bin/activate  # Linux/macOS
# ou
venv\Scripts\activate  # Windows

# Exécuter les migrations Alembic
alembic upgrade head

# Initialiser les données de base (rôles, permissions)
python scripts/init_db.py
```

## Installation des Modules Odoo

Les modules Odoo standards (CRM, Facturation, Contacts) sont utilisés pour la synchronisation.

## Démarrage de l'Application

### Backend

```bash
# Activer l'environnement virtuel
source venv/bin/activate

# Démarrer le serveur de développement
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000

# Ou avec Gunicorn (production)
gunicorn app.main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

Le backend sera accessible sur : http://localhost:8000

### Frontend

```bash
cd frontend

# Démarrer le serveur de développement
npm run dev

# Ou build pour production
npm run build
npm run preview
```

Le frontend sera accessible sur : http://localhost:5173

## Vérification de l'Installation

### 1. Vérifier le Backend

```bash
# Test de santé
curl http://localhost:8000/health

# Devrait retourner: {"status":"ok"}
```

### 2. Vérifier la Base de Données

```bash
# Se connecter à MySQL
mysql -u gestion_user -p gestion_db

# Vérifier les tables
SHOW TABLES;

# Devrait afficher toutes les tables créées
```

### 3. Vérifier le Frontend

Ouvrir http://localhost:5173 dans un navigateur. La page de login devrait s'afficher.

## Scripts d'Installation Automatisés

### Script Windows (install.ps1)

```powershell
# Créer environnement virtuel
python -m venv venv
venv\Scripts\activate

# Installer dépendances
pip install -r requirements.txt

# Créer .env depuis .env.example
Copy-Item .env.example .env
# Éditer .env avec vos valeurs

# Initialiser base de données
alembic upgrade head
python scripts/init_db.py
```

### Script Linux/macOS (install.sh)

```bash
#!/bin/bash

# Créer environnement virtuel
python3 -m venv venv
source venv/bin/activate

# Installer dépendances
pip install -r requirements.txt

# Créer .env depuis .env.example
cp .env.example .env
# Éditer .env avec vos valeurs

# Initialiser base de données
alembic upgrade head
python scripts/init_db.py
```

## Problèmes Courants

### Erreur de Connexion MySQL

- Vérifier que MySQL est démarré : `sudo systemctl status mysql`
- Vérifier les identifiants dans `DATABASE_URL`
- Vérifier que l'utilisateur a les permissions : `GRANT ALL PRIVILEGES ON gestion_db.* TO 'gestion_user'@'localhost';`

### Erreur PyMySQL

```bash
pip install PyMySQL
```

### Erreur CORS

Vérifier que `CORS_ORIGINS` dans `.env` contient l'URL du frontend.

### Port déjà utilisé

Changer le port dans la commande de démarrage :
```bash
uvicorn app.main:app --reload --port 8001
```

## Prochaines Étapes

1. **Configuration Odoo** : Voir [Guide Intégration Odoo](../10_documentation_integrations/01_integration_odoo.md)
2. **Configuration Stripe** : Voir [Guide Intégration Stripe](../10_documentation_integrations/02_integration_stripe.md)
3. **Premier Utilisateur** : Créer un utilisateur admin via l'API ou directement en base

---

**Version** : 1.0  
**Date** : 2025-01-20
