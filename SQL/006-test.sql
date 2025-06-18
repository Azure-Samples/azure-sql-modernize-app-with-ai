use MigrateAndModernize
go

/* insert new products */

delete from [dbo].[ecommerce_product_details] where id >= 90000;
insert into [dbo].[ecommerce_product_details]    
values
(
    90000, 'test-product-1', sysdatetime(), 'https://www.xbox.com/en-us/handhelds/rog-xbox-ally', 'ROG Xbox Ally X', 'Next-gen power in your hands. Power of Xbox. Freedom of Windows. Craftmanship of ROG. The portable console you always want to bring with you, wherever you go, wherever you are.',
    null, null, 'XBOX', null, null, null, 
    'Video Games|Portable Consoles', null, 'TRUE', null    
),
(
    90001, 'test-product-2', sysdatetime(), 'https://www.xbox.com/en-us/handhelds/rog-xbox-ally', 'ROG Xbox Ally', 'Handheld freedom for everyone. Power of Xbox. Freedom of Windows. Craftmanship of ROG. The portable console you always want to bring with you, wherever you go, wherever you are.',
    null, null, 'XBOX', null, null, null, 
    'Video Games|Portable Consoles', null, 'TRUE', null   
)
go

select * from [dbo].[ecommerce_product_details] where id >= 90000
go

update [dbo].[ecommerce_product_details] 
set embedding = ai_generate_embeddings((product_name || ' ' || [description]) use model Ada2Embeddings)
where id >= 90000
go

select * from [dbo].[ecommerce_product_details] where id >= 90000
go


/*
    Semantic Search
*/
declare @category nvarchar(1000) = 'video games'; 
declare @qv vector(1536) = ai_generate_embeddings('find the best video game to gift to a teenager boy always on the move' use model Ada2Embeddings);

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
