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
-- trandul cere cu functii
create or replace function f1(supplier_id int)
return varchar2 as
    returns verchar2(100);
begin
    select
        o.shipcity
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
        o.shipcity
    order by
        count(o.orderid) desc;
    return returns;
end;
/
