/* ============================================================
   Data Warehouse (warehouse schema) — CREATE TABLES
   Grain:
     - DimDate: 1 row per calendar date
     - DimChannel: 1 row per channel
     - DimCustomer: SCD2 (current/dated rows)
     - DimProduct: 1 row per product variant (includes product/category attrs)
     - FactSales: 1 row per order line
     - FactPayment: 1 row per payment
   ============================================================ */
USE DataWarehouse;
GO
IF SCHEMA_ID('warehouse') IS NULL EXEC('CREATE SCHEMA warehouse;');
GO

/* Drop in FK-safe order (facts first) */
IF OBJECT_ID('warehouse.FactPayment','U') IS NOT NULL DROP TABLE warehouse.FactPayment;
IF OBJECT_ID('warehouse.FactSales','U')   IS NOT NULL DROP TABLE warehouse.FactSales;
IF OBJECT_ID('warehouse.DimProduct','U')  IS NOT NULL DROP TABLE warehouse.DimProduct;
IF OBJECT_ID('warehouse.DimCustomer','U') IS NOT NULL DROP TABLE warehouse.DimCustomer;
IF OBJECT_ID('warehouse.DimChannel','U')  IS NOT NULL DROP TABLE warehouse.DimChannel;
IF OBJECT_ID('warehouse.DimDate','U')     IS NOT NULL DROP TABLE warehouse.DimDate;
GO

/* -------------------- DimDate -------------------- */
CREATE TABLE warehouse.DimDate(
  DateKey      INT         NOT NULL PRIMARY KEY,   -- yyyymmdd
  [Date]       DATE        NOT NULL,
  [Year]       INT         NOT NULL,
  [Quarter]    INT         NOT NULL,
  [Month]      INT         NOT NULL,
  [Day]        INT         NOT NULL,
  MonthName    NVARCHAR(20),
  DayName      NVARCHAR(20),
  WeekOfYear   INT,
  CONSTRAINT UQ_DimDate_Date UNIQUE ([Date])
);

/* -------------------- DimChannel  -------------------- */
CREATE TABLE warehouse.DimChannel(
  ChannelKey   INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  ChannelBK    INT               NOT NULL,         -- business key from staging.Channel.ChannelID
  ChannelName  NVARCHAR(200)     NOT NULL,
  ChannelType  NVARCHAR(100)     NULL,
  ChannelRegion NVARCHAR(100)    NULL,
  CONSTRAINT UQ_DimChannel_BK UNIQUE (ChannelBK)
);

/* -------------------- DimCustomer  -------------------- */
CREATE TABLE warehouse.DimCustomer(
  CustomerKey        INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  CustomerBK         INT               NOT NULL,   -- staging.Customer.CustomerID
  CustomerSegment    NVARCHAR(100)     NULL,
  CustomerName       NVARCHAR(200)     NOT NULL,
  CustomerEmail      NVARCHAR(320)     NULL,
  CountryName        NVARCHAR(100)     NULL,
  ProvinceOrState    NVARCHAR(100)     NULL,
  EffectiveStartDate DATE              NOT NULL,
  EffectiveEndDate   DATE              NULL,
  IsCurrent          BIT               NOT NULL DEFAULT (1),
  CONSTRAINT UQ_DimCustomer_BK_Start UNIQUE (CustomerBK, EffectiveStartDate)
);

/* -------------------- DimProduct (variant-level) -------------------- */
CREATE TABLE warehouse.DimProduct(
  ProductKey     INT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  VariantBK      INT               NOT NULL,   -- staging.ProductVariant.VariantID
  ProductBK      INT               NOT NULL,   -- staging.Product.ProductID
  SKU            NVARCHAR(120)     NOT NULL,
  ProductName    NVARCHAR(255)     NOT NULL,
  VariantOptions NVARCHAR(255)     NULL,
  CategoryID     INT               NULL,
  CategoryName   NVARCHAR(200)     NULL,
  UnitCost       DECIMAL(18,2)     NULL,
  IsActive       BIT               NOT NULL DEFAULT(1),
  ProductCreatedAt DATETIME2(0)    NULL,
  CONSTRAINT UQ_DimProduct_VariantBK UNIQUE (VariantBK),
  CONSTRAINT UQ_DimProduct_SKU       UNIQUE (SKU)
);

/* -------------------- FactSales -------------------- */
CREATE TABLE warehouse.FactSales(
  SalesKey        BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  -- Degenerate / trace columns
  OrderID         INT            NOT NULL,
  OrderLineID     INT            NOT NULL,
  CurrencyCode    NVARCHAR(10)   NULL,

  -- Foreign keys to dims
  CustomerKey     INT            NOT NULL,
  ProductKey      INT            NOT NULL,
  ChannelKey      INT            NULL,
  OrderDateKey    INT            NOT NULL,

  -- Measures
  Quantity        INT            NOT NULL,
  UnitPrice       DECIMAL(18,2)  NULL,
  LineDiscount    DECIMAL(18,2)  NULL,
  LineTax         DECIMAL(18,2)  NULL,
  OrderSubtotal   DECIMAL(18,2)  NULL,  -- order-level (optional degenerate)
  OrderShipping   DECIMAL(18,2)  NULL,  -- order-level (optional degenerate)

  CONSTRAINT FK_FactSales_DimDate     FOREIGN KEY (OrderDateKey) REFERENCES warehouse.DimDate(DateKey),
  CONSTRAINT FK_FactSales_DimCustomer FOREIGN KEY (CustomerKey)  REFERENCES warehouse.DimCustomer(CustomerKey),
  CONSTRAINT FK_FactSales_DimProduct  FOREIGN KEY (ProductKey)   REFERENCES warehouse.DimProduct(ProductKey),
  CONSTRAINT FK_FactSales_DimChannel  FOREIGN KEY (ChannelKey)   REFERENCES warehouse.DimChannel(ChannelKey)
);

/* -------------------- FactPayment -------------------- */
CREATE TABLE warehouse.FactPayment(
  PaymentKey     BIGINT IDENTITY(1,1) NOT NULL PRIMARY KEY,
  PaymentID      INT            NOT NULL,
  OrderID        INT            NOT NULL,

  -- Date FKs
  OrderDateKey   INT            NULL,
  PaidDateKey    INT            NULL,

  -- Measures / attrs
  PaymentAmount  DECIMAL(18,2)  NOT NULL,
  PaymentMethod  NVARCHAR(50)   NULL,
  PaymentStatus  NVARCHAR(50)   NULL,
  TransactionRef NVARCHAR(100)  NULL,

  CONSTRAINT FK_FactPayment_OrderDate FOREIGN KEY (OrderDateKey) REFERENCES warehouse.DimDate(DateKey),
  CONSTRAINT FK_FactPayment_PaidDate  FOREIGN KEY (PaidDateKey)  REFERENCES warehouse.DimDate(DateKey)
);
GO


