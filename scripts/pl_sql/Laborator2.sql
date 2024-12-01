-- Exercitiul 1
-- angajat cu o anumita functie (o anumita proprietate) care (indeplineste nu stiu ce conditie) nu primeste un anumit comision, TREBUIE ACUM sa primeasca comision de X % (sa updatezi ceva la el ;) )

set serveroutput on
declare
    nume_ang varchar(50);
    comm number;
    functie varchar(15);
    id_ang employees.employee_id%type;
BEGIN
    id_ang := &id_ang;
    SELECT 
        first_name||' '||last_name,
        job_id,
        commission_pct
    INTO   
        nume_ang,
        functie,
        comm
    FROM
        employees
    where
        employee_id = id_ang;
    if upper(functie) = 'FI_MGR'
        and (comm = 0
            or comm is null) THEN
        update employees
        set commission_pct = 0.1
        where employee_id = id_ang;
        dbms_output.put_line('Comisionul lui '||nume_ang||' a fost modificat!');
    end if;
exception
    when no_data_found THEN
        dbms_output.put_line('Nu exista!');
end;
/


-- Exercitiul 2
-- sa se acorde comision de X% la anumiti angajati care au o vechime de cel putin 15 ani

set serveroutput ON
DECLARE
    nume_ang varchar2(30);
    id_ang emp.empno%type;
    data_ang date;
BEGIN
    id_ang := &id_ang;
    SELECT
        ename,
        hiredate
    INTO
        nume_ang,
        data_ang
    from emp where empno = id_ang;
    if data_ang < add_months(sysdate, -384) then
        update emp set comm = 0.1 * sal where empno = id_ang;
        dbms_output.put_line('Angajatul '||nume_ang||' a primit comision!');
    end if;
exception
    when no_data_found THEN
        dbms_output.put_line('Nu exista!');
end;
/


-- Exercitiul 3
set serveroutput ON
DECLARE
    nume_ang varchar2(50);
    comm number;
    functie varchar2(15);
    id_ang employees.employee_id%type;
BEGIN
    id_ang := &id_ang;
    SELECT
        first_name||' '||last_name,
        job_id,
        commission_pct
    into
        nume_ang,
        functie,
        COMM
    from
        employees
    WHERE
        employee_id = id_ang;
    if upper(functie) = 'AD_PRES' THEN
        dbms_output.put_line(' Presedintele nu primeste comision!');
    elsif ( upper(functie) like '%_MAN'
            or upper(functie) like '%_MGR' 
            ) and (comm = 0
                    or comm is null) then
        update
            employees
        SET
            commission_pct = 0.1
        where employee_id = id_ang;
        dbms_output.put_line('Comisionul lui '||nume_ang||' a fost modificat!');
    ELSE
        dbms_output.put_line('Angajatul nu face parte din conducere!');
    end if;
exception
    when no_data_found then
        dbms_output.put_line('Nu exista!');
end;
/


-- Exercitiul 4
-- impozitul pe salariu al unui angajat daca (+nume_ang):
--   salariu minim din jobs => 10%
--   salariu maxim din jobs => 30%
--   altfel 20%


set serveroutput ON
DECLARE
    nume_ang VARCHAR2(50);
    salariu number;
    salariu_minim number;
    salariu_maxim number;
    functie VARCHAR2(10);
    id_ang employees.employee_id%type;
    impozit number;
BEGIN
    id_ang := &id_ang;
    select
        first_name||' '||last_name,
        job_id,
        salary
    into
        nume_ang,
        functie,
        salariu
    from
        employees
    where
        employee_id = id_ang;
    select
        min_salary,
        max_salary
    INTO
        salariu_minim,
        salariu_maxim
    from
        jobs
    WHERE
        job_id = functie;
    <<mycase>>
    case salariu
        when salariu_minim then
            impozit := salariu * 0.1;
        when salariu_maxim THEN
            impozit := salariu * 0.3;
        ELSE
            impozit := salariu * 0.2;
    end case mycase;
    dbms_output.put_line('Impozitul lui '||nume_ang||' este '||impozit);
exception
    when no_data_found THEN
        dbms_output.put_line('Nu exista!');
end;
/


-- Exercitiul 5
set serveroutput on;
DECLARE
    grade float := 7.2;
BEGIN
    CASE
        when grade >= 9 THEN
            dbms_output.put_line('fb+');
        when grade >= 8 and grade < 9 THEN
            dbms_output.put_line('fb');
        when grade >= 7 and grade < 8 THEN
            dbms_output.put_line('b');
        when grade >= 6 and grade < 7 THEN
            dbms_output.put_line('s');
        when grade < 5 THEN
            dbms_output.put_line('i');
        ELSE
            dbms_output.put_line('nu exista asa ceva!');
    end case;
