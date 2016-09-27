rem XML->SOAP
:: by Volkov.Sergey@redsys.ru
:: Утилита оборачивания файлов в SOAP конверт (Формат СКМВ(СМЭВ))
:: Поместить файлы XML рядом и запустить командный файл XML_to_SOAP_SKMV.cmd
:: Принцип работы: файлы XML будут заархивированы и сконвертированы в формат BASE64 (файл data_for_SOAP.txt)
:: Затем данные будут подставлены в шаблон SOAP конверта (имя шаблона указано в начале файла - nameSOAP) 

@ECHO OFF
chcp 1251 >nul
Setlocal EnableDelayedExpansion
set nameSOAP=soapSKMV_ADV.xml 

:: Проверка существования файлов
if not exist "%~dp0\*.xml" echo Файл XML не найден & pause & exit
:: Представление даты в нужном нам виде
ECHO wscript.ECHO YEAR(DATE) ^& "_" ^& RIGHT(0 ^& MONTH(DATE),2) ^& "_" ^& RIGHT(0 ^& DAY(DATE),2) ^& "~" ^& RIGHT(0 ^& hour(TIME),2) ^& "-" ^& RIGHT(0 ^& minute(TIME),2) ^& "-" ^& RIGHT(0 ^& second(TIME),2)>"%TEMP%\tmp.vbs"
FOR /F %%i IN ('cscript "%TEMP%\tmp.vbs" //Nologo') DO SET "TEKDATATIME=%%i"
IF EXIST "%TEMP%\tmp.vbs" DEL "%TEMP%\tmp.vbs"
:: Создаем и запоминаем текущую папку для работы
SET "SOURCE_FOLDER=%~dp0\s%TEKDATATIME%"
md "%SOURCE_FOLDER%"
:: Архивируем файлы xml и p7s
"%~dp07z.exe" a -tzip "%SOURCE_FOLDER%\SOAP1.zip" "%~dp0\*.xml" "%~dp0\*.p7s" -mx5
echo Создан zip архив
:: Конвертация архива в base64
certutil.exe -encode "%SOURCE_FOLDER%\SOAP1.zip" "%SOURCE_FOLDER%\SOAP2.bas"
echo Файл сконвертирован в BASE64
:: Удаляем лишние строки в файле
type "%SOURCE_FOLDER%\SOAP2.bas" | find /v /i "-----END CERTIFICATE-----"> "%SOURCE_FOLDER%\SOAP3.bas"
type "%SOURCE_FOLDER%\SOAP3.bas" | find /v /i "-----BEGIN CERTIFICATE-----"> "%SOURCE_FOLDER%\data_for_SOAP.txt"
:: Преобразуем SOAP конверт к нужному виду
type "%~dp0\Template\%nameSOAP%">"%SOURCE_FOLDER%\SOAP1.bas"
"%~dp0xml.exe" ed -N epgu="http://epgu.skmv.rstyle.com" -N rev="http://smev.gosuslugi.ru/rev120315" -d "(soapenv:Envelope/soapenv:Body/epgu:EpguPrivatePersonRequest/rev:MessageData/rev:AppDocument/rev:BinaryData)" "%SOURCE_FOLDER%\SOAP1.bas">"%SOURCE_FOLDER%\soap_bez_body.bas"
type "%SOURCE_FOLDER%\soap_bez_body.bas" | find /v /i "</soapenv:Envelope>" | find /v /i "</soapenv:Body>" | find /v /i " </epgu:EpguPrivatePersonRequest>" | find /v /i "</rev:MessageData>" | find /v /i "</rev:AppDocument>"> "%SOURCE_FOLDER%\soap_bez_str.bas"
:: Собраем новый SOAP конверт с нашими данными
type "%SOURCE_FOLDER%\soap_bez_str.bas">"%SOURCE_FOLDER%\soapFIN_SKMV.xml" 
echo ^<rev:BinaryData^>>>"%SOURCE_FOLDER%\soapFIN_SKMV.xml" 
type "%SOURCE_FOLDER%\data_for_SOAP.txt">>"%SOURCE_FOLDER%\soapFIN_SKMV.xml" 
echo ^</rev:BinaryData^>>>"%SOURCE_FOLDER%\soapFIN_SKMV.xml" 
echo ^</rev:AppDocument^>>>"%SOURCE_FOLDER%\soapFIN_SKMV.xml"
echo ^</rev:MessageData^>>>"%SOURCE_FOLDER%\soapFIN_SKMV.xml"
echo ^</epgu:EpguPrivatePersonRequest^>>>"%SOURCE_FOLDER%\soapFIN_SKMV.xml"
echo ^</soapenv:Body^>>>"%SOURCE_FOLDER%\soapFIN_SKMV.xml"
echo ^</soapenv:Envelope^>>>"%SOURCE_FOLDER%\soapFIN_SKMV.xml"
:: Удаляем темповые файл 
del "%SOURCE_FOLDER%\*.zip" /q
del "%SOURCE_FOLDER%\*.bas" /q
::del "%SOURCE_FOLDER%\*.txt" /q
:: Переносим обработанные исходные файлы в рабочуюю папку 
move "%~dp0\*.xml" "%SOURCE_FOLDER%\" 
move "%~dp0\*.p7s" "%SOURCE_FOLDER%\" 
echo Успехх
