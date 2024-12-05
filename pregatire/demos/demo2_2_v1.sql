/*
2_12_2_v1m
NR 2
Pentru fiecare angajat, afiseaza:

- (0.75p) ultimul ciclu de studii absolvit, astfel:
  - daca "BA", "BS" sau "BSC se regasesc pe Employees.Notes, se va afisa "Licenta"
  - daca "MA", "MBA" se regasesc pe Employees.Notes, se va afisa "Master
  - daca "Ph.D" se regaseste pe Employees.Notes, se va afisa "Doctorat"
  - altfel, va afisa "Lipsa informatii"
- (0.25p) daca regaseste mai mult de o diploma, o vom afisa doar pe cea superioara.
  ex. Daca regasim si "BA" si "MA", vom afisa doar "Master"
- (2p) care este cel mai mare discount in bani acordat pe o comanda (pretul unei comenzi se calculeaza ca Order_Details.UnitPrice * Order_Details.Quantity, dupa care aplica se discountul; ATENTIE: relatia dintre Orders si Order_Details este "one to many")
- (3p) diferenta absoluta maxima dintre numarul total de produse. (Order_Details.Quantity) ale aceluiasi supplier vandute intr-o luna vs luna precededenta in care a mai fost vandut (ex. in iunie 1988 au fost vandute 50 de produse ale supplier 1, in iulie 1988 au fost vandute 60 de produse ale supplier 1, deci diferenta este de 10 produse; in august 1988 nu au fost vandute produse ale supplier 1, iar in septembrie 1988 au fost vandute doar 5 produse ale supplier 1, deci diferenta este 55 produse; diferenta maxima este 55). Data la care sunt vandute comenzile este Orders.ShippedDate.
- (4p) bonusul de performanta, care se calculeaza astfel:
  - (1p) daca angajatul a vandut macar 3 produse care se afla in "stoc suficient. (Products.UnitsInStock > media valorilor Products.UnitsInStock pentru toate produsele aflate in colaborare activa (Products.Discontinued = 0)) primeste cate 60 RON per produs;
  - (1p) daca angajatul are nivelul ierarhic 2 (are macar un manager in subordine, care la randul lui are angajati in subordine; managerii apa, coloana Ernployees.ReportsTo) primeste 1000 RON;
    -(1.5p) daca este in top 30% angajati de acelasi gen "rapizi. (clasifi.re pe gen (Mr./Mrs.) in functie de valoarea medie a duratei de livrare (numarul de zilei dintre Orders.ShippedDate si Orders.OrderDate) primeste 1100 RON;
  - altfel, nu primeste;
  - (1p) Afisati rezultatele sub forma unui singur tabel.
  */
  -- faci functii care primesc ca argument employee_id
  -- 1.
  -- prelucare pe stringuri =))
  -- traiasca stack overflow

select distinct notes from employees;

create or replace function f1(id integer)
return varchar
AS
returns varchar(20);
ceva varchar(2000);
BEGIN
    select e.notes into ceva from employees e where e.EMPLOYEEID = id;
    SELECT
    CASE 
        WHEN (
            ceva LIKE '%BA%MA%' OR ceva LIKE '%BS%MA%' OR ceva LIKE '%BSC%MA%' OR 
            ceva LIKE '%BA%MBA%' OR ceva LIKE '%BS%MBA%' OR ceva LIKE '%BSC%MBA%'
        ) THEN 'Master'
        WHEN (
            ceva LIKE '%BA%Ph.D%' OR ceva LIKE '%BS%Ph.D%' OR ceva LIKE '%BSC%Ph.D%' OR 
            ceva LIKE '%MA%Ph.D%' OR ceva LIKE '%MBA%Ph.D%' OR ceva LIKE '%BA%MA%Ph.D%' OR 
            ceva LIKE '%BS%MA%Ph.D%' OR ceva LIKE '%BSC%MA%Ph.D%' OR ceva LIKE '%BA%MBA%Ph.D%' OR 
            ceva LIKE '%BS%MBA%Ph.D%' OR ceva LIKE '%BSC%MBA%Ph.D%'
        ) THEN 'Doctorat'
        -- ideea e ca pe mai multe seturi de date 
        -- nu ai de unde sa stii cate si in ce format or sa vina. 
        -- trendul vad ca da cronologic sau direct ultima facuta-ish
        -- incercam sa facem cat mai complet, desi pare sa fie irelevant
        -- le-am luat pe combinari, acum le iau pe bucatele
        WHEN (
            (ceva LIKE '%BA%' OR ceva LIKE '%BS%' OR ceva LIKE '%BSC%') AND
            ceva NOT LIKE '%MA%' AND ceva NOT LIKE '%MBA%' AND
            ceva NOT LIKE '%Ph.D%'
        ) THEN 'Licenta'
        WHEN (
            (ceva LIKE '%MA%' OR ceva LIKE '%MBA%') AND
            ceva NOT LIKE '%BA%' AND ceva NOT LIKE '%BS%' AND ceva NOT LIKE '%BSC%' AND
            ceva NOT LIKE '%Ph.D%'
        ) THEN 'Master'
        WHEN (
            ceva LIKE '%Ph.D%' AND
            ceva NOT LIKE '%BA%' AND ceva NOT LIKE '%BS%' AND ceva NOT LIKE '%BSC%' AND
            ceva NOT LIKE '%MA%' AND ceva NOT LIKE '%MBA%'
        ) THEN 'Doctorat'
        ELSE 'Lipsa informatii'
    END
    INTO returns
    FROM employees e
    WHERE e.EMPLOYEEID = id;
    return returns;
