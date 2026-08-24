# Data Warehouse Boutique Vertice - Fase 3

Implementación completa de Data Warehouse con automatización ETL para Boutique Vertice.

## Estructura del Proyecto

```
Proyecto Base de Datos 2/
├── config/
│   ├── config.py              # Configuración BD y rutas
│   ├── requirements.txt       # Dependencias Python
│   └── .env.example           # Template variables entorno
├── data/
│   ├── Carga_Historica_2025_2026.xlsx  # Datos históricos (14 meses)
│   └── Carga_Diaria.xlsx             # Datos diarios (ejemplo)
├── docs/
│   ├── GUIA_POWER_BI.md       # Guía conexión Power BI (conceptual)
│   └── diagrama hefestos bd.jpg       # Diagrama entidad-relación
├── scripts/
│   ├── etl_historico.py       # Script carga histórica (Excel -> DW)
│   ├── etl_diario.py          # Script carga diaria incremental
│   ├── run_etl_diario.ps1     # Wrapper PowerShell para automatización
│   ├── setup_task_scheduler.ps1   # Configurar Task Scheduler (Admin)
│   └── setup_automatizacion.bat   # Alternativa .bat simple
└── sql/
    ├── dw_schema_postgresql.sql     # Esquema BD optimizado (con feedback profesor)
    ├── consultas_8_preguntas.sql    # SQL para las 8 preguntas del proyecto
    └── hefesto_dw_schema.sql        # Esquema original
```

---

## Requisitos Previos

1. PostgreSQL 14+ instalado y corriendo
2. Python 3.9+ en PATH del sistema
3. Permisos de Administrador (para Task Scheduler)

---

## Instalación Rápida

### 1. Instalar dependencias Python
```bash
pip install -r config/requirements.txt
```

### 2. Configurar variables de entorno
```bash
copy config\.env.example .env
# Editar .env con tus credenciales PostgreSQL
```

### 3. Crear base de datos y esquemas
```bash
# Opción A: Desde psql
psql -U postgres -c "CREATE DATABASE boutique_vertice_dw;"
psql -U postgres -d boutique_vertice_dw -f sql/dw_schema_postgresql.sql

# Opción B: Desde pgAdmin / DBeaver
# 1. Crear BD "boutique_vertice_dw"
# 2. Ejecutar sql/dw_schema_postgresql.sql
```

---

## Carga de Datos

### Carga Histórica (una sola vez)
```bash
python scripts/etl_historico.py
```
Procesa `data/Carga_Historica_2025_2026.xlsx` (1,602 registros) y puebla todas las dimensiones y hechos.

### Carga Diaria (incremental)
```bash
# Carga de ayer (por defecto)
python scripts/etl_diario.py

# Carga fecha específica
python scripts/etl_diario.py --date 2026-07-15
```
Procesa `data/Carga_Diaria.xlsx` solo para fechas nuevas no existentes en DW.

---

## Automatización Diaria (Task Scheduler)

### Opción A: PowerShell (Recomendado - Robusto)
```powershell
# Ejecutar COMO ADMINISTRADOR
.\scripts\setup_task_scheduler.ps1
```
Crea tarea "BoutiqueVertice_ETL_Diario" que:
- Ejecuta diario a las 03:00 AM
- Usuario: SYSTEM (no requiere login)
- Logs en: `logs/etl_diario_YYYYMMDD_HHMMSS.log`
- Reintentos automáticos si falla

### Opción B: Batch Simple
```cmd
# Ejecutar COMO ADMINISTRADOR
scripts\setup_automatizacion.bat
```

### Verificar / Gestionar Tarea
```powershell
# Ver estado
Get-ScheduledTask -TaskName "BoutiqueVertice_ETL_Diario"

# Ejecutar AHORA manualmente
Start-ScheduledTask -TaskName "BoutiqueVertice_ETL_Diario"

# Ver última ejecución
Get-ScheduledTaskInfo -TaskName "BoutiqueVertice_ETL_Diario"

# Deshabilitar
Disable-ScheduledTask -TaskName "BoutiqueVertice_ETL_Diario"
```

---

## Consultas SQL (8 Preguntas)

Ejecutar en pgAdmin / DBeaver / psql:
```bash
psql -U postgres -d boutique_vertice_dw -f sql/consultas_8_preguntas.sql
```

