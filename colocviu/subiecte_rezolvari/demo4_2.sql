-- 27_11_2
-- NR 2.
-- Pentru fiecare produs vrem sa aflam:
-- - In cate regiuni diferite a fost vandut? (1p)
-- - Cea mai scumpa comanda plasata (OrderID & pret) (1p)
-- - Daca face parte dintr-o "categorie top".
--   O "categorie top "are vanzari de peste 15k (UnitPrice * Quantity)
--   in ultima luna in cel putin 17 regiuni. Afisati numele categoriei sau "Nu". (2p)
-- - Care este cea mai profitabilă locație (ShipCity) pentru acest produs? (2p)
-- - Daca este cel mai vandut (Quantity) produs dintre cele livrate de cei mai bine cotati livratori.
--   Cei mai bine cotati livratori, livreaza in peste 85% din tari. Afisati "Da" sau "Nu". (3p)
-- - Afisati rezultatele sub forma unui singur tabel. (1p)

-- 1. In cate regiuni diferite a fost vandut? (1p)
-- singurul loc unde ai regiuni este orders =))
-- diferite = distinct
create or replace function f1(supplier_id integer)
return integer
as
returns integer;
begin 
    select 
        COUNT(distinct o.ShipRegion)
    into returns
    from Orders o
    join order_details od on o.OrderID = od.OrderID
    join Products p on p.ProductID = od.ProductID
    where p.supplierid = supplier_id;
    return returns;
end;
/

select 
    s.companyname as supplier,
    nvl(to_char(f1(s.supplierid)), '-') as regiuni_distincte
from suppliers s
order by regiuni_distincte desc; -- adaugata in plus
/

-- 2. Cea mai scumpa comanda plasata (OrderID & pret) (1p) adica from orders =))
create or replace function f2(supplier_id integer)
return VARCHAR
as
returns varchar(2000);
begin 
    select
        to_char(o.OrderID)||' & '||to_char(sum(od.Quantity*od.UnitPrice)) as comanda
    into returns
    from Orders o
    join order_details od on o.OrderID = od.OrderID
    join Products p on p.ProductID = od.ProductID
    where p.supplierid = supplier_id
    group by o.OrderID
    order by sum(od.Quantity*od.UnitPrice) desc; 
    -- cea mai scumpa e gen maxim dar gen maximul il iei daca ordonezi descrescator si iei prima chestie =))
    return @result;
end;
/

select
    s.companyname as furnizor,
    nvl(f2(s.supplierid), '-') as comanda_scumpa
from suppliers s
fetch first 1 rows only; 
/

-- 3. Daca face parte dintr-o "categorie top". 
-- O "categorie top "are vanzari de peste 15k (UnitPrice * Quantity) in ultima luna
-- in cel putin 17 regiuni. Afisati numele categoriei sau "Nu". (2p)
CREATE OR REPLACE FUNCTION f3(supplier_id INT)
RETURN VARCHAR2
AS
    returns VARCHAR2(2000) := 'NU';  -- Default to 'NU'
BEGIN 
    SELECT c.CategoryName
    INTO returns
    FROM Orders o
    JOIN order_details od ON o.OrderID = od.OrderID
    JOIN Products p ON p.ProductID = od.ProductID
    JOIN Categories c ON p.CategoryID = c.CategoryID
    WHERE p.supplierid = supplier_id
      AND o.orderdate >= ADD_MONTHS(TRUNC(SYSDATE, 'MM'), -1)  -- Last month from the first day of the current month
      -- tot nu cred ca e bine, dar vedem
      AND o.orderdate < TRUNC(SYSDATE, 'MM')  -- Before the first day of the current month
    GROUP BY c.CategoryName
    HAVING SUM(od.Quantity * od.UnitPrice) >= 15000 
      AND COUNT(DISTINCT o.ShipRegion) >= 17
    ORDER BY COUNT(DISTINCT o.ShipRegion) DESC
    FETCH FIRST 1 ROW ONLY;  -- Ensuring only the top category is selected if more than one qualifies

    RETURN returns;
