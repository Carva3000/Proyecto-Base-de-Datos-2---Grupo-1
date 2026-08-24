-- =====================================================================
-- MODELO DIMENSIONAL HEFESTO (Constelación de hechos)
-- Data Warehouse - Script de creación de tablas (Modelo Físico)
-- =====================================================================
-- Generado a partir del diagrama ERD proporcionado.
-- Sintaxis compatible con PostgreSQL (SERIAL).
--   - Para MySQL: reemplazar SERIAL por INT ... AUTO_INCREMENT
--   - Para SQL Server: reemplazar SERIAL por INT ... IDENTITY(1,1)
-- =====================================================================

-- ---------------------------------------------------------------------
-- DIMENSIONES
-- ---------------------------------------------------------------------

CREATE TABLE Dim_Tiempo (
    Id_Tiempo   SERIAL PRIMARY KEY,
    Mes         INT NOT NULL,
    Anio        INT NOT NULL
);

CREATE TABLE Dim_Prenda (
    Id_prenda       SERIAL PRIMARY KEY,
    Nombre_Prenda   VARCHAR(100) NOT NULL,
    Color           VARCHAR(50),
    Talla           VARCHAR(20),
    Categoria       VARCHAR(100)
);

CREATE TABLE Dim_FormaPago (
    Id_FormaPago    SERIAL PRIMARY KEY,
    Tipo_FormaPago  VARCHAR(50) NOT NULL
);

CREATE TABLE Dim_Promocion (
    Id_Promocion      SERIAL PRIMARY KEY,
    Nombre_Promocion  VARCHAR(100) NOT NULL,
    Descuento         DECIMAL(5,2)
);

CREATE TABLE Dim_Vendedor (
    Id_Vendedor      SERIAL PRIMARY KEY,
    Nombre_Vendedor  VARCHAR(100) NOT NULL
);

-- ---------------------------------------------------------------------
-- TABLAS DE HECHOS
-- ---------------------------------------------------------------------

-- Hechos: ventas de prendas por producto y tiempo
CREATE TABLE Fact_Ventas_prendas (
    Id_Prenda         INT NOT NULL,
    Id_Tiempo         INT NOT NULL,
    Cantidad_Vendida  INT NOT NULL,
    PRIMARY KEY (Id_Prenda, Id_Tiempo),
    FOREIGN KEY (Id_Prenda) REFERENCES Dim_Prenda (Id_prenda),
    FOREIGN KEY (Id_Tiempo) REFERENCES Dim_Tiempo (Id_Tiempo)
);

-- Hechos: ingresos totales agregados por periodo de tiempo
CREATE TABLE Fact_Ingresos_temporales (
    Id_Tiempo          INT NOT NULL,
    Monto_Total_Venta  DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (Id_Tiempo),
    FOREIGN KEY (Id_Tiempo) REFERENCES Dim_Tiempo (Id_Tiempo)
);

-- Hechos: transacciones por forma de pago y tiempo
CREATE TABLE Fact_Transacciones (
    Id_FormaPago            INT NOT NULL,
    Id_Tiempo               INT NOT NULL,
    Cantidad_Transacciones  INT NOT NULL,
    PRIMARY KEY (Id_FormaPago, Id_Tiempo),
    FOREIGN KEY (Id_FormaPago) REFERENCES Dim_FormaPago (Id_FormaPago),
    FOREIGN KEY (Id_Tiempo) REFERENCES Dim_Tiempo (Id_Tiempo)
);

-- Hechos: ventas asociadas a promociones
CREATE TABLE Fact_Venta_Promociones (
    Id_Prenda         INT NOT NULL,
    Id_Promocion      INT NOT NULL,
    Id_Tiempo         INT NOT NULL,
    Cantidad_Vendida  INT NOT NULL,
    PRIMARY KEY (Id_Prenda, Id_Promocion, Id_Tiempo),
    FOREIGN KEY (Id_Prenda) REFERENCES Dim_Prenda (Id_prenda),
    FOREIGN KEY (Id_Promocion) REFERENCES Dim_Promocion (Id_Promocion),
    FOREIGN KEY (Id_Tiempo) REFERENCES Dim_Tiempo (Id_Tiempo)
);

-- Hechos: rendimiento de vendedores por periodo
CREATE TABLE Hechos_rendimiento (
    Id_Vendedor         INT NOT NULL,
    Id_Tiempo           INT NOT NULL,
    Monto_Total_Venta   DECIMAL(12,2) NOT NULL,
    PRIMARY KEY (Id_Vendedor, Id_Tiempo),
    FOREIGN KEY (Id_Vendedor) REFERENCES Dim_Vendedor (Id_Vendedor),
    FOREIGN KEY (Id_Tiempo) REFERENCES Dim_Tiempo (Id_Tiempo)
);
