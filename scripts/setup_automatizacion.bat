@echo off
REM =====================================================================
REM SCRIPT DE AUTOMATIZACIÓN WINDOWS - BOUTIQUE VÉRTICE DATA WAREHOUSE
REM Configura la ejecución automática diaria via Task Scheduler
REM =====================================================================

REM CONFIGURACIÓN - MODIFICAR SEGÚN TU ENTORNO
SET PROJECT_DIR=C:\Users\Artur\OneDrive\Escritorio\Proyecto Base de Datos 2
SET PYTHON_EXE=python.exe
SET LOG_DIR=%PROJECT_DIR%\logs

REM Crear directorio de logs si no existe
IF NOT EXIST "%LOG_DIR%" MKDIR "%LOG_DIR%"

REM Nombre de la tarea programada
SET TASK_NAME=BoutiqueVertice_ETL_Diario

REM Hora de ejecución (formato 24h: HH:MM)
SET RUN_TIME=03:00

REM =====================================================================
echo =====================================================================
echo CONFIGURANDO AUTOMATIZACIÓN ETL DIARIA - BOUTIQUE VÉRTICE
echo =====================================================================
echo Directorio del proyecto: %PROJECT_DIR%
echo Python: %PYTHON_EXE%
echo Hora programada: %RUN_TIME%
echo Nombre tarea: %TASK_NAME%
echo =====================================================================

REM Verificar que Python existe
WHERE %PYTHON_EXE% >NUL 2>NUL
IF %ERRORLEVEL% NEQ 0 (
    echo ERROR: No se encuentra %PYTHON_EXE% en el PATH
    echo Instala Python y agrega al PATH del sistema
    pause
    exit /b 1
)

REM Verificar script diario
IF NOT EXIST "%PROJECT_DIR%\scripts\etl_diario.py" (
    echo ERROR: No se encuentra etl_diario.py en %PROJECT_DIR%\scripts
    pause
    exit /b 1
)

REM Crear tarea programada usando SCHTASKS
echo.
echo Creando tarea programada en Windows Task Scheduler...
echo.

SCHTASKS /CREATE /TN "%TASK_NAME%" ^
    /TR "\"%PYTHON_EXE%\" \"%PROJECT_DIR%\scripts\etl_diario.py\"" ^
    /SC DAILY ^
    /ST %RUN_TIME% ^
    /RL HIGHEST ^
    /F ^
    /IT

IF %ERRORLEVEL% EQU 0 (
    echo.
    echo =====================================================================
    echo TAREA CREADA EXITOSAMENTE
    echo =====================================================================
    echo La tarea "%TASK_NAME%" se ejecutará automáticamente
    echo todos los días a las %RUN_TIME%
    echo.
    echo Para verificar: Abre "Programador de tareas" en Windows
    echo.
    echo Para ejecutar manualmente ahora:
    echo   SCHTASKS /RUN /TN "%TASK_NAME%"
    echo.
    echo Para ver logs:
    echo   type "%LOG_DIR%\etl_diario_%DATE:~-4,4%%DATE:~-7,2%%DATE:~-10,2%.log"
    echo =====================================================================
) ELSE (
    echo.
    echo ERROR: No se pudo crear la tarea.
    echo Ejecuta este script como ADMINISTRADOR.
    echo.
)

pause