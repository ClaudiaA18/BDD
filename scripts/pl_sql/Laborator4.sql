-- Exercitiul 0
/*
Sa se scrie un bloc PL/SQL care printeaza angajatii care detin venitul maxim din fiecare departament sau detin un salariu peste media job-ului lor cu cel putin 15%. Sa se poata face distinctia intre ei.
*/
SET serveroutput ON;
BEGIN
    FOR angajat IN (SELECT e.ename,
                           e.sal + Nvl(e.comm, 0) Venit,
                           e.job,
                           'Venit Maxim'          Criteriu
                    FROM   emp e
                    WHERE  e.sal + Nvl(e.comm, 0) IN (SELECT Max(sal + Nvl(comm,
                                                                 0))
                                                      FROM   emp
                                                      GROUP  BY deptno)
                    UNION
                    SELECT e.ename,
                           e.sal + Nvl(e.comm, 0) Venit,
                           e.job,
                           'Venit Peste Medie'    Criteriu
                    FROM   emp e
                    WHERE  e.sal + Nvl(e.comm, 0) > (SELECT 1.15 * Avg(
                                                            sal + Nvl(comm, 0))
                                                     FROM   emp
                                                     WHERE  job = e.job)) LOOP
        dbms_output.Put_line(Rpad(angajat.ename, 30)
                             || Rpad(angajat.venit, 10)
                             || Rpad(angajat.job, 10)
                             || Rpad(angajat.criteriu, 20));
    END LOOP;
END; 
/

-- Exercitiul 1
-- exemplu gresit de folosire al unui cursor implicit -> returneaza mai multe valori ce nu pot fi puse intr-o variabila
set serveroutput on;
declare
    salariu number;
begin
    select
        salary
    into
        salariu
    from
        employees
    where
        department_id = 80;
end;
/

-- Exercitiul 2
-- exemplu corect de folosire a unuui cursor implicit -> se garanteaza ca exista o singura valoare
set serveroutput on;
declare
    salariu number;
begin
    select
        salary
    into
        salariu
    from
        employees
    where
        employee_id = 100;
end;
/

-- Exercitiul 3
-- exemplu corect de folosire a unui cursor implicit -> se foloseste un nested table care insereaza valorile de la exercitiul 1
set serveroutput on;
declare
    type nested_table is table of employees.salary%type;
    salariu nested_table;
begin
    select
        salary
    bulk collect into
        salariu
    from
        employees
    where
        department_id = 80;
end;
/


-- Exercitiul 4
-- denumirea departamentului, numele angajatului, salariul si data_ang pentru persoane ce au venit in 2003
set serveroutput on;
declare
    cursor c is
        select
            dep.department_name,
            ang.employee_id,
            ang.first_name||' '||ang.last_name as name,
            ang.salary,
            ang.hire_date
        from
            employees ang
        inner join
            departments dep
        on
            ang.department_id = dep.department_id
        order by
            hire_date;
    v_ang c%rowtype;
begin
    open c;
    loop
        fetch
            c
        into
            v_ang;
        exit when c%notfound;
        dbms_output.put_line(v_ang.department_name||' '||v_ang.employee_id||' '||v_ang.name||' '||v_ang.salary||' '||v_ang.hire_date);
    end loop;
    close c;
end;
/

-- Exercitiul 5
/*
lista cu veniturile managerilor din companie
*/
set serveroutput on;
declare
    cursor c_ang is
        select
            dep.department_name,
            emp.employee_id,
            emp.first_name||' '||emp.last_name as name,
            emp.salary,
            emp.commission_pct
        from
            employees emp
        inner join
            departments dep
        on
            emp.department_id = dep.department_id
        where
            upper(emp.job_id) like '%MGR' or
            upper(emp.job_id) like '%MAN' or
            upper(emp.job_id) like '%PRES';
    ang c_ang%rowtype;
    venit number := 0;
begin
    open c_ang;
    dbms_output.put_line(rpad('id',10)||rpad('nume',30)||rpad('dep',20)||lpad('venit',10));
    dbms_output.put_line(rpad('=',10,'=')||rpad('=',30,'=')||rpad('=',20,'=')||lpad('=',10, '='));
    loop
        fetch c_ang into ang;
        exit when c_ang%notfound;
        venit := round(ang.salary + nvl(ang.commission_pct,0)*ang.salary);
        dbms_output.put_line(rpad(ang.employee_id,10)||rpad(ang.name,30)||rpad(ang.department_name,20)||lpad(venit,10));
        venit := 0;
    end loop;
    close c_ang;
