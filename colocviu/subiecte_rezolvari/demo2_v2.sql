-- 26_11_2v2c
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
-- daca vrea pentru fiecare tara, functiile iau ca argument tara
-- daca zice categoria => from category.
-- vanzari => e gen profit, e gen od.Quantity * od.UnitPrice, mi se pare ca si zice
-- cele mai mari => max => ord desc si fetch first 1 row only
create or replace function f1(tara varchar)
return varchar as
returns varchar(200);
begin
    select c.CategoryName
    into returns
    from Categories c
    join Products p on c.CategoryID = p.CategoryID
    join order_details od on p.ProductID = od.ProductID
    join Orders o on od.OrderID = o.OrderID
    where o.ShipCountry = tara
    group by c.CategoryName
    order by sum(od.Quantity * od.UnitPrice) desc
    fetch first 1 rows only;
    -- grupezi dupa nume ca gen verifici per categorie
    return returns;
end;
/

select 
    o.ShipCountry as tara,
    nvl(f1(o.ShipCountry), '-') as categorii_top
from Orders o
group by o.ShipCountry;
-- aici grupezi pe tara
/

-- 2.⁠ ⁠(2p)Daca este tara target afișați “target”, altfel afișați “normal” 
-- (o tara este target daca valoarea totală a comenzilor 
-- OrderDetails.Quantity *OrderDetails.UnitPrice) 
-- depășește media valorii comenzilor pe toate țările) 
create or replace function f2(tara varchar)
return varchar as
    returns varchar(200);
    vanzari_tot float;
    med_vanzari float;
begin
    -- acum le iei pe bucatele
    -- Calcularea vanzarilor totale pentru tara specificata\
    -- vanzarile sunt pe produse gen
    -- si le grupezi pe tari ca na pe tara cere
    -- desi merge sa faci direct si din od, nuj de ce a luat pe produs but ok
    select 
        sum(od.Quantity * od.UnitPrice)
    into vanzari_tot
    from Products p
    join order_details od on p.ProductID = od.ProductID
    join Orders o on od.OrderID = o.OrderID
    where o.ShipCountry = tara;

    -- Calcularea mediei globale a vanzarilor
    select 
        avg(TotalSales) -- si faci media pe toate tarile
    into med_vanzari
    from (
        select sum(od.Quantity * od.UnitPrice) as TotalSales -- faci vanzarile
        from order_details od -- din od
        join Orders o on od.OrderID = o.OrderID -- si le faci pe tara =S
        group by o.ShipCountry
    );

    if vanzari_tot > med_vanzari then
        -- Tara target
        returns := 'target';
    else
        -- Tara normala
        returns := 'normal';
    end if;

    return returns;
end;
/

select 
    o.ShipCountry as tara,
    nvl(f2(o.ShipCountry), '-') as target_vs_normal
from Orders o
group by o.ShipCountry;
/

-- 3.⁠ ⁠(2p)Furnizorii care au livrat produse discontinue 
-- (Products.Discontinued = 1) din cel puțin 2 categorii diferite.
-- din cel putin 2 categorii -> adica from categories si de acolo vezi ce faci si unde te duci 
create or replace function f3(tara varchar)
return varchar as
    returns varchar(100);
begin
    select c.CategoryName
    into returns
    from Categories c
    join Products p on c.CategoryID = p.CategoryID
    join order_details od on p.ProductID = od.ProductID
    join Orders o on od.OrderID = o.OrderID
    where o.ShipCountry = tara
    and p.Discontinued = 1
    group by c.CategoryName --daca ai count pe asa ceva inseamna ca faci grup by si ca e in select
    having count(c.CategoryName) >=2
    order by count(c.CategoryName)
    fetch first 1 rows only;

    return returns;
end;
/

select 
    o.ShipCountry as tara,
    nvl(f3(o.ShipCountry), '-') as categorii_top
from Orders o
group by o.ShipCountry;
/

-- 4.⁠ ⁠(2p)Daca valoarea totală a comenzilor depășește 
-- cu cel puțin 20% valoarea medie globală a comenzilor. ( “da” sau “nu”) 
create or replace function f4(tara varchar)
return varchar as
    returns varchar(100);
    vanzari_totale float;
    vanzari_globale float;
begin
    -- asta e 2ish
    -- acum le iei pe bucatele
    -- Calcularea vanzarilor totale pentru tara specificata\
    -- vanzarile sunt pe produse gen
    -- si le grupezi pe tari ca na pe tara cere
    -- desi merge sa faci direct si din od, nuj de ce a luat pe produs but ok
    select 
        sum(od.Quantity * od.UnitPrice)
    into vanzari_totale
    from Products p
    join order_details od on p.ProductID = od.ProductID
    join Orders o on od.OrderID = o.OrderID
    where o.ShipCountry = tara;

    -- Calcularea mediei globale a vanzarilor
    select 
        avg(TotalSales) -- si faci media pe toate tarile
    into vanzari_globale
    from (
        select sum(od.Quantity * od.UnitPrice) as TotalSales -- faci vanzarile
        from order_details od -- din od
        join Orders o on od.OrderID = o.OrderID -- si le faci pe tara =S
        group by o.ShipCountry
    );
    -- vanzari_globale = medie si gen da astea au fost si la 2
    -- depaseste cu 20% adica cu 0.2 adica este cu 0.2 peste 1 adica 1.2
    if vanzari_totale > vanzari_globale * 1.2 then
        returns := 'da';
    else
        -- Tara normala
        returns := 'nu';
    end if;

    return returns;
end;
/

select 
    o.ShipCountry as tara,
    nvl(f4(o.ShipCountry), '-') as peste_medie
from Orders o
group by o.ShipCountry;
/

-- 5.⁠ ⁠(3p)Cea mai profitabila locație de livrare 
-- (ShipCity orasul care a produs cel mai mulți bani, 
-- dar ia in considerare doar orașele in care au fost 
-- in cel puțin 20 de livrări). 
-- O locație este profitabila doar daca are concurenta
-- (in tara respectivă exista cel puțin 2 orașe in care se fac livrări)
create or replace function f5(tara varchar)
return varchar as
returns varchar(100);
ceva integer;
begin
    -- Verificam daca tara are cel putin 2 orase diferite cu livrari
    select count(distinct o.ShipCity)
    into ceva
        from Orders o
        where o.ShipCountry = tara;
    if ceva >= 2 then
        -- Determinam locatia cu cele mai mari vanzari
        -- vanzarile sunt in orders
        select o.ShipCity
        into returns
        from Orders o
        join order_details od on o.OrderID = od.OrderID
        where o.ShipCountry = tara
        group by o.ShipCity
        having count(o.OrderID) >= 20 -- daca au fost macar 20 orderuri si gen grupezi oras ca oras cere =))
        order by sum(od.Quantity * od.UnitPrice) desc
        fetch first 1 rows only;
    else
        returns := 'NU';
    end if;
    return returns;
end;
/

select 
    o.ShipCountry as tara,
    nvl(f5(o.ShipCountry), '-') as categorii_top
from Orders o
group by o.ShipCountry;
/

