@echo off
rem J1b : stub neutre pour neutraliser le POST_BUILD windeployqt du sous-module CloudCompare.
rem Le windeployqt du Qt 6.9 Conda ne supporte plus --openglwidgets/--concurrent;
rem le deploiement Qt complet sera repris au jalon GUI.
exit /b 0
