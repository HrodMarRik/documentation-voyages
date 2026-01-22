# Script PowerShell pour générer les images PlantUML
# Usage: .\generate_images.ps1

Write-Host "Génération des images PlantUML..." -ForegroundColor Green

# Vérifier que plantuml.jar existe
if (-not (Test-Path "plantuml.jar")) {
    Write-Host "ERREUR: plantuml.jar introuvable!" -ForegroundColor Red
    Write-Host "Téléchargement de PlantUML..." -ForegroundColor Yellow
    Invoke-WebRequest -Uri "https://github.com/plantuml/plantuml/releases/download/v1.2026.1/plantuml-1.2026.1.jar" -OutFile "plantuml.jar"
}

# Créer le répertoire images s'il n'existe pas
if (-not (Test-Path "images")) {
    New-Item -ItemType Directory -Path "images" | Out-Null
}

# Générer les images
Write-Host "Génération des images depuis plantuml/*.puml..." -ForegroundColor Cyan
java -jar plantuml.jar -tpng -o images plantuml/*.puml

# Compter les images générées
$imageCount = (Get-ChildItem images -Filter "*.png").Count
Write-Host "`n$imageCount image(s) générée(s) dans le répertoire images/" -ForegroundColor Green

# Mettre à jour les références dans les fichiers markdown
Write-Host "`nMise à jour des références dans les fichiers markdown..." -ForegroundColor Cyan
$mdFiles = Get-ChildItem -Filter "*.md" | Where-Object { $_.Name -ne "README.md" -and $_.FullName -notlike "*plantuml*" }
$updatedCount = 0
foreach ($mdFile in $mdFiles) {
    $content = Get-Content $mdFile.FullName -Raw -Encoding UTF8
    $originalContent = $content
    
    # Remplacer ![texte](plantuml/xxx.puml) par ![texte](images/xxx.png)
    $content = $content -replace '!\[([^\]]+)\]\(plantuml/([^)]+\.puml)\)', '![$1](images/$2)'
    $content = $content -replace '\.puml\)', '.png)'
    
    if ($content -ne $originalContent) {
        Set-Content -Path $mdFile.FullName -Value $content -Encoding UTF8 -NoNewline
        $updatedCount++
    }
}

if ($updatedCount -gt 0) {
    Write-Host "$updatedCount fichier(s) markdown mis à jour" -ForegroundColor Green
}
