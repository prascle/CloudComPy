#!/bin/zsh
##########################################################################
#                                                                        #
#                              CloudComPy                                #
#                                                                        #
#  This program is free software; you can redistribute it and/or modify  #
#  it under the terms of the GNU General Public License as published by  #
#  the Free Software Foundation, either version 3 of the License, or     #
#  any later version.                                                    #
#                                                                        #
#  This program is distributed in the hope that it will be useful,       #
#  but WITHOUT ANY WARRANTY; without even the implied warranty of        #
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the          #
#  GNU General Public License for more details.                          #
#                                                                        #
#  You should have received a copy of the GNU General Public License     #
#  along with this program. If not, see <https://www.gnu.org/licenses/>. #
#                                                                        #
#          Copyright 2020-2026 Paul RASCLE www.openfields.fr             #
#                                                                        #
##########################################################################

# J1b-mac - build "leger" CloudComPy pour CI GitHub Actions (macOS arm64, Conda 3.12)
# D9 : chaine wheel BUILD_PYPI=1 inspiree de genCloudComPy_Conda3xx_macos.zsh,
#      SANS signature ni notarisation (hors perimetre CI).
#
# Differences avec la procedure de reference genCloudComPy_Conda3xx_macos.zsh :
#  - pas de dependances externes non-Conda (cork, FBX SDK, libigl, RDB SDK) :
#    les plugins qui les exigent sont desactives (QCORK, QFBX, QMESH_BOOLEAN, QRDB)
#  - BUILD_REFERENCE_DOC=0 : pas de generation de documentation
#  - pas de signature/notarisation du wheel (pas de certificat en CI)
#  - smoke test d'import (wheel installe dans un venv vierge) a la place des tests
#  - l'install va dans ../installConda/CloudComPy_PyPI, comme l'attend MacOS/pyproject.toml
#
# Le script suppose l'environnement Conda deja active (micromamba activate CloudComPy312).

set -e
trap 'echo "### script echoue ligne ${LINENO} (rc=${?})"
# (trap ERR : rend non muet tout exit implicite sous set -e)' ERR

PYMINOR="12"
CLOUDCOMPARE_VERSION="2.14.beta"
CLOUDCOMPY_VERSION="2.13.90"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${ROOT}/build-ci"
INSTDIR="${ROOT}/../installConda"
INSTALL="${INSTDIR}/CloudComPy_PyPI"
CONDA_PATH="${CONDA_PREFIX:?CONDA_PREFIX non defini : activer l'environnement Conda}"

echo "# --- J1b build leger CloudComPy (CI macOS) ---"
echo "sources : ${ROOT}"
echo "build   : ${BUILD}"
echo "install : ${INSTALL}"
echo "conda   : ${CONDA_PATH}"

# maj de la liste conda-list depuis l'environnement reellement utilise au build,
# pour les diagnostics cote utilisateur (comportement de la procedure de production)
micromamba list > "${ROOT}/building/conda-list_macOS_3${PYMINOR}"

rm -rf "${BUILD}" "${INSTALL}"
mkdir -p "${BUILD}"

echo "# --- configuration CMake ---"
# INSTALL_PREREQUISITE_LIBRARIES=0 (D13 etendue au mac) : sinon copy_files
# du sous-module installe des copies Conda (libomp, etc.) dans Frameworks,
# coexistant avec la copie delocatee dans .dylibs -> deux runtimes OpenMP
# dans le process (OMP Error #15). Delocate fournit l'unique copie.
# EXPERIENCE CLASSE C (audit J2a 8.4) - EXPERIMENT TEMPORAIRE, A RETIRER AVANT LA PR :
# CLASS_C=1 retire la pre-allocation classe A (variables resolvables par
# find_package via CMAKE_PREFIX_PATH, y compris les *_DIR config-mode) pour
# comparer les chemins resolus au build de reference (mode par defaut). Les
# variables classe B (EIGEN_ROOT_DIR custom, OPENCASCADE_INC/LIB_DIR, FFMPEG_*,
# TBB_DIR, CONDA_PATH, PYTHONVENV_DIR, REPO_DIR, DRACO_LIBRARIES) restent
# toujours passees. LECON DES RUNS #65 (windows) ET DU RUN macOS CLASSE C
# (27/11, echec de lien qDracoIO) : le find_package(Draco) du paquet conda
# resout Draco_DIR mais ne fournit pas DRACO_LIBRARIES exploitable ->
# pre-allocation a garder sur windows et macos (le run Linux classe C est
# vert avec DRACO retire). Cf. audit 8.4 : un *_DIR utilise ne prouve pas
# que l autodetection suffit.
CLASS_C_D=()
if [ "${CLASS_C:-0}" = "1" ]; then
    echo "# --- classe C : pre-allocation classe A retiree, CMAKE_PREFIX_PATH explicite ---"
    CLASS_C_D+=(-DCMAKE_PREFIX_PATH:PATH="${CONDA_PATH}")