### Respuestas a las 8 Preguntas:

| # | Pregunta | Tabla Principal | Métrica |
|---|----------|-----------------|---------|
| 1 | Prendas más vendidas | Fact_Ventas_Prendas | SUM(Cantidad_Vendida) |
| 2 | Meses con mayores ventas | Fact_Ingresos_Temporales | SUM(Monto_Total_Venta) |
| 3 | Mejores vendedores | Hechos_Rendimiento | SUM(Monto_Total_Venta) |
| 4 | Formas de pago más usadas | Fact_Transacciones | SUM(Cantidad_Transacciones) |
| 5 | Ingresos totales por año | Fact_Ingresos_Temporales | SUM(Monto_Total_Venta) |
| 6 | Prendas con menos rotación | Fact_Ventas_Prendas | SUM(Cantidad_Vendida) ASC |
| 7 | Prendas en oferta | Fact_Venta_Promociones | Filtrar Nombre_Promocion != 'Sin Promoción' |
| 8 | Prenda+Color top ventas | Fact_Ventas_Prendas | Agrupar por Nombre_Prenda, Color |

---

## Power BI (Conceptual)

Ver `docs/GUIA_POWER_BI.md` para:
- Pasos de conexión nativa PostgreSQL
- Modelo estrella automático
- Medidas DAX para las 8 preguntas
- Programación refresh diario (04:00) vía Gateway
- No requiere implementar dashboards, solo documentar concepto

---

## Modelo Dimensional (Constelación Hechos)

```
                    ┌─────────────┐
                    │  Dim_Tiempo │◄──────────────────────┐
                    └──────┬──────┘                       │
                           │                              │
        ┌──────────────────┼──────────────────┐          │
        ▼                  ▼                  ▼          ▼
┌───────────────┐  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐
│Fact_Ventas_   │  │Fact_Ingresos_ │  │Fact_Transacc_ │  │Fact_Venta_    │
│Prendas        │  │Temporales     │  │iones          │  │Promociones    │
└───────┬───────┘  └───────┬───────┘  └───────┬───────┘  └───────┬───────┘
        │                  │                  │                  │
        ▼                  ▼                  ▼                  ▼
┌───────────────┐                              ┌───────────────┐
│  Dim_Prenda   │                              │ Dim_Promocion │
└───────────────┘                              └───────────────┘

┌───────────────┐
│Hechos_Rendim. │
└───────┬───────┘
        │
        ▼
┌───────────────┐     ┌───────────────┐
│ Dim_Vendedor  │     │  Dim_Tiempo   │
└───────────────┘     └───────────────┘
```

---

## Feedback del Profesor Implementado

1. Monto_Vendido agregado a Fact_Ventas_Prendas y Fact_Venta_Promociones
2. Fact_Transacciones solo tiene Cantidad_Transacciones (frecuencia, no monto)
3. Modelo estrella/constelación para consultas performantes
4. Índices en claves foráneas y fechas

---

## Troubleshooting

### Error conexión PostgreSQL
```bash
# Verificar servicio corriendo
services.msc -> postgresql-x64-14 -> Running

# Verificar pg_hba.conf permite conexiones locales
# Verificar postgresql.conf: listen_addresses = '*'
```

### Error "ModuleNotFoundError: psycopg2"
```bash
pip install psycopg2-binary
```

### Task Scheduler no ejecuta
- Ejecutar `scripts/setup_task_scheduler.ps1` como Administrador
- Verificar ExecutionPolicy: `Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
- Revisar logs en `logs/`

### Carga diaria no inserta datos
- Verificar que `data/Carga_Diaria.xlsx` tiene fecha mayor a la máxima en Dim_Tiempo
- El script es idempotente: re-ejecutar no duplica datos (UPSERT)

---

## Entregables Fase 3

| Entregable | Archivo |
|------------|---------|
| Esquema DW SQL | sql/dw_schema_postgresql.sql |
| Script carga histórica | scripts/etl_historico.py |
| Script carga diaria | scripts/etl_diario.py |
| Automatización (Task Scheduler) | scripts/setup_task_scheduler.ps1 + scripts/run_etl_diario.ps1 |
| Consultas 8 preguntas | sql/consultas_8_preguntas.sql |
| Guía Power BI conceptual | docs/GUIA_POWER_BI.md |