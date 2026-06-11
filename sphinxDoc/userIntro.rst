
============================
Introduction
============================

------------------------------
Set the CloudComPy environment
------------------------------

Before importing CloudComPy, you need to configure and load the required environment, 
mainly the PATH and PYTHONPATH used by the different executables, library and Python modules.

You should read the installation instructions in your CloudComPy installation, in the doc directory,
or on `GitHub <https://github.com/CloudCompare/CloudComPy#readme>`_.

The Python 3.12 environment must contain at least the following packages:
::

    numpy requests psutil scipy numpy-quaternion cmake matplotlib

Windows
~~~~~~~

The Windows packaging provides a batch file to call after loading the Python environment. From the prompt:
::

    cd <path install>\CloudComPy312
    envCloudComPy.bat


Linux
~~~~~

The Linux packaging provides a shell script to call after loading the Python environment. From the terminal:
::

    cd <path install>/CloudComPy312
    . bin/envCloudComPy.sh activate

macOS
~~~~~

The macOS environment is similar to the Linux one. After loading the Python environment, from the terminal:
::

    cd <path install>/CloudComPy312
    . bin/envCloudComPyMacOS.zsh activate


--------------------------
Python3: CloudComPy import
--------------------------

The starting sequence is:
::

    import os
    os.environ["_CCTRACE_"]="ON"          # only if you want debug traces from C++
    import cloudComPy as cc               # import the CloudComPy module

It is no longer necessary to call ``initCC`` to discover all the CloudCompare plugins, this is done automatically at import.
::

    cc.initCC()  # done automatically at import, before using plugins

-----------------------
Useful commands
-----------------------

Launch the tests
~~~~~~~~~~~~~~~~

The :py:func:`cloudComPy.launchTests` function allows you to launch the tests provided with CloudComPy, and check that everything is working correctly.
::

    cc.launchTests()

The tests takes about 3 minutes to complete and create files (2.2 Go) under the ``CloudComPy/Data`` and ``CloudComPy/ExternalData`` 
subdirectories of your Home. 

Launch the documentation in a web browser
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

The :py:func:`cloudComPy.launchDoc` function allows you to launch the documentation in a web browser.
::

    cc.launchDoc()

Launch the cloudCompare GUI
~~~~~~~~~~~~~~~~~~~~~~~~~~~

The :py:func:`cloudComPy.launchCloudCompareGUI` function allows you to launch the CloudCompare GUI.
::

    cc.launchCloudCompareGUI()
