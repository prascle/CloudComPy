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

# - Find PYQT and SIP
# Sets the following variables:
#   PYQT_PYUIC_EXECUTABLE  - path to pyuic5 script           : pyuic5
#   PYQT_PYRCC_EXECUTABLE  - path to pyrcc5 script           : pyrcc5
#   PYQT_PYTHONPATH        - path to PyQt5 Python module
#   SIP_EXECUTABLE         - path to the SIP executable      : sip
#   SIP_INCLUDE_DIR        - path to the SIP headers         : sip.h
#   SIP_PYTHONPATH         - path to the SIP Python packages : sipconfig.py (not required)
#   PYQT_SIPFLAGS
#

if(NOT PYQTSIP_FIND_QUIETLY)
  message(STATUS "Looking for PYQT5 and SIP ...")
endif()

find_program(PYQT_PYUIC_EXECUTABLE NAMES pyuic5 pyuic5.bat DOC "full path of pyuic5 script")
find_program(PYQT_PYRCC_EXECUTABLE NAMES pyrcc5 pyrcc5.bat DOC "full path of pyrcc5 script")

execute_process(COMMAND ${Python3_EXECUTABLE} -c
"
import sys
hints=' '.join(sys.path)
sys.stdout.write(hints)
"
COMMAND_ECHO STDOUT
RESULT_VARIABLE RESULT_tmpPythonPath
OUTPUT_VARIABLE _tmpPythonPath)
#message(STATUS "  RESULT_tmpPythonPath: " ${RESULT_tmpPythonPath})
#message(STATUS "  _tmpPythonPath: " ${_tmpPythonPath})

separate_arguments(_tmpPythonPath)
find_path(PYQT_PYTHONPATH PyQt5/__init__.py HINTS ${_tmpPythonPath} DOC "directory path of PyQt5 Python module")
message(STATUS "  PYQT_PYTHONPATH: " ${PYQT_PYTHONPATH})

find_program(SIP_EXECUTABLE sip DOC "full path of executable: sip")
message(STATUS "SIP_EXECUTABLE: " ${SIP_EXECUTABLE})

find_path(SIP_INCLUDE_DIR sip.h PATH_SUFFIXES python${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR} DOC "directory path of include: sip.h")
message(STATUS "SIP_INCLUDE_DIR: " ${SIP_INCLUDE_DIR})

find_path(PYQT_SIPS QtGui/QtGuimod.sip HINTS "/usr/share/sip/PyQt5" DOC "directory path of QtGui/QtGuimod.sip")
message(STATUS "PYQT_SIPS: " ${PYQT_SIPS})

if(SIP_INCLUDE_DIR)
    get_filename_component(SIP_PYTHONPATH "${SIP_INCLUDE_DIR}" PATH)
    get_filename_component(SIP_PYTHONPATH "${SIP_PYTHONPATH}" PATH)
    set(SIP_PYTHONPATH "${SIP_PYTHONPATH}/lib/python${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}/site-packages")
    message(STATUS "SIP_PYTHONPATH: " ${SIP_PYTHONPATH})
endif()

set(TEST_SCRIPT
"
import sys
sys.path[:0] = '${PYQT_PYTHONPATH}'.split(';')
from PyQt5.QtCore import PYQT_CONFIGURATION
sys.stdout.write(PYQT_CONFIGURATION['sip_flags'])
"
)
#message(STATUS "  TEST_SCRIPT: " "${TEST_SCRIPT}")

execute_process(COMMAND ${Python3_EXECUTABLE} -c "${TEST_SCRIPT}"
RESULT_VARIABLE RESULT_PYQT_SIPFLAGS
OUTPUT_VARIABLE PYQT_SIPFLAGS
ERROR_VARIABLE ERROR_PYQT_SIPFLAGS)
#message(STATUS "RESULT_PYQT_SIPFLAGS: " ${RESULT_PYQT_SIPFLAGS})
#message(STATUS "ERROR_PYQT_SIPFLAGS: " ${ERROR_PYQT_SIPFLAGS})
if (RESULT_PYQT_SIPFLAGS)
    message(STATUS "detection of PyQt sipflags using a Python script does not work: alternate method")
    # error on Python script execution, probably because Python environnement is not set
	set(_SIP_QT_VERSION Qt_${Qt5Core_VERSION_MAJOR}_${Qt5Core_VERSION_MINOR}_${Qt5Core_VERSION_PATCH})
	if (WIN32)
	    set(_SIP_PLATFORM WS_WIN)
	else()
	    set(_SIP_PLATFORM WS_X11)
	endif()
	set(PYQT_SIPFLAGS "-t ${_SIP_PLATFORM} -t ${_SIP_QT_VERSION}")
endif()

separate_arguments(PYQT_SIPFLAGS)

set(PYQT_SIPFLAGS ${PYQT_SIPFLAGS} -I "${PYQT_SIPS}")
message(STATUS "  PYQT_SIPFLAGS: " "${PYQT_SIPFLAGS}")

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(PYQTSIP REQUIRED_VARS PYQT_PYUIC_EXECUTABLE SIP_INCLUDE_DIR SIP_EXECUTABLE PYQT_SIPFLAGS)
