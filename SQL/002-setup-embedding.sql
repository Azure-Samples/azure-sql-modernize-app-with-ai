use MigrateAndModernize
go

-- Enable external rest endpoint used to communicate with Azure OpenAI
exec sp_configure 'external rest endpoint enabled', 1
reconfigure
go

-- Create database credentials to store API key
if not exists(select * from sys.symmetric_keys where [name] = '##MS_DatabaseMasterKey##')
begin
	create master key encryption by password = 'Pa$$_w0rd!ThatIS_L0Ng'
end
go

if exists(select * from sys.[database_scoped_credentials] where name = '<OPENAI_URL>') -- use your Azure OpenAI endpoint
begin
	drop database scoped credential [<OPENAI_URL>];
end
create database scoped credential [<OPENAI_URL>]
with identity = 'HTTPEndpointHeaders', secret = '{"api-key": "<OPENAI_API_KEY>"}'; -- Add your Azure OpenAI Key
go

-- Create reference to OpenAI model
if not exists (select * from sys.external_models where [name] = 'Ada2Embeddings') begin
	create external model Ada2Embeddings
	with ( 
		location = '<OPENAI_URL>/openai/deployments/<OPENAI_EMBEDDING_MODEL_DEPLOYMENT>/embeddings?api-version=2024-08-01-preview',
		credential = [<OPENAI_URL>],
		api_format = 'Azure OpenAI',
		model_type = embeddings,
		model = 'embeddings'
	);
end
go

