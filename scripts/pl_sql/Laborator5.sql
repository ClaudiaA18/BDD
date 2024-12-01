-- Exercitiul 1
set verify off;
set serveroutput on;
declare
    procedure unu
as
    begin
        dbms_output.put_line('test');
    end unu;
begin
    unu();
end;
/

-- Exercitiul 2
--salariul maxim pentru un anumkit departament si o anumita functie, returnat ca o variabila scalara + traducere joburi in romana in interiorul procedurii

set serveroutput on;
declare
    numedep departments.department_name%type;
    iddep employees.department_id%type := &iddept;
    procedure salariu(
        id_dep in number,
        functie in out varchar2,
        salmaxim out number
    )
    is -- merge si as
        salmax number; -- imediat aici se fac declaratiile
    begin
        select
            max(salary)
        into
            salmax
        from
            employees
        where
            department_id = id_dep
        and
            lower(job_id) = lower(functie)
        group by
            department_id;
        salmaxim := salmax;
        -- sau inserat direct in variabila transmisa ca parametru 
        -- select max(salary) into salmaxim from employees where department_id = id_dep and lower(job_id) = lower(functie) group by department_id;
        functie := case
                    when (upper(functie) = 'FI_ACCOUNT') then 'contabil'
                    when (upper(functie) = 'IT_PROG') then 'programator'
                    when (upper(functie) like '%_CLERK') then 'functionar'
                    when (upper(functie) = 'AD_PRES') then 'presedinte'
                    when (upper(functie) like '%_MAN') then 'manager'
                    else 'nu exista'
                end;
    exception
        when no_data_found then
            dbms_output.put_line('nu exista');
    end;
begin
    declare
        functie varchar(40) := '&nume';
        salmax number;
    begin
        select
            department_name
        into
            numedep
        from
            departments
        where
            department_id = iddep;
        salariu(iddep, functie, salmax);
        -- sau, cu operatorul asociere =>
        -- salariu(iddept => iddep, salmaxim => salmax, functie => functie)
        -- salariu(iddep, salmaxim => salmax, functie => functie)
        -- salariu(iddep, functie, salmaxim => salmax)
        dbms_output.put_line('in departamentul '||numedep||' salariul maxim pentru functia '||functie||' este '||salmax);
    exception
        when no_data_found then
            dbms_output.put_line('nu exista');
    end;
end;
/


-- Exercitiul 3
-- calculati veniturile angajatilor cu o vechime de peste 10 ani in firma, dintr-un aumit departament
create or replace procedure ceva(iddep in number,
                                venit in out number,
                                dataref in date default sysdate)
is
    numedep departments.department_name%type;
begin
    select
        department_name
    into
        numedep
    from 
        departments
    where
        department_id = iddep;
    select
        sum(salary *(1 + nvl(commission_pct, 0)))
    into
        venit
    from
        employees
    where
        department_id = iddep
    and
        add_months(hire_date, 120) < dataref;
    dbms_output.put_line(rpad(numedep, 20) || rpad(venit, 20));
exception
    when no_data_found then
        venit := 0;
        dbms_output.put_line('nu exista');
end ceva;
/ -- de pus urgent, ca altfel da procedure created with compilation errors -> slash-ul existentei....
set verify off;
set serveroutput on;
declare
    dataref date := sysdate;
    venit number;
    total number := 0;
begin
    for i in (
        select
            distinct department_id
        from
            departments
        order by department_id
    ) loop
        venit := 0;  -- Inițializează venitul înainte de fiecare apel
        ceva(i.department_id, venit, dataref);
        total := total + venit;
    end loop;
    dbms_output.put_line(total);
end;
/

SELECT line, position, text
FROM user_errors
WHERE name = 'CEVA'
ORDER BY sequence;
-- sau, mai simplu, cu show errors, dar aici iti fcai tu afisare frumoasa cu linia la care e =)))


-- Exercitiul 4
/*
procedura nestocata cu cursor pentru a calcula numarul de zile de concediu pentru toti angajatii, astfel:
- manageri de departament: cu vechime < 13 ani: 20 zile, altfel 22
- angajati care nu sunt sefi: cu vechime < 13 ani: 15 zile, alftel 17
*/
set serveroutput on;
declare
    procedure concediu
