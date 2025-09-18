USE DataWarehouse;
GO


/* ============================================================
   1) RAW: lossless landing (all text)
   ============================================================ */
IF OBJECT_ID('raw.Category','U') IS NOT NULL DROP TABLE raw.Category;
GO
CREATE TABLE raw.Category(
  category_id    NVARCHAR(100), 
  name NVARCHAR(4000)
);
GO

IF OBJECT_ID('raw.Channel','U') IS NOT NULL DROP TABLE raw.Channel;
GO
CREATE TABLE raw.Channel(
  channel_id NVARCHAR(100), 
  name NVARCHAR(4000), 
  type NVARCHAR(4000), 
  region NVARCHAR(4000)
);
GO


IF OBJECT_ID('raw.Customer','U') IS NOT NULL DROP TABLE raw.Customer;
GO

CREATE TABLE raw.Customer(
  customer_id NVARCHAR(100), 
  segment NVARCHAR(4000), 
  name NVARCHAR(4000), 
  email NVARCHAR(4000),
  country NVARCHAR(4000), 
  province_state NVARCHAR(4000), 
  created_at NVARCHAR(100)
);
GO

IF OBJECT_ID('raw.Product','U') IS NOT NULL DROP TABLE raw.Product;
GO

CREATE TABLE raw.Product(
  product_id NVARCHAR(100), 
  category_id NVARCHAR(100), 
  product_name NVARCHAR(4000),
  is_active NVARCHAR(100), 
  created_at NVARCHAR(100)
);
GO

IF OBJECT_ID('raw.ProductVariant','U') IS NOT NULL DROP TABLE raw.ProductVariant;
GO
CREATE TABLE raw.ProductVariant(
  variant_id NVARCHAR(100), 
  product_id NVARCHAR(100), 
  sku NVARCHAR(4000),
  option_summary NVARCHAR(4000), 
  unit_cost NVARCHAR(100), 
  is_active NVARCHAR(100),
  created_at NVARCHAR(100)
);
GO

IF OBJECT_ID('raw.[Order]','U') IS NOT NULL DROP TABLE raw.[Order];
GO
CREATE TABLE raw.[Order](
  order_id NVARCHAR(100), 
  order_number NVARCHAR(4000), 
  customer_id NVARCHAR(100),
  channel_id NVARCHAR(100), 
  order_date NVARCHAR(100), 
  status NVARCHAR(4000),
  currency NVARCHAR(100), 
  subtotal NVARCHAR(100), 
  discount_total NVARCHAR(100),
  tax_total NVARCHAR(100), 
  shipping_total NVARCHAR(100)
);
GO

IF OBJECT_ID('raw.OrderLine','U') IS NOT NULL DROP TABLE raw.OrderLine;
GO
CREATE TABLE raw.OrderLine(
  orderline_id NVARCHAR(100), 
  order_id NVARCHAR(100), 
  variant_id NVARCHAR(100),
  title_snapshot NVARCHAR(4000), 
  quantity NVARCHAR(100), 
  unit_price NVARCHAR(100),
  line_discount NVARCHAR(100), 
  line_tax NVARCHAR(100)
);
GO

IF OBJECT_ID('raw.Payment','U') IS NOT NULL DROP TABLE raw.Payment;
GO
CREATE TABLE raw.Payment(
  payment_id NVARCHAR(100), 
  order_id NVARCHAR(100), 
  method NVARCHAR(4000),
  amount NVARCHAR(100), 
  paid_at NVARCHAR(100), 
  status NVARCHAR(4000), 
  txn_ref NVARCHAR(4000)
);