else
    CLASS_C_D=(
        -DCGAL_DIR:PATH="${CONDA_PATH}/lib/cmake/CGAL"
        -DGDAL_INCLUDE_DIR:PATH="${CONDA_PATH}/include"
        -DGDAL_LIBRARY:FILEPATH="${CONDA_PATH}/lib/libgdal.dylib"
        -DGMPXX_INCLUDE_DIR:PATH="${CONDA_PATH}/include"
        -DGMPXX_LIBRARIES:FILEPATH="${CONDA_PATH}/lib/libgmp.dylib"
        -DGMP_INCLUDE_DIR:PATH="${CONDA_PATH}/include"
        -DGMP_LIBRARY_DEBUG:FILEPATH="${CONDA_PATH}/lib/libgmp.dylib"
        -DGMP_LIBRARY_RELEASE:FILEPATH="${CONDA_PATH}/lib/libgmp.dylib"
        -DLASZIP_INCLUDE_DIR:PATH="${CONDA_PATH}/include"
        -DLASZIP_LIBRARY:FILEPATH="${CONDA_PATH}/lib/liblaszip.dylib"
        -DMPFR_INCLUDE_DIR:PATH="${CONDA_PATH}/include"
        -DMPFR_LIBRARIES:FILEPATH="${CONDA_PATH}/lib/libmpfr.dylib"
        -DOpenCV_DIR:PATH="${CONDA_PATH}/lib/cmake/opencv4"
        -DPCL_DIR:PATH="${CONDA_PATH}/share/pcl-1.15"
        -DPNG_INCLUDE_DIR:PATH="${CONDA_PATH}/include/libpng16"
        -DPNG_LIBRARIES:FILEPATH="${CONDA_PATH}/lib/libpng16.dylib"
        -DQhull_DIR:PATH="${CONDA_PATH}/lib/cmake/Qhull"
        -Dpybind11_DIR:PATH="${CONDA_PATH}/share/cmake/pybind11"
        -DXercesC_INCLUDE_DIR:PATH="${CONDA_PATH}/include"
        -DXercesC_LIBRARY_DEBUG:FILEPATH="${CONDA_PATH}/lib/libxerces-c.dylib"
        -DXercesC_LIBRARY_RELEASE:FILEPATH="${CONDA_PATH}/lib/libxerces-c.dylib"
        -DZLIB_INCLUDE_DIR:PATH="${CONDA_PATH}/include"
        -DZLIB_LIBRARY_RELEASE:FILEPATH="${CONDA_PATH}/lib/libz.1.dylib"
    )
fi

