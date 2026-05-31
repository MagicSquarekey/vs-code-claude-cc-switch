@echo off
:: ============================================================
:: VS Code + Claude Code + CC-Switch 一键部署
:: 双击此文件开始安装
:: ============================================================
title VS Code + Claude Code + CC-Switch 安装程序
cd /d "%~dp0"
echo ============================================================
echo   VS Code + Claude Code + CC-Switch 一键部署工具
echo ============================================================
echo.
echo 即将开始安装，需要管理员权限。
echo 安装过程中请勿关闭此窗口。
echo.
pause
powershell -ExecutionPolicy Bypass -File "%~dp0install.ps1"
pause
