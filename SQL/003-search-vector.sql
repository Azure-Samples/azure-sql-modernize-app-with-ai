/*
    Improved product search procedure, using semantic search to provide better results
*/ 
CREATE OR ALTER PROCEDURE dbo.search_products
@searchTerm NVARCHAR(1000),
@category NVARCHAR(1000) = NULL
AS

declare @qv vector(1536), @retval int, @e json;
exec @retval = dbo.get_embedding @searchTerm, @qv output, @e output with result sets none;
if @retval <> 0
begin;
    print cast(@e as nvarchar(max));
    throw 50000, 'Failed to get embedding', 1;
end;

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
        *,
        vector_distance('cosine', @qv, [embedding]) as [similarity_distance]
    from
        cte
    where
        [rn] = 1
    and  
        (
            category like '%' + @category + '%'
        or
            @category is null
        )
)
select top(10)
    [id], 
    [product_name], 
    [description],
    [category],
    [similarity_distance]
from 
    cte2
order by 
    similarity_distance;