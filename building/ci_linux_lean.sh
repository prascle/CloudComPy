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

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUILD="${ROOT}/build-ci"
INSTALL="${ROOT}/install-ci"
CONDA_PATH="${CONDA_PREFIX}"

echo "# --- J1a build leger CloudComPy (CI Linux) ---"
echo "sources : ${ROOT}"
echo "build   : ${BUILD}"
echo "install : ${INSTALL}"
echo "conda   : ${CONDA_PATH} (${CONDA_ENV_NAME})"

rm -rf "${BUILD}" "${INSTALL}"
mkdir -p "${BUILD}"

echo "# --- configuration CMake ---"
cmake \
    -S"${ROOT}" \
    -B"${BUILD}" \
    -G"Unix Makefiles" \
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
    -DDRACO_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DDRACO_LIB_DIR:PATH="${CONDA_PATH}/lib" \
    -DDRACO_LIBRARIES:PATH="${CONDA_PATH}/lib/libdraco.a" \
    -DEIGEN_INCLUDE_DIR:PATH="${CONDA_PATH}/include/eigen3" \
    -DEIGEN_ROOT_DIR:PATH="${CONDA_PATH}/include/eigen3" \
    -DGDAL_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DGDAL_LIBRARY:FILEPATH="${CONDA_PATH}/lib/libgdal.so" \
    -DGMP_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DGMP_LIBRARIES:FILEPATH="${CONDA_PATH}/lib/libgmp.so" \
    -DGMP_LIBRARIES_DIR:PATH="${CONDA_PATH}" \
    -DLASZIP_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DLASZIP_LIBRARY:FILEPATH="${CONDA_PATH}/lib/liblaszip.so" \
    -DMPFR_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DMPFR_LIBRARIES:FILEPATH="${CONDA_PATH}/lib/libmpfr.so" \
    -DMPFR_LIBRARIES_DIR:PATH="${CONDA_PATH}" \
    -DMPIR_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DMPIR_RELEASE_LIBRARY_FILE:FILEPATH="${CONDA_PATH}/lib/libgmp.so" \
    -DOPENCASCADE_78_OR_NEWER:BOOL="1" \
    -DOPENCASCADE_DLL_DIR:PATH="${CONDA_PATH}/lib" \
    -DOPENCASCADE_INC_DIR:PATH="${CONDA_PATH}/include/opencascade" \
    -DOPENCASCADE_LIB_DIR:PATH="${CONDA_PATH}/lib" \
    -DOPENCASCADE_TBB_DLL_DIR:PATH="${CONDA_PATH}/lib" \
    -DOPTION_USE_GDAL:BOOL="1" \
    -DOpenMP_omp_LIBRARY:FILEPATH="${CONDA_PATH}/lib/libomp.so" \
    -DPLUGIN_GL_QEDL:BOOL="1" \
    -DPLUGIN_GL_QSSAO:BOOL="1" \
    -DPLUGIN_IO_QADDITIONAL:BOOL="1" \
    -DPLUGIN_IO_QCORE:BOOL="1" \
    -DPLUGIN_IO_QCSV_MATRIX:BOOL="1" \
    -DPLUGIN_IO_QDRACO:BOOL="1" \
    -DPLUGIN_IO_QE57:BOOL="1" \
    -DPLUGIN_IO_QLAS:BOOL="1" \
    -DPLUGIN_IO_QSTEP:BOOL="1" \
    -DPLUGIN_PYTHON="OFF" \
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
    -DPYTHONVENV_DIR:PATH="${CONDA_PATH}" \
    -DTBB_DIR:PATH="${CONDA_PATH}/lib/cmake/TBB" \
    -DUSE_CONDA_PACKAGES:BOOL="1" \
    -DUSE_EXTERNAL_QHULL_FOR_QHPR:BOOL="0" \
    -DXercesC_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DXercesC_LIBRARY_DEBUG:FILEPATH="XercesC_LIBRARY_DEBUG-NOTFOUND" \
    -DXercesC_LIBRARY_RELEASE:FILEPATH="${CONDA_PATH}/lib/libxerces-c.so" \
    -DZLIB_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DZLIB_LIBRARY_RELEASE:FILEPATH="${CONDA_PATH}/lib/libz.so"

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
python3 -c "import cloudComPy; print('cloudComPy import OK:', cloudComPy.__file__)"
python3 - <<'EOF'
import cloudComPy as cc
print("version CloudCompare:", cc.ccLog.Version)
EOF

echo "# --- J1a: build leger termine avec succes ---"
