-- 1
create or replace function f1(tara VARCHAR)
return integer
as
returns integer;
year integer;
BEGIN
    select count(*)
    into returns
    from orders o
    -- nu ne mai complicam, luam direct
    where o.ShipAddress <> 
    (select csq.address from customers csq where csq.CUSTOMERID = o.CUSTOMERID)
    -- la alta adresa
    and EXTRACT(YEAR FROM (o.orderdate)) = 
    ( 
        -- in anul curent (ultima comanda si de acolo vezi anul)
        select EXTRACT(YEAR FROM (osq.orderdate))
        from orders osq
        where osq.customerid = o.customerid
        order by o.orderdate desc
        fetch first 1 rows only
        )
        
        -- EXTRACT(YEAR FROM (sysdate))
    group by o.CUSTOMERID
    having count(distinct o.customerid) >= 1 -- macar o comanda
    order by count(*) desc
    fetch first 1 rows only
    ;
    return returns;
end;
/

select
o.ShipCountry as tara,
f1(o.ShipCountry) as cati
from
orders o
group by o.SHIPCOUNTRY;
/

-- 2
CREATE OR REPLACE FUNCTION f2(tara VARCHAR2)
RETURN SYS_REFCURSOR
AS
  v_cursor SYS_REFCURSOR;
BEGIN
  OPEN v_cursor FOR
    SELECT
        s.companyname as curier,
        COUNT(*) AS cati
    FROM shippers s
    JOIN orders o ON s.shipperid = o.shipvia 
    -- assuming shipvia links orders to shippers
    JOIN customers c ON c.customerid = o.customerid
    WHERE c.country = tara -- Use the tara parameter to filter by country
      AND ((o.shipcountry = c.country AND o.shipcity <> c.city AND o.shippeddate <= o.orderdate + 2)
       OR  (o.shipcountry = c.country AND o.shipregion = c.region AND o.shippeddate <= o.orderdate + 3)
       OR  (o.shipcountry = c.country AND o.shippeddate <= o.orderdate + 5))
    GROUP BY s.companyname
    ORDER BY cati DESC
    FETCH FIRST 3 ROWS ONLY;

  RETURN v_cursor;
END;
/

-- nu stiu cum sa testez asta, sorry, eu am mers pe logica
-- nu pot sa pun alea in tabel, le las asa...
DECLARE
  v_result SYS_REFCURSOR;
  v_curier VARCHAR2(100);
  v_cati NUMBER;
  v_country VARCHAR2(100);
  v_country_cursor SYS_REFCURSOR;
BEGIN
  -- Open a cursor to select distinct countries from the orders table
  OPEN v_country_cursor FOR
    SELECT DISTINCT shipcountry 
    FROM orders 
    WHERE shipcountry IS NOT NULL;

  -- Loop over each country found in the orders table
  LOOP
    FETCH v_country_cursor INTO v_country;
    EXIT WHEN v_country_cursor%NOTFOUND;

    -- Call the function f2 for the current country and retrieve the cursor
    v_result := f2(v_country);

    -- Output the country being processed
    DBMS_OUTPUT.PUT_LINE('Country: ' || v_country);

    -- Loop through the results from the function and print each shipper and delivery count
    LOOP
      FETCH v_result INTO v_curier, v_cati;
      EXIT WHEN v_result%NOTFOUND;
      DBMS_OUTPUT.PUT_LINE('  Courier: ' || v_curier || ', Deliveries: ' || v_cati);
    END LOOP;

    -- Close the cursor for the current function call to avoid leaks
    CLOSE v_result;
  END LOOP;

  -- Close the cursor that iterates through the countries
  CLOSE v_country_cursor;
END;
/
