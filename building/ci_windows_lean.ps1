# J1b - build "leger" CloudComPy pour CI GitHub Actions (Windows, Conda 3.12)
#
# Differences avec la procedure de reference build.ps1 :
#  - pas de dependances externes non-Conda (cork, FBX SDK, libigl, RDB SDK) :
#    les plugins qui les exigent sont desactives (QFBX, QRDB, QCORK, QMESH_BOOLEAN)
#  - PYTHONAPI_TRACES=1 obligatoire (cf. ci_linux_lean.sh)
#  - BUILD_REFERENCE_DOC=0 : pas de generation de documentation
#  - pas de packaging wheel/7z ni de batterie CTest : pris en charge par le workflow
#  - smoke test d'import a la place des tests complets
#  - INSTALL_PREREQUISITE_LIBRARIES=0 comme build.ps1 (prerequis fournis par l'environnement Conda)
#
# Le script suppose l'environnement Conda deja active (micromamba activate CloudComPy312)
# et le toolkit MSVC charge depuis vcvars64 (via vswhere).

param([string]$PyMinor = "12")

$ErrorActionPreference = "Stop"

$CondaEnvName = "CloudComPy3$PyMinor"
$CondaRoot = $env:CONDA_PREFIX
$Library = Join-Path $CondaRoot "Library"

$ROOT = Split-Path -Parent $PSScriptRoot
$BUILD = Join-Path $ROOT "build-ci"
$INSTALL = Join-Path $ROOT "install-ci"
$CloudCompareVersion = "2.14.beta"

Write-Host "# --- J1b build leger CloudComPy (CI Windows) ---"
Write-Host "sources : $ROOT"
Write-Host "build   : $BUILD"
Write-Host "install : $INSTALL"
Write-Host "conda   : $CondaRoot ($CondaEnvName)"

# --- neutralisation du Qt Conda dans PATH (cf. build.ps1) ---
$env:PATH = ($env:PATH -split ';' | Where-Object { $_ -notmatch 'Library\\bin\\[Qq]t' }) -join ';'
Remove-Item Env:CMAKE_PREFIX_PATH -ErrorAction Ignore

# --- environnement MSVC (vcvars64) ---
$vswhere = Join-Path ${env:ProgramFiles(x86)} "Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vswhere)) { throw "vswhere introuvable : $vswhere" }
$vsPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
$vcvars = Join-Path $vsPath "VC\Auxiliary\Build\vcvars64.bat"
if (-not (Test-Path $vcvars)) { throw "vcvars64.bat introuvable : $vcvars" }
$output = cmd /c "`"$vcvars`" && set"
foreach ($line in $output) {
    if ($line -match "^([^=]*)=(.*)$") {
        $name = $Matches[1]
        $value = $Matches[2].TrimEnd("`r")
        if ($name -match "^(PATH|INCLUDE|LIB|LIBPATH|TMP|TEMP|CMAKE|C|CXX)[^=]*$") {
            Set-Item -Path "env:$name" -Value $value
        }
    }
}
$cl = Get-Command cl.exe -ErrorAction SilentlyContinue
if ($null -eq $cl) {
    Write-Host "PATH : $env:PATH"
    throw "cl.exe introuvable apres chargement de vcvars64"
}
Write-Host "cl.exe : $($cl.Source)"

# --- mise a jour de la liste conda-list (diagnostics cote utilisateur) ---
$condaList = Join-Path $ROOT "building\conda-list_Windows11_conda3$PyMinor"
& micromamba list | Out-File -FilePath $condaList -Encoding utf8

if (Test-Path $BUILD) { Remove-Item -Recurse -Force $BUILD }
if (Test-Path $INSTALL) { Remove-Item -Recurse -Force $INSTALL }
New-Item -ItemType Directory -Force $BUILD | Out-Null