cmake \
    -S"${ROOT}" \
    -B"${BUILD}" \
    -G"Unix Makefiles" \
    "${CLASS_C_D[@]}" \
    -DBUILD_PYPI="1" \
    -DBUILD_PY_TESTING:BOOL="1" \
    -DBUILD_REFERENCE_DOC:BOOL="0" \
    -DBUILD_TESTING:BOOL="1" \
    -DCCCORELIB_SHARED:BOOL="1" \
    -DCCCORELIB_USE_CGAL:BOOL="1" \
    -DCCCORELIB_USE_QT_CONCURRENT:BOOL="1" \
    -DCCCORELIB_USE_TBB:BOOL="0" \
    -DCLOUDCOMPARE_VERSION:STRING="${CLOUDCOMPARE_VERSION}" \
    -DCLOUDCOMPY_VERSION:STRING="${CLOUDCOMPY_VERSION}" \
    -DCMAKE_BUILD_TYPE:STRING="Release" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="13.0" \
    -DCMAKE_INSTALL_PREFIX:PATH="${INSTALL}" \
    -DCMAKE_INSTALL_RPATH="@loader_path;@loader_path/../Frameworks;@loader_path/../../Frameworks;${CONDA_PATH}/lib" \
    -DCMAKE_MACOSX_RPATH=ON \
    -DINSTALL_PREREQUISITE_LIBRARIES="0" \
    -DCONDA_PATH:PATH="${CONDA_PATH}" \
    -DDRACO_LIBRARIES:PATH="${CONDA_PATH}/lib/libdraco.a" \
    -DEIGEN_ROOT_DIR:PATH="${CONDA_PATH}/include/eigen3" \
    -DFFMPEG_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DFFMPEG_LIBRARY_DIR:FILEPATH="${CONDA_PATH}/lib" \
    -DFFMPEG_X264_LIBRARY_DIR:FILEPATH="${CONDA_PATH}/lib" \
    -DOPENCASCADE_78_OR_NEWER:BOOL="1" \
    -DOPENCASCADE_INC_DIR:PATH="${CONDA_PATH}/include/opencascade" \
    -DOPENCASCADE_LIB_DIR:PATH="${CONDA_PATH}/lib" \
    -DOPTION_BUILD_CCVIEWER:BOOL="0" \
    -DOPTION_SUPPORT_3DMOUSE_WITH_3DxWARE="0" \
    -DOPTION_SUPPORT_3DMOUSE_WITH_HIDAPI="1" \
    -DOPTION_HID_DEBUG="0" \
    -DOPTION_USE_GDAL:BOOL="1" \
    -DPLUGIN_EXAMPLE_GL:BOOL="1" \
    -DPLUGIN_EXAMPLE_IO:BOOL="1" \
    -DPLUGIN_EXAMPLE_STANDARD:BOOL="1" \
    -DPLUGIN_GL_QEDL:BOOL="1" \
    -DPLUGIN_GL_QSSAO:BOOL="1" \
    -DPLUGIN_IO_QADDITIONAL:BOOL="1" \
    -DPLUGIN_IO_QCORE:BOOL="1" \
    -DPLUGIN_IO_QCSV_MATRIX:BOOL="1" \
    -DPLUGIN_IO_QDRACO:BOOL="1" \
    -DPLUGIN_IO_QE57:BOOL="1" \
    -DPLUGIN_IO_QFBX:BOOL="0" \
    -DPLUGIN_IO_QLAS:BOOL="1" \
    -DPLUGIN_IO_QLAS_FWF:BOOL="0" \
    -DPLUGIN_IO_QPDAL:BOOL="0" \
    -DPLUGIN_IO_QPHOTOSCAN:BOOL="1" \
    -DPLUGIN_IO_QRDB:BOOL="0" \
    -DPLUGIN_IO_QSTEP:BOOL="1" \
    -DPLUGIN_STANDARD_3DMASC:BOOL="1" \
    -DPLUGIN_STANDARD_QANIMATION:BOOL="1" \
    -DPLUGIN_STANDARD_QBROOM:BOOL="1" \
    -DPLUGIN_STANDARD_QCANUPO:BOOL="1" \
    -DPLUGIN_STANDARD_QCLOUDLAYERS:BOOL="1" \
    -DPLUGIN_STANDARD_QCOLORIMETRIC_SEGMENTER:BOOL="1" \
    -DPLUGIN_STANDARD_QCOMPASS:BOOL="1" \
    -DPLUGIN_STANDARD_QCORK:BOOL="0" \
    -DPLUGIN_STANDARD_QCSF:BOOL="1" \
    -DPLUGIN_STANDARD_QFACETS:BOOL="1" \
    -DPLUGIN_STANDARD_QHOUGH_NORMALS:BOOL="1" \
    -DPLUGIN_STANDARD_QHPR:BOOL="1" \
    -DPLUGIN_STANDARD_QJSONRPC:BOOL="1" \
    -DPLUGIN_STANDARD_QM3C2:BOOL="1" \
    -DPLUGIN_STANDARD_QMESH_BOOLEAN:BOOL="0" \
    -DPLUGIN_STANDARD_QMPLANE:BOOL="1" \
    -DPLUGIN_STANDARD_QPCL:BOOL="1" \
    -DPLUGIN_STANDARD_QPCV:BOOL="1" \
    -DPLUGIN_STANDARD_QPOISSON_RECON:BOOL="1" \
    -DPLUGIN_STANDARD_QRANSAC_SD:BOOL="1" \
    -DPLUGIN_STANDARD_QSRA:BOOL="1" \
    -DPLUGIN_STANDARD_QTREEISO:BOOL="1" \
    -DQANIMATION_WITH_FFMPEG_SUPPORT:BOOL="1" \
    -DPYTHONAPI_TEST_DIRECTORY:STRING="CloudComPy/Data" \
    -DPYTHONAPI_EXTDATA_DIRECTORY:STRING="CloudComPy/ExternalData" \
    -DPYTHONAPI_TRACES:BOOL="1" \
    -DPYMINOR:STRING="${PYMINOR}" \
    -DPYTHON_PREFERED_VERSION:STRING="3.${PYMINOR}" \
    -DPYTHONVENV_DIR:PATH="${CONDA_PATH}" \
    -DREPO_DIR:PATH="${ROOT}" \
    -DTBB_DIR:PATH="${CONDA_PATH}/lib/cmake/TBB" \
    -DUSE_CONDA_PACKAGES:BOOL="1" \
    -DUSE_EXTERNAL_QHULL_FOR_QHPR:BOOL="0"

