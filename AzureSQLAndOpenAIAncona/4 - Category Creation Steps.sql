	
	
	
-- Product information in JSON format

	select (
	select [Product Name],Description, Brand, Category
	from walmart_product_details
	where id=1
	for json auto ) as product

-- System Message

-- You are a marketing specialist and your work is to improve 
-- the information provided about the products to make them more 
-- attractive to consumers.

-- You will receive information in JSON and it's imperative 
-- that your entire response is provided as a JSON object

-- JSON Message to be built

{ "messages"
	[
		{"role": "system, 
		 "Content":""},
		 {"role":"user",
			"content":""}
	]
}

-- User Message

-- Using the information of the product located below, could you provide a beter description for the product, a description more attractive to the consumers ?

-- each message is a JSON Object

JSON_OBJECT('role' : 'system', 'content' : '')
JSON_OBJECT('role' : 'user', 'content' : '')

-- The main messages is an object with an array

JSON_OBJECT('messages',
	JSON_ARRAY(
		JSON_OBJECT('role' : 'system', 'content' : ''),
		JSON_OBJECT('role' : 'system', 'content' : '') 
	)

-- We insert the system message

JSON_OBJECT('messages',
	JSON_ARRAY(JSON_OBJECT('role' : 'system', 'content' : 
	'You are a marketing specialist and your work is to 
	improve the information provided about the products to 
	make them more attractive to consumers.
	
	You will receive information in JSON and it''s 
	imperative that your entire response is 
	provided as a JSON object'),

	JSON_OBJECT('role' : 'user', 'content' : '') )

-- we need the product JSON to be included in the message

declare @jProducts JSON

select @jProducts=(
	select [Product Name],Description, Brand, Category
	from walmart_product_details
	where id=1
	for json auto )

print convert(varchar(max),@jProducts)

-- User message built with JSON

declare @jProducts JSON

select @jProducts=(
	select [Product Name],Description, Brand, Category
	from walmart_product_details
	where id=1
	for json auto )

JSON_OBJECT('messages':
	JSON_ARRAY(JSON_OBJECT('role' : 'system', 'content' : 
	'You are a marketing specialist and your work is to 
	improve the information provided about the products to 
	make them more attractive to consumers.
	
	You will receive information in JSON and it''s 
	imperative that your entire response is 
	provided as a JSON object'),

	JSON_OBJECT('role' : 'system',
	'Content' : 'Using the information of the product located below,
	could you provide a beter description for the product,
	a description more attractive to the consumers ?
	
	'
	+ convert(varchar(max),@jProducts)

	) ) )

-- Building the payload variable
declare @llm_payload nvarchar(max);

declare @jProducts JSON

select @jProducts=(
	select [Product Name],Description, Brand, Category
	from walmart_product_details
	where id=1
	for json auto )

set @llm_payload=JSON_OBJECT('Messages':
	JSON_ARRAY(JSON_OBJECT('Role' : 'System', 'Content' : 
	'You are a marketing specialist and your work is to 
	improve the information provided about the products to 
	make them more attractive to consumers.
	
	You will receive information in JSON and it''s 
	imperative that your entire response is 
	provided as a JSON object'),

	JSON_OBJECT('Role' : 'System',
	'Content' : 'Using the information of the product located below,
	could you provide a beter description for the product,
	a description more attractive to the consumers ?
	
	'
	+ convert(varchar(max),@jProducts)

	) ))

-- building the URL for the call
declare @deployedModelName nvarchar(1000)
set @deployedModelName='geolake'
declare @url nvarchar(max)=
	'https://onyxlakechat.openai.azure.com/openai/deployments/' 
	+ @deployedModelName + 
		'/chat/completions?api-version=2024-08-01-preview' -- Completions API


-- Complete the call
;
declare @llm_payload nvarchar(max);
declare @jProducts JSON
declare @deployedModelName nvarchar(1000)='geolake'
declare @url nvarchar(max)=
	'https://onyxlakechat.openai.azure.com/openai/deployments/' 
	+ @deployedModelName + 
		'/chat/completions?api-version=2024-08-01-preview' -- Completions API

declare @retval int
declare @response nvarchar(max);

select @jProducts=(
	select [Product Name],Description, Brand, Category
	from walmart_product_details
	where id=1
	for json auto )

set @llm_payload=json_object('messages':
	json_array(json_object('role' : 'system', 'content' : 
	'You are a marketing specialist and your work is to 
	improve the information provided about the products to 
	make them more attractive to consumers.
	
	You will receive information in JSON and it''s 
	imperative that your entire response is 
	provided as a JSON object'),

	json_object('role' : 'user',
	'content' : 'Using the information of the product located below,
	could you provide a beter description for the product,
	a description more attractive to the consumers ?
	
	'
	+ convert(varchar(max),@jProducts) ) ) )



exec @retval = sp_invoke_external_rest_endpoint
    @url = @url,
    @headers = '{"Content-Type":"application/json"}',
    @method = 'POST',
    @credential = [https://onyxlakechat.openai.azure.com/],
    @timeout = 120,
    @payload = @llm_payload,
    @response = @response output;

print(@response)