-- 27_11_1
-- NR 1.
-- Pentru fiecare supplier vrem sa aflam:
-- 1. Orașul cu cele mai multe comenzi (1p)
-- 2. Cea mai veche comanda (OrderID & data) (1p)
-- 3. Produsele (ProductName) cu pretul peste media preturilor tuturor produselor din baza de date. (2p)
-- 4. Daca furnizorul (supplier-ul) a livrat produse in cel putin 10 regiuni distincte. Afisati "Da" sau "Nu".(2p)
-- 5. Categoria de produse (CategoryName) care este cea mai vanduta (Quantity * UnitPrice) in peste 50 % din tari si cel mai vandut produs asociat acestei categorii (3p)
-- Afisati rezultatele sub forma unui singur tabel. (1p)

-- 1. Orașul cu cele mai multe comenzi (1p)
create or replace function f1(supplier_idd int)
return varchar
as
returns varchar(100);
begin
    select
        o.shipcity
    into
        returns
    from products p
    join order_details od on p.productid = od.productid
    join orders o on od.orderid = o.orderid
    where p.supplierid = supplier_idd
    group by o.shipcity
    order by count(o.orderid) desc
    fetch first 1 row only;

    return returns;
end;
/

select 
    s.companyname as furnizor, 
    nvl(f1(s.supplierid), '-') as cmvp
from suppliers s;
/

-- 2. Cea mai veche comanda (OrderID & data) (1p)
-- chiar daca zice supplier, luam pe produs... ca noi facem functie ce numara sau face alte chestii pe un produs
-- still, de ce pe produs cand poti face pe ceva total altceva?
-- in fine...
create or replace function f2(supplier_idd integer)
return varchar as
returns varchar(200);
begin
    select
        to_char(o.orderdate)
    into returns
    from products p
    join order_details od on p.productid = od.productid
    join orders o on od.orderid = o.orderid
    where p.supplierid = supplier_idd -- ok, dar daca eu vedeam direct pe supplier?
    order by o.orderdate
    fetch first 1 row only;
    return returns;
end;
/

select 
    s.companyname as furnizor, 
    nvl(f2(s.supplierid), '-') as cmvc
from suppliers s;
/

-- 3. Produsele (ProductName) cu pretul peste media preturilor tuturor produselor din baza de date. (2p)
-- daca intreaba cineva, exista internet. doar e openbook, asa-i?
-- listagg si ai un grup de ce ai in listagg, ordonat eventual =))
CREATE OR REPLACE FUNCTION f3(supplier_idd INTEGER)
RETURN VARCHAR2 AS
    returns VARCHAR2(2000);  
BEGIN
    SELECT LISTAGG(p.productname, ', ') WITHIN GROUP (ORDER BY p.productname)
    INTO returns
    FROM products p
    WHERE p.supplierid = supplier_idd
      AND p.unitprice > (SELECT AVG(unitprice) FROM products);
    
    RETURN returns;
END;
/

select 
    s.companyname as supplier,
    nvl(f3(s.supplierid), '-') as pppmptp
from suppliers s;
/

-- 4. Daca furnizorul (supplier-ul) a livrat produse in cel putin 10 regiuni distincte. Afisati "Da" sau "Nu".(2p)
create or replace function f4(supplier_idd integer)
return varchar as
returns varchar(10);
begin 
    select
        case 
            when count(distinct o.shipregion) >=10 then 'Da'
            else 'Nu'
        end into returns
    from orders o
    join order_details od on o.OrderID = od.OrderID
    join Products p on od.ProductID = p.ProductID
    where p.supplierid = supplier_idd;
    return returns;
end;
/

select 
    s.companyname as furnizor,
    nvl(f4(s.supplierid), '-') as livrare_buna
from suppliers s;
/

-- 5. Categoria de produse (CategoryName) care este cea mai vanduta (Quantity * UnitPrice) in peste 50 % din tari 
-- si cel mai vandut produs asociat acestei categorii (3p)
-- de obicei primul spec e gen de unde se face from =))
create or replace function f5(supplier_idd integer)
return varchar
as
    returns varchar(2000);
begin 
    select 
        c.CategoryName||' - '||p.ProductName
    into returns
    from categories c
    join products p on p.CategoryID = c.CategoryID
    join order_details od on od.ProductID = p.ProductID 
    join Orders o on o.OrderID = od.OrderID
    where p.supplierid = supplier_idd
    group by c.CategoryName, p.ProductName
    having count(distinct o.shipcountry) > (
        select count(distinct shipcountry) / 2.0 
        from orders
    )
    order by sum(od.quantity * od.unitprice) desc
    fetch first 1 row only;
    return returns;
end;
/

select 
    s.companyname as furnizor,
    nvl(f5(s.supplierid), '-') as cmvcat
from suppliers s;
/

-- Afisati rezultatele sub forma unui singur tabel. (1p)
select 
    s.companyname as furnizor, 
    nvl(f1(s.supplierid), '-') as oras,
    nvl(f2(s.supplierid), '-') as prima_comanda,
    nvl(f3(s.supplierid), '-') as produse_peste_medie,
    nvl(f4(s.supplierid), '-') as livrare_buna,
    nvl(f5(s.supplierid), '-') as top_categorie_produs
from suppliers s;
/