as
    cursor c is
        select *
        from
            employees
        where
            department_id is not null
        order by
            department_id;
        i c%rowtype;
        type r_concediu is record(
            numedep departments.department_name%type,
            numeang varchar2(50),
            dataang employees.hire_date%type,
            sef varchar2(2), -- pe post de boolean, un fel de ok sa vezi daca e sef sau nu
            vechime number,
            zile number
        );
        concediu r_concediu;
        manager employees.manager_id%type;
    begin
        open c;
        loop
            fetch c into i;
            exit when c%notfound;
            select
                department_name
            into
                concediu.numedep
            from
                departments
            where
                department_id = i.department_id;
            concediu.dataang := i.hire_date;
            concediu.numeang := i.first_name||' '||i.last_name;
            concediu.vechime := trunc(months_between(sysdate, i.hire_date)/12);
            begin
                select
                    manager_id
                into
                    manager
                from
                    employees
                where
                    manager_id = i.employee_id;
                concediu.sef := 'DA';
            exception
                when no_data_found then
                    concediu.sef := 'NU';
                when too_many_rows then
                    concediu.sef := 'DA';
            end;
            if concediu.vechime < 13 and concediu.sef = 'DA' then
                concediu.zile := 20;
            elsif concediu.vechime >= 13 and concediu.sef = 'DA' then
                concediu.zile := 22;
            elsif concediu.vechime < 13 and concediu.sef = 'NU' then
                concediu.zile := 15;
            else
                concediu.zile := 17;
            end if;
            dbms_output.put_line(
                rpad(concediu.numedep, 20)||
                rpad(concediu.numeang, 20)||
                rpad(concediu.dataang, 20)||
                rpad(concediu.sef, 20)||
                rpad(concediu.vechime, 20)||
                rpad(concediu.zile, 20)
            );
        end loop;
    end;
begin
    concediu;
end;
/

-- Exercitiul 5
/*
sa se distribuie in mod egal salariul sefului de departament la subalternii lui, in fucntie de vechime, astfel:
- gr1: subalternii cu o vechime <= 31 ani: +30% din salariul sefului
- gr2: ceilalti, +70% din salariu sef
*/
set serveroutput on;
declare
    procedure distr(
        salary in number,
        vechime in number,
        nrang1 in number,
        nrang2 in number,
        prima out number,
        grupa out number
    )
    is
    begin
        if vechime <= 31 then
            prima := round(0.3 * salary / nrang1);
            grupa := 1;
        else
            prima := round(0.7 * salary /nrang2);
            grupa := 2;
        end if;
    end;
begin
    declare
        nrang1 number := 0;
        nrang2 number := 0;
        dataang date;
        salsef employees.salary%type;
        prima number;
        grupa number;
        numesef varchar2(20);
        vechime number;
    begin
        dbms_output.put_line(
            rpad('nume sef', 50)||
            rpad('salariu sef', 20)||
            rpad('nume ang', 50)||
            rpad('vechime', 20)||
            rpad('prima', 20)||
            rpad('grupa', 20)
        );
        for sef in (
            select
                distinct manager_id
            from
                employees
            where
                manager_id is not null
        ) loop
            nrang1 := 0;
            nrang2 := 0;
            select
                first_name||' '||last_name,
                salary
            into
                numesef,
                salsef
            from
                employees
            where
                employee_id = sef.manager_id;
            for ang in (
                select
                    distinct employee_id
                from
                    employees
                where
                    manager_id = sef.manager_id
            ) loop
                select
                    trunc(months_between(sysdate, hire_date) / 12)
                into
                    vechime
                from
                    employees
                where
                    employee_id = ang.employee_id;
                if vechime <= 31 then
                    nrang1 := nrang1 + 1;
                else
                    nrang2 := nrang2 + 1;
                end if;
            end loop;
            for ang in (
                select
                    distinct first_name||' '||last_name as fullname,
                    trunc(months_between(sysdate,hire_date)/12) as vechime
                from
                    employees
                where
                    manager_id = sef.manager_id
            ) loop
                distr(salsef, ang.vechime, nrang1, nrang2, prima, grupa);
                dbms_output.put_Line(
                    rpad(numesef, 50)||
                    rpad(salsef, 20)||
                    rpad(ang.fullname, 50)||
                    rpad(ang.vechime, 20)||
                    rpad(prima, 20)||
                    rpad(grupa, 20)
                );
            end loop;
        end loop;
    end;
end;
/

