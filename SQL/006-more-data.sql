/*
    Add more data. Run the sample from file 04 again to see how the answer changes
*/
delete from [dbo].[ecommerce_product_details] where id >= 90000;
insert into [dbo].[ecommerce_product_details]    
values
(
    90000, 'f1_25_xbox', sysdatetime(), 'https://www.xbox.com/en-US/games/store/f1-25/9NWPW7F19FS5', 'F1® 25 - XBOX', 'This Story is Yours. Leave your mark on the world of racing in F1® 25, the official video game of the 2025 FIA Formula One World Championship™',
    null, null, 'EA', null, null, null, 
    'Video Games|Portable Consoles', null, 'TRUE', null    
),
(
    90001, 'f1_25_ps5', sysdatetime(), 'https://store.playstation.com/en-us/product/UP0006-PPSA24662_00-F125DELUXEDITION', 'F1® 25 - PS5', 'This Story is Yours. Leave your mark on the world of racing in F1® 25, the official video game of the 2025 FIA Formula One World Championship™',
    null, null, 'EA', null, null, null, 
    'Video Games|Portable Consoles', null, 'TRUE', null    
),
(
    90002, 'rgo_xbox_ally', sysdatetime(), 'https://www.xbox.com/en-us/handhelds/rog-xbox-ally', 'ROG Xbox Ally', 'Handheld freedom for everyone. Power of Xbox. Freedom of Windows. Craftmanship of ROG. The portable console you always want to bring with you, wherever you go, wherever you are.',
    null, null, 'XBOX', null, null, null, 
    'Video Games|Portable Consoles', null, 'TRUE', null   
)
go

select id from [dbo].[ecommerce_product_details] 
where id >= 90000 and embedding is null
go

-- Generate embeddings
update
    [dbo].[ecommerce_product_details] 
set
    embedding = ai_generate_embeddings(product_name || ' ' || [description] use model Ada2Embeddings)
where 
    id >= 90000
and 
    embedding is null

-- Check 
select id from [dbo].[ecommerce_product_details] 
where id >= 90000 and embedding is null
go