end;
/


-- Exercitiul 6
set serveroutput on;
DECLARE
    alege integer;
    functie employees.job_id%type;
    nume_ang VARCHAR2(50);
BEGIN
    dbms_output.put_line('Alege '||chr(13)||chr(10)||'1 - IT_PROG'||chr(13)||chr(10)||'2 - FI_MGR'||chr(13)||chr(10)||'# - PU_MAN');
    alege := &numar;
    dbms_output.put_line('Alege versiunea 1 sau 2');
    case &alegeversiune
        when 1 THEN
            BEGIN
                dbms_output.put_line('Ai ales versiunea 1');
                goto versiunea1;
            end;
        when 2 THEN
            BEGIN
                dbms_output.put_line('Ai ales versiunea 2');
                goto versiunea2;
            end;
        else
            BEGIN
                dbms_output.put_line('Nu ai ales nicio versiune');
                goto endofprogram;
            end;
    end case;
    <<versiunea1>>
    functie := CASE
                    when alege = 1 then 'IT_PROG'
                    when alege = 2 then 'FI_MGR'
                    else 'PU_MAN'
                end;
    SELECT
        first_name||' '||last_name
    INTO
        nume_ang
    from
        employees
    WHERE
        employee_id = ( CASE
                        when functie = 'IT_PROG' then 103
                        when functie = 'FI_MGR' then 108
                        when functie = 'PU_MAN' then 114
                        else 118
                    end );
    dbms_output.put_line(nume_ang||' are functia '||functie);
    goto endofprogram;
    <<versiunea2>>
    functie := CASE
                    when alege = 1 then 'IT_PROG'
                    when alege = 2 then 'CLERK'
                    else 'PU_MAN'
                end;
    SELECT
        first_name||' '||last_name
    INTO
        nume_ang
    from
        employees
    WHERE
        employee_id = (
                    CASE
                        when functie = 'IT_PROG' then 103
                        when functie = 'FI_MGR' then 108
                        when functie = 'PU_MAN' then 114
                        else 118
                    end);
    dbms_output.put_line(nume_ang||' are functia '||functie);
    <<endofprogram>>
    dbms_output.put_line('end.');
end;
/

-- Exercitiul 7
set serveroutput on;
DECLARE
    nume_ang VARCHAR2(50);
    functie VARCHAR2(15);
BEGIN
    select emp.first_name||' '||emp.last_name,
    (
        case emp.job_id
            when 'FI_MGR' then 'Finance Manager'
            when 'FI_ACCOUNT' then 'Accountant'
            when 'AC_ACCOUNT' then 'Public Accountant'
            when 'SA_MAN' then 'Sales Manager'
            when 'ST_MAN' then 'Stock Manager'
            else ' #nuAvetiPermisiuni'
        end
    )
    INTO
        nume_ang,
        functie
    from
        employees emp
    where employee_id = &idemp;
    dbms_output.put_line(nume_ang||' are functia '||functie);
end;
/


-- Exercitiul 8
-- o lista cu data angajarii si veniturile dintr-un anumit departament
set serveroutput on;
DECLARE
    id_dep integer;
    cnt integer := 100;
    nume_ang VARCHAR2(50);
    venit number(10);
    data_ang date;
    nume_dep departments.department_name%type;
BEGIN
    id_dep := &id_dep;
    select
        department_name
    into
        nume_dep
    FROM
        departments
    WHERE
        department_id = id_dep;
    dbms_output.put_line(rpad('Nume',30,'=')||rpad('Data ang',15,'=')||lpad('Venit', 10, '='));
    loop
        cnt := cnt + 1;
        BEGIN
            SELECT
                first_name||' '||last_name,
                hire_date,
                salary + (nvl(commission_pct, 0) * salary)
            INTO
                nume_ang,
                data_ang,
                venit
            from
                employees
            where
                department_id = id_dep
            AND
                employee_id = cnt;
            dbms_output.put_line(rpad(nume_ang, 30,'=')||rpad(data_ang,15,'=')||lpad(venit,10,'='));
        exception
            when no_data_found THEN
                null;
        end;
        exit when cnt = 206;
    end loop;
exception
    when no_data_found THEN
        dbms_output.put_line('Nu exista');
end;
/


-- Exercitiul 9
-- ca la exercutiul 8, dar cu while
set serveroutput on;
DECLARE
    id_dep integer;
    cnt integer := 100;
    nume_ang VARCHAR2(30);
    venit number(10);
    data_ang date;
    nume_dep departments.department_name%type;
