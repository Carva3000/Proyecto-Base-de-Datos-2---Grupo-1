# Guía de Conexión Power BI - Data Warehouse Boutique Vértice

## Resumen Conceptual (Lo que pide el profesor)

El profesor solicita **investigación conceptual** sobre cómo Power BI se conectaría a la base de datos creada. **NO es obligatorio implementar dashboards complejos**, solo documentar el proceso de conexión.

---

## 1. Arquitectura de Conexión

```
┌─────────────────┐     PostgreSQL      ┌─────────────────┐
│   Power BI      │ ──────────────────► │  Data Warehouse │
│   Desktop/Service│   (Driver ODBC/    │  (boutique_     │
│                 │    Conector nativo) │   vertice_dw)   │
└─────────────────┘                     └─────────────────┘
       │                                       │
       ▼                                       ▼
┌─────────────────┐                     ┌─────────────────┐
│  Modelado de    │                     │  Tablas Dimens. │
│  datos (Star    │                     │  + Hechos       │
│  Schema)        │                     │                 │
└─────────────────┘                     └─────────────────┘
```

---

## 2. Métodos de Conexión Disponibles

### A. Conector Nativo PostgreSQL (Recomendado)
- **Power BI Desktop**: `Obtener datos` → `PostgreSQL database`
- **Power BI Service**: Requiere *On-premises data gateway*

### B. Conector ODBC
- Requiere driver `psqlodbc` instalado en la máquina
- `Obtener datos` → `ODBC` → Seleccionar DSN PostgreSQL

### C. Conexión DirectQuery vs Import
| Modo | Ventajas | Desventajas |
|------|----------|-------------|
| **Import** | Rendimiento óptimo, DAX completo | Datos estáticos hasta refresh |
| **DirectQuery** | Datos en tiempo real | Limitaciones DAX, más lento |

**Recomendación**: **Import** con *Scheduled Refresh* diario (después del ETL 03:00)

---

## 3. Pasos de Configuración en Power BI Desktop

### Paso 1: Obtener Datos
```
Inicio → Obtener datos → PostgreSQL database → Conectar
```

### Paso 2: Configurar Conexión
```
Servidor: localhost:5432 (o IP del servidor)
Base de datos: boutique_vertice_dw
Modo: Import (recomendado)
```

### Paso 3: Autenticación
```
Usuario: postgres
Contraseña: [tu_password]
```

### Paso 4: Seleccionar Tablas (Modelo Estrella)
Marcar **TODAS** las tablas:
- ✅ Dim_Tiempo
- ✅ Dim_Prenda  
- ✅ Dim_FormaPago
- ✅ Dim_Promocion
- ✅ Dim_Vendedor
- ✅ Fact_Ventas_Prendas
- ✅ Fact_Ingresos_Temporales
- ✅ Fact_Transacciones
- ✅ Fact_Venta_Promociones
- ✅ Hechos_Rendimiento

### Paso 5: Verificar Relaciones (Modelado)
Power BI detecta automáticamente las FK. Verificar:
```
Dim_Tiempo (1) ───< (N) Fact_Ventas_Prendas
Dim_Prenda  (1) ───< (N) Fact_Ventas_Prendas
Dim_FormaPago (1) ───< (N) Fact_Transacciones
Dim_Tiempo (1) ───< (N) Fact_Transacciones
Dim_Prenda (1) ───< (N) Fact_Venta_Promociones
Dim_Promocion (1) ───< (N) Fact_Venta_Promociones
Dim_Tiempo (1) ───< (N) Fact_Venta_Promociones
Dim_Vendedor (1) ───< (N) Hechos_Rendimiento
Dim_Tiempo (1) ───< (N) Hechos_Rendimiento
Dim_Tiempo (1) ───< (1) Fact_Ingresos_Temporales
```

---

## 4. Medidas DAX Sugeridas (Para las 8 Preguntas)

