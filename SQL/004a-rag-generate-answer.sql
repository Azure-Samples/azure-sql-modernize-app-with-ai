/*
    Call LLM for analyzing and enriching semantic search results
    with Generative AI while returning data in structured format
    This procedure is called from the RAG version (script 004b) 
    of the dbo.search_products procedure.
*/ 
create or alter procedure [dbo].[generate_answer] 
@request nvarchar(max),
@products nvarchar(max), 
@response nvarchar(max) output,
@error json output
as
declare @retval int;

/* Create the prompt for the LLM */
declare @p nvarchar(max) = 
json_object(
    'messages': json_array(
        json_object(
            'role':'system',
            'content':'
                You as a system assistant who helps users find the best products available in the catalog to satisfy the requested ask.
                Products are provided in an assitant message using a JSON Array with the following format: [{id, name, description}].                 
                Use only the provided products to help you answer the question.        
                Use only the information available in the provided JSON to answer the question.
                Return the top ten products that best answer the question.
                Make sure to use details, notes, and description that are provided in each product are used only with that product.                
                If the question cannot be answered by the provided samples, don''t return any result.
                If asked question is about topics you don''t know, don''t return any result.
                If no products are provided, don''t return any result.                
            '
        ),
        json_object(
            'role':'assistant',
            'content': 'The available products are the following:'
            ),
        json_object(
            'role':'assistant',
            'content': coalesce(@products, '')
            ),
        json_object(
            'role':'user',
            'content': + @request
        )
    ),    
    'temperature': 0.2,
    'frequency_penalty': 0,
    'presence_penalty': 0,    
    'stop': null
);

declare @js nvarchar(max) = N'{
    "type": "json_schema",
    "json_schema": {
        "name": "products",
        "strict": true,
        "schema": {
            "type": "object",
            "properties": {
                "products": {
                    "type": "array",
                    "items": {
                        "type": "object",
                        "properties": {
                            "result_position": {
                                "type": "number"
                            },
                            "id": {
                                "type": "number"
                            },
                            "description": {
                                "type": "string",
                                "description": "a brief and summarized description of the product, no more than ten words"
                            },                            
                            "thoughts": {
                                "type": "string",
                                "description": "explanation of why the product has been chosen"
                            }
                        },
                        "required": [
                            "result_position",
                            "id",                            
                            "description",                            
                            "thoughts"                            
                        ],
                        "additionalProperties": false
                    }
                }
            },
            "required": ["products"],
            "additionalProperties": false
        }        
    }        
}'

set @p = json_modify(@p, '$.response_format', json_query(@js))
---select @p

/* Send request to LLM */
begin try
    exec @retval = sp_invoke_external_rest_endpoint
        @url = '<OPENAI_URL>/openai/deployments/<OPENAI_CHAT_MODEL_DEPLOYMENT>/chat/completions?api-version=2024-08-01-preview',
        @headers = '{"Content-Type":"application/json"}',
        @method = 'POST',
        @credential = [<OPENAI_URL>],
        @timeout = 120,
        @payload = @p,
        @response = @response output
        with result sets none;
end try
begin catch
    set @error = json_object('error':'Embedding:REST', 'error_code':ERROR_NUMBER(), 'error_message':ERROR_MESSAGE())
    return -1
end catch

if @retval != 0 begin
    set @error = json_object('error':'Embedding:OpenAI', 'error_code':@retval, 'response':@response)
    return @retval
end
