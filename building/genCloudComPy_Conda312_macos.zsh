#!/bin/zsh

export CLOUDCOMPY_SRC=${HOME}/projets/CloudComPy/CloudComPy                            # CloudComPy source directory
export CLOUDCOMPY_BUILD=${HOME}/projets/CloudComPy/buildConda312                       # CloudComPy build directory
export CLOUDCOMPY_INSTDIR=${HOME}/projets/CloudComPy/installConda                      # directory for CloudComPy installs
export CLOUDCOMPY_INSTNAME=CloudComPy312                                               # CloudComPy install directory name
export CLOUDCOMPY_INSTALL=${CLOUDCOMPY_INSTDIR}/${CLOUDCOMPY_INSTNAME}                 # CloudComPy install directory
export CLOUDCOMPY_TARFILE=CloudComPy_Conda312_MacOS_"$(date +"%Y%m%d-%H%M")".tgz     # CloudComPy Binary tarfile (will be in ${CLOUDCOMPY_INSTDIR}
if [ -d ${HOME}/anaconda3 ]; then
    export CONDA_ROOT=${HOME}/anaconda3                                                # root directory of conda installation
else
    export CONDA_ROOT=${HOME}/miniconda3                                               # root directory of conda installation
fi
export CONDA_ENV=CloudComPy312                                                         # conda environment name
export CONDA_PATH=${CONDA_ROOT}/envs/${CONDA_ENV}                                      # conda environment directory
export CORK_REP=${HOME}/projets/CloudComPy/Cork/cork                                   # directory of cork (remove the plugin in cmake options if not needed)
export FBXSDK_REP="/Applications/Autodesk/FBX SDK/2020.2.1"                            # directory of fbx sdk (remove the plugin in cmake options if not needed)
export LIBIGL_REP=${HOME}/projets/CloudComPy/libigl                                    # directory of libigl (remove the plugin in cmake options if not needed)
if [ -d ${HOME}/projets/CloudComPy/Occ-740p3_opt ]; then
    export OPENCASCADE_REP=${HOME}/projets/CloudComPy/Occ-740p3_opt                    # directory of OpenCascade (remove the plugin in cmake options if not needed)
elif [ -d ${HOME}/projets/hydro95/prerequisites/install/Occ-740p3_opt ]; then
    export OPENCASCADE_REP=${HOME}/projets/hydro95/prerequisites/install/Occ-740p3_opt
else
    export OPENCASCADE_REP=${HOME}/projets/hydro95/prerequisites/install/Occ-740p3EDFp1
fi
export PCLLIB_REP=${HOME}/projets/CloudComPy/pcl/install                               # patch on pcl lib (issue #100): libpcl_common.so
export NBTHREADS=10                                                                    # number of threads for parallel make

. ${CONDA_ROOT}/etc/profile.d/conda.sh                                                 # required to have access to conda commands in a shell script

error_exit()
{
  echo "Error $1" 1>&2
  exit 1
}

# --- conda environment
#     bug lldb with latest version openssl (>=3.1) https://stackoverflow.com/questions/74059978/why-is-lldb-generating-exc-bad-instruction-with-user-compiled-library-on-macos/76032052#76032052

conda_buildenv()
{
    echo "# --- build conda environment ---"
    conda update -y -n base -c defaults conda
    conda activate ${CONDA_ENV}
    ret=$?
    ret=1
    if [ $ret != "0" ]; then
        conda activate && \
        conda create -y --name ${CONDA_ENV} python=3.12 && \
        conda activate ${CONDA_ENV} || error_exit "conda environment ${CONDA_ENV} cannot be built"
    fi
    conda config --add channels conda-forge && \
    conda config --set channel_priority flexible && \
    conda install -y "boost" "cgal" cmake "draco" "ffmpeg" "gdal" jupyterlab laszip "matplotlib" "mysql" notebook numpy "opencv" "openssl" "pcl" "pdal" "psutil" pybind11 quaternion "qhull" "qt" scipy sphinx_rtd_theme spyder tbb tbb-devel "xerces-c" xorg-libx11  || error_exit "conda environment ${CONDA_ENV} cannot be completed"
    #conda install -y "boost=1.84" "cgal=5.6" cmake "draco=1.5" "ffmpeg=6.1" "gdal=3.8" jupyterlab laszip "matplotlib=3.10" "mysql=8.0" notebook numpy "opencv=4.9" "openssl=3.5" "pcl=1.14" "pdal=2.7" "psutil=7.0" pybind11 quaternion "qhull=2020.2" "qt=5.15.8" scipy sphinx_rtd_theme spyder tbb tbb-devel "xerces-c=3.2" xorg-libx11  || error_exit "conda environment ${CONDA_ENV} cannot be completed"
}