# EXPERIENCE CLASSE C (audit J2a 8.4), TERMINEE le 27/11/2026 : la pre-allocation
# Qt6_DIR a ete retiree (resolution identique via CMAKE_PREFIX_PATH prouvee par les
# runs reference/classe C). LECON DU RUN #65 (LNK2019 x19 dans qDracoIO) :
# DRACO_INCLUDE_DIRS/DRACO_LIBRARIES ne sont PAS redondants (le find_package(Draco)
# du paquet conda resout Draco_DIR mais ne fournit pas DRACO_LIBRARIES) -> classe B
# passee ci-dessous. Cf. audit 8.4 : un *_DIR utilise ne prouve pas que
# l autodetection suffit.

# J2c : le panneau constant des drapeaux est consomme via le preset
# ci-windows-lean (CMakePresets.json, resolution DJ4) ; le script ne passe
# plus que les chemins machine et la classe B (INSTALL_PREREQUISITE_LIBRARIES
# est porte par le preset, cf. D13).

$cmakeArgs = @(
    "-DCLOUDCOMPARE_VERSION=$CloudCompareVersion",
    "-DCONDA_BASE_DIRECTORY=$env:MAMBA_ROOT_PREFIX",
    "-DCONDA_ENV_NAME=$CondaEnvName",
    "-DCONDA_ROOT_DIRECTORY=$CondaRoot",
    "-DCMAKE_PREFIX_PATH=$Library",
    "-DCMAKE_INSTALL_PREFIX=$INSTALL",
    # classe B depuis le run #65 : sans DRACO_LIBRARIES explicite, le plugin
    # qDracoIO compile mais ne lie pas draco.lib (LNK2019). Cf. audit 8.4 :
    # un *_DIR utilise ne prouve pas que l autodetection suffit.
    "-DDRACO_INCLUDE_DIRS=$Library/include",
    "-DDRACO_LIBRARIES=$Library/lib/draco.lib",
    "-DEIGEN_ROOT_DIR=$Library/include/eigen3",
    "-DOPENCASCADE_INC_DIR=$Library/include/opencascade",
    "-DOPENCASCADE_LIB_DIR=$Library/lib",
    "-DOPENCASCADE_DLL_DIR=$Library/bin",
    "-DOPENCASCADE_TBB_DLL_DIR=$Library/bin",
    "-DPYTHON_PREFERED_VERSION=3.$PyMinor",
    # stub neutre a la place du windeployqt Conda (Qt >= 6.9 refuse --openglwidgets/--concurrent)
    "-Dwin_deploy_qt=$ROOT\building\ci_windeployqt_stub.cmd"
)

Write-Host "# --- configuration CMake ---"
& cmake --preset ci-windows-lean @cmakeArgs
if ($LASTEXITCODE -ne 0) { throw "echec de la configuration CMake" }

Write-Host "# --- compilation (ninja) ---"
& cmake --build $BUILD
if ($LASTEXITCODE -ne 0) { throw "echec de la compilation" }

Write-Host "# --- installation ---"
& cmake --install $BUILD
if ($LASTEXITCODE -ne 0) { throw "echec de l'installation" }

