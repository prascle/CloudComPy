param(
    [switch]$All,         # Clean + Configure + Build + Install + Package + Tests
    [switch]$FromScratch, # Clean + Configure + Build
    [switch]$BuildOnly,   # Build uniquement
    [switch]$InstallOnly, # Install uniquement
    [switch]$Package,     # Packaging .7z
    [switch]$Tests        # Tests CTest
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

# --- VARIABLES ORIGINALES ---
$CondaBase = "$Home/miniconda3"
$CondaEnvName = "CloudComPy312"
$CondaRoot = "$CondaBase/envs/$CondaEnvName"
$PyMinVersion = "12"
$Qt6root = "C:/Qt/6.10.2/msvc2022_64"
$WorkRoot = "$Home/cloudComPy"
$SourceDir = "$WorkRoot/CloudComPy"
$BuildRoot = "$WorkRoot/build2026"
$InstallRoot = "$WorkRoot/install/$CondaEnvName"
$Configuration = "Release"
$BuildDir = "$BuildRoot/x64-$Configuration"
$corkDir = "$WorkRoot/cork"
$libiglDir = "$WorkRoot/libigl/libigl"
$fbxSdk = "C:/Program Files/Autodesk/FBX/FBX SDK/2020.3.9"
$PythonVenv = "$WorkRoot/venv3${PyMinVersion}doc"
$CloudCompareVersion = "2.14.beta"

# --- FONCTIONS ---

function Invoke-Clean {
    [Console]::Out.Flush()
    Write-Host ""
    Write-Host "🧹 Clean build + install..." -ForegroundColor Cyan
    if (Test-Path $BuildDir) { Remove-Item -Recurse -Force $BuildDir }
    if (Test-Path $InstallRoot) { Remove-Item -Recurse -Force $InstallRoot }
}

function Invoke-PrepareEnvironment {
    [Console]::Out.Flush()
    Write-Host ""
    Clear-Host
    Write-Host "🐍 Conda actif (Qt Conda neutralisé)..." -ForegroundColor Green

    # Nettoyage PATH Qt Conda
    $env:PATH = ($env:PATH -split ';' | Where-Object { $_ -notmatch 'Library\\bin\\Qt' -and $_ -notmatch 'Library\\bin\\qt' }) -join ';'

    # Supprimer CMAKE_PREFIX_PATH venant de Conda
    Remove-Item Env:CMAKE_PREFIX_PATH -ErrorAction Ignore

    # Charger MSVC
    Write-Host "⚙️  MSVC environment..." -ForegroundColor Cyan
    $vcvarsPath = "C:\Program Files\Microsoft Visual Studio\18\Community\VC\Auxiliary\Build\vcvars64.bat"
    $output = cmd /c "`"$vcvarsPath`" && set"

    $output | Select-String '^([^=]*)=(.*)$' | ForEach-Object {
        if ($_.Matches.Groups[1].Value -match '^(PATH|INCLUDE|LIB|LIBPATH|TMP|TEMP|CMAKE|C|CXX)') {
            Set-Item -Path "env:$($_.Matches.Groups[1].Value)" -Value $_.Matches.Groups[2].Value
        }
    }

    Write-Host "✅ cl.exe: $(where.exe cl.exe 2>$null)" -ForegroundColor Green
}

function Invoke-Configure {
    [Console]::Out.Flush()
    Write-Host ""
    Write-Host "🔧 CMake configure..." -ForegroundColor Green
    if (Test-Path $BuildDir) { Remove-Item -Recurse -Force $BuildDir }
    New-Item -ItemType Directory -Force $BuildDir | Out-Null

    $cmakeArgs = @(
        "-S$SourceDir",
        "-B$BuildDir",
        "-G", "Ninja",
        "-DCMAKE_BUILD_TYPE=$Configuration",
        "-DCMAKE_SHARED_LINKER_FLAGS='/machine:x64 /FORCE:MULTIPLE'",
        "-DPYTHON_PREFERED_VERSION=3.$PyMinVersion",
        "-DPYTHON_MIN_VERSION=$PyMinVersion",
        "-DUSE_CONDA_PACKAGES=ON",
        "-DCLOUDCOMPARE_VERSION=$CloudCompareVersion",
        "-DCONDA_BASE_DIRECTORY=$CondaBase",
        "-DCONDA_ENV_NAME=$CondaEnvName",
        "-DCONDA_ROOT_DIRECTORY=$CondaRoot",
        "-DQt6_DIR=$Qt6root/lib/cmake/Qt6",
        "-DCMAKE_PREFIX_PATH=$Qt6root",
        "-DCMAKE_INSTALL_PREFIX=$InstallRoot",
        "-DBUILD_PYPI_PACKAGE=0",
        "-DBUILD_PY_TESTING=1",
        "-DBUILD_REFERENCE_DOC=1",
        "-DBUILD_TESTING=1",
        "-DCCCORELIB_SHARED=1",
        "-DCCCORELIB_USE_CGAL=1",
        "-DCCCORELIB_USE_QT_CONCURRENT=1",
        "-DCCCORELIB_USE_TBB=0",
        "-DCORK_INCLUDE_DIR:PATH=$corkDir/src",
        "-DCORK_RELEASE_LIBRARY_FILE=$corkDir/win/VS2022/x64/Release/wincork2022.lib",
        "-DDRACO_INCLUDE_DIRS=$condaRoot/Library/include",
        "-DDRACO_LIBRARIES=$condaRoot/Library/lib/draco.lib",
        "-DEIGEN_ROOT_DIR=$condaRoot/Library/include/eigen3",
        "-DFBX_SDK_INCLUDE_DIR=$fbxSdk/include",
        "-DFBX_SDK_LIBRARY_FILE=$fbxSdk/lib/x64/release/libfbxsdk-md.lib",
        "-DFBX_XML2_LIBRARY_FILE=$fbxSdk/lib/x64/release/libxml2.lib",
        "-DFBX_ZLIB_LIBRARY_FILE=$fbxSdk/lib/x64/release/zlib.lib",
        "-DINSTALL_PREREQUISITE_LIBRARIES=0",
        "-DLIBIGL_INCLUDE_DIR=$libiglDir/include",
        "-DLIBIGL_RELEASE_LIBRARY_FILE=$libiglDir/out/install/x64-Release/lib/igl.lib",
        "-DMPIR_INCLUDE_DIR=$condaRoot/Library/include",
        "-DMPIR_RELEASE_LIBRARY_FILE=$condaRoot/Library/lib/mpir.lib",
        "-DOPENCASCADE_78_OR_NEWER=1",
        "-DOPENCASCADE_INC_DIR=$condaRoot/Library/include/opencascade",
        "-DOPENCASCADE_LIB_DIR=$condaRoot/Library/lib",
        "-DOPENCASCADE_DLL_DIR=$condaRoot/Library/bin",
        "-DOPENCASCADE_TBB_DLL_DIR=$condaRoot/Library/bin",
        "-DOPTION_BUILD_CCVIEWER=OFF",
        "-DOPTION_USE_GDAL=1",
        "-DPLUGIN_EXAMPLE_GL=1",
        "-DPLUGIN_EXAMPLE_IO=1",
        "-DPLUGIN_EXAMPLE_STANDARD=1",
        "-DPLUGIN_GL_QEDL=1",
        "-DPLUGIN_GL_QSSAO=1",
        "-DPLUGIN_IO_QADDITIONAL=1",
        "-DPLUGIN_IO_QCORE=1",
        "-DPLUGIN_IO_QCSV_MATRIX=1",
        "-DPLUGIN_IO_QDRACO=1",
        "-DPLUGIN_IO_QE57=1",
        "-DPLUGIN_IO_QFBX=1",
        "-DPLUGIN_IO_QLAS=1",
        "-DPLUGIN_IO_QLAS_FWF=0",
        "-DPLUGIN_IO_QPDAL=0",
        "-DPLUGIN_IO_QPHOTOSCAN=1",
        "-DPLUGIN_IO_QRDB=1",
        "-DPLUGIN_IO_QRDB_FETCH_DEPENDENCY=1",
        "-DPLUGIN_IO_QRDB_INSTALL_DEPENDENCY=1",
        "-DPLUGIN_IO_QSTEP=1",
        "-DPLUGIN_PYTHON=OFF",
        "-DPLUGIN_STANDARD_3DMASC=1",
        "-DPLUGIN_STANDARD_MASONRY_QAUTO_SEG=1",
        "-DPLUGIN_STANDARD_MASONRY_QMANUAL_SEG=1",
        "-DPLUGIN_STANDARD_QANIMATION=1",
        "-DPLUGIN_STANDARD_QBROOM=1",
        "-DPLUGIN_STANDARD_QCANUPO=1",
        "-DPLUGIN_STANDARD_QCLOUDLAYERS=1",
        "-DPLUGIN_STANDARD_QCOLORIMETRIC_SEGMENTER=1",
        "-DPLUGIN_STANDARD_QCOMPASS=1",
        "-DPLUGIN_STANDARD_QCORK=1",
        "-DPLUGIN_STANDARD_QCSF=1",
        "-DPLUGIN_STANDARD_QFACETS=1",
        "-DPLUGIN_STANDARD_QHOUGH_NORMALS=1",
        "-DPLUGIN_STANDARD_QHPR=1",
        "-DPLUGIN_STANDARD_QJSONRPC=1",
        "-DPLUGIN_STANDARD_QM3C2=1",
        "-DPLUGIN_STANDARD_QMESH_BOOLEAN=1",
        "-DPLUGIN_STANDARD_QMPLANE=1",
        "-DPLUGIN_STANDARD_QPCL=1",
        "-DPLUGIN_STANDARD_QPCV=1",
        "-DPLUGIN_STANDARD_QPOISSON_RECON=1",
        "-DPLUGIN_STANDARD_QRANSAC_SD=1",
        "-DPLUGIN_STANDARD_QSRA=1",
        "-DPLUGIN_STANDARD_QTREEISO=1",
        "-DPYTHONAPI_TEST_DIRECTORY=CloudComPy/Data",
        "-DPYTHONAPI_EXTDATA_DIRECTORY=CloudComPy/ExternalData",
        "-DPYTHONAPI_TRACES=1",
        "-DPYTHONVENV=$PythonVenv",
        "-DQANIMATION_WITH_FFMPEG_SUPPORT=1",
        "-DUSE_EXTERNAL_QHULL_FOR_QHPR=0",
        "-DWORKROOT=$WorkRoot"
    )

    cmake @cmakeArgs
}

function Invoke-Build {
    [Console]::Out.Flush()
    Write-Host ""
    Write-Host "🚀 Build..." -ForegroundColor Green
    Set-Location $BuildDir
    cmake --build .
    Set-Location $SourceDir
}

function Invoke-Install {
    [Console]::Out.Flush()
    Write-Host ""
    Write-Host "📦 Install..." -ForegroundColor Green
    if (Test-Path $InstallRoot) { Remove-Item -Recurse -Force $InstallRoot }
    Set-Location $BuildDir
    cmake --install .
    Set-Location $SourceDir
}

function Invoke-Package {
    [Console]::Out.Flush()
    Write-Host ""
    Write-Host "📦 Packaging CloudComPy..." -ForegroundColor Cyan

    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $packageName = "CloudComPy_${CondaEnvName}_$timestamp.7z"
    $packagePath = Join-Path "$WorkRoot/install" $packageName

    $sevenZip = "C:\Program Files\7-Zip\7z.exe"
    if (-not (Test-Path $sevenZip)) {
        throw "7z.exe introuvable : $sevenZip"
    }

    & $sevenZip a `
        -t7z -m0=lzma2 -mx=9 -mmt=on -ms=on `
        $packagePath `
        $InstallRoot

    Write-Host "🎉 Package créé : $packagePath" -ForegroundColor Green
}

function Invoke-Tests {
    [Console]::Out.Flush()
    Write-Host ""
    Write-Host "🧪 Lancement des tests PythonAPI..." -ForegroundColor Cyan

    $venvActivate = Join-Path $PythonVenv "Scripts/Activate.ps1"
    & $venvActivate

    Push-Location $InstallRoot
    cmd /c "`"$(Join-Path $InstallRoot 'envCloudComPy.bat')`""

    Push-Location (Join-Path $InstallRoot "doc/PythonAPI_test")
    ctest --output-on-failure

    Pop-Location
    Pop-Location

    Write-Host "🧪 Tests terminés." -ForegroundColor Green
}

# --- LOGIQUE PRINCIPALE ---

Invoke-PrepareEnvironment

if ($All) {
    Invoke-Clean
    Invoke-Configure
    Invoke-Build
    Invoke-Install
    Invoke-Package
    Invoke-Tests
    exit
}

if ($FromScratch) {
    Invoke-Clean
    Invoke-Configure
    Invoke-Build
    exit
}

if ($BuildOnly) {
    Invoke-Build
    exit
}

if ($InstallOnly) {
    Invoke-Install
    exit
}

if ($Package) {
    Invoke-Package
    exit
}

if ($Tests) {
    Invoke-Tests
    exit
}

Write-Host "ℹ️ Aucun switch fourni. Utilise -All, -FromScratch, -BuildOnly, -InstallOnly, -Package ou -Tests"
