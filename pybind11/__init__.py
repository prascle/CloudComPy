#!/usr/bin/env python3

##########################################################################
#                                                                        #
#                              CloudComPy                                #
#                                                                        #
#  This program is free software; you can redistribute it and/or modify  #
#  it under the terms of the GNU General Public License as published by  #
#  the Free Software Foundation; either version 3 of the License, or     #
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
#          Copyright 2020-2025 Paul RASCLE www.openfields.fr             #
#                                                                        #
##########################################################################

"""
cloudComPy is the Python module interfacing cloudCompare library.
Python3 access to cloudCompare objects is done like this:
::

  import cloudComPy as cc 
  cc.initCC()  # to do once before using plugins
  cloud = cc.loadPointCloud("/home/paul/CloudComPy/Data/boule.bin")
 
"""
import os
cloudComPyInstallDir = os.path.dirname(__file__)
os.environ["QT_QPA_PLATFORM_PLUGIN_PATH"]=os.path.join(cloudComPyInstallDir, "plugins")
print("QT_QPA_PLATFORM_PLUGIN_PATH", os.environ["QT_QPA_PLATFORM_PLUGIN_PATH"])

#Available platform plugins are: eglfs, linuxfb, minimal, minimalegl, offscreen, vnc, wayland-egl, wayland, wayland-xcomposite-egl, wayland-xcomposite-glx, webgl, xcb.
os.environ["QT_QPA_PLATFORM"]="offscreen"
print("QT_QPA_PLATFORM", os.environ["QT_QPA_PLATFORM"])

os.environ["QT_XCB_GL_INTEGRATION"]="none" # 3 possibles values : xcb_egl, xcb_glx, none
print("QT_XCB_GL_INTEGRATION", os.environ["QT_XCB_GL_INTEGRATION"])

from ._cloudComPy import *
initCC()
initCloudCompare()

def launchCloudCompareGUI():
    """
    Launch the CloudCompare GUI in a subprocess, and return immediately.
    """
    import subprocess
    subprocess.Popen(os.path.join(cloudComPyInstallDir, "CloudCompare"))
    
def launchTests():
    """
    Launch the cloudComPy Python tests
    """
    import subprocess
    oldCWD = os.getcwd()
    os.chdir(os.path.join(cloudComPyInstallDir,"doc/PythonAPI_test"))
    subprocess.run("ctest")
    os.chdir(oldCWD)
