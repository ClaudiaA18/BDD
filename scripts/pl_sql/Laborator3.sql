-- Exercitiul 1
-- id dep de la tastatura si se afiseaza nume_dep
set serveroutput on
declare
    id_dep number;
    nume_dep departments.department_name%type;
begin
    id_dep := &iddep;
    select department_name into nume_dep from departments where department_id = id_dep;
    dbms_output.put_line(id_dep||' - '||nume_dep);
end;
/

-- Exercitiul 2
-- tratarea exceptiei de la exercitiul 1
set serveroutput on
declare
    id_dep number;
    nume_dep departments.department_name%type;
begin
    id_dep := &iddep;
    select department_name into nume_dep from departments where department_id = id_dep;
    dbms_output.put_line(id_dep||' - '||nume_dep);
exception
    when no_data_found then
        dbms_output.put_line(id_dep||' - N/A');
end;
/

-- Exercitiul 3
-- inserare in tabela employees a unui nou angajat dara sa aiba employye_id
set serveroutput on;
declare
    insert_angajat exception;
    pragma exception_init(insert_angajat, -01400);
begin
    insert into employees(first_name, last_name, hire_date, salary)
    values ('Ion', 'Ionescu', '14-aug-2020', 1450);
exception
    when insert_angajat then
        dbms_output.put_line('Nu se accepta inregistrari noi in tabela employees fara employee_id');
        dbms_output.put_line('Cod eroare '||SQLCODE);
        dbms_output.put_line('Mesaj '||SQLERRM);
end;
/

-- Exercitiul 4
-- exercitiul 3 dar cu tratare exceptie ce nu a fost declarata

set serveroutput on;
declare
    insert_angajat exception;
    pragma exception_init(insert_angajat, -01400);
begin
    insert into employees(first_name, last_name, hire_date, salary)
    values('Ion', 'Ionescu', '14-aug-2020', 1450);
exception
    when insert_angajat then
        dbms_output.put_line('Nu se acceota inserari noi in tabela employees fara employee_id');
        dbms_output.put_line('Cod eroare '||SQLCODE);
        dbms_output.put_line('Mesaj '||SQLERRM);
    when exceptie_eronata then null;
end;
/

-- Exercitiul 5
/*
pentru angajatii dintr-un departament, al carui id este de la tastatura, care au un comision null, sa se genereze o exceptie definita
*/
set serveroutput on;
declare
    idDepartament number;
    contor number := 100;
    numeAngajat employees.first_name%type;
    comision employees.commission_pct%type;
    dataAngajare employees.hire_date%type;
    lipsaComision exception;
begin
    idDepartament := &deptId;
    dbms_output.put_line(rpad('Nume', 15,' ')||rpad('Data_ang',20,' ')||lpad('Comision',15,' '));
    dbms_output.put_line(rpad('=', 15,'=')||rpad('=',20,'=')||lpad('=',15,'='));
    loop
        contor := contor + 1;
        begin
            select
                first_name || ' ' || last_name,
                hire_date,
                commission_pct
            into
                numeAngajat, dataAngajare, comision
            from
                employees
            where
                department_id = idDepartament
            and
                employee_id = contor;
            if comision is null then
                raise lipsaComision;
            end if;
            dbms_output.put_line(rpad(numeAngajat, 15, ' ')||rpad(dataAngajare, 20, ' ')||lpad(comision, 15, ' '));
        exception
            when lipsaComision then
                dbms_output.put_line(rpad(numeAngajat, 15, ' ')||rpad(dataAngajare, 20, ' ')||lpad('lipsa comision', 15, ' '));
            when no_data_found then null;
            when others then null;
        end;
        exit when contor = 300;
    end loop;
end;
/

-- Exercitiul 6
-- tratare exceptie de mai devreme in blocul principal
set serveroutput on;
declare
    idDepartament number;
    contor number := 100;
    numeAngajat employees.first_name%type;
    comision employees.commission_pct%type;
    dataAngajare employees.hire_date%type;
    lipsaComision exception;
begin
    idDepartament := &deptId;
    dbms_output.put_line(rpad('nume',15,' ')||rpad('data_ang',20,' ')||lpad('comision',15,' '));
    dbms_output.put_line(rpad('=',15,'=')||rpad('=',20,'=')||lpad('=',15,'='));
    loop
        contor := contor + 1;
        begin
            select
                first_name || ' ' || last_name,
                hire_date,
                commission_pct
            into
                numeAngajat,
                dataAngajare,
                comision
            from
                employees
            where
                department_id = idDepartament
            and
                employee_id = contor;
            if comision is null then
                raise lipsaComision;
            end if;
            dbms_output.put_line(rpad(numeAngajat,15,' ')||rpad(dataAngajare,20,' ')||lpad(comision,15,' '));
        exception
            when no_data_found then null;
        end;
        exit when contor = 300;
    end loop;
