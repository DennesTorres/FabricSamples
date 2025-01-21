declare @search_text nvarchar(max) = 'help me plan a high school graduation party'
declare @reply JSON
declare @retval int

exec @retval = dbo.get_answer 'localgpt4o', @search_text,@reply output;

