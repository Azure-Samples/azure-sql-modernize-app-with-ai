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
if exists(select * from sys.[external_data_sources] where name = 'openai_playground')
begin
	drop external data source [openai_playground];
end
go
if exists(select * from sys.[database_scoped_credentials] where name = 'openai_playground')
begin
	drop database scoped credential [openai_playground];
end
go

/*
	Create database scoped credential and external data source.
	File is assumed to be in a path like: 
	https://<myaccount>.blob.core.windows.net/playground/wikipedia/vector_database_wikipedia_articles_embedded.csv

	Make sure to replace the `<STORAGE_ACCOUNT>` and `<SAS_TOKEN>` placeholders with the value correct for your environment:

	- `<STORAGE_ACCOUNT>` is the name of the storage account where the CSV file has been uploaded
	- `<SAS_TOKEN>` is the Share Access Signature obtained before

	Please note that it is recommened to avoid using SAS tokens: the best practice is to use Managed Identity as described here:
	https://learn.microsoft.com/en-us/sql/relational-databases/import-export/import-bulk-data-by-using-bulk-insert-or-openrowset-bulk-sql-server?view=sql-server-ver16#bulk-importing-from-azure-blob-storage
*/
create database scoped credential [openai_playground]
with identity = 'SHARED ACCESS SIGNATURE',
secret = '<SAS_TOKEN>'; -- make sure not to include the ? at the beginning
go
-- If using MSI, used the following code instead of the above one
-- create database scoped credential [openai_playground]
-- with identity = 'Managed Identity'

create external data source [openai_playground]
with 
( 
	type = blob_storage,
 	location = 'https://<STORAGE_ACCOUNT>.blob.core.windows.net/playground',
 	credential = [openai_playground]
);
go

/*
    Import data (may take up to 4 minutes)
*/
bulk insert dbo.[ecommerce_product_details]
from 'walmart/walmart-product-with-embeddings-dataset-usa.csv'
with (
	data_source = 'openai_playground',
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
    Create a column to store the embeddings as a native vector format.
*/
alter table dbo.[ecommerce_product_details]
add embedding_vector vector(1536)
go

/*
    Convert the JSON array to a native vector format.
*/
update dbo.[ecommerce_product_details]
set embedding_vector = cast(embedding as vector(1536))
go

/*
    Drop the JSON column.
*/
alter table dbo.[ecommerce_product_details]
drop column [embedding]
go

/*
    Rename the new column to the original column name.
*/
exec sp_rename 'dbo.[ecommerce_product_details].embedding_vector', 'embedding', 'COLUMN'
go

/*
    Look at the first row to verify the conversion.
*/
select top (1) * from dbo.[ecommerce_product_details]