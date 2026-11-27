#!/bin/bash
##########################################################################
#                                                                        #
#                              CloudComPy                                #
#                                                                        #
#  This program is free software; you can redistribute it and/or modify  #
#  it under the terms of the GNU General Public License as published by  #
#  the Free Software Foundation; either version 3 of the License, or     #
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

# J1a - build "leger" CloudComPy pour CI GitHub Actions (Linux, Conda 3.12)
#
# Differences avec le build de production (genCloudComPy_Conda3xx_Ubuntu2004.sh):
#  - pas de dependances externes non-Conda (cork, FBX SDK, libigl, RDB SDK):
#    les plugins qui les exigent sont desactives
#  - PYTHONAPI_TRACES=ON obligatoire: le main.cpp de CloudCompare patche appelle
#    ccLogTrace::settrace() sans garde #ifdef (declared seulement si _PYTHONAPI_DEBUG_)
#  - pas de generation de documentation
#  - smoke test d'import a la place de la batterie complete de tests
#
# Variables d'environnement (optionnelles):
#  CLOUDCOMPARE_VERSION : version CloudCompare pour la doc, defaut "2.14.beta"
#  CONDA_ENV_NAME       : nom de l'environnement Conda, defaut "CloudComPy312"

set -e

CLOUDCOMPARE_VERSION="${CLOUDCOMPARE_VERSION:-2.14.beta}"
CONDA_ENV_NAME="${CONDA_ENV_NAME:-CloudComPy312}"
PYMINOR="${PYMINOR:-12}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${ROOT}/build-ci"
INSTALL="${ROOT}/install-ci"
CONDA_PATH="${CONDA_PREFIX}"

echo "# --- J1a build leger CloudComPy (CI Linux) ---"
echo "sources : ${ROOT}"
echo "build   : ${BUILD}"
echo "install : ${INSTALL}"
echo "conda   : ${CONDA_PATH} (${CONDA_ENV_NAME})"

# maj de la liste conda-list depuis l'environnement reellement utilise au build,
# pour les diagnostics cote utilisateur (comportement de la procedure de production)
micromamba list > "${ROOT}/building/conda-list_Ubuntu20.04_3${PYMINOR}"

rm -rf "${BUILD}" "${INSTALL}"
mkdir -p "${BUILD}"

# EXPERIENCE CLASSE C (audit J2a 8.4) - EXPERIMENT TEMPORAIRE, A RETIRER AVANT LA PR :
# CLASS_C=1 retire la pre-allocation classe A (variables resolvables par
# find_package via CMAKE_PREFIX_PATH) pour comparer les chemins resolus au build
# de reference (mode par defaut). Les variables classe B (EIGEN_ROOT_DIR custom,
# OPENCASCADE_INC/LIB_DIR, CONDA_*, PYTHONVENV_DIR) restent toujours passees.
CLASS_C_D=()
if [ "${CLASS_C:-0}" = "1" ]; then
    echo "# --- classe C : pre-allocation classe A retiree, CMAKE_PREFIX_PATH explicite ---"
    CLASS_C_D+=(-DCMAKE_PREFIX_PATH:PATH="${CONDA_PATH}")
else
    CLASS_C_D=(
        -DDRACO_LIBRARIES:PATH="${CONDA_PATH}/lib/libdraco.a"
        -DGDAL_INCLUDE_DIR:PATH="${CONDA_PATH}/include"
        -DGDAL_LIBRARY:FILEPATH="${CONDA_PATH}/lib/libgdal.so"
        -DGMP_INCLUDE_DIR:PATH="${CONDA_PATH}/include"
        -DGMP_LIBRARIES:FILEPATH="${CONDA_PATH}/lib/libgmp.so"
        -DLASZIP_INCLUDE_DIR:PATH="${CONDA_PATH}/include"
        -DLASZIP_LIBRARY:FILEPATH="${CONDA_PATH}/lib/liblaszip.so"
        -DMPFR_INCLUDE_DIR:PATH="${CONDA_PATH}/include"
        -DMPFR_LIBRARIES:FILEPATH="${CONDA_PATH}/lib/libmpfr.so"
        -DXercesC_INCLUDE_DIR:PATH="${CONDA_PATH}/include"
        -DXercesC_LIBRARY_RELEASE:FILEPATH="${CONDA_PATH}/lib/libxerces-c.so"
        -DZLIB_INCLUDE_DIR:PATH="${CONDA_PATH}/include"
        -DZLIB_LIBRARY_RELEASE:FILEPATH="${CONDA_PATH}/lib/libz.so"
    )
fi

