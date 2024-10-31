-- Exercitiul 1
-- Exemplu de procedură declarată într-un bloc.
/*
set verify off
set serveroutput on
DECLARE
    PROCEDURE procFaraParam
    AS
    BEGIN
        dbms_output.put_line('Am apelat o procedura fara parametri');
    END procFaraParam;
BEGIN
    procFaraParam();
END;
/
*/

-- Exercitiul 2
-- Să se scrie o procedură declarată în cadrul unui bloc care întoarce salariu maxim pentru un ID de departament și o funcție introduse de la tastatură. 
-- Salariu maxim să fie returnat folosindu-se o variabilă scalară. Să se traducă joburile în limba română, în cadrul procedurii. 
-- Aveți grijă la cum sunt repartizate job-urile în departamente.
/*
set serveroutput on;
DECLARE
    numedeptament departments.department_name%TYPE;
    iddept employees.department_id%TYPE := &iddepartament;
    PROCEDURE Salariu(
        deptid IN NUMBER,
        functie IN OUT VARCHAR2,
        salariumaxim OUT NUMBER
    )
    IS 
        salmax NUMBER;
    BEGIN
        SELECT MAX(salary)
        INTO salmax
        FROM employees
        WHERE department_id = deptid AND LOWER(job_id) = LOWER(functie);
        GROUP BY department_id;

        salariumaxim := salmax;

        functie := CASE
            WHEN (UPPER(functie) = 'FI_ACCOUNT') THEN 'Contabil'
            WHEN (UPPER(functie) = 'IT_PROG') THEN 'Programator'
            WHEN (UPPER(functie) LIKE '%_CLERK') THEN 'Functionar'
            WHEN (UPPER(functie) = 'AD_PRES') THEN 'Presedinte'
            WHEN (UPPER(functie) LIKE '%_MAN') THEN 'Manager'
            ELSE 'Nu avem functia'
        END;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            dbms_output.put_line('Nu a fost gasita nici o inregistrare');
    END;
BEGIN
    DECLARE
        functie VARCHAR(40) := '&numeFunctie';
        salmax NUMBER;
    BEGIN
        SELECT department_name
        INTO numedeptament
        FROM departments
        WHERE department_id = iddept;

        Salariu(iddept, functie, salmax);

        dbms_output.put_line('In departamentul ' 
                            || numedeptament 
                            || ' salariul maxim pentru functia ' 
                            || functie 
                            || ' este ' 
                            || salmax);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            dbms_output.put_line('Departament inexistent');
    END;
END;
/
*/
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