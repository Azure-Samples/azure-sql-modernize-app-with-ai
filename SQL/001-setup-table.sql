use MigrateAndModernize
go

/*
	Create product table
*/
drop table if exists [dbo].[ecommerce_product_details]
create table [dbo].[ecommerce_product_details]
(
	[id] [int] not null,
	[source_unique_id] [char](32) not null,
	[crawl_timestamp] [nvarchar](50) not null,
	[product_url] [nvarchar](200) not null,
	[product_name] [nvarchar](200) not null,
	[description] [nvarchar](max) null,
	[list_price] [decimal](18, 10) null,
	[sale_price] [decimal](18, 10) null,
	[brand] [nvarchar](500) null,
	[item_number] [bigint] null,
	[gtin] [bigint] null,
	[package_size] [nvarchar](500) null,
	[category] [nvarchar](1000) null,
	[postal_code] [nvarchar](10) null,
	[available] [nvarchar](10) not null,
	[embedding] [nvarchar](max) null
)
go

/*
	Setup security to connect to Azure Storage
*/
if not exists(select * from sys.symmetric_keys where [name] = '##MS_DatabaseMasterKey##')
begin
	create master key encryption by password = 'Pa$$w0rd!'
end
go

/*
    Import data (may take up to 4 minutes)
*/
bulk insert dbo.[ecommerce_product_details]
from 'C:\Work\datasets\walmart-product-with-embeddings-dataset-usa.csv'
with (
    format = 'csv',
    firstrow = 2,
    codepage = '65001',
	fieldterminator = ',',
	rowterminator = '0x0a',
    fieldquote = '"',
    batchsize = 1000,
    tablock
)
go

/*
	Add index
*/
create unique clustered index ixc on dbo.[ecommerce_product_details](id)
go

/*
    Convert column storing embeddings into native vector format.
*/
alter table dbo.[ecommerce_product_details]
alter column embedding vector(1536)
go

/*
    Look at the first row to verify the conversion.
*/
select top (1) * from dbo.[ecommerce_product_details]