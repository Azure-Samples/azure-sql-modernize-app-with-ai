/*
	Create database scoped credential to call OpenAI.

	Please note that it is recommened to avoid using SAS tokens: the best practice is to use Managed Identity as described here:
	https://devblogs.microsoft.com/azure-sql/go-passwordless-when-calling-azure-openai-from-azure-sql-using-managed-identities/
    
    create database scoped credential [<OPENAI_URL>]
    with identity = 'Managed Identity', secret = '{"resourceid":"https://cognitiveservices.azure.com"}';
*/
if not exists(select * from sys.database_scoped_credentials where [name] = '<OPENAI_URL>')
begin
    create database scoped credential [<OPENAI_URL>]
    with identity = 'HTTPEndpointHeaders', secret = '{"api-key":"<OPENAI_API_KEY>"}';
end
go

/*
    Procedure to call OpenAI and get embeddings from a given text
*/
create or alter procedure [dbo].[get_embedding]
@inputText nvarchar(max),
@embedding vector(1536) output,
@error json output
as
declare @retval int;
declare @payload nvarchar(max) = json_object('input': @inputText);
declare @response nvarchar(max)
begin try
    exec @retval = sp_invoke_external_rest_endpoint
        @url = '<OPENAI_URL>/openai/deployments/<OPENAI_EMBEDDING_MODEL_DEPLOYMENT>/embeddings?api-version=2023-03-15-preview',
        @method = 'POST',
        @credential = [<OPENAI_URL>],
        @payload = @payload,
        @response = @response output;
end try
begin catch
    set @error = json_object('error':'Embedding:REST', 'error_code':ERROR_NUMBER(), 'error_message':ERROR_MESSAGE())
    return -1
end catch

if @retval != 0 begin
    set @error = json_object('error':'Embedding:OpenAI', 'error_code':@retval, 'response':@response)
    return @retval
end

declare @re nvarchar(max) = json_query(@response, '$.result.data[0].embedding')
set @embedding = cast(@re as vector(1536));

return @retval
GO
