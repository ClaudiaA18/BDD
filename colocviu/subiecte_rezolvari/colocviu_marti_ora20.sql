use northwind;
go 

-- NR 1

-- Analiza performanței pe furnizori. Pentru fiecare furnizor (CompanyName), afișați:

-- 1.  (1p) Care este produsul cel mai vândut
create or alter function produs_vandut(@supplier_id int)
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

-- 2.  ⁠(2p) Dacă furnizorul este "relevant" sau "marginal": Un furnizor este "relevant" dacă valoarea totală a produselor (OrderDetails.Quantity *OrderDetails.UnitPrice
-- ) livrate depășește media globală a vânzărilor pe furnizori.
create or alter function relevant_sau_marginal(@supplier_id int)
returns varchar(100) as
begin
    declare @result varchar(100);

    declare @total_vanzari_furnizor float;
    select 
        @total_vanzari_furnizor = sum(od.Quantity * od.UnitPrice)
    from Products p
    join [Order Details] od on od.ProductID = p.ProductID
    where p.SupplierID = @supplier_id;

    declare @media_globala float;
    select 
        @media_globala = avg(total_sales)
    from (
        select 
            sum(od.Quantity * od.UnitPrice) as total_sales
        from Products p
        join [Order Details] od on od.ProductID = p.ProductID
        group by p.SupplierID
    ) as sales_data;

    if @total_vanzari_furnizor > @media_globala
        set @result = 'Relevant';
    else
        set @result = 'Marginal';

    return @result;
end;
go

select 
    s.CompanyName as supplier, 
    coalesce(dbo.relevant_sau_marginal(s.SupplierID), '-') as decizie
from Suppliers s;
go


-- 3.  ⁠(2p) Produsul cel mai bine vândut (ProductName) pentru fiecare furnizor, dar doar dacă produsul a fost comandat în cel puțin 20 locații distincte (ShipCity).
-- Crearea funcției pentru a determina produsul cel mai bine vândut
create or alter function produs_vandut_locatii(@supplier_id int)
returns varchar(100)
as
begin
    declare @result varchar(100);

    select top 1
        @result = p.ProductName
    from Products p
    join [Order Details] od on p.ProductID = od.ProductID
    join Orders o on od.OrderID = o.OrderID
    where p.SupplierID = @supplier_id
    group by p.ProductName
    having count(distinct o.ShipCity) >= 20
    order by sum(od.Quantity) desc;

    return @result;
end;
go

select 
    s.CompanyName as supplier,
    coalesce(dbo.produs_vandut_locatii(s.SupplierID), '-') as top_selling_product
from Suppliers s;
go
-- 4.  ⁠(2p) Dacă furnizorul a livrat produse către cel puțin 5 categorii distincte (CategoryID) (da sau nu).
create or alter function livrare_5_categorii(@supplier_id int)
returns varchar(10)
as
begin
    declare @result varchar(10);

    if exists (
        select 1
        from Products p
        join Categories c on p.CategoryID = c.CategoryID
        where p.SupplierID = @supplier_id
        group by p.SupplierID
        having count(distinct p.CategoryID) >= 5
    )
    begin
        set @result = 'Da';
    end
    else
    begin
        set @result = 'Nu';
    end

    return @result;
end;
go

select 
    s.CompanyName as supplier,
    dbo.livrare_5_categorii(s.SupplierID) as delivers_to_5_categories
from Suppliers s;
go

-- 5.  ⁠(3p) care este cel mai popular produs de la furnizor, cumpărat de clienții noi in mai multe tari
create or alter function produs_popular_clienti_noi(@supplier_id int)
returns varchar(100)
as
begin
    declare @result varchar(100);

    select top 1
        @result = p.ProductName
    from Products p
    join [Order Details] od on p.ProductID = od.ProductID
    join Orders o on od.OrderID = o.OrderID
    join Customers c on o.CustomerID = c.CustomerID
    where p.SupplierID = @supplier_id
      and c.CustomerID not in (
          select CustomerID
          from Orders
          where OrderDate < o.OrderDate
      )
    group by p.ProductName
    order by count(distinct o.ShipCountry) desc;

    return @result;
end;
go

select 
    s.CompanyName as supplier,
    coalesce(dbo.produs_popular_clienti_noi(s.SupplierID), '-') as popular_product_new_customers
from Suppliers s;
go

-- NR 2

-- Pentru fiecare tara afișați:

-- 1.⁠ ⁠(1p)Categoria cu cele mai mari vânzări(CategoryName).
create or alter function vanzari_record(@country varchar(200))
returns varchar(100) as
begin
    declare @result varchar(100);

    select top 1 
        @result = c.CategoryName
    from Categories c
    join Products p on c.CategoryID = p.CategoryID
    join [Order Details] od on p.ProductID = od.ProductID
    join Orders o on od.OrderID = o.OrderID
    where o.ShipCountry = @country
    group by c.CategoryName
    order by sum(od.Quantity * od.UnitPrice) desc;

    return @result;
end;
go

select 
    o.ShipCountry as Country,
    coalesce(dbo.vanzari_record(o.ShipCountry), '-') as categorii_top
