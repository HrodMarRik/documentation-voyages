# Diagramme de Classes - Quotes & Invoices

```mermaid
classDiagram
    class Quote {
        +Integer id
        +Integer travel_id
        +String quote_number
        +String status
        +Float total_amount
        +DateTime created_at
        +DateTime updated_at
        +DateTime sent_at
        +DateTime validated_at
    }
    
    class QuoteLine {
        +Integer id
        +Integer quote_id
        +String description
        +Integer quantity
        +Float unit_price
        +Float line_total
        +String line_type
    }
    
    class Invoice {
        +Integer id
        +Integer travel_id
        +String invoice_number
        +String status
        +Float total_amount
        +Float tax_amount
        +JSON e_invoice_data
        +DateTime created_at
        +DateTime validated_at
        +Integer validated_by_user_id
    }
    
    class InvoiceLine {
        +Integer id
        +Integer invoice_id
        +String description
        +Integer quantity
        +Float unit_price
        +Float line_total
        +Float tax_rate
    }
    
    Quote "1" *-- "*" QuoteLine
    Invoice "1" *-- "*" InvoiceLine
    Quote "1" ..> "0..1" Invoice : generates
```

## Notes

**Quote Status** : draft, sent, validated, rejected

**Invoice Status** : draft, validated, paid, cancelled  
**e_invoice_data** : Factur-X XML  
**Lien** : Invoice est liée à Travel uniquement

---

**Version** : 1.0  
**Date** : 2025-01-20
