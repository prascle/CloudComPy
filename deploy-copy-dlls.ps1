param(
    [Parameter(Mandatory)][string]$SourceDir,
    [Parameter(Mandatory)][string]$DestinationDir
)

# Créer destination si inexistant
New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null

# 1. LISTER TOUS les DLL **AVANT** copie (exclut déjà destination vide)
$dlls = Get-ChildItem -Path $SourceDir -Recurse -File -Filter '*.dll'

Write-Host "Trouvé $($dlls.Count) DLL à copier"

# 2. ENSUITE copier la liste
$dlls | Copy-Item -Destination $DestinationDir -Force

Write-Host "Copié : $( (Get-ChildItem $DestinationDir -Filter '*.dll').Count ) DLL dans $DestinationDir"