from Orders o
group by o.ShipCountry;
go

-- 2.⁠ ⁠(2p)Daca este tara target afișați “target”, altfel afișați “normal” ( o tara este target daca valoarea totală a comenzilor OrderDetails.Quantity *OrderDetails.UnitPrice) depășește media valorii comenzilor pe toate țările) 
create or alter function target_vs_normal(@country varchar(200))
returns varchar(100) as
begin
    declare @result varchar(100);
    declare @total_sales float;
    declare @global_avg_sales float;

    -- Calcularea vanzarilor totale pentru tara specificata
    select 
        @total_sales = sum(od.Quantity * od.UnitPrice)
    from Products p
    join [Order Details] od on p.ProductID = od.ProductID
    join Orders o on od.OrderID = o.OrderID
    where o.ShipCountry = @country;

    -- Calcularea mediei globale a vanzarilor
    select 
        @global_avg_sales = avg(TotalSales)
    from (
        select sum(od.Quantity * od.UnitPrice) as TotalSales
        from [Order Details] od
        join Orders o on od.OrderID = o.OrderID
        group by o.ShipCountry
    ) as GlobalSales;

    if @total_sales > @global_avg_sales
    begin
        -- Tara target
        set @result = 'target'
    end
    else
    begin
        -- Tara normala
        set @result = 'normal'
    end

    return @result;
end;
go

select 
    o.ShipCountry as Country,
    coalesce(dbo.target_vs_normal(o.ShipCountry), '-') as target_vs_normal_coloana
from Orders o
group by o.ShipCountry;
go

-- 3.⁠ ⁠(2p)Furnizorii care au livrat produse discontinue (Products.Discontinued = 1) din cel puțin 2 categorii diferite. 
create or alter function produse_discontinue(@country varchar(200))
returns varchar(100) as
begin
    declare @result varchar(100);

    select 
        @result = c.CategoryName
    from Categories c
    join Products p on c.CategoryID = p.CategoryID
    join [Order Details] od on p.ProductID = od.ProductID
    join Orders o on od.OrderID = o.OrderID
    where o.ShipCountry = @country
    and p.Discontinued = 1
    group by c.CategoryName 
    having count(c.CategoryName) >=2
    order by count(c.CategoryName);

    return @result;
end;
go

select 
    o.ShipCountry as Country,
    coalesce(dbo.produse_discontinue(o.ShipCountry), '-') as categorii_top
from Orders o
group by o.ShipCountry;
go

-- 4.⁠ ⁠(2p)Daca valoarea totală a comenzilor depășește cu cel puțin 20% valoarea medie globală a comenzilor. ( “da” sau “nu”) 
create or alter function valoare_peste_medie(@country varchar(200))
returns varchar(100) as
begin
    declare @result varchar(100);
    declare @total_sales float;
    declare @global_avg_sales float;

    -- Calcularea vanzarilor totale pentru tara specificata
    select 
        @total_sales = sum(od.Quantity * od.UnitPrice)
    from Products p
    join [Order Details] od on p.ProductID = od.ProductID
    join Orders o on od.OrderID = o.OrderID
    where o.ShipCountry = @country;

    -- Calcularea mediei globale a vanzarilor
    select 
        @global_avg_sales = avg(TotalSales)
    from (
        select sum(od.Quantity * od.UnitPrice) as TotalSales
        from [Order Details] od
        join Orders o on od.OrderID = o.OrderID
        group by o.ShipCountry
    ) as GlobalSales;

    if @total_sales > @global_avg_sales * 1.2
    begin
        set @result = 'da'
    end
    else
    begin
        set @result = 'nu'
    end

    return @result;
end;
go

select 
    o.ShipCountry as Country,
    coalesce(dbo.valoare_peste_medie(o.ShipCountry), '-') as peste_medie
from Orders o
group by o.ShipCountry;
go

-- 5.⁠ ⁠(3p)Cea mai profitabila locație de livrare (ShipCity orasul care a produs cel mai mulți bani, dar ia in considerare doar orașele in care au fost cel puțin 20 de livrări). O locație este profitabila doar daca are concurenta ( in tara respectivă exista cel puțin 2 orașe in care se fac livrări)
create or alter function locatie_profitabila(@country varchar(200))
returns varchar(100) as
begin
    declare @result varchar(100);

    -- Verificam daca tara are cel putin 2 orase diferite cu livrari
    if exists (
        select count(distinct o.ShipCity)
        from Orders o
        where o.ShipCountry = @country
        having count(distinct o.ShipCity) >= 2
    )
    begin
        -- Determinam locatia cu cele mai mari vanzari
        select top 1
            @result = o.ShipCity
        from Orders o
        join [Order Details] od on o.OrderID = od.OrderID
        where o.ShipCountry = @country
        group by o.ShipCity
        having count(o.OrderID) >= 20 
        order by sum(od.Quantity * od.UnitPrice) desc;
    end
    else
    begin
        set @result = 'Nu'
    end
    return @result;
end;
go

select 
    o.ShipCountry as Country,
    coalesce(dbo.locatie_profitabila(o.ShipCountry), '-') as categorii_top
from Orders o
group by o.ShipCountry;
go

