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
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# 1. Localisation du dossier CloudCompare (racine de CloudComPy)
# ---------------------------------------------------------------------------
_this_dir = Path(__file__).resolve().parent
print(_this_dir)
_cc_root = _this_dir.parent  # CloudCompare/
print(_cc_root)
_cc_plugins = _cc_root / "plugins"
print(_cc_plugins)
# ---------------------------------------------------------------------------
# 2. Ajout explicite des répertoires contenant les DLL CloudCompare
#    Cela force Windows à charger ces DLL en priorité.
# ---------------------------------------------------------------------------
os.add_dll_directory(str(_cc_root))
os.add_dll_directory(str(_cc_plugins))

# ---------------------------------------------------------------------------
# 3. Optionnel : protection contre les DLL parasites dans le PATH
#    (utile si un autre logiciel fournit Qt6 ou des libs CC)
# ---------------------------------------------------------------------------
# On retire du PATH les dossiers Conda susceptibles de contenir des DLL conflictuelles.
#_clean_path = []
#for p in os.environ["PATH"].split(";"):
#    if "miniconda3" not in p.lower():  # évite les DLL Conda
#        _clean_path.append(p)
#os.environ["PATH"] = ";".join(_clean_path)

# ---------------------------------------------------------------------------
# 4. Plugins Qt
# ---------------------------------------------------------------------------
os.environ["QT_QPA_PLATFORM_PLUGIN_PATH"] = os.path.join(os.path.dirname(__file__), "..", "platforms")

# ---------------------------------------------------------------------------
# 5. Import du module natif CloudComPy
# ---------------------------------------------------------------------------

from _cloudComPy import *
initCC()
initCloudCompare()
