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

# --- PYMINOR derivation (audit J2a, section 8.3):
# PYMINOR feeds only the conda-list filenames below; it is derived from
# PYTHON_PREFERED_VERSION so scripts and presets no longer need to define
# both. If a caller still passes PYMINOR, a divergence with
# PYTHON_PREFERED_VERSION is a configuration error (J1b lesson ebbd785).
if ( DEFINED PYMINOR AND NOT "${PYMINOR}" STREQUAL "" )
    string( REGEX REPLACE "^3\\." "" _PYMINOR_DERIVED "${PYTHON_PREFERED_VERSION}" )
    if ( NOT "${PYMINOR}" STREQUAL "${_PYMINOR_DERIVED}" )
        message( WARNING
            "PYMINOR (${PYMINOR}) is inconsistent with PYTHON_PREFERED_VERSION "
            "(${PYTHON_PREFERED_VERSION}); using PYMINOR for the conda-list filenames "
            "(see audit J2a, section 8.3)")
    endif()
    unset( _PYMINOR_DERIVED )
else()
    string( REGEX REPLACE "^3\\." "" PYMINOR "${PYTHON_PREFERED_VERSION}" )
endif()

if(WIN32)
        set( BUILDING_DOCS
            conda-list_Windows11_conda3${PYMINOR}
            cpy312.yml
            )
elseif (USE_CONDA_PACKAGES)
    if(APPLE)
        set( BUILDING_DOCS
            conda-list_macOS_3${PYMINOR}
            )
    else()
        set( BUILDING_DOCS
            conda-list_Ubuntu20.04_3${PYMINOR}
            )
    endif()
endif()

if ( LINUX )
    install(FILES ${BUILDING_DOCS} DESTINATION cloudComPy/doc)
else()
    if (BUILD_PYPI)
        install(FILES ${BUILDING_DOCS} DESTINATION ${CMAKE_INSTALL_PREFIX}/cloudComPy/doc)
    else()
        install(FILES ${BUILDING_DOCS} DESTINATION doc)
    endif()
endif()