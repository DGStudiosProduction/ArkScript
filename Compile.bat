@echo off
title ModMismatch Compiler
color 0B

echo ===================================================
echo  ARK Mod Mismatch - Auto Compiler
echo ===================================================
echo.
echo Ensuring the PS2EXE compiler is installed...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "if (-not (Get-Module -ListAvailable -Name ps2exe)) { Write-Host 'Downloading ps2exe module from PowerShell Gallery...' -ForegroundColor Yellow; Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Scope CurrentUser; Install-Module ps2exe -Scope CurrentUser -Force } else { Write-Host 'PS2EXE is already installed.' -ForegroundColor Green }"

echo.
echo ===================================================
echo Compiling ModMissmatch.ps1 into an executable...
echo ===================================================
echo.

powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-ps2exe -inputFile '.\ModMissmatch.ps1' -outputFile '.\ModMissmatch.exe'"

echo.
echo ===================================================
echo Compilation Successful!
echo You can now find ModMissmatch.exe in this folder.
echo ===================================================
echo.
pause
