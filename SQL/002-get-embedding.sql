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
    Make sure to use the latest compatibility level
*/
alter database current set compatibility_level = 170
go

/*
    Create the external model reference
*/
if not exists(select * from sys.external_models where [name] = 'Ada2Embeddings')
begin
    create external model Ada2Embeddings
    with (
        location = '<OPENAI_URL>/openai/deployments/<OPENAI_EMBEDDING_MODEL_DEPLOYMENT>/embeddings?api-version=2023-05-15',
        api_format = 'Azure OpenAI',
        credential = [<OPENAI_URL>],
        model_type = embeddings,
        model = 'text-embedding-ada-002'
    )
end
go

/*
    Test embedding generation
*/
select ai_generate_embeddings(N'Just a test' use model Ada2Embeddings)
go
