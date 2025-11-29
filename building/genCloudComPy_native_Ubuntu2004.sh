#!/bin/bash

export CLOUDCOMPY_SRC=${HOME}/projets/CloudComPy/CloudComPy                            # CloudComPy source directory
export CLOUDCOMPY_BUILD=${HOME}/projets/CloudComPy/buildNativeU2004                    # CloudComPy build directory
export CLOUDCOMPY_INSTDIR=${HOME}/projets/CloudComPy/installNative                     # directory for CloudComPy installs
export CLOUDCOMPY_INSTNAME=CloudComPy308                                               # CloudComPy install directory name
export CLOUDCOMPY_INSTALL=${CLOUDCOMPY_INSTDIR}/${CLOUDCOMPY_INSTNAME}                 # CloudComPy install directory
export CLOUDCOMPY_TARFILE=CloudComPy_native308_Linux64_"$(date +"%Y%m%d-%H%M")".tgz    # CloudComPy Binary tarfile (will be in ${CLOUDCOMPY_INSTDIR}
export CORK_REP=${HOME}/projets/CloudComPy/cork                                        # directory of cork (remove the plugin in cmake options if not needed)
export DRACO_REP=${HOME}/projets/CloudComPy/dracoInstall
export FBXSDK_REP=${HOME}/projets/CloudComPy/fbxSdk                                    # directory of fbx sdk (remove the plugin in cmake options if not needed)
export LIBIGL_REP=${HOME}/projets/CloudComPy/libigl                                    # directory of libigl (remove the plugin in cmake options if not needed)
if [ -d ${HOME}/projets/CloudComPy/Occ-740p3_opt ]; then
    export OPENCASCADE_REP=${HOME}/projets/CloudComPy/Occ-740p3_opt                    # directory of OpenCascade (remove the plugin in cmake options if not needed)
elif [ -d ${HOME}/projets/hydro95/prerequisites/install/Occ-740p3_opt ]; then
    export OPENCASCADE_REP=${HOME}/projets/hydro95/prerequisites/install/Occ-740p3_opt
else
    export OPENCASCADE_REP=${HOME}/projets/hydro95/prerequisites/install/Occ-740p3EDFp1
fi
export PCLLIB_REP=${HOME}/projets/CloudComPy/pcl/install                               # patch on pcl lib (issue #100): libpcl_common.so
export NBTHREADS="$(grep -c processor /proc/cpuinfo)"                                  # number of threads for parallel make

error_exit()
{
  echo "Error $1" 1>&2
  exit 1
}

# --- CloudComPy build

cloudcompy_setenv()
{
    echo "# --- set CloudComPy build environment ---"
    cd ~/projets/CloudComPy
    rm -rf .venv308
    python3 -m venv .venv308
    . .venv308/bin/activate
    pip install pybind11
    echo ${CLOUDCOMPY_BUILD}
    echo ${CLOUDCOMPY_INSTALL}
    rm -rf ${CLOUDCOMPY_BUILD}
    rm -rf ${CLOUDCOMPY_INSTALL}
    mkdir -p ${CLOUDCOMPY_BUILD} && cd ${CLOUDCOMPY_BUILD} || error_exit "access problem to ${CLOUDCOMPY_BUILD}"
}