end;
/

select 
    e.FIRSTNAME||' '||e.LASTNAME as nume
    , f1(e.EMPLOYEEID) as last_absolv
from employees e;
/
-- dupa lupte seculare am fcaut si asta
-- like-ul existentei...
-- macar acum avem o idee despre cum sa prelucram stringri in sql =))

-- 2. care este cel mai mare discount *IN BANI* acordat pe o comanda 
-- (pretul unei comenzi se calculeaza ca 
-- Order_Details.UnitPrice * Order_Details.Quantity, dupa care aplica se discountul;
-- ATENTIE: relatia dintre Orders si Order_Details este "one to many")
create or replace function f2(id integer)
return varchar
AS
returns varchar(20);
BEGIN
    SELECT
    od.UnitPrice * od.Quantity * od.discount as disc
    INTO returns
    FROM orders o
    join ORDER_DETAILS od on od.ORDERID = o.ORDERID
    join EMPLOYEES e on e.EMPLOYEEID = o.EMPLOYEEID
    WHERE e.EMPLOYEEID = id
    order by od.DISCOUNT desc
    fetch first 1 row only;
    return returns;
end;
/
select 
    e.FIRSTNAME||' '||e.LASTNAME as nume
    , nvl(f2(e.EMPLOYEEID), ' - ') as max_disc
from employees e;
/

-- 3. diferenta absoluta maxima dintre numarul total de produse. 
-- (Order_Details.Quantity) ale aceluiasi supplier vandute 
-- intr-o luna vs luna precededenta in care a mai fost vandut
-- (ex. in iunie 1988 au fost vandute 50 de produse ale supplier 1, in iulie 1988 au fost vandute 60 de produse ale supplier 1, deci diferenta este de 10 produse; in august 1988 nu au fost vandute produse ale supplier 1, iar in septembrie 1988 au fost vandute doar 5 produse ale supplier 1, deci diferenta este 55 produse; diferenta maxima este 55). Data la care sunt vandute comenzile este Orders.ShippedDate.
-- numarul total de produse -> sum de quantity (nu degeaba zice de quantity)
-- group by supplier
-- luna e si ea data ca param aparent =))
-- absolut adica abs adica modul
CREATE OR REPLACE FUNCTION f3(id INTEGER, luna DATE)
RETURN VARCHAR2 AS
    returns varchar(2000);
    curr INTEGER := 0;  
    prec INTEGER := 0;  
    diff INTEGER;
BEGIN
    -- luna curr(ent)
    SELECT SUM(od.quantity)
    INTO curr
    FROM order_details od
    JOIN orders o ON od.ORDERID = o.ORDERID
    JOIN products p ON p.PRODUCTID = od.PRODUCTID
    WHERE o.employeeid = id
      AND TRUNC(o.ShippedDate, 'MM') = TRUNC(luna, 'MM')
    GROUP BY p.SUPPLIERID;

    -- Calculate the total products sold in the previous month
    SELECT SUM(od.quantity)
    INTO prec
    FROM order_details od
    JOIN orders o ON od.ORDERID = o.ORDERID
    JOIN products p ON p.PRODUCTID = od.PRODUCTID
    WHERE o.employeeid = id
      AND TRUNC(o.ShippedDate, 'MM') = ADD_MONTHS(TRUNC(luna, 'MM'), -1)
    GROUP BY p.SUPPLIERID;

    -- Calculate the absolute difference
    diff := ABS(curr - prec);

    -- Convert difference to varchar to return
    RETURN TO_CHAR(diff);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN '0';  -- Return '0' if no records found
    WHEN OTHERS THEN
        RETURN 'Error';  -- Return 'Error' on any other exceptions
END;
/

select 
    e.FIRSTNAME||' '||e.LASTNAME as nume
    , nvl(f3(e.EMPLOYEEID, TO_DATE('1988-06-01', 'YYYY-MM--DD')), ' - ') as max_disc
from employees e;
/