-- =====================================================================
-- CONSULTAS SQL PARA LAS 8 PREGUNTAS DEL PROYECTO
-- Data Warehouse Boutique Vértice
-- =====================================================================

-- ---------------------------------------------------------------------
-- PREGUNTA 1: ¿Cuáles son las prendas más vendidas?
-- Métrica: Cantidad total vendida (top 10)
-- ---------------------------------------------------------------------
SELECT 
    dp.Nombre_Prenda,
    dp.Color,
    dp.Talla,
    dp.Categoria,
    SUM(fvp.Cantidad_Vendida) AS Total_Unidades_Vendidas,
    SUM(fvp.Monto_Vendido) AS Total_Ingresos
FROM Fact_Ventas_Prendas fvp
JOIN Dim_Prenda dp ON fvp.Id_Prenda = dp.Id_Prenda
GROUP BY dp.Nombre_Prenda, dp.Color, dp.Talla, dp.Categoria
ORDER BY Total_Unidades_Vendidas DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- PREGUNTA 2: ¿Qué meses presentan mayores ventas?
-- Métrica: Ingresos totales por mes
-- ---------------------------------------------------------------------
SELECT 
    dt.Anio,
    dt.Mes,
    TO_CHAR(MAKE_DATE(dt.Anio, dt.Mes, 1), 'Month') AS Nombre_Mes,
    SUM(fit.Monto_Total_Venta) AS Total_Ingresos_Mes
FROM Fact_Ingresos_Temporales fit
JOIN Dim_Tiempo dt ON fit.Id_Tiempo = dt.Id_Tiempo
GROUP BY dt.Anio, dt.Mes
ORDER BY Total_Ingresos_Mes DESC;

-- ---------------------------------------------------------------------
-- PREGUNTA 3: ¿Qué vendedores obtienen mejores resultados?
-- Métrica: Ingresos totales generados por vendedor
-- ---------------------------------------------------------------------
SELECT 
    dv.Nombre_Vendedor,
    SUM(hr.Monto_Total_Venta) AS Total_Ingresos,
    COUNT(DISTINCT hr.Id_Tiempo) AS Dias_Con_Ventas,
    ROUND(SUM(hr.Monto_Total_Venta) / NULLIF(COUNT(DISTINCT hr.Id_Tiempo), 0), 2) AS Promedio_Diario
FROM Hechos_Rendimiento hr
JOIN Dim_Vendedor dv ON hr.Id_Vendedor = dv.Id_Vendedor
GROUP BY dv.Nombre_Vendedor
ORDER BY Total_Ingresos DESC;

-- ---------------------------------------------------------------------
-- PREGUNTA 4: ¿Cuáles son las formas de pago más utilizadas?
-- Métrica: Frecuencia (Cantidad_Transacciones) - NO monto (feedback profesor)
-- ---------------------------------------------------------------------
SELECT 
    dfp.Tipo_FormaPago,
    SUM(ft.Cantidad_Transacciones) AS Total_Transacciones,
    ROUND(
        SUM(ft.Cantidad_Transacciones) * 100.0 / 
        SUM(SUM(ft.Cantidad_Transacciones)) OVER (), 2
    ) AS Porcentaje_Uso
FROM Fact_Transacciones ft
JOIN Dim_FormaPago dfp ON ft.Id_FormaPago = dfp.Id_FormaPago
GROUP BY dfp.Tipo_FormaPago
ORDER BY Total_Transacciones DESC;

-- ---------------------------------------------------------------------
-- PREGUNTA 5: ¿Cuál es el total de ingresos generados por año?
-- Métrica: Suma de ingresos anuales
-- ---------------------------------------------------------------------
SELECT 
    dt.Anio,
    SUM(fit.Monto_Total_Venta) AS Total_Ingresos_Anual,
    COUNT(DISTINCT dt.Mes) AS Meses_Con_Ventas,
    ROUND(SUM(fit.Monto_Total_Venta) / NULLIF(COUNT(DISTINCT dt.Mes), 0), 2) AS Promedio_Mensual
FROM Fact_Ingresos_Temporales fit
JOIN Dim_Tiempo dt ON fit.Id_Tiempo = dt.Id_Tiempo
GROUP BY dt.Anio
ORDER BY dt.Anio;

-- ---------------------------------------------------------------------
-- PREGUNTA 6: ¿Qué prendas tienen menos rotación?
-- Métrica: Menor cantidad vendida (bottom 10), excluyendo las que nunca se vendieron
-- ---------------------------------------------------------------------
SELECT 
    dp.Nombre_Prenda,
    dp.Color,
    dp.Talla,
    dp.Categoria,
    COALESCE(SUM(fvp.Cantidad_Vendida), 0) AS Total_Unidades_Vendidas,
    COALESCE(SUM(fvp.Monto_Vendido), 0) AS Total_Ingresos
