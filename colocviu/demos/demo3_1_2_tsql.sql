use northwind;
go
-- NR 1.

-- Pentru fiecare supplier vrem sa aflam:

-- 1. Orașul cu cele mai multe comenzi (1p)
create or alter function get_most_ordered_city(@supplier_id int)
returns varchar(100) as
begin
    declare @result varchar(100);

    select top 1 
        @result = o.shipcity
    from products p
    join [order details] od on p.productid = od.productid
    join orders o on od.orderid = o.orderid
    where p.supplierid = @supplier_id
    group by o.shipcity
    order by count(o.orderid) desc;

    return @result;
end;
go

select 
    s.companyname as supplier, 
    coalesce(dbo.get_most_ordered_city(s.supplierid), '-') as most_ordered_city
from suppliers s;
go


-- 2. Cea mai veche comanda (OrderID & data) (1p)
create or alter function get_oldest_order(@supplier_id int)
returns varchar(200) as
begin
    declare @result varchar(200);

    select top 1 
        @result = cast(o.orderid as varchar) + ' - ' + convert(varchar, o.orderdate, 23)
    from products p
    join [order details] od on p.productid = od.productid
    join orders o on od.orderid = o.orderid
    where p.supplierid = @supplier_id
    order by o.orderdate;

    return @result;
end;
go

select 
    s.companyname as supplier, 
    coalesce(dbo.get_oldest_order(s.supplierid), '-') as oldest_order
from suppliers s;
go


-- 3. Produsele (ProductName) cu pretul peste media preturilor tuturor produselor din baza de date. (2p)
create or alter function peste_medie(@supplier_id int)
returns VARCHAR(200) as
begin
    declare @result varchar(200);
    select 
        @result = STRING_AGG(p.productname, ',')
    from products p
    where p.supplierid = @supplier_id
      and p.unitprice > (select avg(unitprice) from products);
    return @result;
end;
go

select 
    s.companyname as supplier,
    coalesce(dbo.peste_medie(s.supplierid), '-') as high_price_products
from suppliers s;
go


-- 4. Daca furnizorul (supplier-ul) a livrat produse in cel putin 10 regiuni distincte. Afisati "Da" sau "Nu".(2p)
select * from orders;
go
create or alter function livrare_10_regiuni(@supplier_id int)
returns varchar(10) as
begin 
    declare @result varchar(200);
    select
        @result = case 
            when count(distinct o.shipregion) >=10 then 'Da'
            else 'Nu'
        end
    from orders o
    join [Order Details] od on o.OrderID = od.OrderID
    join Products p on od.ProductID = p.ProductID
    where p.supplierid = @supplier_id
    return @result;
end;
go

select 
    s.companyname as supplier,
    coalesce(dbo.livrare_10_regiuni(s.supplierid), '-') as livrare_buna
from suppliers s;
go

-- 5. Categoria de produse (CategoryName) care este cea mai vanduta (Quantity * UnitPrice) in peste 50 % din tari si cel mai vandut produs asociat acestei categorii (3p)
select * from Categories;
select * from Products;
go

create or alter function categorie_top(@supplier_id int)
returns varchar(max)
as
begin 
    declare @result varchar(max);

    select top 1 
        @result = c.CategoryName + ' - ' + p.ProductName
    from categories c
    join products p on p.CategoryID = c.CategoryID
    join [Order Details] od on od.ProductID = p.ProductID 
    join Orders o on o.OrderID = od.OrderID
    where p.supplierid = @supplier_id
    group by c.CategoryName, p.ProductName
    having count(distinct o.shipcountry) > (
        select count(distinct shipcountry) / 2.0 
        from orders
    )
    order by sum(od.quantity * od.unitprice) desc;

    return @result;
end;
go

select 
    s.companyname as supplier,
    coalesce(dbo.categorie_top(s.supplierid), '-') as top_category_and_product
from suppliers s;
go

-- Afisati rezultatele sub forma unui singur tabel. (1p)
select 
    s.companyname as supplier, 
    coalesce(dbo.get_most_ordered_city(s.supplierid), '-') as most_ordered_city,
    coalesce(dbo.get_oldest_order(s.supplierid), '-') as oldest_order,
    coalesce(dbo.peste_medie(s.supplierid), '-') as high_price_products,
    coalesce(dbo.livrare_10_regiuni(s.supplierid), '-') as livrare_buna,
    coalesce(dbo.categorie_top(s.supplierid), '-') as top_category_and_product
from suppliers s;
go

-- NR 2.

-- Pentru fiecare produs vrem sa aflam:

-- 1. In cate regiuni diferite a fost vandut? (1p)
create or alter function regiune(@supplier_id int)
returns int
as
begin 
    declare @result int;

    select 
        @result = COUNT(distinct o.ShipRegion) 
    from Orders o
    join [Order Details] od on o.OrderID = od.OrderID
    join Products p on p.ProductID = od.ProductID
    where p.supplierid = @supplier_id;
    
    return @result;
end;
go

select 
    s.companyname as supplier,
    coalesce(dbo.regiune(s.supplierid), '-') as regiuni_distincte
