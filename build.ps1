# build.ps1 - PowerShell 7 + MSVC + Conda CloudComPyxxx
#param([switch]$Clean)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

$CondaBase = "$Home/miniconda3"
$CondaEnvName = "CloudComPy312b"
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
$PythonVenv = "$WorkRoot/venv3$PyMinVersion"

Clear-Host
Write-Host "🐍 Conda actif ✅" -ForegroundColor Green

# 🔥 AJOUT 1 : Nettoyage du PATH pour éliminer Qt Conda
# (Conda reste actif, mais Qt Conda est neutralisé)
$env:PATH = ($env:PATH -split ';' | Where-Object { $_ -notmatch 'Library\\bin\\Qt' -and $_ -notmatch 'Library\\bin\\qt' }) -join ';'

# 🔥 AJOUT 2 : Supprimer CMAKE_PREFIX_PATH venant de Conda
Remove-Item Env:CMAKE_PREFIX_PATH -ErrorAction Ignore

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

# 2. Clean + CMake

Write-Host "✅ cl.exe: $(where.exe cl.exe 2>$null)" -ForegroundColor Green
if (Test-Path $BuildDir) { Remove-Item -Recurse -Force $BuildDir }
New-Item -ItemType Directory -Force $BuildDir | Out-Null


Write-Host "🔧 CMake..." -ForegroundColor Green

$cmakeArgs = @(
    "-S$SourceDir",
    "-B$BuildDir",
    "-G", "Ninja",
    "-DCMAKE_BUILD_TYPE=$Configuration",
    "-DCMAKE_SHARED_LINKER_FLAGS='/machine:x64 /FORCE:MULTIPLE'",
    "-DPYTHON_PREFERED_VERSION=3.$PyMinVersion",
    "-DPYTHON_MIN_VERSION=$PyMinVersion",
    "-DUSE_CONDA_PACKAGES=ON",
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
    "-DINSTALL_PREREQUISITE_LIBRARIES=0",
    "-DLIBIGL_INCLUDE_DIR=$libiglDir/include",
    "-DLIBIGL_RELEASE_LIBRARY_FILE=$libiglDir/out/install/x64-Release/lib/igl.lib",
    "-DMPIR_INCLUDE_DIR=$condaRoot/Library/include",
    "-DMPIR_RELEASE_LIBRARY_FILE=$condaRoot/Library/lib/mpir.lib",
    "-DOPENCASCADE_78_OR_NEWER=1",
    "-DOPTION_BUILD_CCVIEWER=OFF"
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
    "-DPLUGIN_IO_QFBX=0",
    "-DPLUGIN_IO_QLAS=1",
    "-DPLUGIN_IO_QLAS_FWF=0",
    "-DPLUGIN_IO_QPDAL=0",
    "-DPLUGIN_IO_QPHOTOSCAN=1",
    "-DPLUGIN_IO_QRDB=1",
    "-DPLUGIN_IO_QRDB_FETCH_DEPENDENCY=1",
    "-DPLUGIN_IO_QRDB_INSTALL_DEPENDENCY=1",
    "-DPLUGIN_IO_QSTEP=0",
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

Write-Host "🚀 Build..." -ForegroundColor Green
Set-Location $BuildDir
cmake --build . 
Write-Host "📦 Install..." -ForegroundColor Green
if (Test-Path $InstallRoot) {
    Remove-Item $InstallRoot -Recurse -Force
}
cmake --install . 


Write-Host "✅ TERMINÉ ! $BuildDir" -ForegroundColor Green
Set-Location $SourceDir