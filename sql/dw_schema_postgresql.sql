-- =====================================================================
-- DATA WAREHOUSE BOUTIQUE VÉRTICE - ESQUEMA OPTIMIZADO POSTGRESQL
-- Incluye feedback del profesor: monto_vendido en tablas de hechos
-- =====================================================================

-- ---------------------------------------------------------------------
-- DIMENSIONES
-- ---------------------------------------------------------------------

CREATE TABLE Dim_Tiempo (
    Id_Tiempo   SERIAL PRIMARY KEY,
    Fecha       DATE NOT NULL UNIQUE,
    Dia         INT NOT NULL,
    Mes         INT NOT NULL,
    Anio        INT NOT NULL,
    Trimestre   INT NOT NULL,
    Dia_Semana  INT NOT NULL,  -- 1=Lunes, 7=Domingo
    Es_Fin_Semana BOOLEAN NOT NULL,
    Es_Feriado  BOOLEAN DEFAULT FALSE
);

CREATE TABLE Dim_Prenda (
    Id_Prenda       SERIAL PRIMARY KEY,
    Nombre_Prenda   VARCHAR(100) NOT NULL,
    Color           VARCHAR(50),
    Talla           VARCHAR(20),
    Categoria       VARCHAR(100),
    UNIQUE (Nombre_Prenda, Color, Talla, Categoria)
);

CREATE TABLE Dim_FormaPago (
    Id_FormaPago    SERIAL PRIMARY KEY,
    Tipo_FormaPago  VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE Dim_Promocion (
    Id_Promocion      SERIAL PRIMARY KEY,
    Nombre_Promocion  VARCHAR(100) NOT NULL UNIQUE,
    Descuento         DECIMAL(5,2) DEFAULT 0
);

CREATE TABLE Dim_Vendedor (
    Id_Vendedor      SERIAL PRIMARY KEY,
    Nombre_Vendedor  VARCHAR(100) NOT NULL UNIQUE
);

-- ---------------------------------------------------------------------
-- TABLAS DE HECHOS (Con monto_vendido según feedback profesor)
-- ---------------------------------------------------------------------

-- Hechos: ventas de prendas por producto y tiempo (con monto_vendido)
CREATE TABLE Fact_Ventas_Prendas (
    Id_Prenda         INT NOT NULL,
    Id_Tiempo         INT NOT NULL,
    Cantidad_Vendida  INT NOT NULL,
    Monto_Vendido     DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (Id_Prenda, Id_Tiempo),
    FOREIGN KEY (Id_Prenda) REFERENCES Dim_Prenda (Id_Prenda),
    FOREIGN KEY (Id_Tiempo) REFERENCES Dim_Tiempo (Id_Tiempo)
);

-- Hechos: ingresos totales agregados por periodo de tiempo
CREATE TABLE Fact_Ingresos_Temporales (
    Id_Tiempo          INT NOT NULL,
    Monto_Total_Venta  DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (Id_Tiempo),
    FOREIGN KEY (Id_Tiempo) REFERENCES Dim_Tiempo (Id_Tiempo)
);

-- Hechos: transacciones por forma de pago y tiempo (solo frecuencia)
CREATE TABLE Fact_Transacciones (
    Id_FormaPago            INT NOT NULL,
    Id_Tiempo               INT NOT NULL,
    Cantidad_Transacciones  INT NOT NULL,
    PRIMARY KEY (Id_FormaPago, Id_Tiempo),
    FOREIGN KEY (Id_FormaPago) REFERENCES Dim_FormaPago (Id_FormaPago),
    FOREIGN KEY (Id_Tiempo) REFERENCES Dim_Tiempo (Id_Tiempo)
);

-- Hechos: ventas asociadas a promociones (con monto_vendido)
CREATE TABLE Fact_Venta_Promociones (
    Id_Prenda         INT NOT NULL,
    Id_Promocion      INT NOT NULL,
    Id_Tiempo         INT NOT NULL,
    Cantidad_Vendida  INT NOT NULL,
    Monto_Vendido     DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (Id_Prenda, Id_Promocion, Id_Tiempo),
    FOREIGN KEY (Id_Prenda) REFERENCES Dim_Prenda (Id_Prenda),
    FOREIGN KEY (Id_Promocion) REFERENCES Dim_Promocion (Id_Promocion),
    FOREIGN KEY (Id_Tiempo) REFERENCES Dim_Tiempo (Id_Tiempo)
);

-- Hechos: rendimiento de vendedores por periodo
CREATE TABLE Hechos_Rendimiento (
    Id_Vendedor         INT NOT NULL,
    Id_Tiempo           INT NOT NULL,
    Monto_Total_Venta   DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (Id_Vendedor, Id_Tiempo),
    FOREIGN KEY (Id_Vendedor) REFERENCES Dim_Vendedor (Id_Vendedor),
    FOREIGN KEY (Id_Tiempo) REFERENCES Dim_Tiempo (Id_Tiempo)
);

-- ---------------------------------------------------------------------
-- ÍNDICES PARA OPTIMIZACIÓN DE CONSULTAS
-- ---------------------------------------------------------------------

CREATE INDEX idx_fact_ventas_tiempo ON Fact_Ventas_Prendas(Id_Tiempo);
CREATE INDEX idx_fact_ventas_prenda ON Fact_Ventas_Prendas(Id_Prenda);
CREATE INDEX idx_fact_ingresos_tiempo ON Fact_Ingresos_Temporales(Id_Tiempo);
CREATE INDEX idx_fact_trans_tiempo ON Fact_Transacciones(Id_Tiempo);
CREATE INDEX idx_fact_promo_tiempo ON Fact_Venta_Promociones(Id_Tiempo);
CREATE INDEX idx_fact_promo_prenda ON Fact_Venta_Promociones(Id_Prenda);
CREATE INDEX idx_hechos_vendedor_tiempo ON Hechos_Rendimiento(Id_Tiempo);
CREATE INDEX idx_dim_tiempo_fecha ON Dim_Tiempo(Fecha);
CREATE INDEX idx_dim_prenda_nombre ON Dim_Prenda(Nombre_Prenda);