echo "# --- configuration CMake ---"
cmake \
    -S"${ROOT}" \
    -B"${BUILD}" \
    -G"Unix Makefiles" \
    "${CLASS_C_D[@]}" \
    -DBUILD_REFERENCE_DOC:BOOL="0" \
    -DBUILD_PY_TESTING:BOOL="1" \
    -DBUILD_TESTING:BOOL="1" \
    -DCCCORELIB_SHARED:BOOL="1" \
    -DCCCORELIB_USE_CGAL:BOOL="1" \
    -DCCCORELIB_USE_QT_CONCURRENT:BOOL="1" \
    -DCCCORELIB_USE_TBB:BOOL="0" \
    -DCLOUDCOMPARE_VERSION:STRING="${CLOUDCOMPARE_VERSION}" \
    -DCMAKE_BUILD_TYPE:STRING="Release" \
    -DCMAKE_C_COMPILER:FILEPATH=cc \
    -DCMAKE_CXX_COMPILER:FILEPATH=c++ \
    -DCMAKE_INSTALL_PREFIX:PATH="${INSTALL}" \
    -DCONDA_ENV="${CONDA_ENV_NAME}" \
    -DCONDA_PATH:PATH="${CONDA_PATH}" \
    -DEIGEN_ROOT_DIR:PATH="${CONDA_PATH}/include/eigen3" \
    -DOPENCASCADE_78_OR_NEWER:BOOL="1" \
    -DOPENCASCADE_INC_DIR:PATH="${CONDA_PATH}/include/opencascade" \
    -DOPENCASCADE_LIB_DIR:PATH="${CONDA_PATH}/lib" \
    -DOPTION_USE_GDAL:BOOL="1" \
    -DPLUGIN_GL_QEDL:BOOL="1" \
    -DPLUGIN_GL_QSSAO:BOOL="1" \
    -DPLUGIN_IO_QADDITIONAL:BOOL="1" \
    -DPLUGIN_IO_QCORE:BOOL="1" \
    -DPLUGIN_IO_QCSV_MATRIX:BOOL="1" \
    -DPLUGIN_IO_QDRACO:BOOL="1" \
    -DPLUGIN_IO_QE57:BOOL="1" \
    -DPLUGIN_IO_QLAS:BOOL="1" \
    -DPLUGIN_IO_QSTEP:BOOL="1" \
    -DPLUGIN_STANDARD_QBROOM:BOOL="1" \
    -DPLUGIN_STANDARD_QCANUPO:BOOL="1" \
    -DPLUGIN_STANDARD_QCLOUDLAYERS:BOOL="1" \
    -DPLUGIN_STANDARD_QCOMPASS:BOOL="1" \
    -DPLUGIN_STANDARD_QCSF:BOOL="1" \
    -DPLUGIN_STANDARD_QFACETS:BOOL="1" \
    -DPLUGIN_STANDARD_QHOUGH_NORMALS:BOOL="1" \
    -DPLUGIN_STANDARD_QHPR:BOOL="1" \
    -DPLUGIN_STANDARD_QM3C2:BOOL="1" \
    -DPLUGIN_STANDARD_QMPLANE:BOOL="1" \
    -DPLUGIN_STANDARD_QPOISSON_RECON:BOOL="1" \
    -DPLUGIN_STANDARD_QRANSAC_SD:BOOL="1" \
    -DPLUGIN_STANDARD_QSRA:BOOL="1" \
    -DPLUGIN_STANDARD_QTREEISO:BOOL="1" \
    -DPYTHONAPI_TRACES:BOOL="1" \
    -DPYTHON_PREFERED_VERSION:STRING="3.12" \
    -DPYMINOR:STRING="12" \
    -DPYTHONVENV_DIR:PATH="${CONDA_PATH}" \
    -DUSE_CONDA_PACKAGES:BOOL="1" \
    -DUSE_EXTERNAL_QHULL_FOR_QHPR:BOOL="0"

# EXPERIENCE CLASSE C : chemins resolus a comparer entre runs reference et classe C
# (les entrees existent dans les deux modes, seule leur provenance differe).
echo "# --- classe C : chemins resolus (a comparer au build de reference) ---"
grep -E "^(DRACO_|GDAL_|GMP|LASZIP_|MPFR_|XercesC_|ZLIB_|EIGEN_ROOT_DIR|CMAKE_PREFIX_PATH)[A-Za-z0-9_]*:" "${BUILD}/CMakeCache.txt" | LC_ALL=C sort

echo "# --- compilation (make parallele) ---"
NBTHREADS="$(nproc)"
make -C "${BUILD}" -j"${NBTHREADS}"

echo "# --- installation ---"
make -C "${BUILD}" install

echo "# --- smoke test: import cloudComPy ---"
cd "${INSTALL}"
chmod +x cloudComPy/envCloudComPy.sh
. cloudComPy/envCloudComPy.sh activate
export QT_QPA_PLATFORM=offscreen
python3 - <<'PYEOF'
import cloudComPy as cc
# l import de cloudComPy execute deja l initialisation (initCC) et le chargement
# des plugins CloudCompare (cf. pybind11/__init__-Linux.py.in)
print("cloudComPy import et init OK:", cc.__file__)
PYEOF

echo "# --- J1a: build leger termine avec succes ---"
