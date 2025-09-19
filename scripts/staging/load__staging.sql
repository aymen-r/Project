
USE DataWarehouse;
GO

-- Category 
TRUNCATE TABLE staging.Category;
		
INSERT INTO staging.Category (
			CategoryID, 
			CategoryName
	)
	SELECT
		TRY_CONVERT(INT, category_id) AS CategoryID,
		NULLIF(LTRIM(RTRIM(name)),'') AS CategoryName
	FROM (
		SELECT
			*,
			ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY (SELECT 1)) AS flag_last
		FROM raw.Category
		WHERE category_id IS NOT NULL
	) t
	WHERE flag_last = 1; -- Select the most recent record per customer

-- Channel 
TRUNCATE TABLE staging.Channel;
WITH s AS (
SELECT
    TRY_CONVERT(INT, channel_id) AS ChannelID,
    NULLIF(LTRIM(RTRIM(name)),'')  AS ChannelName,
    NULLIF(LTRIM(RTRIM(type)),'')  AS ChannelType,
    NULLIF(LTRIM(RTRIM(region)),'')AS ChannelRegion,
    ROW_NUMBER() OVER (PARTITION BY channel_id ORDER BY (SELECT 1)) AS rn
FROM raw.Channel
)
INSERT staging.Channel(ChannelID, ChannelName, ChannelType, ChannelRegion)
SELECT ChannelID, ChannelName, ChannelType, ChannelRegion
FROM s WHERE rn = 1 AND ChannelID IS NOT NULL;

-- Customer 
TRUNCATE TABLE staging.Customer;
WITH s AS (
  SELECT
    TRY_CONVERT(INT, customer_id)           AS CustomerID,
    NULLIF(LTRIM(RTRIM(segment)),'')        AS CustomerSegment,
    NULLIF(LTRIM(RTRIM(name)),'')           AS CustomerName,
    NULLIF(LTRIM(RTRIM(email)),'')          AS CustomerEmail,
    NULLIF(LTRIM(RTRIM(country)),'')        AS CountryName,
    NULLIF(LTRIM(RTRIM(province_state)),'') AS ProvinceOrState,
    COALESCE(
      TRY_CONVERT(DATETIME2(0), created_at, 120),  -- ISO
      TRY_CONVERT(DATETIME2(0), created_at, 103)   -- dd/MM/yyyy
    ) AS CustomerCreatedAt,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY (SELECT 1)) AS rn
  FROM raw.Customer
)
INSERT staging.Customer(CustomerID, CustomerSegment, CustomerName, CustomerEmail, CountryName, ProvinceOrState, CustomerCreatedAt)
SELECT CustomerID, CustomerSegment, CustomerName, CustomerEmail, CountryName, ProvinceOrState, CustomerCreatedAt
FROM s WHERE rn = 1 AND CustomerID IS NOT NULL AND CustomerName IS NOT NULL;

-- Product (created_at mostly dd/MM/yyyy HH:mm)
TRUNCATE TABLE staging.Product;
WITH s AS (
  SELECT
    TRY_CONVERT(INT, product_id)  AS ProductID,
    TRY_CONVERT(INT, category_id) AS CategoryID,
    NULLIF(LTRIM(RTRIM(product_name)),'') AS ProductName,
    CASE WHEN LOWER(LTRIM(RTRIM(is_active))) IN ('1','true','yes','y') THEN 1
         WHEN LOWER(LTRIM(RTRIM(is_active))) IN ('0','false','no','n') THEN 0
         ELSE 1 END AS IsActive,
    PARSE(created_at AS DATETIME2(0) USING 'en-GB') AS ProductCreatedAt,
    ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY (SELECT 1)) AS rn
  FROM raw.Product
)
INSERT staging.Product(ProductID, CategoryID, ProductName, IsActive, ProductCreatedAt)
SELECT ProductID, CategoryID, ProductName, IsActive, ProductCreatedAt
FROM s WHERE rn = 1 AND ProductID IS NOT NULL AND ProductName IS NOT NULL;

-- ProductVariant
TRUNCATE TABLE staging.ProductVariant;
WITH s AS (
  SELECT
    TRY_CONVERT(INT, variant_id) AS VariantID,
    TRY_CONVERT(INT, product_id) AS ProductID,
    NULLIF(LTRIM(RTRIM(sku)),'') AS SKU,
    NULLIF(LTRIM(RTRIM(option_summary)),'') AS VariantOptions,
    TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(unit_cost, ',', ''), ' ', '')) AS UnitCost,
    CASE WHEN LOWER(LTRIM(RTRIM(is_active))) IN ('1','true','yes','y') THEN 1
         WHEN LOWER(LTRIM(RTRIM(is_active))) IN ('0','false','no','n') THEN 0
         ELSE 1 END AS IsActive,
     PARSE(created_at AS DATETIME2(0) USING 'en-GB') AS  VariantCreatedAt,
    ROW_NUMBER() OVER (PARTITION BY variant_id ORDER BY (SELECT 1)) AS rn
  FROM raw.ProductVariant
)
INSERT staging.ProductVariant(VariantID, ProductID, SKU, VariantOptions, UnitCost, IsActive, VariantCreatedAt)
SELECT VariantID, ProductID, SKU, VariantOptions, UnitCost, IsActive, VariantCreatedAt
FROM s WHERE rn = 1 AND VariantID IS NOT NULL AND ProductID IS NOT NULL AND SKU IS NOT NULL;

