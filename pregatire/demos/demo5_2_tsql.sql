/*
5_12_2c
NR2
Dorim sa imbunatatim experienta platformei noastre,
asa ca dorim sa aflam urmatoarele statistici
pentru fiecare tara (Orders. ShipCountry):
- Cati clienti au dat macar o comanda pentru o alta
adresa decat a lor, in ultimul an (ultimul an in care
s-au facut comenzi) = 1p
- Care sunt top 3 curieri (Shippers.CompanyName) cu
livrari rapide; o livrare este rapida daca comanda
a fost livrata in cel mult 2 zile daca se livreaza
in alt oras fata de cel din care a plecat comanda,
3 zile daca este aceasi regiune, altfel 5 = 2p
- Daca top 3 cei mai ocupati angajati (angajatii care
au comenzi cu cele mai multe iteme "Order Details".
Quantity) in ultimul an sunt manageri sau nu "Da/Nu".
Un angajat este manager daca id-ul lui apare si in
coloana "Reports To❞ = 3p
- Top 3 categorii cu continuitate (exista minim un
client care comanda din aceasta categorie in luni
consecutive, se permit 3 luni care lipsesc, dar nu
2 consecutive in care sa lipseasca din comenzi) din
punct de vedere al numarului de unitati vandute,
pentru ultimii 2 ani = 4p
- Afisare si precizari extra:
- Daca cumva nu sunt, deloc, astfel de informatii
(categorii, produse, etc) afisati
- Daca cumva nu sunt 3, afisati cate sunt,
separate prin ";"
- Vom afisa pentru fiecare tara aceste informatii,
pe un singur rand
- Exemplu afisare:
- Nume Tara, NumarClientiComandaAltundeva Top3Curieri,
Top3Angajati, Top3 CategoriiContinue
- Romania, 100,"Cargus;Fan;SameDay","Da; Nu”,
*/

use northwind;
go 

-- Cati clienti au dat macar o comanda pentru o alta
-- adresa decat a lor, in ultimul an (ultimul an in care
-- s-au facut comenzi) = 1p

create or alter function comenzi_alta_adresa(@shipcountry varchar(100))
returns int as
begin
    declare @result int;

    select
        @result = count(distinct o.CustomerID)
    from Orders o
    join Customers c on o.CustomerID = c.CustomerID
    where o.ShipCountry = @shipcountry
    and YEAR(o.OrderDate) = (select max(YEAR(OrderDate)) from Orders)
    and o.ShipAddress <> c.Address;
    return @result;
end;
go

select 
    o.ShipCountry as tara, 
    coalesce(dbo.comenzi_alta_adresa(o.ShipCountry), '-') as NumarClientiComandaAltundeva
from Orders o
group by o.ShipCountry;
go


-- - Care sunt top 3 curieri (Shippers.CompanyName) cu
-- livrari rapide; o livrare este rapida daca comanda
-- a fost livrata in cel mult 2 zile daca se livreaza
-- in alt oras fata de cel din care a plecat comanda,
-- 3 zile daca este aceasi regiune, altfel 5 = 2p

create or alter function top_3_curieri(@shipcountry varchar(100))
returns varchar(100) as
begin
    declare @result varchar(100);

    select top 3
        @result = s.CompanyName
    from Orders o
    join Customers c on c.CustomerID = o.CustomerID
    join Shippers s on s.CompanyName = c.CompanyName
    where o.ShipCountry = @shipcountry
    -- datediff = return the difference between two date values, in days
    and datediff(day, o.OrderDate, o.ShippedDate) <= 
              case 
                  when o.ShipRegion = o.ShipCity then 3
                  when o.ShipRegion <> o.ShipCity then 2
                  else 5
              end
    group by s.CompanyName
    order by count(o.OrderID) desc;

    return @result;
end;
go

select 
    o.ShipCountry as tara, 
    coalesce(dbo.top_3_curieri(o.ShipCountry), '-') as Top3Curieri
from Orders o
group by o.ShipCountry;
go

-- Daca top 3 cei mai ocupati angajati (angajatii care
-- au comenzi cu cele mai multe iteme "Order Details".
-- Quantity) in ultimul an sunt manageri sau nu "Da/Nu".
-- Un angajat este manager daca id-ul lui apare si in
-- coloana "Reports To❞ = 3p

create or alter function angajati_ocupati(@shipcountry varchar(100))
returns varchar(10) as
begin
    declare @result varchar(10);

    if exists (
        select top 3 
            e.EmployeeID
        from Employees e
        join Orders o on e.EmployeeID = o.EmployeeID
        join [Order Details] od on o.OrderID = od.OrderID
        where o.ShipCountry = @shipcountry
        group by e.EmployeeID, e.ReportsTo
        having sum(od.Quantity) > 0
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
    o.ShipCountry as Tara, 
    coalesce(dbo.angajati_ocupati(o.ShipCountry), '-') as Top_3_Angajati
from Orders o
group by o.ShipCountry;
go


-- Top 3 categorii cu continuitate (exista minim un
-- client care comanda din aceasta categorie in luni
-- consecutive, se permit 3 luni care lipsesc, dar nu
-- 2 consecutive in care sa lipseasca din comenzi) din
-- punct de vedere al numarului de unitati vandute,
-- pentru ultimii 2 ani = 4p

create or alter function categorii_continuitate(@shipcountry varchar(100))
returns varchar(200) as
begin
    declare @result varchar(200);

    select 
        @result = c.CategoryName
    from Orders o
    join [Order Details] od on o.OrderID = od.OrderID
    join Products p on od.ProductID = p.ProductID
    join Categories c on p.CategoryID = c.CategoryID
    where o.ShipCountry = @shipcountry
    and o.OrderDate >= dateadd(year, -2, getdate())
    group by c.CategoryName
    having count(distinct month(o.OrderDate) + year(o.OrderDate) * 12) >= 9;

    return @result;
end;
go

select 
    o.ShipCountry as tara, 
    coalesce(dbo.categorii_continuitate(o.ShipCountry), '-') as TopCategorii
from Orders o
group by o.ShipCountry;
go



-- Afisare totala
select 
    o.ShipCountry as NumeTara,
    coalesce(dbo.comenzi_alta_adresa(o.ShipCountry), '-') as NumarClientiComandaAltundeva,
    coalesce(dbo.top_3_curieri(o.ShipCountry), '-') as Top3Curieri,
    coalesce(dbo.angajati_ocupati(o.ShipCountry), '-') as Top3Angajati,
    coalesce(dbo.categorii_continuitate(o.ShipCountry), '-') as Top3Categorii
from Orders o
group by o.ShipCountry;
go
