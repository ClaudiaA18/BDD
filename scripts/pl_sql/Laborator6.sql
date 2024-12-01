-- Exercitiul 1
-- pachet cu o functie si o procedura (care afiseaza rezultatele) care face lista cu angajatii care au comision si au venit in firma inaintea sefului direct (specificat in manager_id)
-- acum pui numai antetele la chestii, un fel de interfataish
create or replace package p1 as
  cursor d(iddep number) is
    select
      department_name
    from
      departments
    where
      department_id = iddep
    order by 1;
  function vechime(hdate_ang date, hdate_sef date) return boolean;
  procedure afis;
end p1;
/
-- acum implementezi interfata, cum ar veni 
create or replace package body p1 as
  function vechime(hdate_ang date, hdate_sef date) return boolean as
  begin
    return hdate_ang < hdate_sef;
  end vechime;

  procedure afis is
    cursor c is
      select e.first_name || ' ' || e.last_name as nume_ang,
             e.hire_date as hdate_ang,
             e.commission_pct as com,
             e.department_id as iddep_ang,
             s.first_name || ' ' || s.last_name as nume_sef,
             s.hire_date as hdate_sef,
             s.department_id as iddep_sef
      from employees e
      left join employees s on e.manager_id = s.employee_id;

    d_ang departments.department_name%type;
    d_sef departments.department_name%type;
  begin
    for i in c loop
      if i.iddep_ang is not null then
        open p1.d(i.iddep_ang);
        fetch p1.d into d_ang;
        if p1.d%isopen then
          close p1.d;
        end if;
      else
        d_ang := 'N/A';
      end if;

      if i.iddep_sef is not null then
        open p1.d(i.iddep_sef);
        fetch p1.d into d_sef;
        if p1.d%isopen then
          close p1.d; -- nu te lua dupa poza, e o greseala intentionata cred, 
          -- trebuie neaparat sa pui nume pachet asa cum am explicat si mai sus!
        end if;
      else
        d_sef := 'N/A';
      end if;

      if vechime(i.hdate_ang, i.hdate_sef) and i.com is not null then
        dbms_output.put_line(rpad(d_ang, 30) || ' ' ||
                             rpad(i.nume_ang, 30) || ' ' ||
                             rpad(d_sef, 30));
      end if;
    end loop;
  end afis;
end p1;
/
begin
  p1.afis;
end;
/

-- Exercitiul 2
-- compileaza fara erori, dar da eroare la rulare!
create or replace package p2 as
  function f(data_ang date, n integer) return number;
  function f(data_ang date, n decimal) return number;
  -- daca in loc de decimal am pune varchar2, totul va merge bine
end p2;
/
create or replace package body p2 as
  function f(data_ang date, n integer) return number is
    nr number := 0;
  begin
    if data_ang < sysdate then 
      nr := 1;
    end if;
    return nr;
  end f;
  function f(data_ang date, n decimal) return number is
    nr number := 2;
  begin
    if data_ang < sysdate then 
      nr := 3;
    end if;
    return nr;
  end f;
end p2;
/
declare
  cnt number;
begin
  cnt : p2.f(sysdate, 5);
end;
/

-- Exercitiul 3
create or replace package p3 as
  var number := 10; -- variabila globala folosita pentru a initializa paremtru procedura
  procedure f(nr number := var);
end p3;
/
create or replace package body p3 as
  procedure f(nr number := var) is
  begin
    dbms_output.put_line(nr);
  end f;
end p3;
/
begin
  dbms_output.put_line(p3.var);
  p3.var := 20;
  p3.f;
end;
/

-- Exercitiul 4
create or replace package p4 as
  procedure f(nr number);
end p4;
/
create or replace package body p4 as
  -- variabila privata
  var number := 10;
  -- procedura privata
  procedure f2(nr number := var) is
  begin
    dbms_output.put_line(var + nr);
  end f2;
  procedure f(nr number) is
  begin
    f2(nr + var);
    f2;
  end f;
end p4;
/
begin
  p4.f(1);
end;
/

-- Exercitiul 5
/*
sa se scrie un trigger before care afiseaza un mesaj de fiecare data cand sa insereaza ceva in tabela jobs
*/
create or replace trigger t1
before insert on jobs
begin
  dbms_output.put_line('ok');
end;
/
INSERT INTO jobs(job_id, job_title, min_salary, max_salary)
VALUES('IT_SA', 'System Administrator', 6000, 12000);
-- trigger-ul se declansaeaza si cand e eroare (mai jos)
INSERT INTO jobs(job_id, min_salary, max_salary)
VALUES('IT_TL', 7000, 19000);

-- Exercitiul 6
/*
trigger after care afiseaza mesaj de fiecare data cand se modifica ceva in jobs
*/
create or replace trigger t2
after update on jobs
begin
  dbms_output.put_line('ok');
end;
/
-- test
UPDATE jobs SET max_salary = 14000 WHERE job_id = 'IT_SA';

-- se executa si cand nu gaseste nimic in where
UPDATE jobs SET max_salary = 14000 WHERE job_id = 'IT_TM';

-- numai la eroare nu se declanseaza
UPDATE jobs SET job_id = NULL WHERE job_id = 'IT_SA';
ROLLBACK;

-- Exercitiul 7
-- trigger after daca salariul unui sh_clerk e majorat
create or replace triggee t3
after update of salary on employees
for each row
when (new.salary > old.salary and old.job_id = 'SH_CLERK')
declare
  nume_ang varchar2(45);
begin
  nume_ang := :old.first_name||' '||:old.last_name;
  dbms_output.put_line('salariul lui '||nume_ang||'a fost '||:old.salary||' si acum este '||:new.salary);
