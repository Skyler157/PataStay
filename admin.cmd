@echo off
rem Starts the admin dashboard. See tools\run-admin.ps1.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0tools\run-admin.ps1" %*
