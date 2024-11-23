-- Ex. 1. Să se selecteze numele si functia unui angajat introducand id-ul acestuia de la tastatura (testați cu 1, 100 și 200).

set serveroutput on;
DECLARE
    idemp NUMBER(6) := &id; -- Declaram variabila idemp si ii atribuim valoarea introdusa de la tastatura
    nume VARCHAR2(50); -- Declaram variabila nume de tipul VARCHAR2 cu dimensiunea 50
    functie jobs.job_title%TYPE; -- Declaram variabila functie de tipul job_title din tabela jobs
BEGIN
    SELECT 
        first_name || ' ' || last_name,
        job_title
    INTO 
        nume, functie
    FROM 
        employees 
        NATURAL JOIN jobs -- Join intre employees si jobs
    WHERE 
        employee_id = idemp; -- Selectam numele si functia angajatului cu id-ul idemp
    dbms_output.put_line('Numele angajatului este: ' || nume || ' si are functia ' || functie);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        dbms_output.put_line('Nu am gasit angajat cu id-ul ' || idemp);
END;
/

-- Ex. 2. Să se insereze un nou angajat, astfel:
    -- se introduce de la tastatura un id de job, id-ul angajatului, prenumele și numele
    -- data angajarii este data curenta sysdate
    -- salariul ese 2123.85
    -- id-ul managerului este cel al managerului care are cei mai mulți angajați cu job introdus de la tastatura. Dacă sunt mai mulți manageri cu același număr de angajați se ia managerul care are id-ul cel mai mic.
-- După insert să se adauge pentru acest angajat un punctaj pentru comision de 0.5.​

SET SERVEROUTPUT ON;

-- Definire variabile la nivelul sesiunii
DEFINE id = 1000;
DEFINE fname = 'ion';
DEFINE lname = 'ionescu';
DEFINE jid = 'it_prog';

-- Bloc pentru găsirea managerului cu cei mai mulți angajați în funcția specificată
DECLARE
    ecuson employees.employee_id%TYPE := &id;
    jid employees.job_id%TYPE := UPPER('&jid');
    mgr_id NUMBER(6);
BEGIN
    SELECT 
        manager_id
    INTO 
        mgr_id
    FROM 
        employees 
    WHERE 
        job_id = jid
    GROUP BY 
        manager_id
    HAVING COUNT(*) = (
        SELECT 
            MAX(cnt)
        FROM (
            SELECT 
                COUNT(*) AS cnt
            FROM 
                employees
            WHERE 
                job_id = jid
            GROUP BY 
                manager_id
        )
    )
    ORDER BY 
        manager_id
    FETCH FIRST 1 ROW ONLY;

    DBMS_OUTPUT.PUT_LINE('Manager găsit cu ID: ' || mgr_id);

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Nu am găsit funcția ' || jid);
END;
/

-- Bloc pentru inserarea noului angajat
DECLARE
    fname employees.first_name%TYPE := '&fname';
    lname employees.last_name%TYPE := '&lname';
    email employees.email%TYPE;
    sal NUMBER(8,2) := 2123.85;
BEGIN
    email := UPPER(SUBSTR(fname, 1, 1) || lname);
    INSERT INTO employees (employee_id, first_name, last_name, salary, email, hire_date, job_id, manager_id)
    VALUES (ecuson, INITCAP(fname), INITCAP(lname), sal, email, SYSDATE, jid, mgr_id);

    DBMS_OUTPUT.PUT_LINE('Angajatul ' || fname || ' ' || lname || ' a fost inserat cu succes.');

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('A apărut o eroare la inserarea angajatului: ' || SQLERRM);
END;
/

-- Bloc pentru actualizarea comisionului
DECLARE
    comision employees.commission_pct%TYPE := 0.5;
BEGIN
    UPDATE employees
    SET commission_pct = comision
    WHERE employee_id = ecuson;

    DBMS_OUTPUT.PUT_LINE('Comisionul a fost actualizat pentru angajatul cu ID: ' || ecuson);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('A apărut o eroare la actualizarea comisionului: ' || SQLERRM);
END;
/

-- Curățare variabile la nivelul sesiunii
UNDEFINE id;
UNDEFINE fname;
UNDEFINE lname;
UNDEFINE jid;

-- Verificare inserare
SELECT * FROM employees WHERE employee_id = 1000;

-- Ștergere angajat de test
DELETE FROM employees WHERE employee_id = 1000;