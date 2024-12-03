-- Colocviu 1
-- nr 1
-- Analizati performatnetel furnizlorilor. Pentru fiecrae furnizor, afisati:
--  - 1. care e produsul cel mai vandut (1p)
--  - 2. daca furnizorul este "relevant" sau "marginal" 
-- (relevant = valoarea totala a produselor livrate depaseste marginea
-- globala a vanzarilor pe furnizor) (2p)
--  - 3. produsul cel mai bine vandut pentru fiecare furnizor, dar doar daca produsul a fost comandat in cel putin 20 de locatii distincte (2p)
--  - 4. daca furnizorul a livrat produse catre cel putin 5 categorii distincte (2p)
--  - 5. care este cel mai popular produs de la furnizor, cumparat de clientii noi in mai multe tari (3p)
-- 1. max(count(product_id)) din order =))
-- cu cte-uri!
-- pentru nuj ce -> from acel nuj ce 
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
-- vrei produsul cu maxim pe furnizor gen
where main.cnt = (
    select
        max(sq.cnt)
    from
        ceva sq
    where main.cname = sq.cname
    ); -- aici afli maximul pe furnizor

-- 2. daca furnizorul este "relevant" sau "marginal" 
-- asta e prea business pentru mine 
-- dar i guess asta o sa lucrez... :s
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

-- 3. asemanator cu 1, doar ca ai o conditie in plus
-- produsul cel mai bine vandut pentru fiecare furnizor, 
-- dar doar daca produsul a fost comandat in cel putin 20 de locatii distincte (2p)
-- numara ptr fiecare produs city
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
        -- nu vede aliasuri!!!
    group by
        s.COMPANYNAME
        , p.PRODUCTNAME
)
select
    main.cname
    , main.pname
from
    altceva main
-- vrei produsul cu maxim pe furnizor gen
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
    ) = 20; -- aici afli maximul pe furnizor


