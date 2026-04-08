## Installing, testing and using a CloudComPy binary on Windows 10 or 11 in a Python 3.12 environment

The binary *CloudComPy\*_-date-.7z* available [here](https://www.simulation.openfields.fr/index.php/cloudcompy-downloads) is built in a Conda environment.
(see [here](BuildWindowsConda.md) for the corresponding building instructions).

As CloudComPy is still under development, these instructions and the link are subject to change from time to time...

**This binary works only on Windows 10 or 11, and with a (virtual) Python 3.12 environment as described below**.

**Note:** CloudComPy versions released in 2025 and earlier were built using a **Conda** **Python 3.10** or **Python 3.11** environment: **CloudComPy310** or  **CloudComPy311**.
Now, new versions require only a **Python 3.12** environment. **Conda is not needed anymore**, unless you want it to provide your Python packages.

The Python 3.12 environment must contain the following packages to run all the tests : 
```numpy requests psutil scipy numpy-quaternion cmake matplotlib```

Create a Python virtual environment with venv (*adapt the path for Your Python 3.12 install and for the virtual env*). In the Command Prompt (```cmd```) :

```
cd "%USERPROFILE%\AppData\Local\Programs\Python\Python312"
python -m venv "%USERPROFILE%\CloudComPy\venv312"
cd "%USERPROFILE%\CloudComPy"
venv312\Scripts\activate
pip install numpy requests psutil scipy numpy-quaternion cmake matplotlib
```

Unzip the cloudComPy binary in the directory of your choice. 

### Using CloudCompare and CloudComPy:

From the Command Prompt, activate the Python venv, cd to the cloudComPy install and launch envCloudComPy.bat, to set the CloudComPy PATH and PYTHONPATH.

```
cd %USERPROFILE%\CloudComPy
venv312\Scripts\activate
cd install\CloudComPy312
envCloudComPy.bat
```

To run CloudCompare:

```
CloudCompare
```

To execute a Python script (for instance myscript.py) using CloudComPy:

```
python myscript.py
```

The IDE [Spyder](https://www.spyder-ide.org/) and [Jupyter](https://jupyter.org/) can be launched in this environment:

```
spyder
```
The first time you run Spyder, you may need to add the paths to CloudCompare and the test scripts to the PYTHONPATH,
using the menu Tools / PYTHONPATH Manager. These paths are the same as those defined in the envCloudComPy.bat script.

```
jupyter notebook
```

An example of notebook is provided in ```doc/samples/histogramOnDistanceComputation.ipynb```.

### Execute all the Python tests:

In the virtual environment above :
```
cd  <path install>\CloudComPy312\doc\PythonAPI_test
```
NB: ```envCloudComPy.bat``` is OK but not mandatory here, ```ctest``` resets the necessary paths

To execute all the tests (takes about three minutes, creates about 1.3GB of data files):

```
ctest
```

The files created with the tests are in your user space: %USERPROFILE%\CloudComPy\data

### In case of problem:

The ```envCloudComPy.bat``` file checks whether cloudComPy has been imported into your Python environment. If everything is in order, it displays ```Environment OK!```. Otherwise, there may be a conflict between the Qt6 libraries included in the cloudComPy package and any Qt6 libraries provided by your Python environment. 