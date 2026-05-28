## Installing, testing and using a CloudComPy binary on MacOS, with conda

**Note:** CloudComPy versions released in 2025 and earlier were built using a **Conda** **Python 3.10** or **Python 3.11** environment: **CloudComPy310** or  **CloudComPy311**.

The binary *CloudComPy_Conda312_MacOS-date-.zip* available [here](https://www.simulation.openfields.fr/index.php/cloudcompy-downloads)
 is built with a Conda environment.

**This binary works only on macOS Apple arm64 architecture (not on Intel processors), on recent macOS versions, not anywhere else!**

**Built and tested on macOS Tahoe 26.5.
Please post issues on CloudComPy [GitHub](https://github.com/CloudCompare/CloudComPy/issues) in case of problem**

The macOS binary provides **CloudCompare** and **CloudCompy** (same as binaries for Windows and Linux).

As CloudComPy is under development, these instructions and the link are subject to change from time to time...

**CloudCompare** works as it is (no specific environment).
It is located in CloudComPy312/CloudCompare/CloudCompare.app and can be launched from the Finder.

**CloudComPy** needs a Python 3.12 configuration with at least the following packages, either with aPython virtual env or with conda:

```
numpy
scipy
requests
psutils
matplotlib
numpy-quaternion
cmake
```


Create a Python virtual environment with venv (*adapt the path for Your Python 3.12 install and for the virtual env*). In the terminal :

```
path/to/python3.12 -m venv ${HOME}/.venv312
source ${HOME}/.venv312/bin/activate
python3 -m pip install --upgrade pip
pip install numpy scipy requests psutil matplotlib numpy-quaternion cmake
```

Unzip the CloudcomPy binary in the directory of your choice.

### Using CloudCompare and CloudComPy:

CloudCompare is located in `CloudComPy311/CloudCompare/CloudCompare.app` and can be launched from the Finder.

CloudcomPy requires to set the Python environment and the PYTHONPATH.

Before using CloudComPy, you need to load the environment, with 2 steps :

 - The Python virtual environment:

```
source ${HOME}/.venv312/bin/activate
```

 - The paths (PYTHONPATH, PATH) required for cloudComPy and CloudCompare:

```
cd path/to/CloudComPy312
source bin/envCloudComPyMacOS.zsh activate
```


To execute a Python script (for instance myscript.py) using CloudComPy:

```
python myscript.py
```

### Execute all the Python tests:

In the above Python environment:

```
cd  <path install>/doc/PythonAPI_test
```

To execute all the tests (takes about five minutes, creates about 2GB of data files):

```
ctest
```

The files created with the tests are in your user space: `${HOME}/CloudComPy/Data`


 