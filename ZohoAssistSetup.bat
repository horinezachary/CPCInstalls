set DeployServer=%~1
::Does string have a trailing slash? if so remove it 
IF %DeployServer:~-1%==\ SET DeployServer=%DeployServer:~0,-1%

set LogFileName=%cd%\%computername%.log
set SharedLogLocation=Log
set MSIVerboseLogLocation=MSI_Log
set MSIVerboseLog=%computername%_msi.log

for /F "tokens=2" %%i in ('date /t') do set mydate=%%i
set mytime=%time%
echo %DATE% %TIME% >> %LogFileName%

echo GPO startup script started >> %LogFileName%

set LocalTempDir=TempZohoAssistGPO

reg query "hklm\software\zoho assist\unattended remote support"

if %errorlevel%==1 ( goto install ) else ( goto already_installed )

:already_installed
echo "already installed" >> %LogFileName%
goto script_completion

:install
if %2==MSI ( goto install_with_MSI ) else ( goto install_with_IS_EXE )

:install_with_MSI
echo installation started >> %LogFileName%
mkdir %LocalTempDir%
robocopy "%DeployServer%" "%LocalTempDir%" /XD "%DeployServer%\%SharedLogLocation%" "%DeployServer%\%MSIVerboseLogLocation%" >> %LogFileName%
cd %LocalTempDir%
msiexec /i ZA_Access.msi /quiet /qn /lv %MSIVerboseLog% SILENT=TRUE
robocopy . "%DeployServer%\%MSIVerboseLogLocation%" %MSIVerboseLog%
echo msiexec invoked successfully >> %LogFileName%
echo -------------------------------------------------------------------------------------------------------------------------------------------------------------------- >> %LogFileName%

type %programdata%\ZohoMeeting\log\unattended.log >> %LogFileName%

echo -------------------------------------------------------------------------------------------------------------------------------------------------------------------- >> %LogFileName%
reg query "hklm\software\zoho corp\zoho assist unattended agent\1.0.0" /reg:32 >> %LogFileName%
goto script_completion

:install_with_IS_EXE
echo installation started >> %LogFileName%
mkdir %LocalTempDir%
robocopy "%DeployServer%" "%LocalTempDir%" /XD "%DeployServer%\%SharedLogLocation%" "%DeployServer%\%MSIVerboseLogLocation%" >> %LogFileName%
cd %LocalTempDir%
ZA_Access.exe /z"-silent" -s -f1".\ZohoAssistAgent.iss"
echo msiexec invoked successfully >> %LogFileName%
reg query "hklm\software\zoho corp\zoho assist unattended agent\1.00.0001" /reg:32 >> %LogFileName%

:script_completion
echo GPO startup script completed >> %LogFileName%

echo -------------------------------------------------------------------------------------------------------------------------------------------------------------------- >> %LogFileName%

::deleting temp dir
cd ..
rmdir /S /Q %LocalTempDir%

::copying log file to share
robocopy . "%DeployServer%\%SharedLogLocation%" %computername%.log
del /f %LogFileName%