-- Exercitiul 6
/*
se cere:
un vector la nivelul dictionarului bazei de date, local.
o variabula de tipul acelui vector
o procedura ce afiseaza valorile din acea variabila (asta se cere, de fapt, celelalte sunt extra, detalii de implementare =)) )
la final se sterge tipul vector de mai sus
*/
-- cu varray stocat
create or replace type v_cul is varray(6) of varchar2(20);
/
declare
    procedure iterrator(cul in v_cul)
    is
    begin
        for cnt in cul.first .. cul.last
        loop
            dbms_output.put_line(cul(cnt));
        end loop;
    end;
begin
    declare
        cul v_cul;
    begin
        cul := v_cul('rosu', 'protocaliu', 'galben','verde','albastru','indigo');
        iterrator(cul);
    end;
end;
/
drop type v_cul;

-- cu varray local
declare
    type v is varray(6) of varchar2(20);
    procedure it(c in v)
    is
    begin
        for i in c.first .. c.last
        loop
            dbms_output.put_Line(c(i));
        end loop;
    end;
begin
    declare
        c v;
    begin
        c := v('r','o','g','v','a','iv');
        it(c);
    end;
end;
/
-- nu mai dau drop ca e local

-- cu nested table stocat
create or replace type t is table of varchar2(20);
/
declare
    procedure it(c in t)
    is
    begin
        for i in c.first .. c.last
        loop
            dbms_output.put_line(c(i));
        end loop;
    end;
begin 
    declare
        c t;
    begin
        c := t('r','o','g','v','a','iv');
        it(c);
    end;
end;
/
drop type t;

-- cu nested table local
declare
    type t is table of varchar2(20);
    procedure it(c in t)
    is
    begin
        for i in c.first .. c.last
        loop
            dbms_output.put_line(c(i));
        end loop;
    end;
begin
    declare
        c t;
    begin
        c := t('r','o','g','v','a','iv');
        it(c);
    end;
end;
/

-- cu associative array
declare
    type t is table of varchar2(20) index by pls_integer;
    procedure it(c in t)
    is
    begin
        for i in c.first .. c.last
        loop
            dbms_output.put_line(c(i));
        end loop;
    end;
begin
    declare
        c t;
    begin
        c := t(1=>'r', 2=>'o',3=>'g',4=>'v',5=>'a',6=>'iv');
        it(c);
    end;
end;
/

-- cursor in dat ca parametru
declare
    procedure test(c in sys_refcursor)
    is
        type r_dept is record (
            department_name departments.department_name%type,
            loc locations.city%type
        ); -- deci aici e tipul
        dept_rec r_dept; -- aici e variabila de tipul declarat mai sus
    begin
        dbms_output.put_line(
            rpad('nume',20)||
            rpad('locatie',20)
        );
        loop
            fetch c into dept_rec; -- ai sys_refcursor deci e cursor deci da
            exit when c%notfound;
            dbms_output.put_line(
                rpad(dept_rec.department_name, 20)||
                rpad(dept_rec.loc, 20)
            );
        end loop;
    end;
begin
    declare
        type dep_ref is ref cursor; -- cred ca asa se face
        c dep_ref;
    begin
        open c for
            select
                department_name,
                locations.city
            from
                departments
            inner join
                locations
            on
                locations.location_id = departments.location_id;
        test(c);
        if c%isopen then
            dbms_output.put_line(
                'trebuie inchis!'
            );
            close c;
        end if;
    end;
end;
/       

-- cursor out dat ca parametru
declare
    procedure test (c out sys_refcursor)
    is
    begin
        open c for
            select
                department_name,
                locations.city
            from
                departments
            inner join
                locations
            on
                locations.location_id = departments.location_id;
    end;
begin
    declare
        type dep_ref is ref cursor;
        c dep_ref;
        type r_dep is record (
            department_name departments.department_name%type,
            loc locations.city%type
        );
        dep_rec r_dep;
    begin
        test(c);
        dbms_output.put_line(
            rpad('nume', 20)||
            rpad('loc', 20)
        );
        loop
            fetch c into dep_rec;
            exit when c%notfound;
            dbms_output.put_line(
                rpad(dep_rec.department_name, 20)||
                rpad(dep_rec.loc, 20)
            );
        end loop;
        if c%isopen then
            close c;
        end if;
    end;
end;
/

