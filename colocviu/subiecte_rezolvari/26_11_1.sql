-- Colocviu 1
/*
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

-- 1. max(count(product_id)) din order =))
-- cu cte-uri!
-- pentru nu stiu ce -> from acel nu stiu ce 
WITH ceva as (
    select
        s.companyname as cname
        , p.productname as pname
        , COUNT(*) as cnt
    from
        suppliers s
    join
        products p
    ON
        p.supplierid = s.supplierid
        -- nu vede aliasuri!!!
    group by
        s.COMPANYNAME
        , p.PRODUCTNAME
) select
    main.cname
    , main.pname
    , main.cnt
from
    ceva main
-- vrei produsul cu maxim pe furnizor
where main.cnt = (
    select
        max(sq.cnt)
    from
        ceva sq
    where main.cname = sq.cname
    ); -- aici afli maximul pe furnizor

-- 2. daca furnizorul este "relevant" sau "marginal" 
-- (relevant = valoarea totala a produselor livrate (ce am facut mai jos) depaseste 
-- marginea globala a vanzarilor pe furnizor) > val_tot ce a ramas in stoc (2p)
-- produsul cu valoarea totala maxima pe furnizor
-- dar noi vrem furnizor relevant
-- ai orders cu orderid, order_details cu order_id si productid si quantity si unitprice 
-- si gen faci quantity * unitprice pentru fiecare produs al furnizorului si gen sum de prod asta > max sum_prod pe furnizor si faci select de 2 ori pe acelasi cte
declare
    val_tot2 number := 0;
    val_tot1 number := 0;
    nume_furniz varchar2(100);
begin
    for furnizor in (
    select
        sum(od.UNITPRICE * od.quantity) as val_tot_vandut_furnizor
        , s.SUPPLIERID as sid
    from 
        suppliers s
    join
        products p
    on
        p.supplierid = s.supplierid
    join
        order_details od
    on
        od.productid = p.productid
    group by
        s.supplierid
    ) loop
        val_tot1 := furnizor.val_tot_vandut_furnizor;
        select
            sum(psq.UNITPRICE * psq.UNITSINSTOCK) as val_tot_ramas_furnizor
        into
            val_tot2
        from 
            suppliers ssq
        join
            products psq
        on
            psq.supplierid = ssq.supplierid
        join
            order_details odsq
        on
            odsq.productid = psq.productid
        where
            ssq.supplierid = furnizor.sid
        group by
            ssq.supplierid;
        select
                ssq2.companyname
            into
                nume_furniz
            from
                suppliers ssq2
            where
                ssq2.supplierid = furnizor.sid;
        if val_tot2 < val_tot1 then
            DBMS_OUTPUT.PUT_LINE(nume_furniz||' - relevant');
        else
            DBMS_OUTPUT.PUT_LINE(nume_furniz||' - marginal');
        end if;
    end loop;
end;
/

-- 3. produsul cel mai bine vandut pentru fiecare furnizor, 
-- dar doar daca produsul a fost comandat in cel putin 20 de locatii distincte (2p)
-- numara ptr fiecare produs city
-- asemanator cu 1, doar ca ai o conditie in plus
create or replace function func(product_id integer)
return integer
is
    returns integer;
BEGIN
    select
        count(distinct o.shipcity)
    into
        returns
    from
        products p
    join
        order_details od
    on
        od.productid = p.productid
    join
        orders o
    on
        o.orderid = od.orderid
    where
        p.productid = product_id;

    return returns;
end func;
/
WITH altceva as (
    select
        s.companyname as cname
        , p.productname as pname
        , COUNT(*) as cnt
    from
        suppliers s
    join
        products p
    ON
        p.supplierid = s.supplierid
    group by
        s.COMPANYNAME
        , p.PRODUCTNAME
)
select
    main.cname
    , main.pname
from
    altceva main
where main.cnt = (
    select
        max(sq.cnt)
    from
        altceva sq
    where main.cname = sq.cname
    )
    and func(
        (
            select
                pp.PRODUCTID
            from
                products pp
            where
                pp.PRODUCTNAME = main.pname
            )
    ) = 20; 

-- 4. daca furnizorul a livrat produse catre cel putin 5 categorii distincte (2p)
-- functie ce numara categoriile
create or replace function f(supplier_id number)
    return integer
is
    returns integer;
BEGIN
    select
        COUNT(*)
    into
        returns
    from
        CATEGORIES c
    join
        PRODUCTS p
    on
        p.CATEGORYID = c.CATEGORYID
    where
        p.SUPPLIERID = supplier_id;
    return returns;
end f;
/
-- iif este if pe select
-- iif(conditie, true, false)
DECLARE
    ok varchar(3);
begin
    for sup in 
    (
        select
            s.COMPANYNAME as nume
            ,s.supplierid as sid
        FROM
            suppliers s
    ) loop
        if  f(sup.sid) >= 5 THEN
            ok := 'da';
        else 
            ok := 'nu';
        end if;
        DBMS_OUTPUT.PUT_LINE(sup.nume||' '||ok);
        end loop;
end;
/

-- 5. care este cel mai popular produs de la furnizor (asta e 1), 
-- cumparat de clientii noi in mai multe tari (3p)
WITH ceva as (
    select
        s.companyname as cname
        , p.productname as pname
        , COUNT(*) as cnt
    from
        suppliers s
    join
        products p
    ON
        p.supplierid = s.supplierid
    group by
        s.COMPANYNAME
        , p.PRODUCTNAME
) select
    main.cname
    , main.pname
    , main.cnt
from
    ceva main
where main.cnt = (
    select
        max(sq.cnt)
    from
        ceva sq
    where main.cname = sq.cname
    and  (
        select
        count(count(*)) as countt
        from
            suppliers s
        join
            products p
        on
            p.SUPPLIERID = s.SUPPLIERID
        join
            ORDER_DETAILS od
        on
            od.PRODUCTID = p.PRODUCTID
        join
            orders o
        on 
            o.ORDERID = od.ORDERID
        where
            upper(p.PRODUCTNAME) = upper(main.pname)
        group by
            o.SHIPCOUNTRY
    ) > 1
    ); 

