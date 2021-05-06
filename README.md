# CloudComPy
Python wrapper for CloudCompare

## What is CloudComPy?
This project is a draft of what could be a Python module to interface to CloudCompare, 
of equivalent level to the command mode of CloudCompare.

There are still few features available in this prototype, 
the idea is to collect feedback from interested users to guide future developments.

Here is an example of a Python script:

```
import cloudComPy as cc                                                # import the CloudComPy module
cc.initCC()                                                            # to do once before dealing with plugins

cloud = cc.loadPointCloud("myCloud.xyz")                               # read a point cloud from a file
print("cloud name: %s"%cloud.getName())

res=cc.computeCurvature(cc.CurvatureType.GAUSSIAN_CURV, 0.05, [cloud]) # compute curvature as a scalar field
nsf = cloud.getNumberOfScalarFields()
sfCurv=cloud.getScalarField(nsf-1)
cloud.setCurrentOutScalarField(nsf-1)
filteredCloud=cc.filterBySFValue(0.01, sfCurv.getMax(), cloud)         # keep only the points above a given curvature

ok = filteredCloud.exportCoordToSF(False, False, True)                 # Z coordinate as a scalar Field
nsf = cloud.getNumberOfScalarFields()
sf1=filteredCloud.getScalarField(nsf-1)
mean, var = sf1.computeMeanAndVariance()

# using Numpy...

coordinates = filteredCloud.toNpArrayCopy()                            # coordinates as a numpy array
x=coordinates[:,0]                                                     # x column
y=coordinates[:,1]
z=coordinates[:,2]

f=(2*x-y)*(x+3*y)                                                      # elementwise operation on arrays

asf1=sf1.toNpArray()                                                   # scalar field as a numpy array
sf1.fromNpArrayCopy(f)                                                 # replace scalar field values by a numpy array

res=cc.SavePointCloud(filteredCloud,"myModifiedCloud.bin")             #save the point cloud to a file
```

As you can see, it is possible to read and write point clouds, 
access scalar fields from Numpy (with or without copy of data), call some CloudCompare functions to transform point clouds.

The list of available functions should quickly grow.

From the Python interpreter, Docstrings provide some documentation on the available methods, the arguments.

## how to build CloudComPy?

Prerequisites for CloudComPy are Python3, BoostPython and Numpy plus, of course, everything needed to build CloudCompare.

With CloudComPy you build CloudCompare and the associated Python module.

Compilation is done with CMake, minimum version 3.10, recommended version 3.13 or newer (a lot of false warnings with 3.10).

### prerequisites versions
The minimum required version of each prerequisite is not always precisely identified. Examples of constructions that work are given here.

First example: Linux, Ubuntu 20.04, all native packages.

Second example: Windows 10, Visual Studio 2019, Anaconda3 to get all the prerequisites plus a lot more...


| Platform | Linux Ubuntu 20.04 (clang 10) | Windows 10 Visual Studio 2019 | minimum |
| -------- | ----------------------------- | ------------------------------| ------- |
| Qt       | 5.12.8                        | 5.9.7                         | 5.9 ?   |
| Python   | 3.8.5                         | 3.7.10                        | 3.6     |
| Boost    | 1.71                          | 1.68                          | 1.68 ?  |
| Numpy    | 1.17.4                        | 1.20.2                        | 1.13 ?  |



### Ubuntu 20.04

On Ubuntu 20.04, you can install the development versions of the prerequisites with:
TODO: complete the list...

```
sudo apt-get intall qtbase5-dev python3 libpython3-dev python3-numpy cmake
```
To run tests on memory usage, you need the python3 package python3-psutil.

Commandline options (adapt the paths):

```
-DPYTHONAPI_TRACES:BOOL="1" -DFBX_SDK_INCLUDE_DIR:PATH="" -DCMAKE_INSTALL_PREFIX:PATH="/home/paul/projets/CloudComPy/installRelease" -DPLUGIN_GL_QSSAO:BOOL="1" -DPYTHON_PREFERED_VERSION:STRING="3.8" -DPLUGIN_IO_QADDITIONAL:BOOL="1" -DPLUGIN_IO_QFBX:BOOL="0" -DPLUGIN_STANDARD_QRANSAC_SD:BOOL="1" -DPLUGIN_EXAMPLE_STANDARD:BOOL="1" -DPLUGIN_IO_QPHOTOSCAN:BOOL="1" -DPLUGIN_STANDARD_QPOISSON_RECON:BOOL="1" -DPLUGIN_GL_QEDL:BOOL="1" -DPLUGIN_STANDARD_QM3C2:BOOL="1" -DPLUGIN_STANDARD_QMPLANE:BOOL="1" -DOPTION_USE_GDAL:BOOL="1" -DPLUGIN_EXAMPLE_IO:BOOL="1" -DCMAKE_BUILD_TYPE:STRING="RelWithDebInfo" -DPLUGIN_IO_QE57:BOOL="1" -DBUILD_TESTING:BOOL="1" -DPYTHONAPI_TEST_DIRECTORY:STRING="/home/paul/projets/CloudComPy/data" -DPLUGIN_STANDARD_QCOMPASS:BOOL="1" -DPLUGIN_IO_QCSV_MATRIX:BOOL="1" -DPLUGIN_STANDARD_QPCL:BOOL="1" -DPLUGIN_EXAMPLE_GL:BOOL="1" -DPLUGIN_STANDARD_QBROOM:BOOL="1" -DBUILD_PY_TESTING:BOOL="1"
```

