@echo off

REM This script is going to be run after the Windows boots from the Secondary Site
REM Copyright, DataGardens Inc. 2013.
REM Put your customized routing scripts here.
REM Example: route add <network> mask <mask> <gateway>
echo "This is the customSecScript.bat that is run only in the Secondary data center (original DR site)"


PowerShell -NoProfile -ExecutionPolicy Bypass -Command "& '%~dp0SetNetworksPrivate.ps1'"