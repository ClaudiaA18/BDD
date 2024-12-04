/*
Select P.ProductName--, Count(*) NumSales
FROM Products P
INNER JOIN Order_Details OD ON P.ProductId = OD.ProductId
Group by P.ProductId, P.ProductName
Order by Count(*) desc
Fetch first 1 row only
*/
-- 1. care este cel mai popular produs? (apare in cat mai multe comenzi)
-- 2. care sunt produsele care in general sunt vandute sau in cantitati mari sau impreuna cu un alt produs din categoria lor? (1p)
-- (cantitate mare = din toare cantit posibile vandute din order_details) sa fie in top 10% (daca cantitea vanduta e 1000, sa fim in 900+) (2p)
-- 3. care este produsul care are cele mai mari sanse sa apara in urmatoarea comanda:
--  - avem stoc suficient relativ la comenzile care s-au dat (facem mediana cantitatii din comenzi si vedem daca avem in stoc) (stocul e in products, order_details vedem)
--  - este unul din cele mai bine vandute produse (vedem cea mai mare cantitate de prod vanduste si vedem dk e in top 10) (3o)
--  - are un pret atractiv (pretul este in jurul mediei, cu o abatere de 25%)

use Northwind;

-- 1. care este cel mai popular produs? (apare in cat mai multe comenzi)
select top 1 
    p.productname, 
    count(od.productid) as num_sales
from products p
inner join [order details] od 
    on p.productid = od.productid
group by p.productname
order by num_sales desc;

-- 2. care sunt produsele care in general sunt vandute sau in cantitati mari sau impreuna cu un alt produs din categoria lor? (1p)
-- (cantitate mare = din toare cantit posibile vandute din order_details) sa fie in top 10% (daca cantitea vanduta e 1000, sa fim in 900+) (2p)

-- Produse vândute în cantități mari (Top 10% după cantitate)
with total_quantities as (
    select 
        od.productid, 
        sum(od.quantity) as total_sold
    from [order details] od
    group by od.productid
),
threshold as (
    select max(total_sold) * 0.9 as min_high_quantity 
    from total_quantities
)
select 
    p.productname
from products p
inner join total_quantities tq 
    on p.productid = tq.productid
cross join threshold
where tq.total_sold >= threshold.min_high_quantity;


-- Produse vândute împreună din aceeași categorie
with order_product as (
    select 
        p.productname, 
        p.categoryid, 
        od.orderid
    from products p
    inner join [order details] od 
        on p.productid = od.productid
)
select distinct 
    p1.productname
from order_product p1
inner join order_product p2 
    on p1.orderid = p2.orderid 
    and p1.categoryid = p2.categoryid 
    and p1.productname <> p2.productname;

-- 3. care este produsul care are cele mai mari sanse sa apara in urmatoarea comanda:
--  - avem stoc suficient relativ la comenzile care s-au dat (facem mediana cantitatii din comenzi si vedem daca avem in stoc) (stocul e in products, order_details vedem)
--  - este unul din cele mai bine vandute produse (vedem cea mai mare cantitate de prod vanduste si vedem dk e in top 10) (3o)
--  - are un pret atractiv (pretul este in jurul mediei, cu o abatere de 25%)

-- 1. Determinarea medianei cantităților comandate
with product_quantities as (
    select 
        od.productid,
        od.quantity
    from [order details] od
),
stock_sufficient as (
    select 
        p.productid
    from products p
    join (
        select 
            pq.productid,
            avg(pq.quantity) as median_quantity
        from product_quantities pq
        group by pq.productid
    ) as mq on p.productid = mq.productid
    where p.unitsinstock >= mq.median_quantity
),

-- 2. Determinarea produselor cel mai bine vândute (top 10 produse)
best_selling as (
    select 
        top 10 od.productid
    from [order details] od
    group by od.productid
    order by sum(od.quantity) desc
),

-- 3. Determinarea produselor cu preț atractiv
price_attractive as (
    select 
        p.productid
    from products p
    cross join (
        select avg(p.unitprice) as avg_price
        from products p
    ) as ap
    where p.unitprice between ap.avg_price * 0.75 and ap.avg_price * 1.25
)

-- Combinarea criteriilor
select 
    p.productname,
    p.unitsinstock as stock,
    (select sum(od.quantity) from [order details] od where od.productid = p.productid) as total_sold,
    p.unitprice as price
from products p
where p.productid in (select productid from stock_sufficient)
  and p.productid in (select productid from best_selling)
  and p.productid in (select productid from price_attractive)
order by total_sold desc, price;

