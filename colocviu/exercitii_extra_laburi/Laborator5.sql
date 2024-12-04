-- Laboratorul 5
/*Sa se gaseasca tarile care au unul sau mai multi din urmatorii factori de risc si sa se listeze numele factorilor de risc:
    - Factor de risc 1 -> managerul are angajati din alt departament decat cel in care este el (afisati numele managerilor)
    - Factor de risc 2 -> managerii au un range salarial de cel putin doua ori mai mare decat oricare din rangeurile salariale ale celor de sub ei ()
    - Factor de risc 3 -> in acea tara se gaseste cel putin un angajat care nu are o functie compatibila sau cu managerul lui direct sau cu managerul de departamentul de care tine (niste tampneii, tbh)
Header afisare: nume tara + factor de risc 1 + factor de risc 2 + factor de risc 3
*/

SET serveroutput ON;
-- cum poti ajunge de la employees la tari dar sa iei manager? =))
-- risk 3
SELECT
    c.country_name as tara
    , e.FIRST_NAME||' '||e.last_name as name
from
    employees e
join
    employees m
on
    e.manager_Id = m.employee_id
join
    departments d
on
    d.department_id = e.EMPLOYEE_ID
join
    locations l
on
    l.location_id = d.location_id
JOIN
    countries c
on
    c.COUNTRY_ID = l.COUNTRY_ID
WHERE
    e.job_id not in
    (
        -- cred ca aasta e rsik3 ca vrea sa fie joburi incompatibile
        select
            sq.job_id
        from
            employees sq
        where
            sq.manager_id = d.MANAGER_ID
        -- deci tu iei de aici job manager dep si vrei ca ang sa nu aiba acel job gen =))
    )
group by c.country_name, e.FIRST_NAME||' '||e.last_name;

-- risk2
SELECT
    c.country_name as tara
    , e.FIRST_NAME||' '||e.last_name as name
from
    employees e
join
    employees m
on
    e.manager_Id = m.employee_id
join
    departments d
on
    d.department_id = e.EMPLOYEE_ID
join
    locations l
on
    l.location_id = d.location_id
JOIN
    countries c
on
    c.COUNTRY_ID = l.COUNTRY_ID
WHERE
   m.salary >= 2 * (
    select
        max(salary)
    from
        employees sq
    where
        sq.manager_id = m.employee_id
   )
group by c.country_name, e.FIRST_NAME||' '||e.last_name;

-- risk1
SELECT
    c.country_name as tara
    , e.FIRST_NAME||' '||e.last_name as name
from
    employees e
join
    employees m
on
    e.manager_Id = m.employee_id
join
    departments d
on
    d.department_id = e.EMPLOYEE_ID
join
    locations l
on
    l.location_id = d.location_id
JOIN
    countries c
on
    c.COUNTRY_ID = l.COUNTRY_ID
WHERE
-- care are manager din alt departament
    e.manager_id not in 
    (
        select
            sq.manager_id
        from
            DEPARTMENTS sq
        where
            sq.department_id = e.DEPARTMENT_ID
    )
group by c.country_name, e.FIRST_NAME||' '||e.last_name;