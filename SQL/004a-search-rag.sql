/*
    Even better product search procedure, using RAG pattern to provide even better 
    search result with even explanation for each result.
    This procedure needs the "[dbo].[generate_answer]" procedure for LLM call
*/ 
CREATE OR ALTER PROCEDURE dbo.search_products
@searchTerm NVARCHAR(1000),
@category NVARCHAR(1000) = NULL
AS

declare @results as nvarchar(max);

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
),
cte3 as (
    select top(50)
        [id], 
        [product_name], 
        [description],
        [similarity_distance]
    from 
        cte2
    order by 
        similarity_distance
)

select @results = ((
    select 
        [id], 
        [product_name], 
        [description],
        [similarity_distance]
    from
        cte3
    for json auto
));

declare @answer nvarchar(max), @error json;
exec generate_answer @searchTerm, @results, @answer output, @error output with result sets none; 
if @retval <> 0
begin;
    print cast(@error as nvarchar(max));
    throw 50000, 'Failed to get generate answer', 1;
end;

select 
    p.[id], 
    p.[product_name], 
    p.[description],
    sr.[description] as short_description,
    p.[category],
    sr.thoughts
from 
    openjson(@answer, '$.result.choices[0].message') with (
        content nvarchar(max) '$.content'
    ) m
cross apply
    openjson(m.content, '$.products') with (
        result_position int,
        id int,        
        [description] nvarchar(max),
        thoughts nvarchar(max)
    ) as sr
inner join
    [dbo].[ecommerce_product_details] p on sr.id = p.id
order by
    sr.result_position
