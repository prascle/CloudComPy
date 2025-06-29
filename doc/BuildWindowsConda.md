
## Build on Windows 10 or 11, with Anaconda3 or miniconda3

There are several methods to install the prerequisites on Windows 10 or 11. 
I chose to install miniconda, which is a very complete and large Python-based tools environment. 
There is a package system under miniconda, to select the products you need. It has all our prerequisites.

**Note:** CloudComPy versions released in 2024 and earlier were built using a Conda **Python 3.10** environment: **CloudComPy310**.
Now, new versions are built with a **Python 3.11** Conda environment: **CloudComPy311**

From miniconda prompt:
```
conda activate
conda update -y -n base -c defaults conda
conda create -y --name CloudComPy311 python=3.11
   # --- erase previous env with the same name if existing
conda activate CloudComPy311
conda config --add channels conda-forge
conda config --set channel_priority flexible
conda install -y "boost=1.84" "cgal=5.6" cmake "draco=1.5" "ffmpeg=6.1" "gdal=3.8" jupyterlab laszip "matplotlib=3.9" "mpir=3.0" "mysql=8" notebook numpy "opencv=4.9" "openmp=8.0" "openssl>=3.1" "pcl=1.14" "pdal=2.6" "psutil=6.0" pybind11 quaternion "qhull=2020.2" "qt=5.15.8" scipy sphinx_rtd_theme spyder tbb tbb-devel "xerces-c=3.2"
```
For information, the list of packages actually installed for building and testing can be found in [conda-list_Windows11_311](../building/conda-list_Windows11_311).

CMake from miniconda is used to get ctest at install, not for build.

To use FBX format plugin, install the FBX SDK, not provided by an miniconda package.

It is necessary to configure Visual Studio (2022) with CMake.

I don't master well the configuration and use of Visual Studio, so I tested two ways to use the Visual Studio GUI, 
without knowing if there is a better way to take into account the prerequisites in the Visual Studio environment.

- 1: Launch the Visual Studio GUI as is, without any additions, and give all the necessary paths for the prerequisites.

- 2: Launch the Visual Studio GUI from the `miniconda Prompt (miniconda3)` console with the command: 
`"C:\Program Files (x86)\Microsoft Visual Studio\2022\Community\Common7\IDE\devenv.exe"`. 

With the miniconda environment, many paths and variables are found automatically. 
In both cases, it is necessary to provide some configuration variables to CMake. 
With Visual Studio, these variables can be filled in a json file, which is read during the configuration step. 
I suppose it is also possible to install cmake-gui to do the same.

The following plugins require to install specific libraries, not packaged. You can deactivate these plugins in the json file if you don't want to rebuild
the libraries...

    PLUGIN_STANDARD_QCORK see Cork for boolean operation
    PLUGIN_STANDARD_QMESH_BOOLEAN 
    PLUGIN_IO_QFBX for Autodesk format, see file I/O and above
    PLUGIN_IO_QSTEP for step format (OpenCascade libraries)

My [CMakeSettings.json](../CMakeSettings.json) file used to build CloudComPy is in the source package.

After the installation step, it is in any case necessary to load the miniconda environment (miniconda Prompt console) 
for Python and Numpy to be correctly configured.

The tests are installed in `<install-dir>/doc/PythonAPI_test`, with shell scripts to set the `PYTHONPATH` and launch one test.
When in `<install-dir>/doc/PythonAPI_test`, `ctest` launches all the tests. 

The CloudCompare GUI is installed in  `<install-dir>/bin/CloudCompare`, and works as usual. 
