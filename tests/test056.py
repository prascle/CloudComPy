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

import os
import sys
import math

os.environ["_CCTRACE_"]="ON" # only if you want C++ debug traces

from gendata import dataDir

import cloudComPy as cc

#---Cork01-begin
tr1 = cc.ccGLMatrix()
tr1.initFromParameters(0.0, (0., 0., 0.), (1.0, 0.0, 0.0))
sphere = cc.ccSphere(2, tr1, "aSphere")

cylinder = cc.ccCylinder(2.0, 5.0)

if not cc.isPluginCork():
    print("Test skipped")
    sys.exit()

import cloudComPy.Cork
mesh = cc.Cork.Cork.compute(cylinder, sphere, cc.Cork.DIFF)
#---Cork01-end
if (mesh.size() < 1100) or (mesh.size() > 1200):
    raise RuntimeError

cc.SaveEntities([sphere, cylinder, mesh], os.path.join(dataDir, "Cork.bin"))
