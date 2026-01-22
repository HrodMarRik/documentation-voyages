# Guide d'Intégration Stripe

## Vue d'Ensemble

L'intégration Stripe permet de gérer les paiements en ligne pour les voyages linguistiques. Stripe gère la sécurité des paiements et la conformité PCI-DSS.

## Configuration

### 1. Créer un Compte Stripe

1. Aller sur https://stripe.com
2. Créer un compte
3. Compléter les informations de l'entreprise
4. Activer le compte

### 2. Récupérer les Clés API

#### Mode Test

1. Aller dans **Developers** → **API keys**
2. Copier la **Publishable key** (commence par `pk_test_`)
3. Copier la **Secret key** (commence par `sk_test_`)

#### Mode Production

1. Basculer en mode **Live**
2. Copier les clés de production (commence par `pk_live_` et `sk_live_`)

### 3. Configuration dans l'Application

Ajouter dans le fichier `.env` :

```env
# Stripe - Mode Test
STRIPE_PUBLIC_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...

# Stripe - Mode Production (remplacer en production)
# STRIPE_PUBLIC_KEY=pk_live_...
# STRIPE_SECRET_KEY=sk_live_...
```

### 4. Installer le SDK Stripe

```bash
pip install stripe
```

## Utilisation

### Créer un PaymentIntent

```python
import stripe
from app.config import settings

stripe.api_key = settings.STRIPE_SECRET_KEY

def create_payment_intent(amount: float, currency: str = "eur"):
    intent = stripe.PaymentIntent.create(
        amount=int(amount * 100),  # Stripe utilise les centimes
        currency=currency,
        metadata={
            "booking_id": booking_id,
            "travel_id": travel_id
        }
    )
    return intent.client_secret
```

### Webhooks Stripe

#### Configuration

1. Aller dans **Developers** → **Webhooks**
2. Cliquer sur **Add endpoint**
3. URL : `https://votre-domaine.com/api/webhooks/stripe`
4. Événements à écouter :
   - `payment_intent.succeeded`
   - `payment_intent.payment_failed`

#### Endpoint Webhook

```python
from fastapi import APIRouter, Request
import stripe

router = APIRouter()

@router.post("/webhooks/stripe")
async def stripe_webhook(request: Request):
    payload = await request.body()
    sig_header = request.headers.get("stripe-signature")
    
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        return {"error": "Invalid payload"}, 400
    except stripe.error.SignatureVerificationError:
        return {"error": "Invalid signature"}, 400
    
    # Traiter l'événement
    if event["type"] == "payment_intent.succeeded":
        payment_intent = event["data"]["object"]
        # Mettre à jour la réservation
        update_booking_status(payment_intent["metadata"]["booking_id"])
    
    return {"status": "success"}
```

## Gestion des Paiements

### Paiement Réussi

Lorsqu'un paiement réussit :
1. Webhook `payment_intent.succeeded` reçu
2. Mise à jour du `Booking` :
   - `status` → `CONFIRMED`
   - `payment_status` → `PAID`
   - `payment_id` → ID Stripe
3. Envoi d'un email de confirmation
4. Synchronisation avec Odoo (création contact)

### Paiement Échoué

Lorsqu'un paiement échoue :
1. Webhook `payment_intent.payment_failed` reçu
2. Mise à jour du `Booking` :
   - `payment_status` → `FAILED`
3. Envoi d'un email d'échec
4. Timeout de 24h : Si le paiement n'est pas effectué dans les 24h, la réservation est annulée

### Remboursements

```python
def refund_payment(payment_intent_id: str, amount: float = None):
    if amount:
        refund = stripe.Refund.create(
            payment_intent=payment_intent_id,
            amount=int(amount * 100)
        )
    else:
        refund = stripe.Refund.create(
            payment_intent=payment_intent_id
        )
    
    # Mettre à jour la réservation
    update_booking_payment_status(booking_id, "REFUNDED")
    return refund
```

## Tests

### Mode Test

Utiliser les cartes de test Stripe :

- **Carte valide** : `4242 4242 4242 4242`
- **Carte refusée** : `4000 0000 0000 0002`
- **3D Secure** : `4000 0025 0000 3155`

**Date d'expiration** : N'importe quelle date future  
**CVC** : N'importe quel code à 3 chiffres

### Webhooks Locaux

Pour tester les webhooks en local, utiliser Stripe CLI :

```bash
# Installer Stripe CLI
# https://stripe.com/docs/stripe-cli

# Forwarder les webhooks vers l'application locale
stripe listen --forward-to localhost:8000/api/webhooks/stripe

# Déclencher un événement de test
stripe trigger payment_intent.succeeded
```

## Sécurité

### Validation des Webhooks

Toujours valider la signature des webhooks :

```python
event = stripe.Webhook.construct_event(
    payload, sig_header, webhook_secret
)
```

### Ne Jamais Exposer la Secret Key

- La secret key ne doit jamais être dans le code client
- Utiliser uniquement la public key côté frontend
- Stocker la secret key dans les variables d'environnement

## Coûts

### Frais Stripe

- **Transaction réussie** : 1.4% + 0.25€
- **Transaction échouée** : Gratuit
- **Remboursement** : Frais remboursés si remboursement complet

### Exemple

Pour une transaction de 100€ :
- Frais : 1.4% × 100€ + 0.25€ = 1.65€
- Montant reçu : 98.35€

## Monitoring

### Dashboard Stripe

Le dashboard Stripe permet de :
- Voir toutes les transactions
- Analyser les taux de réussite
- Gérer les remboursements
- Configurer les webhooks

### Logs

Toutes les interactions avec Stripe sont loggées :
- Création de PaymentIntent
- Webhooks reçus
- Erreurs