BEGIN
    id_dep := &id_dep;
    select
        department_name
    into
        nume_dep
    FROM
        departments
    WHERE
        department_id = id_dep;
    dbms_output.put_line(rpad('Nume',30,'=')||rpad('Data ang',15,'=')||lpad('Venit', 10, '='));
    while cnt <= 206
        loop
            cnt := cnt + 1;
            BEGIN
                SELECT
                    first_name||' '||last_name,
                    hire_date,
                    salary + (nvl(commission_pct, 0) * salary)
                INTO
                    nume_ang,
                    data_ang,
                    venit
                from
                    employees
                where
                    department_id = id_dep
                AND
                    employee_id = cnt;
                dbms_output.put_line(rpad(nume_ang, 30,'=')||rpad(data_ang,15,'=')||lpad(venit,10,'='));
            exception
                when no_data_found THEN
                    null;
            end;
    end loop;
exception
    when no_data_found THEN
        dbms_output.put_line('Nu exista');
end;
/


-- Exercitiul 10
-- la fel ca exercitiul 8, dar cu for
set serveroutput on;
DECLARE
    id_dep integer;
    cnt integer := 100;
    nume_ang VARCHAR2(30);
    venit number(10);
    data_ang date;
    nume_dep departments.department_name%type;
BEGIN
    id_dep := &id_dep;
    select
        department_name
    into
        nume_dep
    FROM
        departments
    WHERE
        department_id = id_dep;
    dbms_output.put_line(rpad('Nume',30,'=')||rpad('Data ang',15,'=')||lpad('Venit', 10, '='));
    for cnt in 100 .. 206 -- e da 
        loop
            BEGIN
                SELECT
                    first_name||' '||last_name,
                    hire_date,
                    salary + (nvl(commission_pct, 0) * salary)
                INTO
                    nume_ang,
                    data_ang,
                    venit
                from
                    employees
                where
                    department_id = id_dep
                AND
                    employee_id = cnt;
                dbms_output.put_line(rpad(nume_ang, 30,'=')||rpad(data_ang,15,'=')||lpad(venit,10,'='));
            exception
                when no_data_found THEN
                    null;
            end;
    end loop;
exception
    when no_data_found THEN
        dbms_output.put_line('Nu exista');
end;
/

-- Exercitiul 11
set serveroutput ON
DECLARE
    cnt integer;
begin
    for cnt in 1..10 loop
        if cnt = 5 THEN
            goto label1;
        ELSE
            goto label2;
        end if;
        <<label1>>
        dbms_output.put_line('la_jumate.ro=)))');
        <<label2>>
        dbms_output.put_line(cnt);
    end loop;
end;
/

-- Exercitiul 12
set serveroutput ON
DECLARE
    cnt integer;
begin
    for cnt in 1..10 loop
        if cnt = 5 THEN
            goto label1;
        ELSE
            goto label2;
        end if;
        <<label2>>
        dbms_output.put_line(cnt);
    end loop;
    <<label1>>
        dbms_output.put_line('la_jumate.ro=)))');
end;
/

-- Exercitiul 13
-- lista cu nr angajati cu venituri < 4000 si >= 4000, pentru fiecare departament
set serveroutput on;
DECLARE
    cnt INTEGER := 0;
    cnt1 NUMBER;
    cnt2 NUMBER;
    suma1 NUMBER;
    suma2 NUMBER;
    nume_dep departments.department_name%TYPE;
BEGIN
    dbms_output.put_line(rpad('Nume dep', 20) || rpad('nr sal mici', 20) || rpad('suma sal mici', 20) || rpad('nr sal mari', 20) || rpad('suma sal mari', 20));
    LOOP
        BEGIN
            cnt := cnt + 10;
            SELECT
                department_name
            INTO
                nume_dep
            FROM
                departments
            WHERE
                department_id = cnt;

            SELECT
                count(*),
                sum(salary + (nvl(commission_pct, 0) * salary))
            INTO
                cnt1,
                suma1
            FROM
                employees
            WHERE
                department_id = cnt
            AND
                (salary + (nvl(commission_pct, 0) * salary)) < 4000;

            SELECT
                count(*),
                sum(salary + (nvl(commission_pct, 0) * salary))
            INTO
                cnt2,
                suma2
            FROM
                employees
            WHERE
                department_id = cnt
            AND
                salary + (nvl(commission_pct, 0) * salary) >= 4000;

            dbms_output.put_line(rpad(nume_dep, 20) || rpad(cnt1, 20) || rpad(nvl(suma1, 0), 20) || rpad(cnt2, 20) || rpad(nvl(suma2, 0), 20));
           
            IF cnt1 = 0 AND cnt2 = 0 THEN 
                -- dbms_output.put_line('Departamentul nu exista!');
                null;
            END IF;

        EXCEPTION
            WHEN no_data_found THEN
                IF cnt > 260 THEN
                    EXIT;
                else
                    null;
                END IF;
        END;
    END LOOP;