Write-Host "# --- smoke test : import cloudComPy ---"
# __init__-Windows.py est concu pour le layout wheel : il exige que les dossier et fichiers
# suivants existent DANS le package cloudComPy (sinon os.add_dll_directory leve FileNotFoundError
# et ctypes.WinDLL echoue) : plugins\, et les 5 dll Qt6Core/Gui/Widgets/OpenGL/OpenGLWidgets.
# En non-BUILD_PYPI, le pyd et les dll restent dans CloudCompare\ : on complete le package
# apres install (copie partielle, pas de windeployqt complet, headless D11 inchange).
$ccDir = Join-Path $INSTALL "CloudCompare"
$pkg = Join-Path $ccDir "cloudComPy"
New-Item -ItemType Directory -Force (Join-Path $pkg "plugins") | Out-Null
$qtDlls = @("Qt6Core", "Qt6Gui", "Qt6Widgets", "Qt6OpenGL", "Qt6OpenGLWidgets")
foreach ($d in $qtDlls) {
    Copy-Item (Join-Path $Library ("bin\" + $d + ".dll")) $pkg -Force
}
# plugins natifs CloudCompare installes dans CloudCompare\plugins : les recopier dans le package
$ccPlugins = Join-Path $ccDir "plugins"
if (Test-Path $ccPlugins) {
    Copy-Item (Join-Path $ccPlugins "*") (Join-Path $pkg "plugins") -Recurse -Force
}
# consolidation du layout (cf. fusion avec le layout wheel) : le CMake legacy
# non-PyPI installe aussi des docs dans $INSTALL\cloudComPy\doc (dossier cloudComPy
# fantome a la racine, sans __init__.py, qui capte l'import cloudComPy et n'importe
# rien si la racine est dans PYTHONPATH) et dans $INSTALL\doc. On fusionne tout dans
# le doc du package, et on supprime les deux dossiers fantomes.
$pkgDoc = Join-Path $pkg "doc"
New-Item -ItemType Directory -Force $pkgDoc | Out-Null
foreach ($docSrc in @((Join-Path $INSTALL "cloudComPy\doc"), (Join-Path $INSTALL "doc"))) {
    if (Test-Path $docSrc) {
        Copy-Item (Join-Path $docSrc "*") $pkgDoc -Recurse -Force
    }
}
Remove-Item (Join-Path $INSTALL "cloudComPy") -Recurse -Force -ErrorAction Ignore
Remove-Item (Join-Path $INSTALL "doc") -Recurse -Force -ErrorAction Ignore

# smoke test instrumente : le run precedent a gelé sans aucune sortie (tué après 3 h).
# - sortie non bufferisée + jalons d'impression pour localiser l'étape bloquante ;
# - chien de garde : au bout de 10 minutes le processus est tué et la sortie partielle
#   est affichée ;
# - QT_QPA_PLATFORM=offscreen pour éviter toute dépendance à un plugin plateforme
#   si un QApplication est créé à l'init.
$env:PYTHONPATH = Join-Path $INSTALL "CloudCompare"
$env:QT_QPA_PLATFORM = "offscreen"
$smoke = Join-Path $BUILD "smoke_test_ci.py"
$smokeOut = Join-Path $BUILD "smoke_test_ci.out"
$smokeErr = Join-Path $BUILD "smoke_test_ci.err"
Set-Content -Path $smoke -Value @(
    "print('etape 1 : import du module natif _cloudComPy', flush=True)",
    "import _cloudComPy as m",
    "print('etape 2 : initCC()', flush=True)",
    "m.initCC()",
    "print('etape 3 : initCloudCompare()', flush=True)",
    "m.initCloudCompare()",
    "print('etape 4 : import du package cloudComPy', flush=True)",
    "import cloudComPy as cc",
    "print('cloudComPy import et init OK:', cc.__file__, flush=True)"
)
Write-Host "# --- smoke test : import cloudComPy (instrumenté, watchdog 10 min) ---"
$proc = Start-Process -FilePath "python" -ArgumentList "-u", "`"$smoke`"" -NoNewWindow -PassThru `
    -RedirectStandardOutput $smokeOut -RedirectStandardError $smokeErr
if (-not $proc.WaitForExit(600000)) {
    try { $proc.Kill() } catch { Stop-Process -Id $proc.Id -Force -ErrorAction Ignore }
    Write-Host "### SMOKE TEST : TIMEOUT (ETAPE BLOQUANTE VOIR CI-DESSOUS) ###"
    Write-Host "--- stdout partiel ---"
    Get-Content $smokeOut -ErrorAction Ignore
    Write-Host "--- stderr partiel ---"
    Get-Content $smokeErr -ErrorAction Ignore
    throw "timeout du smoke test d'import cloudComPy (etape bloquante voir ci-dessus)"
}
Write-Host "--- stdout ---"
Get-Content $smokeOut -ErrorAction Ignore
Write-Host "--- stderr ---"
Get-Content $smokeErr -ErrorAction Ignore
if ($proc.ExitCode -ne 0) { throw "echec du smoke test d'import cloudComPy (code $($proc.ExitCode))" }

Write-Host "# --- J1b Windows : build leger termine avec succes ---"
