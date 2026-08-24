<# 
.SYNOPSIS
    Wrapper PowerShell para ejecutar ETL diario con logging robusto
.DESCRIPTION
    Este script ejecuta el ETL diario de Python, captura logs, maneja errores
    y envía notificaciones. Diseñado para ser llamado por Task Scheduler.
#>

param(
    [string]$ProjectDir = "C:\Users\Artur\OneDrive\Escritorio\Proyecto Base de Datos 2",
    [string]$PythonExe = "python.exe",
    [string]$LogDir = "C:\Users\Artur\OneDrive\Escritorio\Proyecto Base de Datos 2\logs"
)

# Crear directorio de logs
if (-not (Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$logFile = Join-Path $LogDir "etl_diario_$timestamp.log"
$errorLogFile = Join-Path $LogDir "etl_diario_ERROR_$timestamp.log"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $entry = "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') [$Level] $Message"
    Add-Content -Path $logFile -Value $entry
    Write-Host $entry
}

Write-Log "=== INICIO ETL DIARIO BOUTIQUE VÉRTICE ==="
Write-Log "Directorio: $ProjectDir"
Write-Log "Python: $PythonExe"

try {
    # Cambiar al directorio del proyecto
    Set-Location -Path $ProjectDir -ErrorAction Stop
    Write-Log "Directorio de trabajo cambiado a $ProjectDir"
    
    # Verificar archivo Excel diario (ahora en carpeta data)
    $excelFile = Join-Path $ProjectDir "data\Carga_Diaria.xlsx"
    if (-not (Test-Path $excelFile)) {
        throw "No se encuentra el archivo Excel diario: $excelFile"
    }
    Write-Log "Archivo Excel encontrado: $excelFile"
    
    # Verificar Python
    $pythonPath = (Get-Command $PythonExe -ErrorAction SilentlyContinue).Source
    if (-not $pythonPath) {
        throw "No se encuentra $PythonExe en el PATH del sistema"
    }
    Write-Log "Python encontrado: $pythonPath"
    
    # Ejecutar ETL (script en carpeta scripts)
    Write-Log "Ejecutando scripts\etl_diario.py..."
    $process = Start-Process -FilePath $PythonExe -ArgumentList "scripts\etl_diario.py" `
        -WorkingDirectory $ProjectDir -Wait -PassThru -RedirectStandardOutput $logFile -RedirectStandardError $errorLogFile
    
    if ($process.ExitCode -eq 0) {
        Write-Log "ETL completado exitosamente (ExitCode: 0)"
    } else {
        Write-Log "ETL falló con ExitCode: $($process.ExitCode)" "ERROR"
        Get-Content $errorLogFile | ForEach-Object { Write-Log $_ "ERROR" }
        exit $process.ExitCode
    }
    
} catch {
    Write-Log "EXCEPCIÓN: $($_.Exception.Message)" "ERROR"
    Write-Log $_.ScriptStackTrace "ERROR"
    exit 1
} finally {
    Write-Log "=== FIN ETL DIARIO ==="
}

# Limpiar logs antiguos (mantener últimos 30 días)
Get-ChildItem -Path $LogDir -Name "etl_diario_*.log" | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | 
    Remove-Item -Force

Write-Log "Limpieza de logs antiguos completada"