-- cursor in out dat ca parametru
declare
    procedure test (refc in out sys_refcursor)
    is
        type r_dep is record (
            department_name departments.department_name%type,
            loc locations.city%type
        );
        dep_rec r_dep;
    begin
        dbms_output.put_line(
            rpad('nume', 20)||
            rpad('loc', 20)
        );
        loop
            fetch refc into dep_rec;
            exit when refc%notfound;
            dbms_output.put_line(
                rpad(dep_rec.department_name, 20)||
                rpad(dep_rec.loc, 20)
            );
        end loop;
        if refc%isopen then
            close refc;
        end if;
        open refc for
            select
                first_name||' '||last_name,
                salary
            from
                employees;
    end;
begin
    declare
        type c_ref is ref cursor;
        refc c_ref;
        type r_emp is record (
            ename varchar2(50),
            salary employees.salary%type
        );
        emp_rec r_emp;
    begin
        open refc for
            select
                department_name,
                locations.city
            from
                departments
            inner join
                locations
            on
                locations.location_id = departments.location_id;
        dbms_output.put_line(
            rpad('nume', 20)||
            rpad('loc', 20)
        );
        test(refc);
        dbms_output.put_line(
            rpad('nume', 20)||
            rpad('salariu', 20)
        );
        loop
            fetch refc into emp_rec;
            exit when refc%notfound;
            dbms_output.put_line(
                rpad(emp_rec.ename, 20) ||
                rpad(emp_rec.salary, 20)
            );
        end loop;
        if refc%isopen then
            close refc;
        end if;
    end;
end;
/

-- Exercitiul 8
-- functie locala ce primeste ca parametru un id_dep si returneaza nr salarati de acolo
declare
    numedep departments.department_name%type;
    iddep departments.department_id%type;
    nrang number;
    function sal(id_dep in number)
    return number
    as  
        nrang number;
    begin
        select
            count(distinct employee_id)
        into
            nrang
        from
            employees
        where
            department_id = id_dep;
        return nrang;
    end;
begin
    iddep := &iddep;
    select
        department_name
    into
        numedep
    from
        departments
    where department_id = iddep;
    nrang := sal(iddep);
    dbms_output.put_line(
        'dep'||' '||numedep||' = '||nrang
    );
exception
    when no_data_found then
        dbms_output.put_line('nu exista');
end;
/

-- Exercitiul 9
/*
functie stocata ce calculeaza nr de puncte al unui angajat; se acorda astfel:

vechime: > 32 ani => 30 p, altfel 15
sal_max: = sal_max => 20 p, altfel 10
comision: > 0 => 10 p, altfel 5 se va crea un nou tabel cu idang, puncte, iddep
*/
-- in apararea mea, sunt dislexica rau atunci cand tastez repede, ok? =))
-- de mers, merge codul de mai jos, asa ca stai chill ;)
create table tempp (
    idang number,
    puncte number,
    iddep number
);
CREATE OR REPLACE FUNCTION f(idang IN NUMBER)
RETURN NUMBER
IS
    dataang employees.hire_date%TYPE;
    iddep NUMBER; -- Corrected data type
    sal employees.salary%TYPE;
    com employees.commission_pct%TYPE;
    salmax NUMBER;
    puncte NUMBER := 0;
BEGIN
    -- Fetch employee data
    SELECT hire_date, department_id, salary, NVL(commission_pct, 0)
    INTO dataang, iddep, sal, com
    FROM employees
    WHERE employee_id = idang;

    -- Calculate points based on tenure
    IF months_between(sysdate, dataang) > 32 * 12 THEN
        puncte := puncte + 30;
    ELSE
        puncte := puncte + 15;
    END IF;

    -- Find max salary in the department
    SELECT max(salary)
    INTO salmax
    FROM employees
    WHERE department_id = iddep;

    -- Points based on salary comparison
    IF salmax = sal THEN
        puncte := puncte + 20;
    ELSE
        puncte := puncte + 10;
    END IF;

    -- Points based on commission
    IF com > 0 THEN
        puncte := puncte + 20;
    ELSE
        puncte := puncte + 5;
    END IF;

    RETURN puncte;
END f;
/
DECLARE
    puncte NUMBER;
    cursor c IS
        SELECT employee_id, department_id
        FROM employees;
    numedep VARCHAR2(100);
    idmgr employees.manager_id%TYPE;
    numeang VARCHAR2(50);
    dataang employees.hire_date%TYPE;
    vechime NUMBER;
    salmax NUMBER;
    com NUMBER;