from suppliers s
order by regiuni_distincte desc; --adaugata in plus
go

-- 2. Cea mai scumpa comanda plasata (OrderID & pret) (1p)
create or alter function comanda_scumpa(@supplier_id int)
returns VARCHAR(max)
as
begin 
    declare @result VARCHAR(max);

    select
        @result = cast(o.OrderID as varchar) + ' & ' + cast(sum(od.Quantity*od.UnitPrice) as varchar)
    from Orders o
    join [Order Details] od on o.OrderID = od.OrderID
    join Products p on p.ProductID = od.ProductID
    where p.supplierid = @supplier_id
    group by o.OrderID
    order by sum(od.Quantity*od.UnitPrice) desc;
    return @result;
end;
go

select top 1
    s.companyname as supplier,
    coalesce(dbo.comanda_scumpa(s.supplierid), '-') as pret_max
from suppliers s; 
go

-- 3. Daca face parte dintr-o "categorie top". O "categorie top "are vanzari de peste 15k (UnitPrice * Quantity) in ultima luna in cel putin 17 regiuni. Afisati numele categoriei sau "Nu". (2p)
create or alter function categorie_top_regiune(@supplier_id int)
returns VARCHAR(max)
as
begin 
    declare @result VARCHAR(max);

    select
        @result =  c.CategoryName
    from Orders o
    join [Order Details] od on o.OrderID = od.OrderID
    join Products p on p.ProductID = od.ProductID
    join Categories c on p.CategoryID = c.CategoryID
    where p.supplierid = @supplier_id
            and month(o.OrderDate) = 12 
    group by c.CategoryName
    having
        sum(od.Quantity*od.UnitPrice) >= 15000 
        and count(distinct o.ShipRegion) >= 17
    order by count(distinct o.ShipRegion) desc;

    return @result;
end;
go

select 
    s.companyname as supplier,
    coalesce(dbo.categorie_top_regiune(s.supplierid), 'NU') as categorie
from suppliers s; 
go

-- 4. Care este cea mai profitabilă locație (ShipCity) pentru acest produs? (2p) 
create or alter function locatie_profitabila(@supplier_id int)
returns VARCHAR(max)
as
begin 
    declare @result VARCHAR(max);

    select top 1
        @result = o.ShipCity
    from Orders o
    join [Order Details] od on o.OrderID = od.OrderID
    join Products p on p.ProductID = od.ProductID
    where p.supplierid = @supplier_id
    group by o.ShipCity
    order by sum(od.Quantity * od.UnitPrice) desc;

    return @result;
end;
go

select
    s.companyname as supplier,
    coalesce(dbo.locatie_profitabila(s.supplierid), '-') as locatie_fancy
from suppliers s; 
go

-- 5. Daca este cel mai vandut (Quantity) produs dintre cele livrate de cei mai bine cotati livratori. Cei mai bine cotati livratori, livreaza in peste 85% din tari. Afisati "Da" sau "Nu". (3p)
create or alter function livratori_top(@ProductID int)
returns varchar(10)
as
begin 
    declare @result varchar(10);

    -- Determinarea numarului total de tari distincte
    declare @total_tari int;
    select 
        @total_tari = count(distinct shipcountry)
    from orders;


    -- Verificarea daca furnizorul a livrat în cel putin 85% din tari
    if exists (
        select 1
        from Orders o
        join [Order Details] od on o.OrderID = od.OrderID
        join Products p on p.ProductID = od.ProductID
        join Suppliers s on p.SupplierID = s.SupplierID
        where p.ProductID = @ProductID
        group by p.ProductID, p.SupplierID
        having count(distinct o.ShipCountry) >= 0.85 * @total_tari -- livrator bine cotat
                and sum(od.Quantity) = ( -- produsul este cel mai vândut
                        select max(total_quantity)
                        from (
                            select 
                                p2.SupplierID, 
                                sum(od2.Quantity) as total_quantity
                            from [Order Details] od2
                            join Products p2 on od2.ProductID = p2.ProductID
                            group by p2.SupplierID
                        ) as supplier_totals
                        where supplier_totals.SupplierID = p.SupplierID
                    )
    )
    begin
        -- Livrator bine cotat
        set @result = 'Da'
    end
    else
    begin
        -- Livrator nu este bine cotat
        set @result = 'Nu'
    end

    return @result;
end;
go

select
    s.companyname as supplier,
    coalesce(dbo.livratori_top(s.supplierid), '-') as livratori_regiuni
from suppliers s; 
go


-- Afisati rezultatele sub forma unui singur tabel. (1p)
select 
    s.companyname as supplier, 
    coalesce(dbo.regiune(s.supplierid), '-') as regiuni_distincte,
    coalesce(dbo.comanda_scumpa(s.supplierid), '-') as pret_max,
    coalesce(dbo.categorie_top_regiune(s.supplierid), 'NU') as categorie,
    coalesce(dbo.locatie_profitabila(s.supplierid), '-') as locatie_fancy,
    coalesce(dbo.livratori_top(s.supplierid), '-') as livratori_regiuni
from suppliers s;
go