end;
/

-- Exercitiul 6
-- 5 dar cu for
set serveroutput on;
declare
    cursor c is
        select
            dep.department_name,
            emp.employee_id,
            emp.first_name||' '||emp.last_name as name,
            emp.salary,
            emp.commission_pct
        from
            employees emp
        inner join
            departments dep
        on
            emp.department_id = dep.department_id
        where
            upper(emp.job_id) like '%MGR' or
            upper(emp.job_id) like '%MAN' or
            upper(emp.job_id) like '%PRES';
    ang c%rowtype;
    venit number := 0;
begin
    dbms_output.put_line(rpad('id',10)||rpad('nume',30)||rpad('dep',20)||lpad('venit',10));
    dbms_output.put_line(rpad('=',10,'=')||rpad('=',30,'=')||rpad('=',20,'=')||lpad('=',10,'='));
    for ang in c
    loop
        venit := round(ang.salary + nvl(ang.commission_pct, 0)*ang.salary);
        dbms_output.put_line(rpad(ang.employee_id,10)||rpad(ang.name,30)||rpad(ang.department_name,20)||lpad(venit,10));
        venit := 0;
    end loop;
end;
/

-- Exercitiul 7
/*
ca exercitiul 6, dar cu select in for
*/
set serveroutput on;
declare
    venit number := 0;
begin
    dbms_output.put_line(rpad('id',10)||rpad('nume',30)||rpad('dep',20)||lpad('venit',10));
    dbms_output.put_line(rpad('=',10,'=')||rpad('=',30,'=')||rpad('=',20,'=')||lpad('=',10,'='));
    for ang in (
        select
            dep.department_name,
            emp.employee_id,
            emp.first_name||' '||emp.last_name as name,
            emp.salary,
            emp.commission_pct
        from
            employees emp
        inner join
            departments dep
        on
            emp.department_id = dep.department_id
        where
            upper(emp.job_id) like '%MGR' or
            upper(emp.job_id) like '%MAN' or
            upper(emp.job_id) like '%PRES'
        )
        loop
            venit := round(ang.salary + nvl(ang.commission_pct,0)*ang.salary);
            dbms_output.put_line(rpad(ang.employee_id,10)||rpad(ang.name,30)||rpad(ang.department_name,20)||lpad(venit,10));
            venit := 0;
        end loop;
end;
/

-- Exercitiul 8
-- sa se modifice comisionul cu 10% din salariu pentru angajatii care au peste 18 ani vechime
set serveroutput on;
declare
    cursor c is
        select
            dep.department_name,
            emp.employee_id,
            emp.first_name||' '||emp.last_name as name,
            emp.commission_pct,
            emp.hire_date,
            emp.salary
        from
            employees emp
        inner join
            departments dep
        on
            emp.department_id = dep.department_id
        for update of commission_pct;
    ang c%rowtype;
    comision_nou number default 0; 
begin
    open c;
    loop
        fetch c into ang;
        exit when c%notfound;
        if add_months(ang.hire_date,216) < sysdate then
            comision_nou := nvl(ang.commission_pct, 0) + 0.1;
            update employees set commission_pct = comision_nou
            where current of c;
        end if;
    end loop;
    close c;
end;
/

-- Exercitiul 9
-- sa se stearga din employees toti angajatii care nu au comision
set serveroutput on;
begin
    for ang in
        (
            select
                employee_id
            from
                employees
            where
                commission_pct is null
        )
        loop
            delete
            from
                employees
            where
                employee_id = ang.employee_id;
        end loop;
end;
/

-- Exercitiul 10
/*
sa se faca o lista cu angajatii care fac parte dintr-un departament specificat, au o anumita functie si au venit in companie la o anumita data. aceste conditii sa fie date printr-un cursor
*/
set serveroutput on;
declare
    cursor c(depid number, jobid varchar2, hiredate date) is
        select
            department_id,
            first_name || ' ' || last_name as name,
            job_id,
            hire_date
        from
            employees
        where
            department_id = depid and
            lower(job_id) = lower(jobid) and
            hire_date > hiredate;
    ang c%rowtype;