# EXPERIENCE CLASSE C : chemins resolus a comparer entre runs reference et classe C
# (les entrees existent dans les deux modes, seule leur provenance differe).
echo "# --- classe C : chemins resolus (a comparer au build de reference) ---"
grep -E "^(CGAL_DIR|DRACO_|GDAL_|GMP|LASZIP_|MPFR_|OpenCV_DIR|PCL_DIR|PNG_|Qhull_DIR|pybind11_DIR|XercesC_|ZLIB_|EIGEN_ROOT_DIR|TBB_DIR|CMAKE_PREFIX_PATH)[A-Za-z0-9_]*:" "${BUILD}/CMakeCache.txt" | LC_ALL=C sort

echo "# --- compilation (make parallele) ---"
NBTHREADS="$(sysctl -n hw.ncpu)"
make -C "${BUILD}" -j"${NBTHREADS}"

echo "# --- installation ---"
make -C "${BUILD}" install
# --- rpaths des binaires du bundle : les binaires SANS LC_RPATH (plugins
# Qt Conda comme libqcocoa, executable CloudCompare, libs CC dont la cible
# ecrase le CMAKE_INSTALL_RPATH global) laissent des refs @rpath irresolues
# pour delocate -> tolerees, donc NON reecrites. Au runtime, dyld les resout
# par le fallback sur les rpaths de l'EXECUTABLE PRINCIPAL (le venv python =
# python Conda -> $CONDA_PREFIX/lib) -> chargement de la copie Conda de Qt en
# double (objc duplicate class, moveToThread, abort). On ajoute donc a chaque
# Mach-O du bundle la paire de rpaths CONDA lib + @loader_path, pour que
# delocate resolve TOUTES les refs, copie les externes et reecrive ensuite
# les referrers en @loader_path relatif (sanitisation : retrait des absolus).
add_rpath_if_missing() {
    local bin="$1"
    local rp="$2"
    if ! otool -l "${bin}" | grep -A2 LC_RPATH | grep -q "path ${rp}"; then
        install_name_tool -add_rpath "${rp}" "${bin}"
        codesign --force --sign - "${bin}" >/dev/null 2>&1 || true
    fi
}
APP="${INSTALL}/cloudComPy/CloudCompare/CloudCompare.app"
find "${APP}/Contents/MacOS" "${APP}/Contents/Frameworks" "${APP}/Contents/PlugIns" -type f 2>/dev/null | while read -r f; do
    otool -l "${f}" >/dev/null 2>&1 || continue
    add_rpath_if_missing "${f}" "${CONDA_PATH}/lib"
    add_rpath_if_missing "${f}" "@loader_path"
