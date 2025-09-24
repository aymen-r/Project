USE DataWarehouse;
GO

/* 1) DimDate — build from dates present in staging */
WITH D AS (
  SELECT CAST(o.OrderDateTime  AS DATE) AS d FROM staging.[Order] o
  UNION
  SELECT CAST(p.PaidAtDateTime AS DATE) FROM staging.Payment p WHERE p.PaidAtDateTime IS NOT NULL
)
INSERT INTO warehouse.DimDate
  (DateKey, [Date], [Year], [Quarter], [Month], [Day], MonthName, DayName, WeekOfYear)
SELECT DISTINCT
  (YEAR(d)*10000 + MONTH(d)*100 + DAY(d))        AS DateKey,
  d                                              AS [Date],
  YEAR(d)                                        AS [Year],
  DATEPART(QUARTER, d)                           AS [Quarter],
  MONTH(d)                                       AS [Month],
  DAY(d)                                         AS [Day],
  DATENAME(MONTH, d)                             AS MonthName,
  DATENAME(WEEKDAY, d)                           AS DayName,
  DATEPART(WEEK, d)                              AS WeekOfYear
FROM D;
GO

/* 2) DimChannel — simple Type-1 snapshot */
INSERT INTO warehouse.DimChannel (ChannelBK, ChannelName, ChannelType, ChannelRegion)
SELECT DISTINCT
  ch.ChannelID, ch.ChannelName, ch.ChannelType, ch.ChannelRegion
FROM staging.Channel ch;
GO

/* 3) DimCustomer — (no SCD) */
INSERT INTO warehouse.DimCustomer
  (CustomerBK, CustomerSegment, CustomerName, CustomerEmail, CountryName, ProvinceOrState,
   EffectiveStartDate, EffectiveEndDate, IsCurrent)
SELECT DISTINCT
  c.CustomerID,
  c.CustomerSegment,
  c.CustomerName,
  c.CustomerEmail,
  c.CountryName,
  c.ProvinceOrState,
  CAST(ISNULL(c.CustomerCreatedAt, '1900-01-01') AS DATE) AS EffectiveStartDate,
  NULL  AS EffectiveEndDate,
  1     AS IsCurrent
FROM staging.Customer c;
GO

/* 4) DimProduct — variant-level row with product/category attributes */
INSERT INTO warehouse.DimProduct
  (VariantBK, ProductBK, SKU, ProductName, VariantOptions, CategoryID, CategoryName,
   UnitCost, IsActive, ProductCreatedAt)
SELECT DISTINCT
  v.VariantID         AS VariantBK,
  p.ProductID         AS ProductBK,
  v.SKU,
  p.ProductName,
  v.VariantOptions,
  p.CategoryID,
  cat.CategoryName,
  v.UnitCost,
  v.IsActive,
  p.ProductCreatedAt
FROM staging.ProductVariant v
JOIN staging.Product  p   ON p.ProductID  = v.ProductID
LEFT JOIN staging.Category cat ON cat.CategoryID = p.CategoryID;
GO

/* 5) FactSales — 1 row per order line (look up SKs from dims) */
INSERT INTO warehouse.FactSales
  (OrderID, OrderLineID, CurrencyCode,
   CustomerKey, ProductKey, ChannelKey, OrderDateKey,
   Quantity, UnitPrice, LineDiscount, LineTax, OrderSubtotal, OrderShipping)
SELECT
  ol.OrderID,
  ol.OrderLineID,
  o.CurrencyCode,
  dc.CustomerKey,
  dp.ProductKey,
  dch.ChannelKey,
  (YEAR(CAST(o.OrderDateTime AS DATE))*10000 + MONTH(CAST(o.OrderDateTime AS DATE))*100 + DAY(CAST(o.OrderDateTime AS DATE))) AS OrderDateKey,
  ol.Quantity,
  ol.UnitPrice,
  ol.LineDiscountAmount,
  ol.LineTaxAmount,
  o.SubtotalAmount,
  o.ShippingAmount
FROM staging.OrderLine ol
JOIN staging.[Order]      o   ON o.OrderID     = ol.OrderID
JOIN warehouse.DimCustomer dc  ON dc.CustomerBK = o.CustomerID AND dc.IsCurrent = 1
JOIN warehouse.DimProduct  dp  ON dp.VariantBK  = ol.VariantID
LEFT JOIN warehouse.DimChannel dch ON dch.ChannelBK = o.ChannelID;
GO

/* 6) FactPayment — 1 row per payment */
INSERT INTO warehouse.FactPayment
  (PaymentID, OrderID, OrderDateKey, PaidDateKey,
   PaymentAmount, PaymentMethod, PaymentStatus, TransactionRef)
SELECT
  p.PaymentID,
  p.OrderID,
  (YEAR(CAST(o.OrderDateTime    AS DATE))*10000 + MONTH(CAST(o.OrderDateTime    AS DATE))*100 + DAY(CAST(o.OrderDateTime    AS DATE))) AS OrderDateKey,
  CASE WHEN p.PaidAtDateTime IS NOT NULL
       THEN (YEAR(CAST(p.PaidAtDateTime AS DATE))*10000 + MONTH(CAST(p.PaidAtDateTime AS DATE))*100 + DAY(CAST(p.PaidAtDateTime AS DATE)))
  END                                                                                                                                    AS PaidDateKey,
  p.PaymentAmount,
  p.PaymentMethod,
  p.PaymentStatus,
  p.TransactionRef
FROM staging.Payment p
LEFT JOIN staging.[Order] o ON o.OrderID = p.OrderID;
GO
