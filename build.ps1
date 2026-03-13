# build.ps1 - PowerShell 7 + MSVC + Conda CloudComPyxxx

$CondaBase = "$Home/miniconda3"
$CondaRoot = "$CondaBase/envs/CloudComPy313"
$SourceDir = "$Home/cloudComPy/CloudComPy"
$BuildRoot = "$Home/CloudComPy/build2026"
$InstallRoot = "$Home/CloudComPy/install/CloudComPy313"
$Configuration = "RelWithDebInfo"
$BuildDir = "$BuildRoot/x64-$Configuration"

Write-Host "🐍 Conda actif ✅" -ForegroundColor Green

# 1. CAPTURE MSVC ENV VARS (solution Perplexity)
#    cmd /c "vcvars64.bat && set" → capture TOUTES les variables MSVC
#    Select-String + ForEach → parse et applique dans PowerShell 7
#    Filtre PATH|INCLUDE|LIB|... → seules les variables C++ importantes
#    where.exe cl.exe → vérification visuelle

Write-Host "⚙️  MSVC environment..." -ForegroundColor Cyan
$vcvarsPath = "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
$output = cmd /c "`"$vcvarsPath`" && set"

$output | Select-String '^([^=]*)=(.*)$' | ForEach-Object {
    if ($_.Matches.Groups[1].Value -match '^(PATH|INCLUDE|LIB|LIBPATH|TMP|TEMP|CMAKE|C|CXX)') {
        Set-Item -Path "env:$($_.Matches.Groups[1].Value)" -Value $_.Matches.Groups[2].Value
    }
}

Write-Host "✅ cl.exe: $(where.exe cl.exe 2>$null)" -ForegroundColor Green

# 2. Clean + CMake
if (Test-Path $BuildDir) { Remove-Item -Recurse -Force $BuildDir }
New-Item -ItemType Directory -Force $BuildDir | Out-Null
Set-Location $BuildDir

Write-Host "🔧 CMake..." -ForegroundColor Green
cmake -G "Ninja" `
    -DCMAKE_BUILD_TYPE="$Configuration" `
    -DUSE_CONDA_PACKAGES=ON `
    -DCONDA_ROOT_DIRECTORY="$CondaRoot" `
    -DQt6_DIR="$CondaRoot\Library\lib\cmake\Qt6" `
    -DCMAKE_PREFIX_PATH="$CondaRoot\Library" `
	-DCMAKE_INSTALL_PREFIX="$InstallRoot" `
	-DPYTHON_PREFERED_VERSION="3.13" `
    "$SourceDir"

Write-Host "🚀 Build..." -ForegroundColor Green
cmake --build . --config "$Configuration" -v
Write-Host "📦 Install..." -ForegroundColor Green
cmake --install . --config "$Configuration"

Write-Host "✅ TERMINÉ ! $BuildDir" -ForegroundColor Green