exception
    when lipsaComision then
        dbms_output.put_line(rpad(numeAngajat,15,' ')||rpad(dataAngajare,20,' ')||lpad('lipsa comision',15,' '));
end;
/

-- Exercitiul 7
/*
pentru un angajat care nu are comision, sa se defineasca o exceptie ce e tratata in momentul generarii si are codul -20100
*/
sset serveroutput on;
declare
    id employees.employee_id%type;
    comision employees.commission_pct%type;
    lipsaComision exception;
    pragma exception_init(lipsaComision, -20100);
begin
    id := &id;
    select
        commission_pct
    into
        comision
    from
        employees
    where employee_id = id;
    if comision is null then
        raise_application_error(-20100, 'Ang nu are comision!');
    end if;
exception
    when lipsaComision then
        dbms_output.put_line('Ang nu are comision');
        dbms_output.put_line('Cod err: '||SQLCODE);
        dbms_output.put_line('Msg: '||SQLERRM);
end;
/

-- Exercitiul 8
-- suma veniturilor dintr-un departament pe o anumita functie
set serveroutput on;
declare
    iddep departments.department_id%type;
    numedep departments.department_name%type;
    salariu employees.salary%type;
    functie employees.job_id%type;
begin
    iddep := &iddep;
    functie := '&functie';
    select
        sum(salary + salary * nvl(commission_pct, 0))
    into
        salariu
    from
        employees
    where
        department_id = iddep
    and
        upper(job_id) = upper(functie)
    group by
        department_id;
    
    select
        department_name
    into
        numedep
    from
        departments
    where
        department_id = iddep;

    dbms_output.put_line('Suma veniturilor din departamentul '||numedep||' este '||to_char(salariu));
exception
    when no_data_found then
        dbms_output.put_line('In departamentul '||numedep||' nu exista angajati cu functia '||functie);
end;
/

-- sau
set serveroutput on;
declare
   iddep departments.department_id%type;
   numedep departments.department_name%type;
   salariu employees.salary%type;
   functie employees.job_id%type;
begin
   iddep := &iddep;
   functie := '&functie';
   select
       sum(salary + salary * nvl(commission_pct, 0))
   into
       salariu
   from
       employees
   where
       department_id = iddep
   and
       upper(job_id) = upper(functie);
   
   select
       department_name
   into
       numedep
   from
       departments
   where
       department_id = iddep;

   dbms_output.put_line('Suma veniturilor din departamentul '||numedep||' este '||to_char(salariu));
exception
   when no_data_found then
       dbms_output.put_line('In departamentul '||numedep||' nu exista angajati cu functia '||functie);
end;
/

-- de la Maria:

-- Ex. BONUS
-- Sa se scrie un bloc PL/SQL care selecteaza printr-o colectie urmatoarele informatii:
-- numele complet al angajatului
-- daca are vechime de peste 7 ani
-- bonusul anual, astfel: 
     -- daca are vechime de peste 7 ani, comisionul este de 5%
     -- altfel, comisionul este setat la 0

-- !! Obligatoriu de folosit cursori 

SET serveroutput ON;
DECLARE
    CURSOR c_angajati IS
        SELECT 
            first_name || ' ' || last_name AS nume,
            hire_date,
            commission_pct
        FROM
            employees;
    angajat c_angajati%ROWTYPE;
    bonus NUMBER DEFAULT 0;

BEGIN
    OPEN c_angajati;
    
    LOOP
        FETCH c_angajati INTO angajat;
        EXIT WHEN c_angajati%NOTFOUND;
        
        IF add_months(angajat.hire_date, 84) < SYSDATE THEN
            bonus := 0.05;
        ELSE
            bonus := 0;
        END IF;
        
        DBMS_OUTPUT.put_line(
            rpad(angajat.nume, 30) ||
            rpad(CASE WHEN add_months(angajat.hire_date, 84) < SYSDATE THEN 'DA' ELSE 'NU' END, 10) ||
            rpad(TO_CHAR(bonus), 10)
        );
    END LOOP;
    CLOSE c_angajati;
END;
/


-- Ex. BONUS 2
-- TODO
-- Sa se scrie un bloc PL/SQL care printeaza angajatii care detin venitul maxim din fiecare dep,
-- angajatii care detin venitul minim din fiecare departament
--- si pe cei care au peste media departamentului minim 25 %

SET serveroutput ON;
DECLARE
    CURSOR c_angajati IS
        SELECT 
            d.department_name,
            e.employee_id,
            e.first_name || ' ' || e.last_name AS nume,
            e.salary,
            e.commission_pct
        FROM
            employees e
            INNER JOIN departments d
            ON e.department_id = d.department_id;
    angajat c_angajati%ROWTYPE;
    venit NUMBER;
    venit_max NUMBER;
    venit_min NUMBER;
    venit_med NUMBER;
    venit_min_25 NUMBER;