END;
/

-- Exercitiul 14
set serveroutput on;
declare
    type deprec is record (
        id_dep number,
        nume_dep varchar2(30),
        id_mgr number,
        locatie number
    );
    rec_dep deprec;
    deptinfo departments%rowtype;
begin
    select *
    into deptinfo
    from departments
    where department_id = 10;
    rec_dep := deptinfo;
    dbms_output.put_line(rec_dep.id_dep||' - '||rec_dep.nume_dep);
end;
/

-- Exercitiul 15
/*
- inserare nou dep cu record
- selectare intr-un record
- updateze si returneze in record
- stergere si returnare in record
*/
set serveroutput on;
declare

    type myrecord is record(
        id_dep departments.department_id%type,
        nume_dep departments.department_name%type,
        id_mgr departments.manager_id%type,
        id_loc departments.location_id%type
    );

    dept_rec myrecord;
    dept_recx myrecord;
    dept_recu myrecord;
    dept_reci myrecord;

begin

    dept_reci.id_dep := 8001;
    dept_reci.nume_dep := 'IT';
    dept_reci.id_loc := 1700;
    dept_reci.id_mgr := null;

    -- insert cu record
    insert into departments
    values (dept_reci.id_dep,
            dept_reci.nume_dep,
            dept_reci.id_mgr,
            dept_reci.id_loc
    );

    -- select cu record
    select *
    into dept_rec
    from departments
    where department_id = dept_reci.id_dep;
    dbms_output.put_line('Dupa insert:'||dept_rec.id_dep||' - '||dept_rec.nume_dep||' - '||dept_rec.id_mgr||' - '||dept_rec.id_loc);

    dept_recu.id_dep := dept_reci.id_dep;
    dept_recu.nume_dep := 'Operatii';
    dept_recu.id_loc := 2400;
    -- dept_reci.id_mgr := null;

    -- update cu record
    update departments
    set row = dept_recu
    where
        department_id = dept_reci.id_dep
    returning
        department_id,
        department_name,
        manager_id, 
        location_id
    into dept_rec;
    dbms_output.put_line('Dupa update:'||dept_rec.id_dep||' - '||dept_rec.nume_dep||' - '||dept_rec.id_mgr||' - '||dept_rec.id_loc);

    -- stergere
    delete from
        departments
    where
        department_id = dept_recu.id_dep
    returning
        department_id,
        department_name,
        manager_id, 
        location_id
    into dept_recx;
    dbms_output.put_line('Dupa delete:'||dept_recx.id_dep||' - '||dept_recx.nume_dep||' - '||dept_recx.id_mgr||' - '||dept_recx.id_loc);
end;
/

-- Exercitiul 16
set serveroutput on;
declare
    type secventa is varray(5) of varchar(10);
    v secventa := secventa('alb', 'negru', 'rosu', 'verde');
    t boolean;
begin
    dbms_output.put_line(v(1)||', '||v(2)||', '||v(3)||', '||v(4));
    v(4) := 'galben';
    dbms_output.put_line(v.limit); -- desi s-a declarat mai mare si s-a ocupat mai putin, poate da eroare, dar trebuie extins
    dbms_output.put_line(v(1)||', '||v(2)||', '||v(3)||', '||v(4));
    v.extend; -- adauga element null
    dbms_output.put_line(v(1)||', '||v(2)||', '||v(3)||', '||v(4)||', '||v(5));
    v(5) := 'verde';
    dbms_output.put_line(v(1)||', '||v(2)||', '||v(3)||', '||v(4)||', '||v(5));
    dbms_output.put_line(v.limit); 
    -- daca mai extind o data da eroare, ca l-am declarat mai micut =}
end;
/

-- Exercitiul 17
set serveroutput on;
declare
    type tabindex
        is table of departments%rowtype index by binary_integer;
    mytabindex tabindex;
    rowdept departments%rowtype;
begin
    select *
    into rowdept
    from departments
    where department_id = 10;

    mytabindex(1) := rowdept;

    select *
    into mytabindex(2)
    from departments
    where department_id = 20;

    dbms_output.put_line(rpad('id',20)||rpad('nume', 20)||lpad('loc_id',20));
    dbms_output.put_line(rpad(mytabindex(1).department_id,20)||rpad(mytabindex(1).department_name, 20)||lpad(mytabindex(1).location_id,20));
    dbms_output.put_line(rpad(mytabindex(2).department_id,20)||rpad(mytabindex(2).department_name, 20)||lpad(mytabindex(2).location_id,20));
