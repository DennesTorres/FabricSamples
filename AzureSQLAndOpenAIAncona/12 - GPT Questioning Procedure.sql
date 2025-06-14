create or alter procedure dbo.get_answer
    @deployedModelName nvarchar(1000),
    @search_text nvarchar(max),
    @reply JSON output
as

declare @search_vector vector(1536);
declare @retval int
declare @jproducts nvarchar(max)

exec @retval = dbo.get_embedding 'text-embedding-ada-002', @search_text,@search_vector output;

with jRows as (
    SELECT TOP(10) 
    json_object('id':id, 'productName': [product name],'description': description) as product
    FROM [dbo].[walmart_product_details]
    ORDER BY vector_distance('cosine', @search_vector, product_description_vector)
)
select @jproducts=json_arrayagg(product)
from jRows

declare @llm_payload nvarchar(max);

set @llm_payload = 
json_object(
    'messages': json_array(
            json_object(
                'role':'system',
                'content':'
                    You are an awesome AI shopping assistant tasked with helping users find appropriate items they are looking for the occasion. 
                    You have access to a list of products, each with an ID, product name, and description, provided to you in the format of "Id=>Product=>Description". 
                    When users ask for products for specific occasions, you can leverage this information to provide creative and personalized suggestions. 
                    Your goal is to assist users in planning memorable celebrations using the available products.

					Your answer needs to be a json object with the following format. Your answer should always include a list of products involved in your answer. You should also explain how you reached the conclusion about which products to choose and include this in a field in the answer.
					You should not answer an any other format than JSON with the structure below
                    {
                        "answer": // the answer to the question, add a source reference to the end of each sentence. Source reference is the product Id.
                        "products": // a comma-separated list of product ids that you used to come up with the answer.
                        "thoughts": // brief thoughts on how you came up with the answer, e.g. what sources you used, what you thought about, etc.
                    }

                    ## Source ##
                    ' + @jproducts + '
                    ## End ##
                '
            ),
            json_object(
                'role':'user',
                'content': + @search_text
            )
    ),
    'max_tokens': 3000,
    'temperature': 0.7,
    'frequency_penalty': 0,
    'presence_penalty': 0,
    'top_p': 0.95,
    'stop': null
);

declare @response nvarchar(max);
declare @url nvarchar(max)='https://onyxlakechat.openai.azure.com/openai/deployments/' + @deployedModelName + '/chat/completions?api-version=2024-08-01-preview' -- Completions API

exec @retval = sp_invoke_external_rest_endpoint
    @url = @url,
    @headers = '{"Content-Type":"application/json"}',
    @method = 'POST',
    @credential = [https://onyxlakechat.openai.azure.com/],
    @timeout = 120,
    @payload = @llm_payload,
    @response = @response output;

--select @response

--select * 
--from openjson(@response, '$.result.choices')

--select *
--from openjson(@response, '$.result.choices') c cross apply openjson(c.value, '$.message') t

--select *
--from openjson(@response, '$.result.choices') c cross apply openjson(c.value, '$.message') t
--where t.[key]='content'

select t.[value]
from openjson(@response, '$.result.choices') c cross apply openjson(c.value, '$.message') t
where t.[key]='content'