Options to set with cmake-gui or ccmake (adapt the paths):

```
BUILD_PY_TESTING:BOOL=1
BUILD_TESTING:BOOL=1
CMAKE_BUILD_TYPE:STRING=RelWithDebInfo
CMAKE_INSTALL_PREFIX:PATH=/home/paul/projets/CloudComPy/installRelease
FBX_SDK_INCLUDE_DIR:PATH=
OPTION_USE_GDAL:BOOL=1
PLUGIN_EXAMPLE_GL:BOOL=1
PLUGIN_EXAMPLE_IO:BOOL=1
PLUGIN_EXAMPLE_STANDARD:BOOL=1
PLUGIN_GL_QEDL:BOOL=1
PLUGIN_GL_QSSAO:BOOL=1
PLUGIN_IO_QADDITIONAL:BOOL=1
PLUGIN_IO_QCSV_MATRIX:BOOL=1
PLUGIN_IO_QE57:BOOL=1
PLUGIN_IO_QFBX:BOOL=0
PLUGIN_IO_QPHOTOSCAN:BOOL=1
PLUGIN_STANDARD_QBROOM:BOOL=1
PLUGIN_STANDARD_QCOMPASS:BOOL=1
PLUGIN_STANDARD_QM3C2:BOOL=1
PLUGIN_STANDARD_QMPLANE:BOOL=1
PLUGIN_STANDARD_QPCL:BOOL=1
PLUGIN_STANDARD_QPOISSON_RECON:BOOL=1
PLUGIN_STANDARD_QRANSAC_SD:BOOL=1
PYTHONAPI_TEST_DIRECTORY:STRING=/home/paul/projets/CloudComPy/data
PYTHONAPI_TRACES:BOOL=1
PYTHON_PREFERED_VERSION:STRING=3.8
```
After the CMake configuration and generation, run make (adapt the parallel option -j to your processor):

```
make -j12 && make test && make install
```

`make test` creates Point Cloud datasets and executes Python tests scripts using the cloudCompare module.
The tests are installed in `<install-dir>/doc/PythonAPI_test`, with shell scripts to set the `PYTHONPATH` and launch one test.
When in `<install-dir>/doc/PythonAPI_test`, `ctest` launches all the tests. 

The CloudCompare GUI is installed in  `<install-dir>/bin/CloudCompare`, and works as usual.	

### Windows 10

There are several methods to install the prerequisites on Windows 10. 
I chose to install Anaconda, which is a very complete and large Python-based tools environment. 
There is a package system under Anaconda, to select the products you need. It has all our prerequisites.

From Anaconda prompt:
```
conda activate
conda create --name CloudComPy37 python=3.7
conda activate CloudComPy37
conda config --add channels conda-forge
conda config --set channel_priority strict
conda install qt=5.9.7 numpy psutil boost=1.68 xerces-c pcl gdal cgal cmake
```
CMake from Anaconda is used to get ctest at install, not for build.

It is necessary to configure Visual Studio 2019 with CMake.

I don't master well the configuration and use of Visual Studio, so I tested two ways to use the Visual Studio GUI, 
without knowing if there is a better way to take into account the prerequisites in the Visual Studio environment.

- 1: Launch the Visual Studio GUI as is, without any additions, and give all the necessary paths for the prerequisites.

- 2: Launch the Visual Studio GUI from the `Anaconda Prompt (Anaconda3)` console with the command: 
`"C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\Common7\IDE\devenv.exe"`. 

With the Anaconda environment, many paths and variables are found automatically. 
In both cases, it is necessary to provide some configuration variables to CMake. 
With Visual Studio, these variables can be filled in a json file, which is read during the configuration step. 
I suppose it is also possible to install cmake-gui to do the same.

Here are my json file, for the first method, with the plugins availables with Anaconda packages:

```
{
  "configurations": [
    {
      "name": "x64-Release",
      "generator": "Ninja",
      "configurationType": "RelWithDebInfo",
      "inheritEnvironments": [ "msvc_x64_x64" ],
      "buildRoot": "C:/Users/paulr/CloudComPy_v212x/build/${name}",
      "installRoot": "C:/Users/paulr/CloudComPy_v212x/install/CloudComPy37_bnf",
      "cmakeCommandArgs": "",
      "buildCommandArgs": "-v",
      "ctestCommandArgs": "",
      "variables": [
        {
          "name": "Qt5_DIR",
          "value": "C:/Users/paulr/anaconda3/envs/CloudComPy37/Library/lib/cmake/Qt5",
          "type": "STRING"
        },
        {
          "name": "Qt5LinguistTools_DIR",
          "value": "C:/Users/paulr/anaconda3/envs/CloudComPy37/Library/lib/cmake/Qt5LinguistTools",
          "type": "STRING"
        },
        {
          "name": "QT5_ROOT_PATH",
          "value": "C:/Users/paulr/anaconda3/envs/CloudComPy37/Library",
          "type": "STRING"
        },
        {
          "name": "BOOST_INCLUDEDIR",
          "value": "C:/Users/paulr/anaconda3/envs/CloudComPy37/Library/include",
          "type": "STRING"
        },
        {
          "name": "BOOST_LIBRARYDIR",
          "value": "C:/Users/paulr/anaconda3/envs/CloudComPy37/Library/lib",
          "type": "STRING"
        },
        {
          "name": "Boost_DEBUG:BOOL",
          "value": "OFF",
          "type": "STRING"
        },
        {
          "name": "Python3_ROOT_DIR",
          "value": "C:/Users/paulr/anaconda3/envs/CloudComPy37",
          "type": "STRING"
        },
        {
          "name": "PYTHON_PREFERED_VERSION:STRING",
          "value": "3.7",
          "type": "STRING"
        },
        {
          "name": "NUMPY_INCLUDE_DIR",
          "value": "C:/Users/paulr/anaconda3/envs/CloudComPy37/Lib/site-packages/numpy/core/include",
          "type": "STRING"
        },
        {
          "name": "PYTHONAPI_TEST_DIRECTORY",
          "value": "CloudComPy/data",
          "type": "STRING"
        },
        {
          "name": "PYTHONAPI_TRACES:BOOL",
          "value": "ON",
          "type": "STRING"
        },
        {
          "name": "INSTALL_PREREQUISITE_LIBRARIES",
          "value": "OFF",
          "type": "STRING"
        },
        {
          "name": "BUILD_PY_TESTING:BOOL",
          "value": "ON",
          "type": "STRING"
        },
        {
          "name": "BUILD_TESTING:BOOL",
          "value": "ON",
          "type": "STRING"
        },
        {
          "name": "OPTION_SCALAR_DOUBLE:BOOL",
          "value": "OFF",
          "type": "STRING"
        },
        {
          "name": "CCCORELIB_USE_CGAL",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "CCCORELIB_USE_QT_CONCURRENT",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "OPTION_USE_GDAL",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "OPTION_USE_SHAPE_LIB",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_EXAMPLE_GL",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_EXAMPLE_IO",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_EXAMPLE_STANDARD",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_GL_QEDL",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_GL_QSSAO",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_IO_QADDITIONAL",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_IO_QCORE",
          "value": "true",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_IO_QCSV_MATRIX",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_IO_QPHOTOSCAN",
          "value": "False",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_STANDARD_QBROOM",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_STANDARD_QCOMPASS",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_STANDARD_QM3C2",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_STANDARD_QPCL",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_STANDARD_QPOISSON_RECON",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_STANDARD_QRANSAC_SD",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "PLUGIN_STANDARD_QSRA",
          "value": "True",
          "type": "BOOL"
        },
        {
          "name": "CGAL_DIR",
          "value": "C:/Users/paulr/anaconda3/envs/CloudComPy37/Library",
          "type": "PATH"
        },
        {
          "name": "GMP_INCLUDE_DIR",
          "value": "C:/Users/paulr/anaconda3/envs/CloudComPy37/Library/include",
          "type": "PATH"
        },
        {
          "name": "GMP_LIBRARIES",
          "value": "C:/Users/paulr/anaconda3/envs/CloudComPy37/Library/lib/mpir.lib",
          "type": "FILEPATH"
        },
        {
          "name": "MPFR_INCLUDE_DIR",
          "value": "C:/Users/paulr/anaconda3/envs/CloudComPy37/Library",
          "type": "PATH"
        },
        {
          "name": "MPFR_LIBRARIES",
          "value": "C:/Users/paulr/anaconda3/envs/CloudComPy37/Library/lib/mpfr.lib",
          "type": "FILEPATH"
        },
        {
          "name": "TBB_INCLUDE_DIRS",
          "value": "C:/Users/paulr/anaconda3/envs/CloudComPy37/Library/include",
          "type": "PATH"
        },
        {
          "name": "ZLIB_INCLUDE_DIRS",
          "value": "C:/Users/paulr/anaconda3/envs/CloudComPy37/Library",
          "type": "PATH"
        },
        {
          "name": "ZLIB_LIBRARIES",
          "value": "C:/Users/paulr/anaconda3/Library/lib/zlib.lib",
          "type": "FILEPATH"
        }
      ]
    }
  ]
}
```

After the installation step, it is in any case necessary to load the Anaconda environment (Anaconda Prompt console) 
for Python and Numpy to be correctly configured.

The tests are installed in `<install-dir>/doc/PythonAPI_test`, with shell scripts to set the `PYTHONPATH` and launch one test.
When in `<install-dir>/doc/PythonAPI_test`, `ctest` launches all the tests. 

The CloudCompare GUI is installed in  `<install-dir>/bin/CloudCompare`, and works as usual. 

There is still a lot of work to do to make a correct packaging, but it is already possible to test the Python interface.

In addition to feedback on the interface itself and the extensions to be made, I take advice on best practices 
for configuration and use of Visual Studio tools :-)
