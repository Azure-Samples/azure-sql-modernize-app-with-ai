# DATA API BUILDER INSTRUCTIONS

When creating a Data API builder configurationg file, ALWAYS use the DAB CLI to make sure you always use the correct format. 
DAB CLI documentation is available here: https://learn.microsoft.com/en-us/azure/data-api-builder/command-line/
Always use a .env file to store connection strings and secrets, and reference them in the DAB configuration file using the @env() syntax.
The connection string must be saved in variable named MSSQL. Use single quotes to wrap the connection string value in the .env file.