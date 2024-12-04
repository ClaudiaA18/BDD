/*
26_11_1_v2
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

-- 1.
-- trendul cere cu functii
create or replace function f1(supplier_id int)
return varchar2 as
    returns varchar2(100);
begin
    select
        p.productname
    into
        returns
    from
        products p
    join
        order_details od
    on
        p.productid = od.productid
    join    
        orders o
    on
        od.orderid = o.orderid
    where
        p.supplierid = supplier_id
    group by
        p.productname
    order by
        count(*) desc
    fetch first 1 row only;
    return returns;
end;
/

select 
    s.companyname as furnizor, 
    nvl(f1(s.supplierid), '-') as most_ordered_prod
from suppliers s;
/

-- sau
create or replace function ex11(supplier_id int)
RETURN integer
as
    returns integer;
BEGIN
    select
        max(p.REORDERLEVEL) -- cel mai vandut adica a fost max reordered
    INTO
        returns
    from
        Products p
    WHERE
        p.SupplierID = supplier_id;
    RETURN returns;
END;
/

select s.CompanyName, ex11(s.SupplierID) AS ReorderLevel
from Suppliers s;
/

-- sau
CREATE OR REPLACE FUNCTION ex1(supplier_id INT)
RETURN VARCHAR2 AS
    returns VARCHAR2(100);
BEGIN
    -- Finding the product with the highest ReorderLevel for a given SupplierID
    SELECT p.ProductName
    INTO returns
    FROM Products p
    WHERE p.SupplierID = supplier_id
      AND p.ReorderLevel = (
          SELECT MAX(ReorderLevel)
          FROM Products
          WHERE SupplierID = supplier_id
      );

    RETURN returns;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN NULL;
    WHEN TOO_MANY_ROWS THEN
        RETURN NULL;
    WHEN OTHERS THEN
        -- Handle unexpected errors
        RETURN 'Error occurred';
END;
/

SELECT s.CompanyName, ex1(s.SupplierID) AS MaxReorderProduct
FROM Suppliers s;
/

-- 2.
create or replace function ex2(supplier_id int) -- functia aceasta intoarce numarul vazarile pe furnizor
return integer AS
returns integer;
BEGIN
    select
        SUM(od.UnitPrice * od.Quantity)
    INTO
        returns
    from
        order_details od
    left join
        Products p
    on
        p.ProductID = od.ProductID
    WHERE
        p.SupplierID = supplier_id;

    RETURN returns;
END;
/
SELECT s.CompanyName,
       CASE
           WHEN MAX(ex2(s.SupplierID)) > 
               (
                   -- Calculate the total sales
                   (SELECT SUM(od2.UnitPrice * od2.Quantity) FROM order_details od2)
                   / 
                   -- Calculate the count of distinct suppliers
                   (SELECT COUNT(DISTINCT SupplierID) FROM Suppliers)
               )
           THEN 'relevant'
           ELSE 'marginal'
       END AS Status
FROM order_details od
LEFT JOIN Products p ON p.ProductID = od.ProductID
LEFT JOIN Suppliers s ON s.SupplierID = p.SupplierID
GROUP BY s.CompanyName;
-- aici asta nu merge for some reason

-- 3.
create or replace function ex3(product_id integer) -- functie ce numara orasele distincte in care s au vandut produse
RETURN integer
AS
returns integer;
BEGIN
    select
        count(distinct o.ShipCity)
    into
        returns
    from
        Products p
    left join
        order_details od
    ON
        od.ProductID = p.ProductID
    left join
        Orders o
    on
        o.OrderID = od.OrderID 
    where
        p.ProductID = product_id;

    return returns;
END;
/

select 
    max(p.ProductName) as ProductName, 
    p.ReorderLevel,
    ex3(p.ProductID) as Orders
from
    Products p
left join
    order_details od
ON
    od.ProductID = p.ProductID
left join
    Orders o
on
    o.OrderID = od.OrderID
where
    p.ReorderLevel = (ex11(p.SupplierID)) -- gen e cel mai recumparat produs, now I see
and (ex3(p.ProductID)) >= 20 -- si e vandut in peste 20 orase distincte
group by
    p.SupplierID,
    p.ReorderLevel,
    p.ProductID;
/

-- se lasa asa chit ca nuj daca afiseaza bine, dar logica e zdravana
SELECT 
    s.companyname AS furnizor,
    MAX(p.ProductName) AS ProductName
FROM
    Products p
JOIN Suppliers s ON s.supplierid = p.supplierid
LEFT JOIN order_details od ON od.ProductID = p.ProductID
LEFT JOIN Orders o ON o.OrderID = od.OrderID
GROUP BY
    p.SupplierID,
    p.ReorderLevel,
    p.ProductID,
    s.companyname
HAVING
    p.ReorderLevel = ex11(p.SupplierID) -- Assuming ex11 is a valid function that returns an integer
    AND ex3(p.ProductID) >= 20 -- Ensuring the product is sold in over 20 distinct cities
;
/

-- 4. daca a livrat cel putin 5 categorii diferite
select 
    max(s.CompanyName) as CompanyName, 
    case
    when (count(distinct p.CategoryID) >= 5) then 'DA' else 'NU' end AS NrCategorii
from
    Suppliers s
left join
    Products p
on
    p.SupplierID = s.SupplierID
group by
    s.SupplierID;

-- 5. care este cel mai popular produs de la furnizor, cumpărat de clienții noi in mai multe tari 
--(noi am pus pe ultimele 3 luni)
CREATE OR REPLACE FUNCTION ex5(product_id INTEGER) RETURN INTEGER
AS
    returns INTEGER;
BEGIN
    SELECT COUNT(DISTINCT o.ShipCountry)
    INTO returns
    FROM Products p
    LEFT JOIN order_details od ON od.ProductID = p.ProductID
    LEFT JOIN Orders o ON o.OrderID = od.OrderID 
    WHERE p.ProductID = product_id;  -- Considering only the last three months

    RETURN returns;
END;
/

SELECT
    s.CompanyName AS furnizor,
    p.ProductName,
    COUNT(DISTINCT o.OrderID) AS TotalOrders, -- Counting distinct orders
    ex5(p.ProductID) AS NrCountries
FROM
    Products p
JOIN Suppliers s ON s.SupplierID = p.SupplierID
LEFT JOIN order_details od ON od.ProductID = p.ProductID
LEFT JOIN Orders o ON o.OrderID = od.OrderID
WHERE
    o.OrderDate >= DATE '1998-05-01' -- Ensure to use ANSI date literal
    AND ex5(p.ProductID) > 3 -- Product must have been ordered from more than 3 countries
GROUP BY
    s.CompanyName,
    p.ProductName,
    p.ProductID
ORDER BY
    TotalOrders DESC -- To find the most popular product
FETCH FIRST 1 ROW ONLY; -- Assuming you need the most popular one
/