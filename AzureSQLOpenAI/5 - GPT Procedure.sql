create or alter procedure dbo.get_answer
    @deployedModelName nvarchar(1000),
    @search_text nvarchar(max),
	@products nvarchar(max),
    @reply JSON output
as

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
                    
                    ## Source ##' + @products +

                    '## End ##

                    Your answer needs to be fully JSON format. Each resource should be a JSON object, with the properties defining the object and included in an array of resources built by you. Any reasoning needs to become a JSON property in the object
                '
            ),
            json_object(
                'role':'user',
                'content': @search_text
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
declare @url nvarchar(max)='https://dpaidemos.openai.azure.com/openai/deployments/' + @deployedModelName + '/chat/completions?api-version=2024-08-01-preview' -- Completions API

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