-- Order (order_date dd/MM/yyyy HH:mm or ISO)
TRUNCATE TABLE staging.[Order];
WITH s AS (
  SELECT
    TRY_CONVERT(INT, order_id) AS OrderID,
    NULLIF(LTRIM(RTRIM(order_number)),'') AS OrderNumber,
    TRY_CONVERT(INT, customer_id) AS CustomerID,
    TRY_CONVERT(INT, channel_id)  AS ChannelID,
    COALESCE(
      TRY_CONVERT(DATETIME2(0), order_date, 103),
      TRY_CONVERT(DATETIME2(0), order_date, 120)
    ) AS OrderDateTime,
    NULLIF(LTRIM(RTRIM(status)),'')   AS OrderStatus,
    NULLIF(LTRIM(RTRIM(currency)),'') AS CurrencyCode,
    TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(subtotal, ',', ''), ' ', ''))       AS SubtotalAmount,
    TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(discount_total, ',', ''), ' ', '')) AS DiscountAmount,
    TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(tax_total, ',', ''), ' ', ''))      AS TaxAmount,
	--TRY_CONVERT(DECIMAL(18,2), REPLACE(shipping_total, '.', ',')) AS ShippingAmount,
	 

    TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(shipping_total, CHAR(13), ''), ' ', '')) AS ShippingAmount,
	--CAST (shipping_total AS DECIMAL(18,2))AS ShippingAmount,

    ROW_NUMBER() OVER (PARTITION BY order_id ORDER BY (SELECT 1)) AS rn
  FROM raw.[Order]
)
INSERT staging.[Order](OrderID, OrderNumber, CustomerID, ChannelID, OrderDateTime, OrderStatus, CurrencyCode, SubtotalAmount, DiscountAmount, TaxAmount, ShippingAmount)
SELECT OrderID, OrderNumber, CustomerID, ChannelID, OrderDateTime, OrderStatus, CurrencyCode, SubtotalAmount, DiscountAmount, TaxAmount, ShippingAmount
FROM s
WHERE rn = 1 AND OrderID IS NOT NULL AND OrderNumber IS NOT NULL AND OrderDateTime IS NOT NULL;


-- OrderLine
TRUNCATE TABLE staging.OrderLine;
WITH s AS (
  SELECT
    TRY_CONVERT(INT, orderline_id) AS OrderLineID,
    TRY_CONVERT(INT, order_id)     AS OrderID,
    TRY_CONVERT(INT, variant_id)   AS VariantID,
    NULLIF(LTRIM(RTRIM(title_snapshot)),'') AS LineTitle,
    TRY_CONVERT(INT, quantity)         AS Quantity,
    TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(unit_price, ',', ''), ' ', ''))     AS UnitPrice,
    TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(line_discount, ',', ''), ' ', ''))  AS LineDiscountAmount,
    TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(line_tax, ',', ''), ' ', ''))       AS LineTaxAmount,
    ROW_NUMBER() OVER (PARTITION BY orderline_id ORDER BY (SELECT 1)) AS rn
  FROM raw.OrderLine
)
INSERT staging.OrderLine(OrderLineID, OrderID, VariantID, LineTitle, Quantity, UnitPrice, LineDiscountAmount, LineTaxAmount)
SELECT OrderLineID, OrderID, VariantID, LineTitle, Quantity, UnitPrice, LineDiscountAmount, LineTaxAmount
FROM s WHERE rn = 1 AND OrderLineID IS NOT NULL AND OrderID IS NOT NULL AND VariantID IS NOT NULL;



-- Payment
TRUNCATE TABLE staging.payment;
WITH s AS (
  SELECT
    TRY_CONVERT(INT, payment_id) AS PaymentID,
    TRY_CONVERT(INT, order_id)   AS OrderID,
    NULLIF(LTRIM(RTRIM(method)),'') AS PaymentMethod,
    TRY_CONVERT(DECIMAL(18,2), REPLACE(REPLACE(amount, ',', ''), ' ', '')) AS PaymentAmount,
    COALESCE(
      TRY_CONVERT(DATETIME2(0), paid_at, 120),
      TRY_CONVERT(DATETIME2(0), paid_at, 103)
    ) AS PaidAtDateTime,
    NULLIF(LTRIM(RTRIM(status)),'')   AS PaymentStatus,
    NULLIF(LTRIM(RTRIM(txn_ref)),'')  AS TransactionRef,
    ROW_NUMBER() OVER (PARTITION BY payment_id ORDER BY (SELECT 1)) AS rn
  FROM raw.Payment
)
INSERT staging.Payment(PaymentID, OrderID, PaymentMethod, PaymentAmount, PaidAtDateTime, PaymentStatus, TransactionRef)
SELECT PaymentID, OrderID, PaymentMethod, PaymentAmount, PaidAtDateTime, PaymentStatus, TransactionRef
FROM s WHERE rn = 1 AND PaymentID IS NOT NULL AND OrderID IS NOT NULL AND PaymentAmount IS NOT NULL;
