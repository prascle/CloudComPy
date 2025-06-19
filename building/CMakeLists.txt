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

if(WIN32)
        set( BUILDING_DOCS
            conda-list_Windows11_311
            )
elseif (USE_CONDA_PACKAGES)
    if(APPLE)
        set( BUILDING_DOCS
            conda-list_macOS_311
            )
    else()
        set( BUILDING_DOCS
        conda-list_Ubuntu20.04
            )
    endif()
endif()

install(FILES ${BUILDING_DOCS} DESTINATION doc)