end;
/

-- Exercitiul 18
set serveroutput on;
declare
    type nesteed is table of varchar2(30);
    curs nesteed;
begin
    curs := nesteed('BD', 'ABD');
    dbms_output.put_line(curs(2));
end;
/

-- Exercitiul 19
-- cu vector
create or replace type listaproiecte as varray(20) of varchar2(20); 
/
create table proiecte
(
    id_dep number(2),
    nume_dep varchar2(20),
    buget number(11, 2),
    proiect listaproiecte
);

-- cu nested table
create or replace type listaproiecte_nt
    as table of varchar2(30)'
/
create table proiecte_nt
(
    id_dep number(2),
    nume_dep varchar2(20),
    buget number(11, 2),
    proiect listaproiecte_nt
    -- nt se stocheaza in aceeasi zona -> de aceea aia de mai jos cu store
) nested table proiect store as proiect_store;

set serveroutput on;
declare
    proiect listaproiecte;
begin
    proiect := listaproiecte('ecomm', 'carduri');
    insert into proiecte
    values (20,
    'proiectare',
    165580,
    proiect);
    dbms_output.put_line('nume: '||proiect(2));
end;
/

-- Exercitiul 20
set serveroutput on;
declare
    type vector is varray(27) of departments.department_id%type;
    myvector vector;
    cnt integer;
begin
    select department_id
    bulk collect
    into
        myvector
    from
        departments;
    for cnt in myvector.first .. myvector.last loop
        dbms_output.put_line('myvector('||cnt||')='||myvector(cnt));
    end loop;
end;
/

-- Exercitiul 21
set serveroutput on;
declare
    type it is table of departments%rowtype index by binary_integer;
    indexedtable it;
    cnt integer;
begin
    select *
    bulk collect
    into
        indexedtable
    from
        departments;
    for cnt in indexedtable.first .. indexedtable.last loop
        dbms_output.put_line('indexedtable('||cnt||')='||indexedtable(cnt).department_id||' - '||indexedtable(cnt).department_name||' - '||indexedtable(cnt).location_id);
    end loop;
end;
/

-- Exercitiul 22
set serveroutput on;
declare
    type nt is table of employees%rowtype;
    nestedtable nt;
    cnt integer;
begin
    select *
    bulk collect
    into
        nestedtable
    from
        employees
    where
        department_id = 20;
    for cnt in nestedtable.first .. nestedtable.last loop
        dbms_output.put_line('nestedtable('||cnt||')='||nestedtable(cnt).employee_id||'.'||nestedtable(cnt).first_name||' '||nestedtable(cnt).last_name);
    end loop;
end;
/

-- Exercitiul 23
set serveroutput on;
declare
    type myrecord is record(
        nume_ang varchar2(50),
        nume_dep departments.department_name%type
    );
    type nt is table of myrecord;
    nestedtable nt;
    cnt integer;
begin
    select ang.first_name||' '||ang.last_name,
    dep.department_name
    bulk collect
    into
        nestedtable
    from
        employees ang
    inner join
        departments dep
    on
        ang.department_id = dep.department_id;
    for cnt in nestedtable.first .. nestedtable.last loop
        dbms_output.put_line('nestedtable('||cnt||')='||nestedtable(cnt).nume_ang||'. - '||nestedtable(cnt).nume_dep);
    end loop;
end;
/

-- de la Alex (bonus):
-- Sa se gaseasaca toti angajatii care au avut macar o schimbare de job

set serveroutput ON;
DECLARE
    type ref_angajati is RECORD(
        id_angajat employees.employee_id%type,
        numeangajat VarChar2(50)
    );
    type colectie_angajati is table of ref_angajati;
    angajati colectie_angajati;
    intreg integer;
BEGIN

SELECT 
    employees.employee_id, 
    employees.first_name || ' ' || employees.last_name
    bulk collect into angajati
FROM 
    employees; 
FOR contor in angajati.first .. angajati.last LOOP
    BEGIN
        select 1 
        into intreg
        from job_history
        where employee_id = angajati(contor).id_angajat
        fetch first 1 rows only;

        dbms_output.Put_line(angajati(contor).numeangajat);
        exception
            when no_data_found then
                null;
    end;
END LOOP;
End;
/

select 1 as ceva_altceva, 'ana are mere' as altceva_ceva2
from employees
fetch first 5 rows only;
