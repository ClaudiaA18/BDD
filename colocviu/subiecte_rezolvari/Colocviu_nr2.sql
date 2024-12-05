use northwind;
go 


-- Exercitiu
create or alter function (@supplier_id int)
returns varchar(100) as
begin
    declare @result varchar(100);

    select top 1 
        @result = p.ProductName
    from Products p
    join [Order Details] od on od.ProductID = p.ProductID
    where p.SupplierID = @supplier_id
    group by p.ProductName
    order by sum(od.Quantity) desc;

    return @result;
end;
go

select 
    s.CompanyName as supplier, 
    coalesce(dbo.produs_vandut(s.SupplierID), '-') as produs_max
from Suppliers s;
go