done

# --- ref lapack -> openblas : dans l'env Conda, liblapack.3.dylib est un symlink
# vers libopenblas.0.dylib. Delocate resout la ref @rpath/liblapack.3.dylib de
# libopencv_core avec une Search path vide -> tolereree non reecrite. Au runtime
# avec un python Conda, le fallback rpath du main executable charge la libopenblas
# CONDA, qui traine libgfortran + libomp Conda en refs absolues -> deux runtimes
# OpenMP (OMP Error #15). Sans env Conda, la ref est introuvable -> import KO.
# On reecrit @rpath/liblapack.3.dylib en @rpath/libopenblas.0.dylib (meme lib,
# nom reel du symlink) : delocate la resoudra et la reecrira, comme il fait
# pour les autres requerants de libopenblas.
find "${INSTALL}/cloudComPy" \( -name "*.dylib" -o -name "*.so" \) -type f | while read -r f; do
    if otool -L "${f}" 2>/dev/null | grep -q "@rpath/liblapack.3.dylib"; then
        install_name_tool -change "@rpath/liblapack.3.dylib" "@rpath/libopenblas.0.dylib" "${f}"
        codesign --force --sign - "${f}" >/dev/null 2>&1 || true
        echo "ref lapack -> openblas reecrite : ${f}"
    fi
done

# Runtime OpenMP unique : le deploiement macOS (BUILD_PYPI) copie des libs
# Conda dans Frameworks (libomp, Qt6, gdal...), INDEPENDAMMENT du drapeau
# INSTALL_PREREQUISITE_LIBRARIES ; delocate copie de son cote libomp dans
# .dylibs : deux fichiers distincts du meme runtime -> OMP Error #15
# (requerants reecrits les uns vers Frameworks, les autres vers .dylibs).
# On supprime la copie du bundle : tous les requerants seront alors resolus vers la
# copie Conda delocatee, unique exemplaire dans .dylibs.
# (N) : glob tolérant — si aucun motif ne matche (ex. pas de libgomp dans l'env
# Conda Apple, qui ne livre que libomp), la boucle ne s'exécute pas sans erreur
# zsh "no matches found" qui ferait échouer le script sous set -e.
for dup in "${APP}/Contents/Frameworks/"libomp*(N) "${APP}/Contents/Frameworks/"libgomp*(N); do
    if [ -f "${dup}" ]; then
        echo "suppression copie OpenMP du bundle : ${dup}"
        rm -f "${dup}"
    fi
done

