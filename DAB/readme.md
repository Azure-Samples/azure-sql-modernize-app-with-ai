# Data API Builder quickstart

Initialize DAB configuration for a Microsoft SQL Server database.

```bash
dab init --database-type mssql --host-mode development --connection-string "@env('MSSQL')"
```

then add the stored procedure to the DAB configuration.

```bash
dab add SearchProducts --source "dbo.search_products" --source.type "stored-procedure" --source.params "searchTerm:" --rest "searchProducts" --rest.methods "post,get" --graphql.operation "query" --permissions "anonymous:*"  
```

start DAB

```bash
dab start
```

and then query the endpoint

```bash
http://localhost:5000/api/searchProducts?searchTerm=f1
```

or 

```
http://localhost:5000/graphql/
```
