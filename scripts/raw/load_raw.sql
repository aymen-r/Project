/*
===============================================================================
Load Raw Tables (Source -> Raw)
===============================================================================
This script loads data into the 'raw' schema from external CSV files.
*/

USE DataWarehouse;
GO

TRUNCATE TABLE raw.Category;
BULK INSERT raw.Category
		FROM 'D:\BI\Stage\irisArlo\csvs\Category.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',    
			CODEPAGE = '65001',         
			DATAFILETYPE = 'char',
			TABLOCK
		);
GO

TRUNCATE TABLE raw.Channel;
BULK INSERT raw.Channel
		FROM 'D:\BI\Stage\irisArlo\csvs\Channel.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',     
			CODEPAGE = '65001',         
			DATAFILETYPE = 'char',
			TABLOCK
		);


TRUNCATE TABLE raw.Customer;
BULK INSERT raw.Customer
		FROM 'D:\BI\Stage\irisArlo\csvs\Customer.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',     
			CODEPAGE = '65001',         
			DATAFILETYPE = 'char',
			TABLOCK
		);
GO


TRUNCATE TABLE raw.[Order];
BULK INSERT raw.[Order]
		FROM 'D:\BI\Stage\irisArlo\csvs\Order.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',     
			CODEPAGE = '65001',         
			DATAFILETYPE = 'char',
			TABLOCK
		);
GO

TRUNCATE TABLE raw.OrderLine;
BULK INSERT raw.OrderLine
		FROM 'D:\BI\Stage\irisArlo\csvs\OrderLine.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',     
			CODEPAGE = '65001',         
			DATAFILETYPE = 'char',
			TABLOCK
		);
GO

TRUNCATE TABLE raw.Payment;
BULK INSERT raw.Payment
		FROM 'D:\BI\Stage\irisArlo\csvs\Payment.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',     
			CODEPAGE = '65001',         
			DATAFILETYPE = 'char',
			TABLOCK
		);
GO

TRUNCATE TABLE raw.[Product];
BULK INSERT raw.[Product]
		FROM 'D:\BI\Stage\irisArlo\csvs\Product.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',     
			CODEPAGE = '65001',         
			DATAFILETYPE = 'char',
			TABLOCK
		);
GO

TRUNCATE TABLE raw.ProductVariant;
BULK INSERT raw.ProductVariant
		FROM 'D:\BI\Stage\irisArlo\csvs\ProductVariant.csv'
		WITH (
			FIRSTROW = 2,
			FIELDTERMINATOR = ',',
			ROWTERMINATOR = '0x0a',     
			CODEPAGE = '65001',         
			DATAFILETYPE = 'char',
			TABLOCK
		);
GO
