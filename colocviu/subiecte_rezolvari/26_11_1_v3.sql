/*
26_11_1_v2c
NR 1
Analiza performanței pe furnizori. Pentru fiecare furnizor (CompanyName), afișați:
1.  (1p) Care este produsul cel mai vândut
2.  ⁠(2p) Dacă furnizorul este "relevant" sau "marginal": Un furnizor este "relevant"
 dacă valoarea totală a produselor (OrderDetails.Quantity * OrderDetails.UnitPrice) 
 livrate depășește media globală a vânzărilor pe furnizori.
3.  ⁠(2p) Produsul cel mai bine vândut (ProductName) pentru fiecare furnizor, 
dar doar dacă produsul a fost comandat în cel puțin 20 locații distincte (ShipCity).
4.  ⁠(2p) Dacă furnizorul a livrat produse către cel puțin 5 categorii distincte 
(CategoryID) (da sau nu).
5.  ⁠(3p) care este cel mai popular produs de la furnizor, cumpărat de clienții noi 
in mai multe tari
*/

-- 1.  (1p) Care este produsul cel mai vândut
create or replace function f1(supplier_id integer)
return varchar 
as
returns varchar(100);
begin
    select p.ProductName
    into returns
    from Products p
    join order_details od on od.ProductID = p.ProductID
    where p.SupplierID = supplier_id
    group by p.ProductName
    order by sum(od.Quantity) desc
    fetch first 1 row only;
    return returns;
end;
/

select 
    s.CompanyName as furnizor, 
    nvl(f1(s.SupplierID), '-') as prod_fav
from Suppliers s;
/

-- 2.  ⁠(2p) Dacă furnizorul este "relevant" sau "marginal": Un furnizor
-- este "relevant" dacă valoarea totală a produselor 
-- (OrderDetails.Quantity *OrderDetails.UnitPrice)
-- livrate depășește media globală a vânzărilor pe furnizori.
create or replace function f2(supplier_id integer)
return varchar as
result varchar(100);
total_vanzari_furnizor number;
media_globala number;
begin
    select sum(od.Quantity * od.UnitPrice)
    into total_vanzari_furnizor
    from Products p
    join order_details od on od.ProductID = p.ProductID
    where p.SupplierID = supplier_id;

    select 
        avg(total_sales)
    into media_globala
    from (
        select 
            sum(od.Quantity * od.UnitPrice) as total_sales
        from Products p
        join order_details od on od.ProductID = p.ProductID
        group by p.SupplierID
    ) 
    fetch first 1 rows only;

    if total_vanzari_furnizor > media_globala then
        result := 'Relevant';
    else
        result := 'Marginal';
    end if;

    return result;
end;
/

select 
    s.CompanyName as furnizor, 
    nvl(f2(s.SupplierID), '-') as ok
from Suppliers s;
/

-- 3.  ⁠(2p) Produsul cel mai bine vândut (ProductName) pentru fiecare furnizor, 
-- dar doar dacă produsul a fost comandat în cel puțin 20 locații distincte (ShipCity).
-- Crearea funcției pentru a determina produsul cel mai bine vândut
create or replace function f3(supplier_id integer)
return varchar
as
returns varchar(100);
begin
    select p.ProductName
    into returns
    from Products p
    join order_details od on p.ProductID = od.ProductID
    join Orders o on od.OrderID = o.OrderID
    where p.SupplierID = supplier_id
    group by p.ProductName
    having count(distinct o.ShipCity) >= 20
    order by sum(od.Quantity) desc -- gen asa faci max, de ce se ti bati capul cu functii de agregare =))
    fetch first 1 rows only;
    return returns;
end;
/

select 
    s.CompanyName as furnizor,
    nvl(f3(s.SupplierID), '-') as best_prod
from Suppliers s;
/

-- 4.  ⁠(2p) Dacă furnizorul a livrat produse către cel puțin 5 categorii distincte (CategoryID) (da sau nu).
CREATE OR REPLACE FUNCTION f4(supplier_id INTEGER)
RETURN VARCHAR2 AS
    category_count INTEGER;
BEGIN
    -- Attempt to count distinct CategoryIDs associated with the supplier
    SELECT COUNT(DISTINCT p.CategoryID)
    INTO category_count
    FROM Products p
    WHERE p.SupplierID = supplier_id;

    -- Check if the count of distinct categories is at least 5
    IF category_count >= 5 THEN
        RETURN 'Da';  -- Yes in Romanian
    ELSE
        RETURN 'Nu';  -- No in Romanian
    END IF;
END;
/
-- asta cu select 1 e cea mai dubiosica => nu facem

select 
    s.CompanyName as furnizor,
    f4(s.SupplierID) as daca_da
from Suppliers s;
/

-- 5.  ⁠(3p) care este cel mai popular produs de la furnizor, cumpărat de clienții noi in mai multe tari
create or replace function f5(supplier_id int)
return varchar
as
returns varchar(100);
begin
    select p.ProductName
    into returns
    from Products p
    join order_details od on p.ProductID = od.ProductID
    join Orders o on od.OrderID = o.OrderID
    join Customers c on o.CustomerID = c.CustomerID
    where p.SupplierID = supplier_id
      and c.CustomerID not in ( 
        -- client nou = nu se afla in orders daca e mai mic 
        -- decat o anumita data selectata in prod sau cv
        -- decat data comenzii produsului curent selectat sau cv
        -- crazy
          select CustomerID
          from Orders
          where OrderDate < o.OrderDate
      ) -- ok!
    group by p.ProductName
    order by count(distinct o.ShipCountry) desc -- max faci asa =))
    fetch first 1 rows only;

    return returns;
end;
/

select 
    s.CompanyName as supplier,
    nvl(f5(s.SupplierID), '-') as prod_pop_nou
from Suppliers s;
/