FROM Dim_Prenda dp
LEFT JOIN Fact_Ventas_Prendas fvp ON dp.Id_Prenda = fvp.Id_Prenda
GROUP BY dp.Nombre_Prenda, dp.Color, dp.Talla, dp.Categoria
HAVING COALESCE(SUM(fvp.Cantidad_Vendida), 0) > 0
ORDER BY Total_Unidades_Vendidas ASC
LIMIT 10;

-- ---------------------------------------------------------------------
-- PREGUNTA 7: ¿Prendas que se venden en oferta?
-- Métrica: Cantidad y monto vendidos bajo promociones (excluyendo 'Sin Promoción')
-- ---------------------------------------------------------------------
SELECT 
    dp.Nombre_Prenda,
    dp.Color,
    dp.Talla,
    dp.Categoria,
    dpr.Nombre_Promocion,
    dpr.Descuento,
    SUM(fvprom.Cantidad_Vendida) AS Unidades_En_Oferta,
    SUM(fvprom.Monto_Vendido) AS Ingresos_En_Oferta
FROM Fact_Venta_Promociones fvprom
JOIN Dim_Prenda dp ON fvprom.Id_Prenda = dp.Id_Prenda
JOIN Dim_Promocion dpr ON fvprom.Id_Promocion = dpr.Id_Promocion
WHERE dpr.Nombre_Promocion != 'Sin Promoción'
GROUP BY dp.Nombre_Prenda, dp.Color, dp.Talla, dp.Categoria, dpr.Nombre_Promocion, dpr.Descuento
ORDER BY Unidades_En_Oferta DESC;

-- ---------------------------------------------------------------------
-- PREGUNTA 8: ¿Qué combinación de prenda y color registra el mayor volumen de ventas?
-- Métrica: Total unidades vendidas agrupado por prenda + color
-- ---------------------------------------------------------------------
SELECT 
    dp.Nombre_Prenda,
    dp.Color,
    SUM(fvp.Cantidad_Vendida) AS Total_Unidades_Vendidas,
    SUM(fvp.Monto_Vendido) AS Total_Ingresos,
    COUNT(DISTINCT dp.Talla) AS Variedad_Tallas
FROM Fact_Ventas_Prendas fvp
JOIN Dim_Prenda dp ON fvp.Id_Prenda = dp.Id_Prenda
GROUP BY dp.Nombre_Prenda, dp.Color
ORDER BY Total_Unidades_Vendidas DESC
LIMIT 10;

-- ---------------------------------------------------------------------
-- CONSULTAS ADICIONALES DE ANÁLISIS (Bonus)
-- ---------------------------------------------------------------------

-- Ventas por día de la semana (para turnos de personal)
SELECT 
    CASE dt.Dia_Semana 
        WHEN 1 THEN 'Lunes' WHEN 2 THEN 'Martes' WHEN 3 THEN 'Miércoles'
        WHEN 4 THEN 'Jueves' WHEN 5 THEN 'Viernes' WHEN 6 THEN 'Sábado'
        WHEN 7 THEN 'Domingo' END AS Dia_Semana,
    dt.Es_Fin_Semana,
    COUNT(DISTINCT dt.Fecha) AS Dias_Analizados,
    SUM(fit.Monto_Total_Venta) AS Total_Ingresos,
    ROUND(AVG(fit.Monto_Total_Venta), 2) AS Promedio_Diario
FROM Fact_Ingresos_Temporales fit
JOIN Dim_Tiempo dt ON fit.Id_Tiempo = dt.Id_Tiempo
GROUP BY dt.Dia_Semana, dt.Es_Fin_Semana
ORDER BY dt.Dia_Semana;

-- Ventas por hora (requiere que el Excel tenga hora, si no, usar día)
-- Top 5 prendas por categoría
SELECT 
    dp.Categoria,
    dp.Nombre_Prenda,
    dp.Color,
    SUM(fvp.Cantidad_Vendida) AS Unidades_Vendidas
FROM Fact_Ventas_Prendas fvp
JOIN Dim_Prenda dp ON fvp.Id_Prenda = dp.Id_Prenda
GROUP BY dp.Categoria, dp.Nombre_Prenda, dp.Color
ORDER BY dp.Categoria, Unidades_Vendidas DESC;