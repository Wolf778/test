rem SOAP->XML
:: by Volkov.Sergey@redsys.ru
:: Утилита доставания из SOAP конверта (Формат ВИО,СКМВ) файла XML
:: Поместить файл XML рядом и запустить командный файл (soap_to_xml.cmd)
:: Далее скрипт делает следующее:
::  Определяется тип пакета (ВИО или СКМВ)
::  Последовательность из SOAP конверта конвертирует из формат BASE64 в нормальный, и затем разархивирует
:: В итоге получаем готовые файл(ы) которые лежали в SOAP, 
:: которые помещаются в отдельную папку с исходником формата <xдата~время>

:: Для обработки нескольких файлов надо скопировать все файлы в данную папку и запускать программу столько раз сколько файлов 

@ECHO OFF
chcp 1251 >nul
Setlocal EnableDelayedExpansion
:: Проверка на существование файла
if not exist "%~dp0\*.xml" echo Файл XML не найден & pause & exit

:: Забираем первый попавшийся файл xml
for %%f in (*.xml) do (set tekfile="%%f")

:: Используемые namespaced во входных файлах
set nsp=-N m=http://r-style.com/2014/routing -N rev=http://smev.gosuslugi.ru/rev120315 
::set nsp=-N m=http://r-style.com/2014/routing -N rev=http://smev.gosuslugi.ru/rev111111 

:: Представление даты в нужном нам виде
ECHO wscript.ECHO YEAR(DATE) ^& "_" ^& RIGHT(0 ^& MONTH(DATE),2) ^& "_" ^& RIGHT(0 ^& DAY(DATE),2) ^& "~" ^& RIGHT(0 ^& hour(TIME),2) ^& "-" ^& RIGHT(0 ^& minute(TIME),2) ^& "-" ^& RIGHT(0 ^& second(TIME),2)>"%TEMP%\tmp.vbs"
FOR /F %%i IN ('cscript "%TEMP%\tmp.vbs" //Nologo') DO SET "TEKDATATIME=%%i"
IF EXIST "%TEMP%\tmp.vbs" DEL "%TEMP%\tmp.vbs"
:: Запоминаем текущую папку
SET "SOURCE_FOLDER=%~dp0x%TEKDATATIME%"
:: Создаем папку с датой
md "%SOURCE_FOLDER%"
::Переносим данные из файла XML в рабочуюю папку 
type "%~dp0\!tekfile!">"%SOURCE_FOLDER%\SOAP1.bas"
:: Определяем тип конверка (поддержка формата ВИО, СКМВ(СМЭВ))
echo on
FOR /F %%i IN ('"xml.exe sel %nsp% -t -v count(//m:data) %SOURCE_FOLDER%\SOAP1.bas"') DO set TYPE_SOAP_VIO=%%i
FOR /F %%j IN ('"xml.exe sel %nsp% -t -v count(//rev:BinaryData) %SOURCE_FOLDER%\SOAP1.bas"') DO set TYPE_SOAP_SKMV=%%j
IF %TYPE_SOAP_VIO%==1 set XPATH_to_DATA=//m:data
IF %TYPE_SOAP_SKMV%==1 set XPATH_to_DATA=//rev:BinaryData
IF NOT %TYPE_SOAP_VIO%==1 IF NOT %TYPE_SOAP_SKMV%==1 echo Не найден Xpath к данным (д.б. для ВИО://m:data для СКМВ://rev:BinaryData) либо не корректный формат  & pause & exit 
:: Забираем данные из пакета
"%~dp0xml.exe" sel %nsp% -t -v "%XPATH_to_DATA%" "%SOURCE_FOLDER%\SOAP1.bas" >"%SOURCE_FOLDER%\SOAP2.bas"
:: Конвертация из base64 в нормальный формат
certutil.exe -decode "%SOURCE_FOLDER%\SOAP2.bas" "%SOURCE_FOLDER%\SOAP3.zip"
:: Разаархивируем файл
"%~dp07z.exe" x -r "%SOURCE_FOLDER%\SOAP3.zip" -o%SOURCE_FOLDER%
:: Удаляем темповые файл 
del "%SOURCE_FOLDER%\*.zip" /q
del "%SOURCE_FOLDER%\*.bas" /q
:: Переносим исходный файл в папку с результатом
move "%~dp0\!tekfile!" "%SOURCE_FOLDER%\"

:: конец цикла по перебору фалов xml
echo Успехх, в смысле скрипт до конца выполнился :)
exit