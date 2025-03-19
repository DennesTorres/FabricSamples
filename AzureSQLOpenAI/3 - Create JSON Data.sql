
select ProductID, p.[Name] as ProductName, Color,pc.Name as CategoryName, 
		pm.Name as ModelName, Description
from SalesLT.Product p
inner join SalesLT.ProductCategory pc
     on p.ProductCategoryID=pc.ProductCategoryID
inner join SalesLT.ProductModel pm
	 on pm.ProductModelID=p.ProductModelID
inner join SalesLT.ProductModelProductDescription PMD
     on PMD.ProductModelID=pm.ProductModelID
inner join SalesLT.ProductDescription pd
	 on pd.ProductDescriptionID=PMD.ProductDescriptionID
where pc.Name in ('Bike Racks','Tires and Tubes','Gloves','Road Bikes')


select JSON_ARRAYAGG(JSON_OBJECT('ProductID':ProductID,'ProductName':p.[Name],
					'Color':Color,'CategoryName':pc.Name, 
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
where pc.Name in ('Bike Racks','Tires and Tubes','Gloves','Road Bikes')

