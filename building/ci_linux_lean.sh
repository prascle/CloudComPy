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

# EXPERIENCE CLASSE C (audit J2a 8.4), TERMINEE le 27/11/2026 : les pre-allocations
# classe A (GDAL, GMP, LASZIP, MPFR, XercesC, ZLIB, DRACO) ont ete retirees apres
# comparaison des chemins resolus entre runs reference et classe C (identiques ;
# le paquet conda linux draco resout meme la lib, contrairement a windows/macos).
# Restent en classe B : EIGEN_ROOT_DIR (custom), OPENCASCADE_INC/LIB_DIR (qStepCAD),
# CONDA_ENV/CONDA_PATH (templates fork), PYTHONVENV_DIR. CMAKE_PREFIX_PATH est
# fourni par l activation de l environnement conda, find_package resout le reste.

echo "# --- configuration CMake ---"
# J2c : le panneau constant des drapeaux est consomme via le preset
# ci-linux-lean (CMakePresets.json, source unique, resolution DJ4) ; le
# script ne passe plus que les chemins machine et la classe B.
cmake --preset ci-linux-lean \
    -DCLOUDCOMPARE_VERSION:STRING="${CLOUDCOMPARE_VERSION}" \
    -DCMAKE_INSTALL_PREFIX:PATH="${INSTALL}" \
    -DCONDA_ENV="${CONDA_ENV_NAME}" \
    -DCONDA_PATH:PATH="${CONDA_PATH}" \
    -DEIGEN_ROOT_DIR:PATH="${CONDA_PATH}/include/eigen3" \
    -DOPENCASCADE_INC_DIR:PATH="${CONDA_PATH}/include/opencascade" \
    -DOPENCASCADE_LIB_DIR:PATH="${CONDA_PATH}/lib" \
    -DPYTHONVENV_DIR:PATH="${CONDA_PATH}"

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
