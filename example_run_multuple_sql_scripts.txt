SET SQLCMD="C:\Program Files\Microsoft SQL Server\100\Tools\Binn\SQLCMD.EXE"
SET PATH="C:\_TFS\Data_Services\SSIS\ETL_DX_load_Enterprise_DMS_sales\Procedures\"
SET SERVER="DXSQLProd01"
SET DB="DMS_INTEGRATION"
SET OUTPUT="C:\_SQL_Documents\Output_log.txt"

CD %PATH%

ECHO %date% %time% > %OUTPUT%

for %%f in (*.sql) do (
ECHO. >> %OUTPUT%
ECHO Running... %%f >> %OUTPUT%
%SQLCMD% -E -S %SERVER% -d %DB% -i %%~f >> %OUTPUT%
)
REM PAUSE