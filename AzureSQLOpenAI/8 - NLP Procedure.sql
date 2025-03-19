
create or alter procedure NLPQuery @question varchar(max)
AS

declare @llm_payload nvarchar(max);
declare @sql varchar(2000)

set @llm_payload = 
json_object(
    'messages': json_array(
            json_object(
                'role':'system',
                'content':'
You are a DBA specialist in T-SQL language for SQL Server. Considering the model explained below, you are responsible for building T-SQL queries to answer the user question.

The database is about sales and contain information about Order, Products and Customers.

All the tables are located in the schema SalesLT.

Each order contains multiple products. The table SalesOrderDetail contains each item in an order. It has the following fields:

OrderQty (quantity), UnitPrice, ProductID (related to product table) and SalesOrderID (related to the actual order). When asked about a "Total of sales or orders" always consider multiplying OrderQty by UnitPrice.

The table SalesOrderHeader contains the following fields: SalesOrderId, OrderDate, CustomerID (Relates to Customer table). 

The Product table contains the fields Name, ProuctID, ProductCategoryID (relates to ProductCategory table) ProductModelId (relates to ProductModel table) and Color.

The table ProductCategory contains the fields ProductCategoryID and Name

The table ProductModel contains the fields ProductModelID and Name.

There is a table called ProductModelProductDescription which relates the table ProductModel with the table ProductDescription. This table has the fields ProductModelID and ProductDescriptionID

The table ProductDescription has the fields ProductDescriptionID and Description

The table Customer has the fields CustomerID, Firstname, MiddleName, LastName and CompanyName. When asked about customer name, concatenate the FirstName with MiddleName and LastName correctly.

The table CustomerAddress makes a relation between the table Customer and the table Address. It contains the fields CustomerID and AddressID

The table Address contains the fields AddressID City, StateProvince and CountryRegion.

Limit the answer to only the generated T-SQL, no explanation, confirmation or reasoning.

                '
            ),
            json_object(
                'role':'user',
                'content': @question
            )
    ),
    'max_tokens': 3000,
    'temperature': 0.7,
    'frequency_penalty': 0,
    'presence_penalty': 0,
    'top_p': 0.95,
    'stop': null
);


-- API CALL
declare @retval int
declare @response nvarchar(max);
declare @url nvarchar(max)='https://dpaidemos.openai.azure.com/openai/deployments/geolake/chat/completions?api-version=2024-08-01-preview' -- Completions API

exec @retval = sp_invoke_external_rest_endpoint
    @url = @url,
    @headers = '{"Content-Type":"application/json"}',
    @method = 'POST',
    @credential = [https://dpaidemos.openai.azure.com/],
    @timeout = 120,
    @payload = @llm_payload,
    @response = @response output;

	select @response

    select @sql=t.value
    from openjson(@response, '$.result.choices') c cross apply openjson(c.value, '$.message') t
    where t.[key]='content'

exec (@sql)