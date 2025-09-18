
USE DataWarehouse;
GO

IF OBJECT_ID('staging.OrderLine','U') IS NOT NULL DROP TABLE staging.OrderLine;
IF OBJECT_ID('staging.Payment','U')   IS NOT NULL DROP TABLE staging.Payment;
IF OBJECT_ID('staging.[Order]','U')   IS NOT NULL DROP TABLE staging.[Order];
IF OBJECT_ID('staging.ProductVariant','U') IS NOT NULL DROP TABLE staging.ProductVariant;
IF OBJECT_ID('staging.Product','U')   IS NOT NULL DROP TABLE staging.Product;
IF OBJECT_ID('staging.Customer','U')  IS NOT NULL DROP TABLE staging.Customer;
IF OBJECT_ID('staging.Channel','U')   IS NOT NULL DROP TABLE staging.Channel;
IF OBJECT_ID('staging.Category','U')  IS NOT NULL DROP TABLE staging.Category;

CREATE TABLE staging.Category(
  CategoryID       INT            NOT NULL PRIMARY KEY,
  CategoryName     NVARCHAR(200)  NOT NULL,
   -- audit
  dwh_create_date    DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE staging.Channel(
  ChannelID        INT            NOT NULL PRIMARY KEY,
  ChannelName      NVARCHAR(200)  NOT NULL,
  ChannelType      NVARCHAR(100)  NULL,
  ChannelRegion    NVARCHAR(100)  NULL,
  -- audit
  dwh_create_date    DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE staging.Customer(
  CustomerID       INT            NOT NULL PRIMARY KEY,
  CustomerSegment  NVARCHAR(100)  NULL,
  CustomerName     NVARCHAR(200)  NOT NULL,
  CustomerEmail    NVARCHAR(320)  NULL,
  CountryName      NVARCHAR(100)  NULL,
  ProvinceOrState  NVARCHAR(100)  NULL,
  CustomerCreatedAt DATETIME2(0)  NULL,
  -- audit
  dwh_create_date    DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE staging.Product(
  ProductID        INT            NOT NULL PRIMARY KEY,
  CategoryID       INT            NULL REFERENCES staging.Category(CategoryID),
  ProductName      NVARCHAR(255)  NOT NULL,
  IsActive         BIT            NOT NULL,
  ProductCreatedAt DATETIME2(0)   NULL,
  -- audit
  dwh_create_date    DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE staging.ProductVariant(
  VariantID        INT            NOT NULL PRIMARY KEY,
  ProductID        INT            NOT NULL REFERENCES staging.Product(ProductID),
  SKU              NVARCHAR(120)  NOT NULL UNIQUE,
  VariantOptions   NVARCHAR(255)  NULL,      -- from option_summary
  UnitCost         DECIMAL(18,2)  NULL,
  IsActive         BIT            NOT NULL,
  VariantCreatedAt DATETIME2(0)   NULL,
  -- audit
  dwh_create_date    DATETIME2 DEFAULT GETDATE()
);

-- Using [Order] to avoid reserved keyword issues; friendly column names inside.
CREATE TABLE staging.[Order](
  OrderID          INT            NOT NULL PRIMARY KEY,
  OrderNumber      NVARCHAR(50)   NOT NULL,
  CustomerID       INT            NOT NULL REFERENCES staging.Customer(CustomerID),
  ChannelID        INT            NULL REFERENCES staging.Channel(ChannelID),
  OrderDateTime    DATETIME2(0)   NOT NULL,
  OrderStatus      NVARCHAR(50)   NULL,
  CurrencyCode     NVARCHAR(10)   NULL,
  SubtotalAmount   DECIMAL(18,2)  NULL,
  DiscountAmount   DECIMAL(18,2)  NULL,
  TaxAmount        DECIMAL(18,2)  NULL,
  ShippingAmount   DECIMAL(18,2)  NULL,
  -- audit
  dwh_create_date    DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE staging.OrderLine(
  OrderLineID        INT            NOT NULL PRIMARY KEY,
  OrderID            INT            NOT NULL REFERENCES staging.[Order](OrderID),
  VariantID          INT            NOT NULL REFERENCES staging.ProductVariant(VariantID),
  LineTitle          NVARCHAR(255)  NULL,   -- from title_snapshot
  Quantity           INT            NOT NULL,
  UnitPrice          DECIMAL(18,2)  NULL,
  LineDiscountAmount DECIMAL(18,2)  NULL,
  LineTaxAmount      DECIMAL(18,2)  NULL,
  -- convenience net amount (persisted)
  LineNetAmount AS ( (Quantity * ISNULL(UnitPrice,0.00)) - ISNULL(LineDiscountAmount,0.00) + ISNULL(LineTaxAmount,0.00) ) PERSISTED,
  -- audit
  dwh_create_date    DATETIME2 DEFAULT GETDATE()
);

CREATE TABLE staging.Payment(
  PaymentID        INT            NOT NULL PRIMARY KEY,
  OrderID          INT            NOT NULL REFERENCES staging.[Order](OrderID),
  PaymentMethod    NVARCHAR(50)   NULL,
  PaymentAmount    DECIMAL(18,2)  NOT NULL,
  PaidAtDateTime   DATETIME2(0)   NULL,
  PaymentStatus    NVARCHAR(50)   NULL,
  TransactionRef   NVARCHAR(100)  NULL,
  -- audit
  dwh_create_date    DATETIME2 DEFAULT GETDATE()
);
