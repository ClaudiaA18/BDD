/*
5_12_1c
NR1
Dorim sa imbunatatim experienta platformei noastre
asa ca dorim sa aflam urmatoarele statistici 
pentru fiecare tara (Orders.ShipCountry):
- Cate comenzi au fost livrate in acelasi oras
(ca si comanda) in ultimul an (ultimul an in care 
s-au facut comenzi) = 1p
- Rata de intarziere a unei comenzi din aceeasi
regiune vs din afara regiunii, calculata ca si 
procent (ex “30% vs 60%”); o comanda se considera
intarziata daca Required Date - ShippedDate >= 3
(zile; daca o comanda nu este inca trimisa folositi
diferenta maxima) = 2p
- Pentru fiecare angajat (Numele complet al angajatului)
din tara, Categoria de produse dominanta 
(categoria din care s-a vandut cel mai mult ca si
suma de bani pentru acel angajat), din ultimii 2 ani
in care a facut vanzari acea tara = 3p
- Furnizorii(Suppliers. CompanyName) care au
redistribuitori; se considera un redistribuitor
un client care se afla in partea de sus a distributiei
cantitatii (pentru o categorie de produse, este
suficient sa fie in una) si in acea distributie
valoarea mediei este minim 1.5 din mediana
(mediana nu se va calcula folosind functia MEDIAN
din oracle); este suficient sa existe un singur
redistribuitor in oricare categorie ca sa afisam
furnizorul = 4p
- Afisare si precizari extra:
- Daca cumva nu sunt, deloc, astfel de informatii
(categorii, produse, etc) afisati 66 39
- Vom afisa pentru fiecare tara aceste informatii,
pe un singur rand
Exemplu afisare:
Nume Tara, NumarComenziRapide,Ratalntarziere,
Favorite, Redistribuitori RO,15,"50% vs 240%"
"Alex: IT, George: Dezinformare”,”Apple"
*/

use northwind;
go 

-- Cate comenzi au fost livrate in acelasi oras
-- (ca si comanda) in ultimul an (ultimul an in care 
-- s-au facut comenzi) = 1p

create or alter function comenzi_acelasi_oras(@shipcountry varchar(100))
returns int as
begin
    declare @result int;

    select 
        @result = count(*)
    from Orders o
    where o.ShipCountry = @shipcountry
      and o.ShipCity = o.ShipAddress
      and YEAR(o.OrderDate) = (select max(YEAR(OrderDate)) from Orders);

    return @result;
end;
go


select 
    o.ShipCountry as NumeTara,
    coalesce(dbo.comenzi_acelasi_oras(o.ShipCountry), '-') as NumarComenziRapide
    from Orders o
group by o.ShipCountry;
go


-- Rata de intarziere a unei comenzi din aceeasi
-- regiune vs din afara regiunii, calculata ca si 
-- procent (ex “30% vs 60%”); o comanda se considera
-- intarziata daca Required Date - ShippedDate >= 3
-- (zile; daca o comanda nu este inca trimisa folositi
-- diferenta maxima) = 2p
create or alter function rata_intarziere(@shipcountry varchar(100))
returns varchar(50) as
begin
    declare @in_region int;
    declare @out_region int;

    -- Întârzieri în aceeași regiune
    select 
        @in_region = count(*)
    from Orders o
    where o.ShipCountry = @shipcountry
      and o.ShipRegion = o.ShipCity
      and DATEDIFF(day, o.RequiredDate, o.ShippedDate) >= 3;

    -- Întârzieri din afara regiunii
    select 
        @out_region = count(*)
    from Orders o
    where o.ShipCountry = @shipcountry
      and o.ShipRegion <> o.ShipCity
      and DATEDIFF(day, o.RequiredDate, o.ShippedDate) >= 3;

    return concat(@in_region, '% vs ', @out_region, '%');
end;
go


select 
    o.ShipCountry as NumeTara,
    coalesce(dbo.rata_intarziere(o.ShipCountry), '-') as Ratalntarziere
from Orders o
group by o.ShipCountry;
go

-- Pentru fiecare angajat (Numele complet al angajatului)
-- din tara, Categoria de produse dominanta 
-- (categoria din care s-a vandut cel mai mult ca si
-- suma de bani pentru acel angajat), din ultimii 2 ani
-- in care a facut vanzari acea tara = 3p

create or alter function categorie_dominanta(@shipcountry varchar(100))
returns varchar(200) as
begin
    declare @result varchar(200);

    select top 1 
        @result = c.CategoryName
    from Employees e
    join Orders o on e.EmployeeID = o.EmployeeID
    join [Order Details] od on o.OrderID = od.OrderID
    join Products p on od.ProductID = p.ProductID
    join Categories c on p.CategoryID = c.CategoryID
    where o.ShipCountry = @shipcountry
    group by c.CategoryName
    order by sum(od.Quantity * od.UnitPrice) desc;

    return @result;
end;
go

select 
    o.ShipCountry as NumeTara,
    coalesce(dbo.categorie_dominanta(o.ShipCountry), '-') as Favorite
from Orders o
group by o.ShipCountry;
go


-- Furnizorii(Suppliers. CompanyName) care au
-- redistribuitori; se considera un redistribuitor
-- un client care se afla in partea de sus a distributiei
-- cantitatii (pentru o categorie de produse, este
-- suficient sa fie in una) si in acea distributie
-- valoarea mediei este minim 1.5 din mediana
-- (mediana nu se va calcula folosind functia MEDIAN
-- din oracle); este suficient sa existe un singur
-- redistribuitor in oricare categorie ca sa afisam
-- furnizorul = 4p

create or alter function redistribuitori(@shipcountry varchar(100))
returns varchar(200) as
begin
    declare @result varchar(200);

    if exists (
        select 1
        from [Order Details] od
        join Orders o on od.OrderID = o.OrderID
        join Products p on od.ProductID = p.ProductID
        join Suppliers s on p.SupplierID = s.SupplierID
        where o.ShipCountry = @shipcountry
          and od.Quantity >= (select avg(od2.Quantity) * 1.5
                              from [Order Details] od2
                              where od2.ProductID = p.ProductID)
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
    o.ShipCountry as NumeTara,
    coalesce(dbo.redistribuitori(o.ShipCountry), '-') as Redistribuitori
from Orders o
group by o.ShipCountry;
go


-- Afisare finala
select 
    o.ShipCountry as NumeTara,
    coalesce(dbo.comenzi_acelasi_oras(o.ShipCountry), '-') as NumarComenziRapide,
    coalesce(dbo.rata_intarziere(o.ShipCountry), '-') as Ratalntarziere,
    coalesce(dbo.categorie_dominanta(o.ShipCountry), '-') as Favorite,
    coalesce(dbo.redistribuitori(o.ShipCountry), '-') as Redistribuitori
from Orders o
group by o.ShipCountry;
go
