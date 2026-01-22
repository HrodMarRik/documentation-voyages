# Diagramme de Classes - Domaine Calculs de Prix

## Vue d'Ensemble

Ce diagramme présente les classes et fonctions SQL du domaine des calculs de prix.

## Diagramme de Classes

![Diagram](images/02_class_diagram_pricing_mermaid_01.png)

## Relations et Dépendances

### Hiérarchie des Fonctions

![Diagram](images/02_class_diagram_pricing_mermaid_02.png)

## Utilisation dans les Services

```python
class PricingService:
    def calculate_price(self, travel_id: int) -> Decimal:
        # Appel direct à la fonction SQL
        return db.execute(
            text("SELECT calculate_final_travel_price(:travel_id)"),
            {"travel_id": travel_id}
        ).scalar()