begin
    dbms_output.put_line('1');
    open c(20, 'MK_REP', TO_DATE('1-JUN-02', 'DD-MON-RR'));
    loop
        fetch c into ang;
        exit when c%notfound;
        dbms_output.put_line(rpad(ang.department_id, 10) || rpad(ang.name, 30) || rpad(ang.job_id, 15) || lpad(ang.hire_date, 20));
    end loop;
    close c;

    dbms_output.put_line('2');
    open c(depid => 30, jobid => 'PU_CLERK', hiredate => TO_DATE('1-JUN-02', 'DD-MON-RR'));
    loop
        fetch c into ang;
        exit when c%notfound;
        dbms_output.put_line(rpad(ang.department_id, 10) || rpad(ang.name, 30) || rpad(ang.job_id, 15) || lpad(ang.hire_date, 20));
    end loop;
    close c;

    dbms_output.put_line('3');
    open c(jobid => 'MK_REP', hiredate => TO_DATE('1-JUN-02', 'DD-MON-RR'), depid => 20);
    loop
        fetch c into ang;
        exit when c%notfound;
        dbms_output.put_line(rpad(ang.department_id, 10) || rpad(ang.name, 30) || rpad(ang.job_id, 15) || lpad(ang.hire_date, 20));
    end loop;
    close c;

    dbms_output.put_line('4');
    open c(30, jobid => 'PU_CLERK', hiredate => TO_DATE('1-JUN-02', 'DD-MON-RR'));
    loop
        fetch c into ang;
        exit when c%notfound;
        dbms_output.put_line(rpad(ang.department_id, 10) || rpad(ang.name, 30) || rpad(ang.job_id, 15) || lpad(ang.hire_date, 20));
    end loop;
    close c;

    dbms_output.put_line('5');
    open c(30, 'PU_CLERK', hiredate => TO_DATE('1-JUN-02', 'DD-MON-RR'));
    loop
        fetch c into ang;
        exit when c%notfound;
        dbms_output.put_line(rpad(ang.department_id, 10) || rpad(ang.name, 30) || rpad(ang.job_id, 15) || lpad(ang.hire_date, 20));
    end loop;
    close c;
end;
/

DECLARE 
	TYPE ref_cursor IS REF CURSOR; 
	c_variable ref_cursor; 
	variable variable_type; 
BEGIN 
	OPEN c_variable 
		FOR SELECT column_manes 
		FROM table_names 
		WHERE conditions  [FOR UPDATE [OF col1_name[, col2_name, …]]]; 
	LOOP 
		FETCH c_variable INTO variable; 
		EXIT WHEN condition 
		... 
	END LOOP; 
	CLOSE c_variable; 
END;
/

DECLARE
	c_variable SYS_REFCURSOR;
	variable variable_type;
BEGIN
	OPEN c_variable 
		FOR SELECT column_manes 
		FROM table_names 
		WHERE conditions  [FOR UPDATE [OF col1_name[, col2_name, …]]]; 
	LOOP 
		FETCH c_variable INTO variable; 
		EXIT WHEN condition 
		... 
	END LOOP; 
	CLOSE c_variable; 
END;
/

-- Exercitiul 11
-- sa se faca o lista cu toate departamentele
set serveer output on;
declare
    type rc is ref cursor;
    cdep rc;
    departament departments.department_name%type;
begin
    open cdep for select department_name from departments;
    loop
        fetch cdep into departament;
        exit when cdep%notfound;
        dbms_output.put_line(departament);
    end loop;
    close cdep;
end;
/

-- Exercitiul 12
-- sa se listeze toti angajatii
set serveroutput on;
declare
    type rc is ref cursor;
    ca rc;
    ang employees%rowtype;
begin
    open ca for select * from employees;
    loop
        fetch ca into ang;
        exit when ca%notfound;
        dbms_output.put_line(ang.first_name||' '||ang.last_name||' '||ang.job_id||' '||ang.salary);
    end loop;
    close ca;
end;
/

-- Exercitiul 13
-- sa se foloseasca un record pentru a pastra numele, functia si salariul pentru toti angajatii
set serveroutput on;
declare
    type rc is ref cursor;
    type er is record(
        name employees.first_name%type,
        job employees.job_id%type,
        salary employees.salary%type
    );
    ca rc;
    ang er;
