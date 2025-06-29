## Installing, testing and using a CloudComPy binary on Linux, with conda

The binary *CloudComPy_Conda311_Linux64_-date-.tgz* available [here](https://www.simulation.openfields.fr/index.php/cloudcompy-downloads) is built with a Conda environment
(see [here](BuildLinuxConda.md) for the corresponding building instructions).

As CloudComPy is under development, these instructions and the link are subject to change from time to time...

**This binary works only on Linux 64, on recent distributions, and with a Conda environment as described below, not anywhere else!**

**Only tested un Ubuntu 20.04 (focal) and Ubuntu 24.04, please report any problems on other distributions.**

GLIBC version should be 2.29 or more. To know your version of GLIBC:

```
ldd --version
```

You need a recent installation of Anaconda3 or miniconda3.

You need to create an environment for CloudComPy with conda, from the terminal
(here, I chose to activate conda environment on demand: please adapt the instructions to your installation):

**Note:** CloudComPy versions released in 2024 and earlier were built using a Conda **Python 3.10** environment: **CloudComPy310**.
Now, new versions are built with a **Python 3.11** Conda environment: **CloudComPy311**

```
conda activate
conda update -y -n base -c defaults conda
```
If your environment CloudComPy311 does not exist or to recreate it from scratch:
(**note:** it's best to recreate the environment from time to time, as conda packages are often updated)
```
conda create -y --name CloudComPy311 python=3.11
   # --- erase previous env with the same name if existing
```
Add or update the packages:
```
conda activate CloudComPy311
conda config --add channels conda-forge
conda config --set channel_priority flexible
conda install -y "boost=1.84" "cgal=5.6" cmake "draco=1.5" "ffmpeg=6.1" "gdal=3.8" jupyterlab laszip "matplotlib=3.9" "mpir=3.0" "mysql=8" notebook numpy "opencv=4.9" "openmp=8.0" "openssl>=3.1" "pcl=1.14" "pdal=2.6" "psutil=6.0" pybind11 quaternion "qhull=2020.2" "qt=5.15.8" scipy sphinx_rtd_theme spyder tbb tbb-devel "xerces-c=3.2"
```

**Remark:** if conda is unknown, or in a bash script, add the following instruction before conda commands:

```
. <conda_dir>/etc/profile.d/conda.sh
```
where `<conda_dir>` is the installation directory of conda (often `~/anaconda3` or `~/miniconda3`)

Install the binary in the directory of your choice.

### Using CloudCompare and CloudComPy:

Before using CloudCompare or CloudComPy, you need to load the environment. 
The script `bin/condaCloud.sh` overrides the conda command for activation and deactivation, it must be sourced. 

From a new prompt (replace `<path install>` by its value): 

```
. <path install>/bin/condaCloud.sh activate CloudComPy311
```

if conda is unknown, execute the following instruction before:

```
. <conda_dir>/etc/profile.d/conda.sh
```
where `<conda_dir>` is the installation directory of conda (often `~/anaconda3` or `~/miniconda3`)

Have a look on the script usage:
```
. <path install>/bin/condaCloud.sh
```

To run CloudCompare:

```
CloudCompare
```

To execute a Python script (for instance myscript.py) using CloudComPy:

```
python myscript.py
```
**Remark**: You may need to install libomp.so.5:
```
sudo apt-get install libomp5

```
The IDE [Spyder](https://www.spyder-ide.org/) and [Jupyter](https://jupyter.org/) can be launched in this environment:

```
spyder
```

```
jupyter notebook
```

An example of notebook is provided in ```doc/samples/histogramOnDistanceComputation.ipynb```.

### Execute all the Python tests:

```
. <path install>/bin/condaCloud.sh activate CloudComPy311
cd  <path install>/doc/PythonAPI_test
```

To execute all the tests (takes about three minutes, creates about 1.3GB of data files):

```
ctest
```

The files created with the tests are in your user space: `${HOME}/CloudComPy/Data`

From the prompt, you can :

### In case of problem:

There may be differences in the versions of conda packages. When updating the conda configuration, the package versions may change slightly.
This is usually not a problem, but since the CloudComPy binary is fixed, there may be a version difference on a package, 
which makes it incompatible with CloudComPy. For your information, here is the list of package versions when CloudComPy was built.

The result of ```conda list``` command is provided in the doc directory of the binary package or, in the sources, in [building directory](../building)
