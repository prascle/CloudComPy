
## Build on Windows 11, with miniconda3

Miniconda provide almost all the prerequisite packages used to build cloudComPy.
Only a few CloudCompare plugins require some libraries not provided in the conda packages.
We do not use QT6 from Conda but a separate installation of the latest Qt6 sources (Qt6.10.2)

The conda environment is built with a script : ```building/genEnv312Qt6.bat```. adapt the script with your cloudComPy source path.
The package configuration is given in ```CloudComPy312Qt6_Ubuntu.yml``` (same set of packages in Linux build).

```
cd cloudComPy\CloudComPy\building
conda install -y -n base mamba -c conda-forge
mamba update -y -n base -c defaults conda
conda activate base

mamba env create -y -n CloudComPy312 -f CloudComPy312Qt6_Ubuntu.yml
```

You also need to build a small Python Venv to create a minimal Python environment used to build the documentation and run the tests.
You have to adapt the script to set the path of Python 3.12 and the path of your venv.

```
cd "%USERPROFILE%\AppData\Local\Programs\Python\Python312"
rmdir /S /Q "%USERPROFILE%\CloudComPy\venv312doc"
python -m venv "%USERPROFILE%\CloudComPy\venv312doc"
cd "%USERPROFILE%\CloudComPy"
venv312doc\Scripts\activate
%USERPROFILE%\CloudComPy\venv312doc\Scripts\python.exe -m pip install --upgrade pip
pip install numpy requests psutil scipy sphinx_rtd_theme numpy-quaternion cmake matplotlib
```

To build the Windows cloudComPy binaries, you need an MSVC installation up to date (Visual Studio 2026), and PowerShell 7.
The ```build.ps1``` PowerShell 7 script needs to activate the conda environment before execution.

In  ```build.ps1```, you have to edit the ```LOCAL CONFIGURATION ``` section, and cmakeargs to select the plugins you want.

From the PowerShell terminal:

```
conda activate CloudComPy312
cd <your cloudComPy sources>
.\build.ps1 --all
```
## Notes on plugins

To use FBX format plugin, install the FBX SDK, not provided by an miniconda package.

The following plugins require to install specific libraries, not packaged. 
You can deactivate these plugins in cmakeargs if you don't want to rebuild the libraries...

    PLUGIN_STANDARD_QCORK see Cork for boolean operation
    PLUGIN_STANDARD_QMESH_BOOLEAN requires libigl
    PLUGIN_IO_QFBX for Autodesk format, see file I/O and above

