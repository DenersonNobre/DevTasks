@echo off
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0claims.ps1" %*