# --- CloudComPy build

cloudcompy_setenv()
{
    echo "# --- set CloudComPy build environment ---"
    conda activate ${CONDA_ENV} || error_exit "${CONDA_ENV} is not a conda environment"
    conda list > ${CLOUDCOMPY_SRC}/building/conda-list_macOS_312 || error_exit "access problem to ${CLOUDCOMPY_SRC}"
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
    -DBoost_DIR:PATH="${CONDA_PATH}/lib/cmake/Boost-1.78.0" \
    -DBUILD_PY_TESTING:BOOL="1" \
    -DBUILD_REFERENCE_DOC:BOOL="1" \
    -DBUILD_TESTING:BOOL="1" \
    -DCCCORELIB_SHARED:BOOL="1" \
    -DCCCORELIB_USE_CGAL:BOOL="1" \
    -DCCCORELIB_USE_QT_CONCURRENT:BOOL="1" \
    -DCCCORELIB_USE_TBB:BOOL="0" \
    -DCGAL_DIR:PATH="${CONDA_PATH}/lib/cmake/CGAL" \
    -DCMAKE_BUILD_TYPE:STRING="RelWithDebInfo" \
    -DCMAKE_C_FLAGS="-mmacosx-version-min=12.7" \
    -DCMAKE_CXX_FLAGS="-mmacosx-version-min=12.7" \
    -DCMAKE_LD_FLAGS="-mmacosx-version-min=12.7" \
    -DCMAKE_INSTALL_PREFIX:PATH="${CLOUDCOMPY_INSTALL}" \
    -DCMAKE_INSTALL_RPATH="${CLOUDCOMPY_INSTALL}/lib;${CLOUDCOMPY_INSTALL}/CloudCompare/CloudCompare.app/Contents/Frameworks" \
    -DCMAKE_MACOSX_RPATH=ON \
    -DCONDA_LIBS:PATH="${CONDA_PATH}/lib" \
    -DCORK_INCLUDE_DIR:PATH="${CORK_REP}/src" \
    -DCORK_RELEASE_LIBRARY_FILE:FILEPATH="${CORK_REP}/lib/libcork.a" \
    -DDRACO_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DDRACO_LIB_DIR:PATH="${CONDA_PATH}/lib" \
    -DDRACO_LIBRARIES:PATH="${CONDA_PATH}/lib/libdraco.a" \
    -DEIGEN_INCLUDE_DIR:PATH="${CONDA_PATH}/include/eigen3" \
    -DEIGEN_ROOT_DIR:PATH="${CONDA_PATH}/include/eigen3" \
    -DFBX_SDK_INCLUDE_DIR:PATH="${FBXSDK_REP}/include" \
    -DFBX_SDK_LIBRARY_DIR:PATH="${FBXSDK_REP}/lib/clang/release" \
    -DFBX_SDK_LIBRARY_FILE:FILEPATH="${FBXSDK_REP}/lib/clang/release/libfbxsdk.dylib" \
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
    -DLIBIGL_INCLUDE_DIR:PATH="${LIBIGL_REP}/libigl/include" \
    -DLIBIGL_RELEASE_LIBRARY_FILE:FILEPATH="${LIBIGL_REP}/install/lib/libigl.a" \
    -DMPFR_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DMPFR_LIBRARIES:FILEPATH="${CONDA_PATH}/lib/libmpfr.dylib" \
    -DMPIR_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DMPIR_RELEASE_LIBRARY_FILE:FILEPATH="${CONDA_PATH}/lib/libgmp.dylib" \
    -DOPTION_BUILD_CCVIEWER:BOOL="0" \
    -DOPTION_USE_GDAL:BOOL="1" \
    -DOpenCV_DIR:PATH="${CONDA_PATH}/lib/cmake/opencv4" \
    -DPCL_DIR:PATH="${CONDA_PATH}/share/pcl-1.13" \
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
    -DPLUGIN_IO_QRDB_FETCH_DEPENDENCY:BOOL="1" \
    -DPLUGIN_IO_QRDB_INSTALL_DEPENDENCY:BOOL="1" \
    -DPLUGIN_IO_QSTEP:BOOL="0" \
    -DPLUGIN_STANDARD_3DMASC:BOOL="1" \
    -DPLUGIN_STANDARD_MASONRY_QAUTO_SEG:BOOL="1" \
    -DPLUGIN_STANDARD_MASONRY_QMANUAL_SEG:BOOL="1" \
    -DPLUGIN_STANDARD_QANIMATION:BOOL="1" \
    -DPLUGIN_STANDARD_QBROOM:BOOL="1" \
    -DPLUGIN_STANDARD_QCANUPO:BOOL="0" \
    -DPLUGIN_STANDARD_QCLOUDLAYERS:BOOL="1" \
    -DPLUGIN_STANDARD_QCOLORIMETRIC_SEGMENTER:BOOL="1" \
    -DPLUGIN_STANDARD_QCOMPASS:BOOL="1" \
    -DPLUGIN_STANDARD_QCORK:BOOL="1" \
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
    -DPLUGIN_STANDARD_QTREEISO:BOOL="0" \
    -Dpybind11_DIR:PATH="${CONDA_PATH}/share/cmake/pybind11" \
    -DPYTHONAPI_TEST_DIRECTORY:STRING="CloudComPy/Data" \
    -DPYTHONAPI_EXTDATA_DIRECTORY:STRING="CloudComPy/ExternalData" \
    -DPYTHONAPI_TRACES:BOOL="1" \
    -DPYTHON_PREFERED_VERSION:STRING="3.12" \
    -DQANIMATION_WITH_FFMPEG_SUPPORT:BOOL="1" \
    -DQHULL_LIBRARY_DEBUG:FILEPATH="${CONDA_PATH}/lib/libqhullcpp.a" \
    -DQHULL_LIBRARY_DEBUG_STATIC:FILEPATH="${CONDA_PATH}/lib/libqhullstatic_r.a" \
    -DQHULL_LIBRARY_SHARED:FILEPATH="${CONDA_PATH}/lib/libqhull_r.dylib" \
    -DQHULL_LIBRARY_STATIC:FILEPATH="${CONDA_PATH}/lib/libqhullstatic_r.a" \
    -DQhull_DIR:PATH="${CONDA_PATH}/lib/cmake/Qhull" \
    -DQt5LinguistTools_DIR:PATH="${CONDA_PATH}/lib/cmake/Qt5LinguistTools" \
    -DQt5Test_DIR:PATH="${CONDA_PATH}/lib/cmake/Qt5Test" \
    -DQt5OpenGL_DIR:PATH="${CONDA_PATH}/lib/cmake/Qt5OpenGL" \
    -DQt5_DIR:PATH="${CONDA_PATH}/lib/cmake/Qt5" \
    -DTBB_DIR:PATH="${CONDA_PATH}/lib/cmake/TBB" \
    -DUSE_CONDA_PACKAGES:BOOL="1" \
    -DUSE_EXTERNAL_QHULL_FOR_QHPR:BOOL="0" \
    -DXercesC_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DXercesC_LIBRARY_DEBUG:FILEPATH="${CONDA_PATH}/lib/libxerces-c.dylib" \
    -DXercesC_LIBRARY_RELEASE:FILEPATH="${CONDA_PATH}/lib/libxerces-c.dylib" \
    -DZLIB_INCLUDE_DIR:PATH="${CONDA_PATH}/include" \
    -DZLIB_LIBRARY_RELEASE:FILEPATH="${CONDA_PATH}/lib/libz.1.dylib"
}

cloudcompy_build()
{
    echo "# --- build and install CloudComPy ---"
    cd ${CLOUDCOMPY_BUILD} && make -j${NBTHREADS} && make install
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
    . bin/condaCloud.zsh activate ${CLOUDCOMPY_INSTNAME} && \
    rm -rf ~/CloudComPy/Data &&
    cd doc/PythonAPI_test && ctest
}

conda_buildenv && \
cloudcompy_setenv && \
cloudcompy_configure && \
cloudcompy_build && \
cloudcompy_tarfile && \
cloudcompy_test