```dax
-- P1: Prendas más vendidas
Top Prendas = 
TOPN(10, 
    SUMMARIZE(
        Fact_Ventas_Prendas,
        Dim_Prenda[Nombre_Prenda],
        Dim_Prenda[Color],
        Dim_Prenda[Talla],
        "Total Unidades", SUM(Fact_Ventas_Prendas[Cantidad_Vendida])
    ),
    [Total Unidades], DESC
)

-- P2: Ventas por mes
Ventas Por Mes = 
SUMMARIZE(
    Fact_Ingresos_Temporales,
    Dim_Tiempo[Anio],
    Dim_Tiempo[Mes],
    "Total Ingresos", SUM(Fact_Ingresos_Temporales[Monto_Total_Venta])
)

-- P3: Top Vendedores
Top Vendedores = 
SUMMARIZE(
    Hechos_Rendimiento,
    Dim_Vendedor[Nombre_Vendedor],
    "Total Ingresos", SUM(Hechos_Rendimiento[Monto_Total_Venta])
)

-- P4: Formas de pago (frecuencia)
Transacciones Por Pago = 
SUMMARIZE(
    Fact_Transacciones,
    Dim_FormaPago[Tipo_FormaPago],
    "Total Transacciones", SUM(Fact_Transacciones[Cantidad_Transacciones])
)

-- P5: Ingresos por año
Ingresos Anuales = 
SUMMARIZE(
    Fact_Ingresos_Temporales,
    Dim_Tiempo[Anio],
    "Total Año", SUM(Fact_Ingresos_Temporales[Monto_Total_Venta])
)

-- P6: Menos rotación
Menos Rotacion = 
TOPN(10,
    SUMMARIZE(
        Fact_Ventas_Prendas,
        Dim_Prenda[Nombre_Prenda],
        Dim_Prenda[Color],
        Dim_Prenda[Talla],
        "Unidades", SUM(Fact_Ventas_Prendas[Cantidad_Vendida])
    ),
    [Unidades], ASC
)

-- P7: Ventas en oferta
Ventas Oferta = 
CALCULATE(
    SUM(Fact_Venta_Promociones[Cantidad_Vendida]),
    Dim_Promocion[Nombre_Promocion] <> "Sin Promoción"
)

-- P8: Prenda + Color top
PrendaColor Top = 
TOPN(10,
    SUMMARIZE(
        Fact_Ventas_Prendas,
        Dim_Prenda[Nombre_Prenda],
        Dim_Prenda[Color],
        "Total", SUM(Fact_Ventas_Prendas[Cantidad_Vendida])
    ),
    [Total], DESC
)
```

---

## 5. Automatización de Refresh (Power BI Service)

### Configuración Requerida:
1. **Publicar** reporte a Power BI Service (app.powerbi.com)
2. **Instalar On-premises Data Gateway** en servidor BD
3. **Configurar Gateway** en Power BI Service → Configuración → Gateways
4. **Programar Actualización** diaria a las **04:00** (1h después del ETL)

```
Horario sugerido:
03:00 - ETL Diario (Python + Task Scheduler)
04:00 - Power BI Refresh (via Gateway)
04:30 - Reportes listos para usuarios
```

---

## 6. Seguridad y Buenas Prácticas

### Seguridad a nivel de fila (RLS) - Opcional
```dax
-- Ejemplo: Vendedor solo ve sus ventas
Filtro_Vendedor = 
USERNAME() = "dominio\" & Dim_Vendedor[Nombre_Vendedor]
```

### Optimización
- Desactivar carga de columnas innecesarias
- Usar `Table.Buffer` en Power Query para tablas pequeñas
- Configurar *Incremental Refresh* en tablas de hechos grandes

---

## 7. Entregable para el Profesor

**Documento de 1-2 páginas con:**
1. Diagrama arquitectura (como arriba)
2. Pasos de conexión (sección 3)
3. Modo elegido (Import + Scheduled Refresh) y justificación
4. Medidas DAX principales (sección 4)
5. Estrategia de automatización refresh (sección 5)
6. Capturas de pantalla: conexión, modelo relaciones, programar actualización

**NO requerido:** Dashboards visuales complejos, publicación real, gateway instalado.

---

## 8. Troubleshooting Común

| Error | Solución |
|-------|----------|
| "Driver not found" | Instalar `psqlodbc` o usar conector nativo |
| "Connection timeout" | Verificar `postgresql.conf`: `listen_addresses = '*'`, `pg_hba.conf` permitir IP |
| "Authentication failed" | Verificar usuario/contraseña, `pg_hba.conf` método `md5` |
| Refresh falla en Service | Gateway offline, credenciales expiradas, firewall bloquea puerto 5432 |

---

## Conclusión

La conexión Power BI → PostgreSQL DW es **estándar y nativa**. El modelo estrella ya implementado en el DW permite análisis directo sin transformaciones complejas en Power Query. La automatización completa (ETL 03:00 → Refresh 04:00) garantiza datos actualizados diariamente sin intervención manual.