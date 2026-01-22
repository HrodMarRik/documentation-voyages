# Fichiers PlantUML - Diagrammes UML

## Structure

Tous les diagrammes UML ont été convertis en fichiers `.puml` séparés dans ce répertoire.

## Organisation

Les fichiers sont organisés par type de diagramme :

- **01_use_case_***.puml** : Diagrammes de cas d'utilisation
- **02_class_diagram_***.puml** : Diagrammes de classes
- **03_sequence_***.puml** : Diagrammes de séquence
- **04_activity_***.puml** : Diagrammes d'activité
- **05_state_***.puml** : Diagrammes d'état
- **06_class_***.puml** : Diagrammes de classes avec fonctions SQL

## Utilisation

Les fichiers markdown dans le répertoire parent référencent ces fichiers `.puml` via :

```markdown
![Diagram](plantuml/nom_du_fichier.puml)

```plantuml
!include plantuml/nom_du_fichier.puml
```
```

## Génération d'Images

### Prérequis
- Java installé (vérifier avec `java -version`)
- Graphviz installé (pour certains diagrammes, vérifier avec `dot -V`)
- `plantuml.jar` dans le répertoire parent (téléchargé automatiquement si absent)

### Méthode 1 : Script PowerShell (Recommandé)

```powershell
# Depuis le répertoire documentation/02_diagrammes_uml/
.\generate_images.ps1
```

### Méthode 2 : Commande manuelle

```powershell
# Depuis le répertoire documentation/02_diagrammes_uml/
java -jar plantuml.jar -tpng -o images plantuml/*.puml
```

Les images seront générées dans le répertoire `images/` du répertoire parent.

### Méthode 3 : Avec Docker

```bash
docker run --rm -v $(pwd):/work plantuml/plantuml plantuml/*.puml
```

## Notes

- Les fichiers `*_mermaid_*.puml` ont été convertis automatiquement depuis Mermaid et peuvent nécessiter des ajustements manuels
- Les fichiers sans le préfixe `mermaid` sont des fichiers PlantUML natifs
