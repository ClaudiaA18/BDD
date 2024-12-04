-- 26_11_2
/*
Pentru fiecare tara afișați:

1.⁠ ⁠(1p)Categoria cu cele mai mari vânzări(CategoryName).

2.⁠ ⁠(2p)Daca este tara target afișați “target”, altfel afișați “normal” ( o tara este target daca valoarea totală a comenzilor OrderDetails.Quantity * OrderDetails.UnitPrice) depășește media valorii comenzilor pe toate țările) 

3.⁠ ⁠(2p)Furnizorii care au livrat produse discontinue (Products.Discontinued = 1) din cel puțin 2 categorii diferite. 

4.⁠ ⁠(2p)Daca valoarea totală a comenzilor depășește cu cel puțin 20% valoarea medie globală a comenzilor. ( “da” sau “nu”) 

5.⁠ ⁠(3p)Cea mai profitabila locație de livrare (ShipCity orasul care a produs cel mai mulți bani, dar ia in considerare doar orașele in care au fost cel puțin 20 de livrări). O locație este profitabila doar daca are concurenta ( in tara respectivă exista cel puțin 2 orașe in care se fac livrări)
*/

-- 1. cele mai mari vanzari = min unitsonstock
with tara as (
    select
        o.SHIPCOUNTRY as taraa
        , cat.CATEGORYNAME as categorie
        , min(p.UNITSINSTOCK) as cate
    from
        orders o
    JOIN
        order_details od
    ON
        od.orderid = o.orderid
    join
        products p
    ON
        p.productid = od.productid
    join
        categories cat
    ON
        cat.CategoryID = p.CategoryID
    group by
        o.SHIPCOUNTRY
        , cat.CATEGORYNAME
    order by min(p.UNITSINSTOCK)
    ) 
select
    main.taraa
    , main.categorie
from
    tara main
where
    main.cate = (
        select
            min(sq.cate)
        FROM
            tara sq
    );

-- 2. sum(order_details.quantity * order_details.unitprice) 
-- > avg(valorilor comenzilor pe toate tarile) adica medie totala
       
with ceva as (
    select
        o.SHIPCOUNTRY as tara
        , sum(od.QUANTITY * od.UNITPRICE) as valoare_vanduta
    from
        orders o
    JOIN
        order_details od
    ON
        od.orderid = o.orderid
    join
        products p
    ON
        p.productid = od.productid
    join
        categories cat
    ON
        cat.CategoryID = p.CategoryID
    group by
        o.SHIPCOUNTRY
    order by 1
) select main.tara, 
CASE
  WHEN  valoare_vanduta > (select avg(sq.valoare_vanduta) from ceva sq) THEN 'target'
  ELSE 'normal'
END as tip
from ceva main;

-- 3. furnizori care au livrat produse discontinue din cel putin 2 categorii diferite
with altceva as (
    select
        o.SHIPCOUNTRY as tara
        , s.COMPANYNAME as furnizor
        , count(*) as cate
    from
        orders o
    JOIN
        order_details od
    ON
        od.orderid = o.orderid
    join
        products p
    ON
        p.productid = od.productid
    join
        categories cat
    ON
        cat.CategoryID = p.CategoryID
    join
        SUPPLIERS s
    on
        s.SUPPLIERID = p.SUPPLIERID
    where
        p.DISCONTINUED = 1
    group by
        o.SHIPCOUNTRY
        , cat.CATEGORYNAME
        , s.COMPANYNAME
    ) 
select
    main.tara
    , main.furnizor
from
    altceva main
where
    main.cate > 2;

-- 4. valoarea totala a comenzilor depaseste cu 0.2 valoarea medie produse de peste tot
with ceva as (
    select
        o.SHIPCOUNTRY as tara
        , sum(od.QUANTITY * od.UNITPRICE) as valoare_vanduta
    from
        orders o
    JOIN
        order_details od
    ON
        od.orderid = o.orderid
    join
        products p
    ON
        p.productid = od.productid
    join
        categories cat
    ON
        cat.CategoryID = p.CategoryID
    group by
        o.SHIPCOUNTRY
    order by 1
) select main.tara, 
CASE
  WHEN  valoare_vanduta > 1.2 * (
    select
        avg(od.QUANTITY * od.UNITPRICE) as valoare_medie
    from
        orders o
    JOIN
        order_details od
    ON
        od.orderid = o.orderid
    join
        products p
    ON
        p.productid = od.productid
    join
        categories cat
    ON
        cat.CategoryID = p.CategoryID
        ) THEN 'da'
  ELSE 'nu'
END as tip
from ceva main;
-- depaseste cu 0.2, adica ai 1 + 0.2 => 1.2 asta e logica mea, acum sper sa fie ok;

-- - 5. cea mai profitabila locatie de livrare 
-- (orasul cu cei mai multi bani dar orasele cu cel outin 20 livrari). 
-- o locatie este profitabila doar daca are concurenta, adica daca in tara 
-- in care se fac livrari, exista cel putin 2 orase in care se fac livrari.
-- if count(orase) >= 2 , max(sum(od.QUANTITY * od.UNITPRICE)), count(*) > 20

WITH cv AS (
    SELECT
        o.SHIPCOUNTRY AS tara,
        o.SHIPCITY AS oras,
        SUM(od.QUANTITY * od.UNITPRICE) AS valoare_vanduta
    FROM
        orders o
    JOIN
        order_details od ON od.orderid = o.orderid
    JOIN
        products p ON p.productid = od.productid
    GROUP BY
        o.SHIPCOUNTRY,
        o.SHIPCITY
), 
livrari AS (
    SELECT
        o.SHIPCOUNTRY AS tara,
        o.SHIPCITY AS oras,
        COUNT(*) AS cate
    FROM
        orders o
    GROUP BY
        o.SHIPCOUNTRY,
        o.SHIPCITY
),
cate AS (
    SELECT
        tara,
        COUNT(DISTINCT oras) AS orase_in_tara
    FROM
        livrari
    GROUP BY
        tara
),
orase AS (
    SELECT
        cv.tara,
        cv.oras,
        cv.valoare_vanduta
    FROM
        cv
    JOIN
        livrari ON cv.tara = livrari.tara AND cv.oras = livrari.oras
    WHERE
        livrari.cate >= 20
),
profit AS (
    SELECT
        tara,
        MAX(valoare_vanduta) AS max_valoare_vanduta
    FROM
        orase
    GROUP BY
        tara
)
SELECT
    o.tara,
    o.oras,
    o.valoare_vanduta AS valoare_vanduta_maxima
FROM
    orase o
JOIN
    profit p ON o.tara = p.tara AND o.valoare_vanduta = p.max_valoare_vanduta
JOIN
    cate c ON o.tara = c.tara
WHERE
    c.orase_in_tara >= 2
ORDER BY
    o.valoare_vanduta DESC;