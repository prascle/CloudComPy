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
cmake \
    -S"${ROOT}" \
    -B"${BUILD}" \
    -G"Unix Makefiles" \
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
    -DCGAL_DIR:PATH="${CONDA_PATH}/lib/cmake/CGAL" \
    -DCMAKE_BUILD_TYPE:STRING="Release" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="13.0" \
    -DCMAKE_INSTALL_PREFIX:PATH="${INSTALL}" \
    -DCMAKE_INSTALL_RPATH="${INSTALL}/cloudComPy/CloudCompare/CloudCompare.app/Contents/Frameworks" \
    -DCMAKE_MACOSX_RPATH=ON \
    -DCONDA_LIBS:PATH="${CONDA_PATH}/lib" \
    -DCONDA_PATH:PATH="${CONDA_PATH}" \
    -DDRACO_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DDRACO_LIB_DIR:PATH="${CONDA_PATH}/lib" \
    -DDRACO_LIBRARIES:PATH="${CONDA_PATH}/lib/libdraco.a" \
    -DEIGEN_INCLUDE_DIR:PATH="${CONDA_PATH}/include/eigen3" \
    -DEIGEN_ROOT_DIR:PATH="${CONDA_PATH}/include/eigen3" \
    -DFFMPEG_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DFFMPEG_LIBRARY_DIR:FILEPATH="${CONDA_PATH}/lib" \
    -DFFMPEG_X264_LIBRARY_DIR:FILEPATH="${CONDA_PATH}/lib" \
    -DFBX_XML2_LIBRARY_FILE:FILEPATH="" \
    -DGDAL_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DGDAL_LIBRARY:FILEPATH="${CONDA_PATH}/lib/libgdal.dylib" \
    -DGMPXX_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DGMPXX_LIBRARIES:FILEPATH="${CONDA_PATH}/lib/libgmp.dylib" \
    -DGMP_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DGMP_LIBRARY_DEBUG:FILEPATH="${CONDA_PATH}/lib/libgmp.dylib" \
    -DGMP_LIBRARY_RELEASE:FILEPATH="${CONDA_PATH}/lib/libgmp.dylib" \
    -DLASZIP_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DLASZIP_LIBRARY:FILEPATH="${CONDA_PATH}/lib/liblaszip.dylib" \
    -DMPFR_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DMPFR_LIBRARIES:FILEPATH="${CONDA_PATH}/lib/libmpfr.dylib" \
    -DMPIR_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DMPIR_RELEASE_LIBRARY_FILE:FILEPATH="${CONDA_PATH}/lib/libgmp.dylib" \
    -DOPENCASCADE_78_OR_NEWER:BOOL="1" \
    -DOPENCASCADE_DLL_DIR:PATH="${CONDA_PATH}/lib" \
    -DOPENCASCADE_INC_DIR:PATH="${CONDA_PATH}/include/opencascade" \
    -DOPENCASCADE_LIB_DIR:PATH="${CONDA_PATH}/lib" \
    -DOPENCASCADE_TBB_DLL_DIR:PATH="${CONDA_PATH}/lib" \
    -DOPTION_BUILD_CCVIEWER:BOOL="0" \
    -DOPTION_SUPPORT_3DMOUSE_WITH_3DxWARE="0" \
    -DOPTION_SUPPORT_3DMOUSE_WITH_HIDAPI="1" \
    -DOPTION_HID_DEBUG="0" \
    -DOPTION_USE_GDAL:BOOL="1" \
    -DOpenCV_DIR:PATH="${CONDA_PATH}/lib/cmake/opencv4" \
    -DPCL_DIR:PATH="${CONDA_PATH}/share/pcl-1.15" \
    -DPNG_INCLUDE_DIR:PATH="${CONDA_PATH}/include/libpng16" \
    -DPNG_LIBRARIES:FILEPATH="${CONDA_PATH}/lib/libpng16.dylib" \
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
    -DPLUGIN_PYTHON="OFF" \
    -DPLUGIN_STANDARD_3DMASC:BOOL="1" \
    -DPLUGIN_STANDARD_MASONRY_QAUTO_SEG:BOOL="1" \
    -DPLUGIN_STANDARD_MASONRY_QMANUAL_SEG:BOOL="1" \
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
    -DQHULL_LIBRARY_DEBUG:FILEPATH="${CONDA_PATH}/lib/libqhullcpp.a" \
    -DQHULL_LIBRARY_DEBUG_STATIC:FILEPATH="${CONDA_PATH}/lib/libqhullstatic_r.a" \
    -DQHULL_LIBRARY_SHARED:FILEPATH="${CONDA_PATH}/lib/libqhull_r.dylib" \
    -DQHULL_LIBRARY_STATIC:FILEPATH="${CONDA_PATH}/lib/libqhullstatic_r.a" \
    -DQhull_DIR:PATH="${CONDA_PATH}/lib/cmake/Qhull" \
    -Dpybind11_DIR:PATH="${CONDA_PATH}/share/cmake/pybind11" \
    -DPYTHONAPI_TEST_DIRECTORY:STRING="CloudComPy/Data" \
    -DPYTHONAPI_EXTDATA_DIRECTORY:STRING="CloudComPy/ExternalData" \
    -DPYTHONAPI_TRACES:BOOL="1" \
    -DPYMINOR:STRING="${PYMINOR}" \
    -DPYTHON_PREFERED_VERSION:STRING="3.${PYMINOR}" \
    -DPYTHONVENV_DIR:PATH="${CONDA_PATH}" \
    -DREPO_DIR:PATH="${ROOT}" \
    -DTBB_DIR:PATH="${CONDA_PATH}/lib/cmake/TBB" \
    -DUSE_CONDA_PACKAGES:BOOL="1" \
    -DUSE_EXTERNAL_QHULL_FOR_QHPR:BOOL="0" \
    -DXercesC_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DXercesC_LIBRARY_DEBUG:FILEPATH="${CONDA_PATH}/lib/libxerces-c.dylib" \
    -DXercesC_LIBRARY_RELEASE:FILEPATH="${CONDA_PATH}/lib/libxerces-c.dylib" \
    -DZLIB_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DZLIB_LIBRARY_RELEASE:FILEPATH="${CONDA_PATH}/lib/libz.1.dylib"

echo "# --- compilation (make parallele) ---"
NBTHREADS="$(sysctl -n hw.ncpu)"
make -C "${BUILD}" -j"${NBTHREADS}"

echo "# --- installation ---"
make -C "${BUILD}" install

echo "# --- generation du wheel (build + delocate, sans signature) ---"
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
    out="$(delocate-wheel --ignore-missing-dependencies --no-sanitize-rpaths -v ${exclude_args} dist/*.whl 2>&1)"
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
twine check dist/*.whl
deactivate

echo "# --- smoke test : wheel installe dans un venv vierge ---"
export QT_QPA_PLATFORM=offscreen
python3 -m venv "${ROOT}/venv-test"
source "${ROOT}/venv-test/bin/activate"
python -m pip install --upgrade pip
pip install "${ROOT}"/dist/cloudcompy-*.whl
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
