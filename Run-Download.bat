@echo off
title Bo3 Load Version - Downloader
echo.
echo Running PowerShell script with bypass...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Download.ps1"

echo.
pause