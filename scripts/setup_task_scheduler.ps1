<# 
.SYNOPSIS
    Configura la tarea programada de Windows para ETL diario automático
.DESCRIPTION
    Crea una tarea en Task Scheduler que ejecuta el wrapper PowerShell
    todos los días a la hora configurada. Requiere ejecutarse como Administrador.
#>

param(
    [string]$ProjectDir = "C:\Users\Artur\OneDrive\Escritorio\Proyecto Base de Datos 2",
    [string]$TaskName = "BoutiqueVertice_ETL_Diario",
    [string]$RunTime = "03:00",
    [string]$Description = "ETL Diario Data Warehouse Boutique Vértice - Carga incremental automática"
)

# Verificar permisos de administrador
$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Este script debe ejecutarse como ADMINISTRADOR"
    Write-Host "Haz clic derecho en PowerShell -> 'Ejecutar como administrador'"
    exit 1
}

$wrapperScript = Join-Path $ProjectDir "scripts\run_etl_diario.ps1"
$pythonExe = "python.exe"

if (-not (Test-Path $wrapperScript)) {
    Write-Error "No se encuentra el wrapper: $wrapperScript"
    exit 1
}

Write-Host "======================================================================"
Write-Host "CONFIGURANDO TAREA PROGRAMADA WINDOWS"
Write-Host "======================================================================"
Write-Host "Proyecto: $ProjectDir"
Write-Host "Wrapper: $wrapperScript"
Write-Host "Tarea: $TaskName"
Write-Host "Hora: $RunTime"
Write-Host "======================================================================"

# Eliminar tarea existente si existe
$existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($existingTask) {
    Write-Host "Eliminando tarea existente..."
    Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
}

# Crear acción
$action = New-ScheduledTaskAction `
    -Execute "powershell.exe" `
    -Argument "-ExecutionPolicy Bypass -File `"$wrapperScript`""

# Crear trigger diario
$trigger = New-ScheduledTaskTrigger -Daily -At $RunTime

# Configuración principal
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -RunOnlyIfNetworkAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 2) `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 5)

# Principales: SYSTEM (ejecuta aunque no haya usuario logueado)
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

# Registrar tarea
Register-ScheduledTask `
    -TaskName $TaskName `
    -Action $action `
    -Trigger $trigger `
    -Settings $settings `
    -Principal $principal `
    -Description $Description `
    -Force

Write-Host ""
Write-Host "======================================================================"
Write-Host "TAREA CREADA EXITOSAMENTE"
Write-Host "======================================================================"
Write-Host "Nombre: $TaskName"
Write-Host "Ejecutará: Diariamente a las $RunTime"
Write-Host "Usuario: SYSTEM (sin necesidad de login)"
Write-Host "Nivel: Máximos privilegios"
Write-Host ""
Write-Host "COMANDOS ÚTILES:"
Write-Host "  Ver tarea:      Get-ScheduledTask -TaskName '$TaskName'"
Write-Host "  Ejecutar ahora: Start-ScheduledTask -TaskName '$TaskName'"
Write-Host "  Ver historial:  Get-ScheduledTaskInfo -TaskName '$TaskName'"
Write-Host "  Deshabilitar:   Disable-ScheduledTask -TaskName '$TaskName'"
Write-Host "  Eliminar:       Unregister-ScheduledTask -TaskName '$TaskName' -Confirm:`$false"
Write-Host ""
Write-Host "LOGS en: $ProjectDir\logs\"
Write-Host "======================================================================"