BEGIN
    -- Clear previous data
    DELETE FROM temp;

    -- Calculate score for each employee and store it
    FOR ang IN c LOOP
        puncte := f(ang.employee_id);
        INSERT INTO tempp(idang, puncte, iddep)
        VALUES(ang.employee_id, puncte, ang.department_id);
    END LOOP;

    -- Output formatted data
    dbms_output.put_line(
        RPAD('dep', 20) || RPAD('sal max', 20) || RPAD('nume ang', 50) ||
        RPAD('vechime', 20) || RPAD('comision', 20) || RPAD('puncte', 20)
    );
    dbms_output.put_line(RPAD('=', 120, '='));

    -- Process each department's top scorer
    FOR cnt IN (
        SELECT t.idang, t.iddep
        FROM tempp t
        JOIN (SELECT iddep, MAX(puncte) AS maxpuncte FROM tempp GROUP BY iddep) maxp
        ON t.iddep = maxp.iddep AND t.puncte = maxp.maxpuncte
    ) LOOP
        -- Fetch department name
        SELECT department_name INTO numedep
        FROM departments
        WHERE department_id = cnt.iddep;

        -- Fetch max salary and other details
        SELECT hire_date, first_name || ' ' || last_name, NVL(commission_pct, 0) * salary
        INTO dataang, numeang, com
        FROM employees
        WHERE employee_id = cnt.idang;

        -- Calculate tenure
        vechime := trunc(months_between(sysdate, dataang) / 12);

        -- Output formatted results
        dbms_output.put_line(
            RPAD(numedep, 20) || RPAD(salmax, 20) || RPAD(numeang, 50) ||
            RPAD(vechime, 20) || RPAD(com, 20) || RPAD(puncte, 20)
        );
    END LOOP;
END;
/
select
    department_name,
    first_name||' '||last_name,
    f(employee_id) puncte
from
    employees
inner join
    departments
on
    department_id = employees.department_id
where
    department_id = 10;
select
    department_name,
    first_name||' '||last_name,
    f(employee_id) puncte
from
    employees
inner join
    departments
on
    departments.department_id = employees.department_id
and
    f(employee_id) >= 40
order by departments.department_name, puncte desc;
SELECT
    departments.department_name AS dep,
    (
        SELECT
            MAX(salary)
        FROM
            employees e
        WHERE
            e.department_id = departments.department_id
    ) AS sal,
    employees.first_name || ' ' || employees.last_name AS nume,
    TRUNC(MONTHS_BETWEEN(SYSDATE, employees.hire_date) / 12) AS vechime,
    NVL(employees.commission_pct, 0) AS com,
    f(employees.employee_id) AS puncte
FROM
    employees
INNER JOIN
    departments ON departments.department_id = employees.department_id
WHERE
    f(employees.employee_id) = (
        SELECT
            MAX(f(e.employee_id))
        FROM
            employees e
        WHERE
            e.department_id = employees.department_id
    )
ORDER BY
    departments.department_name;
/
-- aici, mai sus, e la fel ca la exercitiul 3
-- se doreste, totusi, minimizarea de cereri =/

-- de la Alex:
/*Sa se gaseasca tarile care au unul sau mai multi din urmatorii factori de risc si sa se listeze numele factorilor de risc:
    - Factor de risc 1 -> managerul are angajati din alt departament decat cel in care este el (afisati numele managerilor)
    - Factor de risc 2 -> managerii au un range salarial de cel putin doua ori mai mare decat oricare din rangeurile salariale ale celor de sub ei ()
    - Factor de risc 3 -> in acea tara se gaseste cel putin un angajat care nu are o functie compatibila sau cu managerul lui direct sau cu managerul de departamentul de care tine (niste tampneii, tbh)
Header afisare: nume tara + factor de risc 1 + factor de risc 2 + factor de risc 3
*/

-- SELECT DISTINCT c.country_name
-- FROM employees e
-- JOIN departments d ON e.department_id = d.department_id
-- JOIN locations l ON d.location_id = l.location_id
-- JOIN countries c ON l.country_id = c.country_id
-- /

