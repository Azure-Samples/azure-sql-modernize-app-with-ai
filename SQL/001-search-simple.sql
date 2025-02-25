/*
    Basic product search procedure, using text search only
*/ 
CREATE OR ALTER PROCEDURE dbo.search_products
@searchTerm NVARCHAR(1000),
@category NVARCHAR(1000) = NULL
AS

with cte as 
(
    select 
        row_number() over (partition by product_name order by id) as [rn],
        [id], 
        [product_name], 
        [description],
        [category],
        [embedding]    
    from
        [dbo].[ecommerce_product_details]
), cte2 as
(
    select 
        *        
    from
        cte
    where
        [rn] = 1
)
select top (10) 
	[id], [product_name], [description], [category]
from
	cte2
where 
(
	[product_name] like '%' + @searchTerm + '%'
or 
	[description] like '%' + @searchTerm + '%'
)
and
(
    category like '%' + @category + '%'
or
    @category is null
)