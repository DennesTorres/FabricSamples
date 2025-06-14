declare @search_text nvarchar(max) = 
	'help me plan a high school graduation party'
declare @reply JSON
declare @retval int

exec @retval = dbo.get_answer 'geolake', @search_text,@reply output;

declare @search_text nvarchar(max) = 'help me plan barbecue at my home'
declare @reply JSON
declare @retval int

exec @retval = dbo.get_answer 'geolake', @search_text,@reply output;