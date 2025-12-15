/*
    Improved product search procedure, using semantic search to provide better results
*/ 
CREATE OR ALTER PROCEDURE dbo.search_products
@searchTerm NVARCHAR(1000),
@category NVARCHAR(1000) = NULL
AS

declare @qv vector(1536) = ai_generate_embeddings(@searchTerm use model Ada2Embeddings);

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