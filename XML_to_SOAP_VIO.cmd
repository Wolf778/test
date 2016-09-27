rem XML->SOAP 
:: by Volkov.Sergey@redsys.ru
:: ������� ������������ ������ � SOAP ������� (������ ���)
:: ��������� ����� XML ����� � ��������� ��������� ���� XML_to_SOAP.cmd
:: ������� ������: ����� XML ����� �������������� � ��������������� � ������ BASE64 (���� data_for_SOAP.txt)
:: ����� ������ ����� ����������� � ������ SOAP �������� (��� ������� ������� � ������ ����� - nameSOAP)XML_to_SOAP.cmd

@ECHO OFF
chcp 1251 >nul
Setlocal EnableDelayedExpansion
:: �������� ������ ������:
set nameSOAP=soapVIO_SZVM.xml 
::set nameSOAP=soapVIO_ADVmfc.xml 
::set nameSOAP=soapVIO_RSV-1_2015.xml 
::set nameSOAP=soapVIO_SZV-6-4_2013.xml
::set nameSOAP=soapVIO_SZV-4-x.xml
::set nameSOAP=soapVIO_SZV-1_do2002.xml
::set nameSOAP=soapVIO_SPV.xml
::set nameSOAP=soapVIO_MSK.xml


:: �������� ������������� ������
if not exist "%~dp0\*.xml" echo ���� XML �� ������ & pause & exit
:: ������������� ���� � ������ ��� ����
ECHO wscript.ECHO YEAR(DATE) ^& "_" ^& RIGHT(0 ^& MONTH(DATE),2) ^& "_" ^& RIGHT(0 ^& DAY(DATE),2) ^& "~" ^& RIGHT(0 ^& hour(TIME),2) ^& "-" ^& RIGHT(0 ^& minute(TIME),2) ^& "-" ^& RIGHT(0 ^& second(TIME),2)>"%TEMP%\tmp.vbs"
FOR /F %%i IN ('cscript "%TEMP%\tmp.vbs" //Nologo') DO SET "TEKDATATIME=%%i"
IF EXIST "%TEMP%\tmp.vbs" DEL "%TEMP%\tmp.vbs"
:: ������� � ���������� ������� ����� ��� ������
SET "SOURCE_FOLDER=%~dp0\s%TEKDATATIME%"
md "%SOURCE_FOLDER%"
:: ���������� ����� xml, p7s, sig 
"%~dp07z.exe" a -tzip "%SOURCE_FOLDER%\SOAP1.zip" "%~dp0\*.xml" "%~dp0\*.p7s" "%~dp0\*.sig" -mx5
:: ����������� ������ � base64
certutil.exe -encode "%SOURCE_FOLDER%\SOAP1.zip" "%SOURCE_FOLDER%\SOAP2.bas"
:: ������� ������ ������ � �����
type "%SOURCE_FOLDER%\SOAP2.bas" | find /v /i "-----END CERTIFICATE-----"> "%SOURCE_FOLDER%\SOAP3.bas"
type "%SOURCE_FOLDER%\SOAP3.bas" | find /v /i "-----BEGIN CERTIFICATE-----"> "%SOURCE_FOLDER%\data_for_SOAP.txt"
:: ����������� SOAP ������� � ������� ����
type "%~dp0\Template\%nameSOAP%">"%SOURCE_FOLDER%\SOAP1.bas"
"%~dp0xml.exe" ed -d "(soap:Envelope/soap:Body)" "%SOURCE_FOLDER%\SOAP1.bas">"%SOURCE_FOLDER%\soap_bez_body.bas"
type "%SOURCE_FOLDER%\soap_bez_body.bas" | find /v /i "</soap:Envelope>"> "%SOURCE_FOLDER%\soap_bez_str.bas"
:: ������� ����� SOAP ������� � ������ �������
type "%SOURCE_FOLDER%\soap_bez_str.bas">"%SOURCE_FOLDER%\soapFIN_VIO.xml" 
echo ^<soap:Body^>>>"%SOURCE_FOLDER%\soapFIN_VIO.xml" 
echo ^<m:Message^>>>"%SOURCE_FOLDER%\soapFIN_VIO.xml"
echo ^<m:data mime:contentType=^"application/zip^"^>>>"%SOURCE_FOLDER%\soapFIN_VIO.xml"
type "%SOURCE_FOLDER%\data_for_SOAP.txt">>"%SOURCE_FOLDER%\soapFIN_VIO.xml" 
echo ^</m:data^>>>"%SOURCE_FOLDER%\soapFIN_VIO.xml" 
echo ^</m:Message^>>>"%SOURCE_FOLDER%\soapFIN_VIO.xml"
echo ^</soap:Body^>>>"%SOURCE_FOLDER%\soapFIN_VIO.xml"
echo ^</soap:Envelope^>>>"%SOURCE_FOLDER%\soapFIN_VIO.xml"

:: ������� �������� ����� 
del "%SOURCE_FOLDER%\*.zip" /q
del "%SOURCE_FOLDER%\*.bas" /q
del "%SOURCE_FOLDER%\*.txt" /q
:: ��������� ������������ �������� ����� � �������� ����� 
move "%~dp0\*.xml" "%SOURCE_FOLDER%\" 
move "%~dp0\*.p7s" "%SOURCE_FOLDER%\" 
move "%~dp0\*.sig" "%SOURCE_FOLDER%\" 

echo ������, � ������ ������ �� ����� ���������� :)