-- SELECT DISTINCT m.first_name || ' ' || m.last_name, m.department_id
-- FROM employees e
-- JOIN employees m ON e.manager_id = m.employee_id
-- WHERE e.department_id != m.department_id
-- /
/*
SET serveroutput ON;
DECLARE 
    TYPE mydict IS TABLE OF VARCHAR2(10000) INDEX BY VARCHAR2(100);
    myindex mydict;
BEGIN 
    FOR manager_info IN (SELECT DISTINCT m.first_name || ' ' || m.last_name AS nume, l.country_id AS c_id
                        FROM employees e
                        JOIN employees m ON e.manager_id = m.employee_id
                        JOIN departments d ON m.department_id = d.department_id
                        JOIN locations l ON d.location_id = l.location_id
                        WHERE e.department_id != m.department_id) 
        LOOP
            IF myindex.EXISTS(manager_info.c_id) THEN
                myindex(manager_info.c_id) := myindex(manager_info.c_id) || ';' || manager_info.nume;
            ELSE 
                myindex(manager_info.c_id) := manager_info.nume;
            END IF;
        END LOOP;
    FOR country_info IN (SELECT country_name, country_id
                        FROM countries)
        LOOP
            BEGIN
                dbms_output.PUT_LINE(country_info.country_name || ', ' || myindex(country_info.country_id));     
                EXCEPTION WHEN OTHERS THEN dbms_output.PUT_LINE(country_info.country_name || ', ' || ' ');
            END;
            
        END LOOP;
END;
/
*/

DECLARE 
    TYPE risk_dict IS TABLE OF VARCHAR2(10000) INDEX BY VARCHAR2(100);
    risk1 risk_dict;
    risk2 risk_dict;
    risk3 risk_dict;
BEGIN
    -- Factor de risc 1: manageri cu angajați din alte departamente
    FOR manager_info IN (
        SELECT DISTINCT m.first_name || ' ' || m.last_name AS nume, l.country_id AS c_id
        FROM employees e
        JOIN employees m ON e.manager_id = m.employee_id
        JOIN departments d ON m.department_id = d.department_id
        JOIN locations l ON d.location_id = l.location_id
        WHERE e.department_id != m.department_id
    ) LOOP
        IF risk1.EXISTS(manager_info.c_id) THEN
            risk1(manager_info.c_id) := risk1(manager_info.c_id) || ';' || manager_info.nume;
        ELSE 
            risk1(manager_info.c_id) := manager_info.nume;
        END IF;
    END LOOP;

    -- Factor de risc 2: manageri cu interval de salarii dublu
    FOR salary_info IN (
        SELECT DISTINCT l.country_id AS c_id, m.first_name || ' ' || m.last_name AS nume
        FROM employees e
        JOIN employees m ON e.manager_id = m.employee_id
        JOIN departments d ON m.department_id = d.department_id
        JOIN locations l ON d.location_id = l.location_id
        WHERE m.salary >= 2 * (SELECT MAX(e.salary) FROM employees e WHERE e.manager_id = m.employee_id)
    ) LOOP
        IF risk2.EXISTS(salary_info.c_id) THEN
            risk2(salary_info.c_id) := risk2(salary_info.c_id) || ';' || salary_info.nume;
        ELSE 
            risk2(salary_info.c_id) := salary_info.nume;
        END IF;
    END LOOP;

    -- Factor de risc 3: funcții incompatibile
    FOR incompatibility_info IN (
        SELECT DISTINCT l.country_id AS c_id, e.first_name || ' ' || e.last_name AS nume
        FROM employees e
        JOIN employees m ON e.manager_id = m.employee_id
        JOIN departments d ON m.department_id = d.department_id
        JOIN locations l ON d.location_id = l.location_id
        WHERE e.job_id NOT IN (m.job_id, (SELECT job_id FROM employees WHERE employee_id = d.manager_id))
    ) LOOP
        IF risk3.EXISTS(incompatibility_info.c_id) THEN
            risk3(incompatibility_info.c_id) := risk3(incompatibility_info.c_id) || ';' || incompatibility_info.nume;
        ELSE 
            risk3(incompatibility_info.c_id) := incompatibility_info.nume;
        END IF;
    END LOOP;

    -- Afișare rezultate
    FOR country_info IN (SELECT country_name, country_id FROM countries) LOOP
        BEGIN
            dbms_output.PUT_LINE(
                country_info.country_name || ', ' ||
                NVL(risk1(country_info.country_id), ' ') || ', ' ||
                NVL(risk2(country_info.country_id), ' ') || ', ' ||
                NVL(risk3(country_info.country_id), ' ')
            );     
        EXCEPTION
            WHEN OTHERS THEN 
                dbms_output.PUT_LINE(country_info.country_name || ', ' || ' , , ');
        END; 
    END LOOP; 
END;
/
