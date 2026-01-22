# Processus BPMN - Voyage Scolaire

## Vue d'Ensemble

Ce diagramme BPMN représente le processus complet de gestion d'un voyage scolaire, depuis la demande initiale du professeur jusqu'à la facturation finale.

## Diagramme Mermaid (Simplifié)

```mermaid
flowchart TD
 Start([Début]) --> FillForm[Professeur remplit formulaire]
 FillForm --> CreateTravel[Système crée Travel DRAFT]
 CreateTravel --> NotifyCommercial[Notification commercial]
 
 NotifyCommercial --> GeneratePlanning[Commercial génère planning]
 GeneratePlanning --> ValidatePlanning{Planning validé?}
 ValidatePlanning -->|Non| ModifyPlanning[Modifier planning]
 ModifyPlanning --> ValidatePlanning
 ValidatePlanning -->|Oui| EnterTransport[Saisir prix transport]
 
 EnterTransport --> GenerateQuote[Générer devis]
 GenerateQuote --> SendQuote[Envoyer devis]
 SendQuote --> WaitResponse[Attendre réponse professeur]
 
 WaitResponse --> Decision{Devis accepté?}
 Decision -->|Non| Cancel[Annuler voyage]
 Decision -->|Oui| ValidateQuote[Valider devis]
 
 ValidateQuote --> CollectContacts[Collecter contacts parents]
 CollectContacts --> ValidateDossier[Valider dossier]
 ValidateDossier --> GenerateInvoice[Générer facture]
 GenerateInvoice --> ValidateInvoice[Valider facture]
 ValidateInvoice --> SyncOdoo[Synchroniser Odoo]
 SyncOdoo --> End([Fin])
 
 Cancel --> End
```

## Étapes du Processus

1. **Soumission** : Le professeur remplit le formulaire public
2. **Création** : Le système crée automatiquement le voyage en statut DRAFT
3. **Traitement** : Le commercial génère le planning et saisit les prix
4. **Devis** : Génération et envoi du devis au professeur
5. **Validation** : Acceptation du devis par le professeur
6. **Finalisation** : Collecte des contacts, validation du dossier
7. **Facturation** : Génération et validation de la facture
8. **Synchronisation** : Export vers Odoo

## Acteurs

- **Professeur** : Initie le processus
- **Système** : Automatise certaines étapes
- **Commercial** : Traite la demande
- **Comptable** : Valide la facture (optionnel)

---

**Note** : Un diagramme BPMN complet au format XML sera créé avec un outil dédié (Camunda Modeler, bpmn.io).
