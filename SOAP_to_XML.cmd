rem SOAP->XML
:: by Volkov.Sergey@redsys.ru
:: ������� ���������� �� SOAP �������� (������ ���,����) ����� XML
:: ��������� ���� XML ����� � ��������� ��������� ���� (soap_to_xml.cmd)
:: ����� ������ ������ ���������:
::  ������������ ��� ������ (��� ��� ����)
::  ������������������ �� SOAP �������� ������������ �� ������ BASE64 � ����������, � ����� �������������
:: � ����� �������� ������� ����(�) ������� ������ � SOAP, 
:: ������� ���������� � ��������� ����� � ���������� ������� <x����~�����>

:: ��� ��������� ���������� ������ ���� ����������� ��� ����� � ������ ����� � ��������� ��������� ������� ��� ������� ������ 

@ECHO OFF
chcp 1251 >nul
Setlocal EnableDelayedExpansion
:: �������� �� ������������� �����
if not exist "%~dp0\*.xml" echo ���� XML �� ������ & pause & exit

:: �������� ������ ���������� ���� xml
for %%f in (*.xml) do (set tekfile="%%f")

:: ������������ namespaced �� ������� ������
set nsp=-N m=http://r-style.com/2014/routing -N rev=http://smev.gosuslugi.ru/rev120315 
::set nsp=-N m=http://r-style.com/2014/routing -N rev=http://smev.gosuslugi.ru/rev111111 

:: ������������� ���� � ������ ��� ����
ECHO wscript.ECHO YEAR(DATE) ^& "_" ^& RIGHT(0 ^& MONTH(DATE),2) ^& "_" ^& RIGHT(0 ^& DAY(DATE),2) ^& "~" ^& RIGHT(0 ^& hour(TIME),2) ^& "-" ^& RIGHT(0 ^& minute(TIME),2) ^& "-" ^& RIGHT(0 ^& second(TIME),2)>"%TEMP%\tmp.vbs"
FOR /F %%i IN ('cscript "%TEMP%\tmp.vbs" //Nologo') DO SET "TEKDATATIME=%%i"
IF EXIST "%TEMP%\tmp.vbs" DEL "%TEMP%\tmp.vbs"
:: ���������� ������� �����
SET "SOURCE_FOLDER=%~dp0x%TEKDATATIME%"
:: ������� ����� � �����
md "%SOURCE_FOLDER%"
::��������� ������ �� ����� XML � �������� ����� 
type "%~dp0\!tekfile!">"%SOURCE_FOLDER%\SOAP1.bas"
:: ���������� ��� �������� (��������� ������� ���, ����(����))
echo on
FOR /F %%i IN ('"xml.exe sel %nsp% -t -v count(//m:data) %SOURCE_FOLDER%\SOAP1.bas"') DO set TYPE_SOAP_VIO=%%i
FOR /F %%j IN ('"xml.exe sel %nsp% -t -v count(//rev:BinaryData) %SOURCE_FOLDER%\SOAP1.bas"') DO set TYPE_SOAP_SKMV=%%j
IF %TYPE_SOAP_VIO%==1 set XPATH_to_DATA=//m:data
IF %TYPE_SOAP_SKMV%==1 set XPATH_to_DATA=//rev:BinaryData
IF NOT %TYPE_SOAP_VIO%==1 IF NOT %TYPE_SOAP_SKMV%==1 echo �� ������ Xpath � ������ (�.�. ��� ���://m:data ��� ����://rev:BinaryData) ���� �� ���������� ������  & pause & exit 
:: �������� ������ �� ������
"%~dp0xml.exe" sel %nsp% -t -v "%XPATH_to_DATA%" "%SOURCE_FOLDER%\SOAP1.bas" >"%SOURCE_FOLDER%\SOAP2.bas"
:: ����������� �� base64 � ���������� ������
certutil.exe -decode "%SOURCE_FOLDER%\SOAP2.bas" "%SOURCE_FOLDER%\SOAP3.zip"
:: �������������� ����
"%~dp07z.exe" x -r "%SOURCE_FOLDER%\SOAP3.zip" -o%SOURCE_FOLDER%
:: ������� �������� ���� 
del "%SOURCE_FOLDER%\*.zip" /q
del "%SOURCE_FOLDER%\*.bas" /q
:: ��������� �������� ���� � ����� � �����������
move "%~dp0\!tekfile!" "%SOURCE_FOLDER%\"

:: ����� ����� �� �������� ����� xml
echo ������, � ������ ������ �� ����� ���������� :)
exit