cloudcompy_configure()
{
    echo "# --- configure CloudComPy ---"
    cmake \
    -S"${CLOUDCOMPY_SRC}" \
    -B"${CLOUDCOMPY_BUILD}" \
    -G"Unix Makefiles" \
    -DBUILD_PY_TESTING:BOOL="1" \
    -DBUILD_REFERENCE_DOC:BOOL="1" \
    -DBUILD_TESTING:BOOL="0" \
    -DCCCORELIB_SHARED:BOOL="1" \
    -DCCCORELIB_USE_CGAL:BOOL="1" \
    -DCCCORELIB_USE_QT_CONCURRENT:BOOL="1" \
    -DCCCORELIB_USE_TBB:BOOL="0" \
    -DCMAKE_BUILD_TYPE:STRING="Release" \
    -DCMAKE_CXX_COMPILER:FILEPATH=/usr/bin/c++ \
    -DCMAKE_C_COMPILER:FILEPATH=/usr/bin/cc \
    -DCMAKE_Fortran_COMPILER:FILEPATH=/usr/bin/gfortran \
    -DCMAKE_INSTALL_PREFIX:PATH="${CLOUDCOMPY_INSTALL}" \
    -DCORK_INCLUDE_DIR:PATH="${CORK_REP}/src" \
    -DCORK_RELEASE_LIBRARY_FILE:FILEPATH="${CORK_REP}/lib/libcork.a" \
    -DFBX_SDK_INCLUDE_DIR:PATH="${FBXSDK_REP}/include" \
    -DFBX_SDK_LIBRARY_FILE:FILEPATH="${FBXSDK_REP}/lib/gcc/x64/release/libfbxsdk.a" \
    -DFBX_XML2_LIBRARY_FILE:FILEPATH="" \
    -DLIBIGL_INCLUDE_DIR:PATH="${LIBIGL_REP}/libigl/include" \
    -DLIBIGL_RELEASE_LIBRARY_FILE:FILEPATH="${LIBIGL_REP}/install/lib/libigl.a" \
    -DOPENCASCADE_DLL_DIR:PATH="${OPENCASCADE_REP}/lib" \
    -DOPENCASCADE_INC_DIR:PATH="${OPENCASCADE_REP}/include/opencascade" \
    -DOPENCASCADE_LIB_DIR:PATH="${OPENCASCADE_REP}/lib" \
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
    -DPLUGIN_IO_QFBX:BOOL="1" \
    -DPLUGIN_IO_QLAS:BOOL="1" \
    -DPLUGIN_IO_QLAS_FWF:BOOL="0" \
    -DPLUGIN_IO_QPDAL:BOOL="0" \
    -DPLUGIN_IO_QPHOTOSCAN:BOOL="1" \
    -DPLUGIN_IO_QRDB:BOOL="1" \
    -DPLUGIN_IO_QRDB_FETCH_DEPENDENCY:BOOL="1" \
    -DPLUGIN_IO_QRDB_INSTALL_DEPENDENCY:BOOL="1" \
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
    -DPLUGIN_STANDARD_QMESH_BOOLEAN:BOOL="1" \
    -DPLUGIN_STANDARD_QMPLANE:BOOL="1" \
    -DPLUGIN_STANDARD_QPCL:BOOL="1" \
    -DPLUGIN_STANDARD_QPCV:BOOL="1" \
    -DPLUGIN_STANDARD_QPOISSON_RECON:BOOL="1" \
    -DPLUGIN_STANDARD_QRANSAC_SD:BOOL="1" \
    -DPLUGIN_STANDARD_QSRA:BOOL="1" \
    -DPLUGIN_STANDARD_QTREEISO:BOOL="1" \
    -DPLUGIN_STANDARD_QVOXFALL:BOOL="0" \
    -DPYTHONAPI_TEST_DIRECTORY:STRING="CloudComPy/Data" \
    -DPYTHONAPI_EXTDATA_DIRECTORY:STRING="CloudComPy/ExternalData" \
    -DPYTHONAPI_TRACES:BOOL="1" \
    -DPYTHON_PREFERED_VERSION:STRING="3.8" \
    -DQANIMATION_WITH_FFMPEG_SUPPORT:BOOL="1" \
    -DUSE_CONDA_PACKAGES:BOOL="0" \
    -DUSE_EXTERNAL_QHULL_FOR_QHPR:BOOL="0" \
    -DDraco_DIR:STRING="${DRACO_REP}/share/cmake" \
    -DDRACO_INCLUDE_DIR:PATH="${DRACO_REP}/include" \
    -DDRACO_LIB_DIR:PATH="${DRACO_REP}/lib" \
    -DEIGEN_INCLUDE_DIR:PATH="/usr/include/eigen3" \
    -DEIGEN_ROOT_DIR:PATH="/usr/include/eigen3" \
    -Dpybind11_DIR:PATH="/home/paul/projets/CloudComPy/.venv308/lib/python3.8/site-packages/pybind11/share/cmake/pybind11" \
    -DQt5_DIR:PATH="/home/paul/projets/CloudComPy/Qt_5.15.18/install/lib/cmake/Qt5" \
    -DCGAL_DIR="/home/paul/projets/CloudComPy/cgal563/CGAL-5.6.3"
}

