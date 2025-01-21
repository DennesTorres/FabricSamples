declare @search_text nvarchar(max) = 
	'help me plan a high school graduation party'
declare @search_vector vector(1536);
declare @retval int
exec @retval = dbo.get_embedding 'textembedding’, 
	@search_text,@search_vector output;
SELECT TOP(10) 
  id, [product name], description, 
  vector_distance('cosine', @search_vector, product_description_vector) AS distance
FROM [dbo].[walmart_product_details]
ORDER BY distance