begin
    open ca for
        select
            first_name||' '||last_name,
            job_id,
            salary
        from
            employees;
    loop
        fetch ca into ang;
        exit when ca%notfound;
        dbms_output.put_line(ang.name||' '||ang.job||' '||ang.salary);
    end loop;
    close ca;
end;
/

-- Exercitiul 14
/*
lista pentru acordarea de comisioane tuturor sefilor de departament > daca salariu_sef < salariu_mediu_departament => comision_sef = 10/100 * salariu_mediu_departament > altfel, comision_sef = 20/100 * salariu_mediu_departament
*/
set serveroutput on;
declare
    cursor c is 
        select
            distinct manager_id
        from
            employees
        where
            manager_id is not null;
    nume employees.first_name%type;
    iddep employees.department_id%type;
    numedep departments.department_name%type;
    salariu employees.salary%type;
    id employees.employee_id%type;
    salmed number;
    comision number;
begin
    dbms_output.put_line(
        rpad('dep',20)||
        rpad('sal_med',15)||
        rpad('nume',30)||
        lpad('sal',10)||
        lpad('comision',10)
    );
    dbms_output.put_line(
        rpad('-',20,'-')||
        rpad('-',15,'-')||
        rpad('-',30,'-')||
        lpad('-',10,'-')||
        lpad('-',10,'-')
    );
    for i in c
    loop
        select
            first_name||' '||last_name,
            department_id,
            salary,
            employee_id
        into
            nume,
            iddep,
            salariu,
            id
        from
            employees
        where
            employee_id = i.manager_id;
        select
            round(avg(salary))
        into
            salmed
        from
            employees
        where
            department_id = iddep;
        select
            department_name
        into
            numedep
        from
            departments
        where
            department_id = iddep;
        if salariu < salmed then
            comision := round(0.1*salmed);
        else
            comision := round(0.2*salmed);
        end if;
        comision := comision / salariu;
        dbms_output.put_line(
            rpad(numedep, 20)||
            rpad(salmed,15)||
            rpad(nume, 30)||
            lpad(salariu,10)||
            lpad(to_char(comision, '99.99'),10)
        ); 
    end loop;
end;
/

-- de la Alex:
-- Exercitiul tip colocviu
-- Pt fiecare angajat sa se ofere un bonus in functie de nr de criterii pe care il indeplineste
-- >= 3, 50 %
-- = 2 , 30 %
-- = 1, 10 %
-- altfel, 3 %
-- criteriu 1 - 1p
-- Sa fie angajat inaingte de managerul lui direct
-- criteriu 2 - 2p
-- in departementul lui sa existe o persoana cu cel putin o schimbare de job
-- criteriu 3 - 3p
-- salariul lui sa se afle intre salariul median si cel maxim intre 2/4 si 3/4
-- criteriul 4 - 4p
-- cineva cu functia lui are nivelul ierarhic par


-- Afisarea 1p - din oficiu
-- nume complet angajat, salariu, nr criterii indeplinite, bonus

set verify off
set serveroutput on

create or replace function FCerinta1(
    IdAngajat NUMBER
) RETURN NUMBER
AS 
    FCerinta1_CEVA NUMBER;

    BEGIN
        SELECT 1
        INTO FCerinta1_CEVA
        FROM employees as manager
        LEFT JOIN employees as angajat
        ON manager.employee_id = angajat.employee_id
        WHERE angajat.employee_id = IdAngajat 
        AND angajat.hire_date > manager.hire_date;
        
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
/

CREATE OR REPLACE FUNCTION FCerinta2(
    IdDepartament NUMBER
) RETURN NUMBER

AS
    FCerinta2_CEVA NUMBER;

    BEGIN
        SELECT 1
        INTO FCerinta2_CEVA
        FROM employees as angajat
        JOIN job_history as job
        ON angajat.employee_id = job.employee_id
        WHERE angajat.departament_id = IdDepartament
        AND coleg.job_id != angajat.job_id;
        
        RETURN 1;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
/
SELECT first_name || ' ' || last_name AS nume,
       salary,
       FCerinta1(employee_id) + FCerinta2_CEVA(departament_id) AS NrCriterii,
       0 AS Bonus
FROM employees;
/
