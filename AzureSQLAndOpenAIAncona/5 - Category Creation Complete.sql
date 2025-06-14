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