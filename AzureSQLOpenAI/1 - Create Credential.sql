create master key encryption by password='<<Your master key password here>>'
go

create database scoped credential [https://dpaidemos.openai.azure.com/]
with identity = 'HTTPEndpointHeaders', 
secret = '{"api-key": "<<Your API Key>>"}'
