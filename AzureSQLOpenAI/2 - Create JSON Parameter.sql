
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
                    
                    ## Source ##

                    ## End ##

                    Your answer needs to be in JSON format, specially if the request is to create more than one single resource, the JSON should list the resources and the relation between them and the products
                '
            ),
            json_object(
                'role':'user',
                'content': 'here goes the user message'
            )
    ),
    'max_tokens': 3000,
    'temperature': 0.7,
    'frequency_penalty': 0,
    'presence_penalty': 0,
    'top_p': 0.95,
    'stop': null
);

select @llm_payload