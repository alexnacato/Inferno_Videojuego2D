@echo off
setlocal
set "PROJECT_DIR=%~dp0"
set "GODOT_EXE=%PROJECT_DIR%..\Godot_v4.7.2-stable_win64.exe"
if not exist "%GODOT_EXE%" (
    echo No se encontro Godot 4.7.2 junto a la carpeta del proyecto.
    echo Abre project.godot desde Godot y pulsa F5.
    pause
    exit /b 1
)
start "" "%GODOT_EXE%" --path "%PROJECT_DIR%."
