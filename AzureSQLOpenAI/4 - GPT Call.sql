-- retrieve data in JSON form

declare @jproducts NVARCHAR(max)

select @jproducts=JSON_ARRAYAGG(JSON_OBJECT('ProductID':ProductID,'ProductName':p.[Name],
					'CategoryName':pc.Name, 
					'ModelName':pm.Name,'Description':Description))
from SalesLT.Product p
inner join SalesLT.ProductCategory pc
     on p.ProductCategoryID=pc.ProductCategoryID
inner join SalesLT.ProductModel pm
	 on pm.ProductModelID=p.ProductModelID
inner join SalesLT.ProductModelProductDescription PMD
     on PMD.ProductModelID=pm.ProductModelID
inner join SalesLT.ProductDescription pd
	 on pd.ProductDescriptionID=PMD.ProductDescriptionID
where pc.Name in ('Bike Racks','Gloves')

-- Build the Open AI Input


declare @llm_payload nvarchar(max);

set @llm_payload = 
json_object(
    'messages': json_array(
            json_object(
                'role':'system',
                'content':'
                    You are marketing specialist responsible for the company marketing strategy. 
                    You have access to a list of products, each with an ID, product name, description and category provided to you in the format of "Id=>Product=>Description". 
                    Using the information provided you should create the marketing resources requested by the user
                    
                    ## Source ##' + @jproducts +

                    '## End ##

                    Your answer needs to be in JSON format. Each resource should be a JSON object, with the properties defining the object and included in an array of resources built
                '
            ),
            json_object(
                'role':'user',
                'content': 'Build sales plans with discounts for buying some products together. Organize the sales in a way the set of products is useful and make sense to the buyer and create an announcement explaining the sales and how usefull it is for the buyer'
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


select [key], [value] 
from openjson(( 
    select t.value 
    from openjson(@response, '$.result.choices') c cross apply openjson(c.value, '$.message') t
    where t.[key]='content'
))