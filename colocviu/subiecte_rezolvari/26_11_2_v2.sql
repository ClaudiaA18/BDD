-- 26_11_2
/*
NR 2
Pentru fiecare tara afișați:
1.⁠ ⁠(1p)Categoria cu cele mai mari vânzări(CategoryName).
2.⁠ ⁠(2p)Daca este tara target afișați “target”, altfel afișați “normal” 
(o tara este target daca valoarea totală a comenzilor 
OrderDetails.Quantity * OrderDetails.UnitPrice) depășește 
media valorii comenzilor pe toate țările) 
3.⁠ ⁠(2p)Furnizorii care au livrat produse discontinue (Products.Discontinued = 1)
din cel puțin 2 categorii diferite. 
4.⁠ ⁠(2p)Daca valoarea totală a comenzilor depășește cu cel puțin 20% 
valoarea medie globală a comenzilor. ( “da” sau “nu”) 
5.⁠ ⁠(3p)Cea mai profitabila locație de livrare (ShipCity orasul care 
a produs cel mai mulți bani, dar ia in considerare doar orașele in care
au fost cel puțin 20 de livrări). O locație este profitabila doar daca are concurenta
(in tara respectivă exista cel puțin 2 orașe in care se fac livrări)
*/

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