echo "# --- generation du wheel (build + delocate, sans signature) ---"
rm -rf "${ROOT}/venv-wheel"
python3 -m venv "${ROOT}/venv-wheel"
source "${ROOT}/venv-wheel/bin/activate"
python -m pip install --upgrade pip
pip install build delocate wheel twine pkginfo
cd "${ROOT}"
cp -f MacOS/pyproject.toml pyproject.toml
cp -f MacOS/setup.py setup.py
rm -rf build dist
python -m build --wheel
# delocate resout les references @rpath vers les LC_RPATH absolus des binaires
# (CMAKE_INSTALL_RPATH...) : tant que les arbres reels existent hors du wheel,
# il planifie de COPIER les libs CC (ex. libQCC_GL_LIB.dylib) depuis deux
# emplacements distincts (build-ci et installConda) -> collision "Already
# planning to copy library with same basename". Les arbres etant la source du
# wheel, on les supprime apres 'python -m build' : les references deviennent
# irresolubles et tolerees par --ignore-missing-dependencies, la lib restant
# dans le wheel (Frameworks du bundle). Le smoke test valide la resolution
# runtime (fallback @loader_path dans le wheel) avant publication de l'artifact.
rm -rf "${BUILD}"
rm -rf "${INSTALL}"
# diagnostic : dependances externes les plus frequentes du wheel (comptees),
# et focus sur les libs d'imagerie souvent dupliquees entre paquets Conda.
delocate-listdeps --all dist/*.whl | sort | uniq -c | sort -rn | head -80 || true
delocate-listdeps --all dist/*.whl | grep -Ei "jpeg|png|freetype" | sort -u | head -60 || true

# delocate tolerant : en cas de collision "Already planning to copy library with
# same basename" (deux requerants resolvent la meme lib vers deux chemins externes
# distincts), on exclut le basename en cause (exclusion = lib NON recopiee,
# dependance non reecrite) et on recommence. Le smoke test statue ensuite sur la
# validite reellement fonctionnelle du wheel (une exclusion ne doit pas casser import).
exclude_args=()
attempt=1
max_attempts=8
while true; do
    set +e
    out="$(delocate-wheel --ignore-missing-dependencies -v ${exclude_args} dist/*.whl 2>&1)"
    dl_rc=$?
    set -e
    echo "${out}"
    if [ ${dl_rc} -eq 0 ]; then
        break
    fi
    culprit="$(echo "${out}" | grep -o 'same basename as: [^[:space:]]*' | tail -1 | sed 's/same basename as: //')"
    if [ -z "${culprit}" ] || [ ${attempt} -ge ${max_attempts} ]; then
        echo "delocate : echec non reparable par exclusion (tentative ${attempt}) / ${culprit}"
        exit 1
    fi
    echo "### collision basename : ${culprit} -> exclusion pour la tentative suivante"
    exclude_args+=("-e" "${culprit}")
    attempt=$((attempt+1))
done
# --- reparation lapack post-delocate : la ref @rpath/liblapack.3.dylib ne peut
# pas etre resolue par delocate (libopencv_core est copiee depuis l'env Conda
# dans .dylibs avec une Search path vide -> ref toleree NON reecrite par
# --ignore-missing-dependencies). On patche donc le wheel construit : la ref
# devient @loader_path/libopenblas.0.dylib, openblas etant deja copiee dans
# .dylibs par delocate pour les requerants PCL. Le controle final ci-dessous
# verifie ensuite qu'aucune ref externe ne subsiste dans le wheel.
lp_whl="$(echo "${ROOT}"/dist/cloudcompy-*.whl)"
lp_tmp="$(mktemp -d)"
if unzip -q "${lp_whl}" 'cloudComPy/.dylibs/*' -d "${lp_tmp}" 2>/dev/null; then
    lp_fixed=()
    for lp_f in "${lp_tmp}"/cloudComPy/.dylibs/*.dylib(N) "${lp_tmp}"/cloudComPy/.dylibs/*.so(N); do
        if otool -L "${lp_f}" 2>/dev/null | grep -q "liblapack"; then
            install_name_tool -change "@rpath/liblapack.3.dylib" "@loader_path/libopenblas.0.dylib" "${lp_f}"
            codesign --force --sign - "${lp_f}" >/dev/null 2>&1 || true
            echo "### ref lapack reecrite dans le wheel : cloudComPy/.dylibs/${lp_f:t}"
            lp_fixed+=("${lp_f}")
        fi
    done
    if [ ${#lp_fixed[@]} -gt 0 ]; then
        for lp_r in "${lp_fixed[@]}"; do
            (cd "${lp_tmp}" && zip -q "${lp_whl}" "cloudComPy/.dylibs/${lp_r:t}")
        done
    fi
fi
rm -rf "${lp_tmp}"
# --- controle final : aucune ref @rpath ne doit pointer vers une lib absente
# du wheel (sinon : crash import chez l'utilisateur sans env Conda, ou fallback
# dyld chargant une lib externe, source de conflits type OMP Error #15).
python - dist/cloudcompy-*.whl <<'PYWHEELCHK'
import zipfile, re, os, sys
whl = sys.argv[1]
with zipfile.ZipFile(whl) as z:
    names = {os.path.basename(n) for n in z.namelist()}
    bad = {}
    for n in z.namelist():
        if n.endswith('.dylib') or n.endswith('.so'):
            for m in re.finditer(rb'@rpath/([A-Za-z0-9._+-]+\.dylib)', z.read(n)):
                tgt = m.group(1).decode()
                if tgt not in names:
                    bad.setdefault(tgt, set()).add(n)
if bad:
    for tgt in sorted(bad):
        for r in sorted(bad[tgt]):
            print(f"### ref externe non resolue : {r} -> {tgt}")
    sys.exit(1)
print("### controle refs externes OK")
PYWHEELCHK
if twine check dist/*.whl; then echo "### twine check OK"; else echo "### twine check ECHEC rc=${?}"; exit 1; fi
deactivate

echo "# --- smoke test : wheel installe dans un venv vierge ---"
echo "### smoke test debut"
# QT_QPA_PLATFORM non force (le wheel mac n'embarque que le plugin cocoa ;
# pas de probleme connu de librairies graphiques sur mac, on laisse le defaut)
# purge du venv avant creation : pip saute l'installation quand le meme
# nom+version est deja present (venv persistant entre les runs locaux ;
# no-op sur un runner CI vierge). Sans purge, le smoke test peut valider
# un wheel PERIME du run precedent --- veux dire un fix jamais teste.
rm -rf "${ROOT}/venv-test"
python3 -m venv "${ROOT}/venv-test"
source "${ROOT}/venv-test/bin/activate"
python -m pip install --upgrade pip
pip install "${ROOT}"/dist/cloudcompy-*.whl
# --- diagnostic Mach-O : identifier qui charge la Qt Conda ---
SP="$(pip show cloudcompy | sed -n 's/^Location: //p')"
echo "### site-packages: ${SP}"
echo "### contenu .dylibs (40 premiers)":
ls "${SP}/cloudComPy/.dylibs" | head -40 || true
QC="$(find "${SP}/cloudComPy" -name "libqcocoa*.dylib" | head -1)"
SO="$(find "${SP}/cloudComPy" -name "_cloudComPy*.so" | head -1)"
echo "### qcocoa: ${QC}"
echo "### otool -L qcocoa:"
otool -L "${QC}" || true
echo "### rpaths qcocoa:"
otool -l "${QC}" | grep -A2 LC_RPATH || true
echo "### rpaths _cloudComPy.so:"
otool -l "${SO}" | grep -A2 LC_RPATH || true
echo "### deps de libQt6Core delocatee:"
otool -L "${SP}/cloudComPy/.dylibs/libQt6Core.6.10.2.dylib" | head -12 || true
echo "### rpaths de libQt6Core delocatee:"
otool -l "${SP}/cloudComPy/.dylibs/libQt6Core.6.10.2.dylib" | grep -A2 LC_RPATH || true
echo "### fin diagnostic Mach-O"
echo "### fichiers OpenMP presents dans le wheel installe :"
find "${SP}/cloudComPy" \( -name "libomp*" -o -name "libgomp*" \) -type f || true
echo "### refs OpenMP dans les Mach-O du wheel installe :"
find "${SP}/cloudComPy" -type f | while read -r f; do
    refs=$(otool -L "${f}" 2>/dev/null | grep -i "omp" || true)
    if [ -n "${refs}" ]; then
        echo "--- ${f}"
        echo "${refs}"
    fi
done
echo "### rpaths du python du venv-test :"
PYEXE=$(readlink -f "${ROOT}/venv-test/bin/python")
otool -l "${PYEXE}" 2>/dev/null | grep -A2 LC_RPATH || true
echo "### trace de chargement dyld (filtre omp) :"
DYLD_PRINT_LIBRARIES=1 python -c "import cloudComPy" >/tmp/dyld_trace.log 2>&1 || true
echo "lignes de trace : $(wc -l < /tmp/dyld_trace.log)"
grep -n -i -B3 "omp" /tmp/dyld_trace.log | head -80 || true
echo "### fin trace omp"
python - <<'PYEOF'
print("etape 1 : import du package cloudComPy", flush=True)
import cloudComPy as cc
# l'import de cloudComPy execute deja l'initialisation (initCC) et le chargement
# des plugins CloudCompare (cf. pybind11/__init__-macOS.py.in)
print("etape 2 : verification d'un plugin natif", flush=True)
print("PCL charge :", cc.isPluginPCL())
print("cloudComPy import et init OK:", cc.__file__, flush=True)
PYEOF

echo "# --- J1b macOS : build leger termine avec succes ---"