END;
/

select 
    s.companyname as furnizor,
    nvl(f3(s.supplierid), 'NU') as categorie
from suppliers s; 
/

-- helpers
describe orders;
SELECT EXTRACT(MONTH FROM orderdate) AS order_month
FROM orders;

-- 4. Care este cea mai profitabilă locație (ShipCity) pentru acest produs? (2p) 
create or replace function f4(supplier_id integer)
return VARCHAR
as
returns varchar(2000);
begin 
    select o.ShipCity
    into returns
    from Orders o
    join order_details od on o.OrderID = od.OrderID
    join Products p on p.ProductID = od.ProductID
    where p.supplierid = supplier_id
    group by o.ShipCity
    order by sum(od.Quantity * od.UnitPrice) desc 
    -- cea mai profitabila => max profit care (aparent) e asta si
    -- ordonaezi descrescator si iei primul de ce sa te complici cu functii de agregare =))
    fetch first 1 row only;

    return returns;
end;
/

select
    s.companyname as furnizor,
    nvl(f4(s.supplierid), '-') as locatie_fancy
from suppliers s; 
/

-- 5. Daca este cel mai vandut (Quantity) produs dintre cele livrate de cei mai bine cotati livratori. 
-- Cei mai bine cotati livratori, livreaza in peste 85% din tari. Afisati "Da" sau "Nu". (3p)
-- de refacut, ca nu merge
/*
create or replace function f5(ProductID integer)
return varchar
as
returns varchar(10);
total_tari integer := 0;
begin 
    -- Determinarea numarului total de tari distincte
    select 
        count(distinct shipcountry)
    into total_tari
    from orders;

    -- Verificarea daca furnizorul a livrat în cel putin 85% din tari
    if exists (
        select 1 -- asta oricum verifica existenta
        from Orders o
        join order_details od on o.OrderID = od.OrderID
        join Products p on p.ProductID = od.ProductID
        join Suppliers s on p.SupplierID = s.SupplierID
        where p.ProductID = ProductID
        group by p.ProductID, p.SupplierID
        having count(distinct o.ShipCountry) >= 0.85 * total_tari 
        -- livrator bine cotat = produse vandute/catitate este maxim din toate contatitle de la acel furnizor
                and sum(od.Quantity) = ( -- produsul este cel mai vândut
                        select max(total_quantity) -- okk
                        from ( -- furnizori cu cantitate produse vandute (per total per furnzior)
                            select 
                                p2.SupplierID, 
                                sum(od2.Quantity) as total_quantity
                            from order_details od2
                            join Products p2 on od2.ProductID = p2.ProductID
                            group by p2.SupplierID
                        ) as supplier_totals
                        where supplier_totals.SupplierID = p.SupplierID -- pe acel furnizor 
                    ) -- mamaaa, ce ciudatica e asta
    )
    begin
        -- Livrator bine cotat
        set returns = 'Da'
    end
    else
    begin
        -- Livrator nu este bine cotat
        -- pica ceva pe where alea alea
        set returns = 'Nu'
    end;

    return returns;
end;
/

select
    s.companyname as furnizor,
    nvl(f5(s.supplierid), '-') as livratori_regiuni
from suppliers s; 
/
*/

-- Afisati rezultatele sub forma unui singur tabel. (1p)
select 
    s.companyname as furnizor, 
    nvl(to_char(f1(s.supplierid)), '-') as regiuni_distincte,
    nvl(f2(s.supplierid), '-') as pret_max,
    nvl(f3(s.supplierid), 'NU') as categorie,
    nvl(f4(s.supplierid), '-') as locatie_fancy --,
    -- coalesce(dbo.livratori_top(s.supplierid), '-') as livratori_regiuni
from suppliers s;
/