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


declare @search_text nvarchar(max) = 'Build sales plans with discounts for buying some products together. Organize the sales in a way the set of products is useful and make sense to the buyer and create an announcement explaining the sales and how usefull it is for the buyer'
declare @reply JSON
declare @retval int

exec @retval = dbo.get_answer 'geolake', @search_text, @jproducts, @reply output;