#    -DDRACO_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
#    -DDRACO_LIB_DIR:PATH="${CONDA_PATH}/lib" \
#    -DDRACO_LIBRARIES:PATH="${CONDA_PATH}/lib/libdraco.a" \
#    -DEIGEN_INCLUDE_DIR:PATH="${CONDA_PATH}/include/eigen3" \
#    -DEIGEN_ROOT_DIR:PATH="${CONDA_PATH}/include/eigen3" \
#    -DGDAL_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
#    -DGDAL_LIBRARY:FILEPATH="${CONDA_PATH}/lib/libgdal.so" \
#    -DGMP_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
#    -DGMP_LIBRARIES:FILEPATH="${CONDA_PATH}/lib/libgmp.so" \
#    -DGMP_LIBRARIES_DIR:FILEPATH="${CONDA_PATH}" \
#    -DMPFR_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
#    -DMPFR_LIBRARIES:FILEPATH="${CONDA_PATH}/lib/libmpfr.so" \
#    -DMPFR_LIBRARIES_DIR:FILEPATH="${CONDA_PATH}" \
#    -DMPIR_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
#    -DMPIR_RELEASE_LIBRARY_FILE:FILEPATH="${CONDA_PATH}/lib/libgmp.so" \
#    -DOpenMP_omp_LIBRARY:FILEPATH="${CONDA_PATH}/lib/libomp.so" \
#    -DTBB_DIR:PATH="${CONDA_PATH}/lib/cmake/TBB" \
#    -DXercesC_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
#    -DXercesC_LIBRARY_DEBUG:FILEPATH="XercesC_LIBRARY_DEBUG-NOTFOUND" \
#    -DXercesC_LIBRARY_RELEASE:FILEPATH="${CONDA_PATH}/lib/libxerces-c.so" \
#    -DZLIB_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
#    -DZLIB_LIBRARY_RELEASE:FILEPATH="${CONDA_PATH}/lib/libz.so"

cloudcompy_build()
{
    echo "# --- build and install CloudComPy ---"
    cd ${CLOUDCOMPY_BUILD} && make -j${NBTHREADS} && make install
    cd ${OPENCASCADE_REP}/lib && \
    cp -f libTKSTEP.so.7 libTKSTEPBase.so.7 libTKSTEPAttr.so.7 libTKSTEP209.so.7 libTKShHealing.so.7 libTKTopAlgo.so.7 libTKBRep.so.7 \
    libTKGeomBase.so.7 libTKG3d.so.7 libTKG2d.so.7 libTKMath.so.7 libTKernel.so.7 libTKXSBase.so.7 libTKGeomAlgo.so.7 libTKMesh.so.7 \
    ${CLOUDCOMPY_INSTALL}/lib/cloudcompare/plugins
    cd ${PCLLIB_REP}/lib && \
    cp -f libpcl_common.so.1.12.1 ${CLOUDCOMPY_INSTALL}/lib/cloudcompare
    cd ${CLOUDCOMPY_INSTALL}/lib/cloudcompare && \
    ln -s libpcl_common.so.1.12.1 libpcl_common.so.1.12 && ln -s libpcl_common.so.1.12.1 libpcl_common.so
}

cloudcompy_tarfile()
{
    echo "# --- generate CloudComPy binaries tarfile ---"
    cd ${CLOUDCOMPY_INSTNAME} && find . -type d -name __pycache__ -exec rm -rf {} \;
    cd ${CLOUDCOMPY_INSTDIR} && rm -f ${CLOUDCOMPY_TARFILE} &&\
    tar cvzf ${CLOUDCOMPY_TARFILE} ${CLOUDCOMPY_INSTNAME}
}

cloudcompy_test()
{
    echo "# --- test CloudComPy ---"
    cd ${CLOUDCOMPY_INSTALL} && \
    . bin/condaCloud.sh activate ${CLOUDCOMPY_INSTNAME} && \
    rm -rf ~/CloudComPy/Data &&
    cd doc/PythonAPI_test && ctest
}

cloudcompy_setenv && \
cloudcompy_configure && \
cloudcompy_build && \
cloudcompy_tarfile && \
cloudcompy_test
