-- 26_11_2
-- Pentru fiecare tara, afisati
-- - 1. categoria cu cele mai mari vanzari (CatgoryName)
-- - 2. daca este tara target afisati "target", altfel "normal" 
-- (target = valoarea totala a comenzilor order_details.quantity * order_details.unitprice > avg(val comanda toate tari))
-- - 3. furnizorii care au livrat produse discontinue (products.discontinued=1) din cel putin 2 categorii diferite
-- - 4. daca valoarea totala a comenzilor depaseste cu cel putin 0.2* valoare medie globala a produselor
-- - 5. cea mai profitabila locatie de livrare (orasul cu cei mai multi bani dar orasele cu cel outin 20 livrari). 
-- o locatie este profitabila diar daca are concurenta daca in tara in care se fac livrari
-- exista cel putin 2 orase in care se fac livrari.

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

-- 2. sum(order_details.quantity * order_details.unitprice) > avg(valorilor comenzilor pe toate tarile) aka medie tot
       
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

-- depaseste cu 0.2 gen ai 1 + 0.2 => 1.2 asta e logica mea;
-- daca nu e asa, ramai sanatos ca mathe left the chat de mult =)))
-- 3:19
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