end;
/
UPDATE employees SET salary = 3000 WHERE employee_id = 182;
UPDATE employees SET salary = 3000 WHERE employee_id = 120;
ROLLBACK;

-- Exercitiul 8
/*
tigger after cand se face un insert, update sau delete pe coloanele salary si commission_pct din employees
*/
-- in apararea mea, sunt dislexica rau atunci cand tastez repede, ok? =))
-- de mers, merge codul de mai jos, asa ca stai chill ;)
create or replace trigger t4
  after insert or delete or update of salary, commission_pct on employees
  for each row
declare
  sal_old employees.salary%type := :old.salary;
  com_old employees.commission_pct%type := :old.commission_pct;
  sal_new employees.salary%type := :new.salary;
  com_new employees.commission_pct%type := :new.commission_pct;
  tip varchar2(30);
  op varchar2(20);
  data varchar2(50); -- Ajustat pentru acomodarea formatarei extinse
begin
  data := to_char(sysdate, 'DD-MM-YYYY HH24:MI:SS'); -- Corectat formatul datei
  op := user; -- Numele variabilei pentru operator este acum 'op'
  
  if inserting then
    tip := 'insert';
  elsif deleting then
    tip := 'delete';
  elsif updating('salary') and updating('commission_pct') then
    tip := 'modif salariu si comision';
  elsif updating('salary') then
    tip := 'modif salariu';
  elsif updating('commission_pct') then
    tip := 'modif comision';
  end if;

  dbms_output.put_line('Operator: ' || op);
  dbms_output.put_line('Tip operație: ' || tip);
  dbms_output.put_line('Data și ora: ' || data);
  dbms_output.put_line('Salariu vechi: ' || nvl(to_char(sal_old), 'N/A'));
  dbms_output.put_line('Salariu nou: ' || nvl(to_char(sal_new), 'N/A'));
  dbms_output.put_line('Comision vechi: ' || nvl(to_char(com_old), 'N/A'));
  dbms_output.put_line('Comision nou: ' || nvl(to_char(com_new), 'N/A'));
end;
/

INSERT INTO employees VALUES(1000, 'Ion', 'Ionescu', 'IIONESCU', '321.321.3214',
          TO_DATE('17-06-2015', 'dd-MM-yyyy'), 'IT_PROG', 4200, NULL, NULL, 90);
 
UPDATE employees SET commission_pct = nvl(commission_pct, 0) + 0.05 WHERE employee_id = 1000;
 
UPDATE employees SET salary = NVL(salary, 0) + 500 WHERE employee_id = 1000;
 
UPDATE employees SET salary = NVL(salary, 0) + 500, 
    commission_pct = nvl(commission_pct, 0) + 0.05  WHERE employee_id = 1000;
 
DELETE FROM employees WHERE employee_id = 1000;
 
ROLLBACK;

-- Exercitiul 9
-- creare vedere ce selecteaza angajatii care nu sunt sefi
create or replace view notsefi as
  select
    d.department_name
    , e.first_name
    , e.last_name
    , j.job_title
    , e.hire_date
    , e.salary
    , e.commission_pct
  from
    employees e
  inner join
    departments d
  on
    d.department_id = e.department_id
  inner join
    jobs j
  on
    j.job_id = e.job_id
  where
    e.employee_id not in
      (
        select
          distinct manager_id
        from
          employees
        where
          manager_id is not null
      );

-- test (e ok sa nu mearga)
INSERT INTO notsefi
VALUES('Treasury', 'Vasile', 'Ionescu', 'System Administrator', sysdate, 2000, 0.15);
 
INSERT INTO notsefi
VALUES('Mediu', 'Ion', 'Ionescu', 'System Administrator', sysdate, 2000, 0.15);
 
INSERT INTO notsefi
VALUES('Mediu', 'George', 'Ionescu', 'Help Deck', sysdate, 2000, 0.15);
 
ROLLBACK;

-- creare trigger ca sa mearga ;)
create or replace trigger t5
instead of insert on notsefi
  referencing new as n
  for each row
declare
  nr number;
  nid employees.employee_id%type;
  did departments.department_id%type;
  jid jobs.job_id%type;
  email employees.email%type; -- Corectat numele tabelului
begin
  -- Generarea noului ID pentru angajat
  select max(employee_id) + 1
  into nid
  from employees;
  
  -- Verificare și inserție departament nou, dacă este necesar
  select count(*)
  into nr
  from departments
  where lower(department_name) = lower(:n.department_name);

  if nr = 0 then
    select max(department_id) + 10
    into did
    from departments;
    insert into departments(department_id, department_name)
    values (did, :n.department_name);
  else
    select department_id
    into did
    from departments
    where lower(department_name) = lower(:n.department_name);
  end if;

  -- Verificare și inserție job nou, dacă este necesar
  select count(*)
  into nr
  from jobs
  where lower(job_title) = lower(:n.job_title);

  if nr = 0 then
    jid := upper(substr(:n.job_title, 1, 4));
    insert into jobs(job_id, job_title)
    values (jid, :n.job_title);
  else
    select job_id
    into jid
    from jobs
    where lower(job_title) = lower(:n.job_title);
  end if;

  -- Generarea email-ului pentru angajat
  email := upper(substr(:n.first_name, 1, 1)) || '.' || upper(:n.last_name);

  -- Inserție angajat
  insert into employees(
    employee_id,
    first_name,
    last_name,
    email,
    hire_date,
    job_id,
    salary,
    commission_pct,
    department_id
  )
  values (
    nid,
    :n.first_name,
    :n.last_name,
    email,
    :n.hire_date,
    jid,
    :n.salary, -- Verifică dacă acesta este câmpul corect pentru salariu, există confuzie cu commission_pct
    :n.commission_pct,
    did
  );
end;
/
