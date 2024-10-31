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
            ON e.department_id = d.department_id
        WHERE
            UPPER(e.job_id) LIKE '%MGR' OR
            UPPER(e.job_id) LIKE '%MAN' OR
            UPPER(e.job_id) LIKE '%PRES';
    
    angajat c_angajati%ROWTYPE;
    venit NUMBER;
BEGIN
    OPEN c_angajati;
    
    -- Output the headers
    DBMS_OUTPUT.put_line(
        RPAD('ECUSON', 10) ||
        RPAD('NUME', 30) ||
        RPAD('DEPARTAMENT', 20) ||
        RPAD('VENIT', 10)
    );
    
    DBMS_OUTPUT.put_line(
        RPAD('=', 10, '=') ||
        RPAD('=', 30, '=') ||
        RPAD('=', 20, '=') ||
        RPAD('=', 10, '=')
    );

    -- Loop through the cursor
    LOOP
        FETCH c_angajati INTO angajat;
        EXIT WHEN c_angajati%NOTFOUND;

        -- Calculate the income (venit)
        venit := ROUND(angajat.salary + NVL(angajat.commission_pct, 0) * angajat.salary);

        -- Output the values
        DBMS_OUTPUT.put_line(
            RPAD(angajat.employee_id, 10) ||
            RPAD(angajat.nume, 30) ||
            RPAD(angajat.department_name, 20) ||
            RPAD(venit, 10)
        );
    END LOOP;

    -- Close the cursor
    CLOSE c_angajati;
END;
/


-- Ex. 8 Să se modifice comisionul cu 10% din salariu pentru angajații care au peste 18 ani vechime în companie.

SET serveroutput ON;

DECLARE
    CURSOR c_angajati IS
        SELECT 
           d.department_name, 
           e.employee_id, 
           e.commission_pct, 
           e.hire_date,
           e.first_name || ' ' || e.last_name AS nume,
           e.salary
        FROM
            employees e
            INNER JOIN departments d
            ON e.department_id = d.department_id
        FOR UPDATE OF commission_pct;
    angajat c_angajati%ROWTYPE;
    comision_nou NUMBER DEFAULT 0;

BEGIN
    OPEN c_angajati;
    
    LOOP
        FETCH c_angajati INTO angajat;
        EXIT WHEN c_angajati%NOTFOUND;
        IF add_months(angajat.hire_date, 216) < SYSDATE THEN
            comision_nou := nvl(angajat.commission_pct, 0) + 0.1;
            UPDATE employees SET commission_pct = comision_nou
            WHERE CURRENT OF c_angajati;
        END IF;
    END LOOP;
    CLOSE c_angajati;
END;
/

SELECT * FROM employees;


-- Ex. 10 Să se facă o listă cu angajații care fac parte dintr-un departament specificat, au o anumită funcție și au venit în companie la o anumită dată specificată. Aceste condiții să fie transmise ca parametri unui cursor.

SET serveroutput ON;
DECLARE
    CURSOR c_angajati(departamentId NUMBER, jobID CHAR, hireDate DATE) IS
        SELECT
            department_id,
            first_name || ' ' || last_name AS nume,
            job_id,
            hire_date
        FROM
            employees
        WHERE
            department_id = departamentId AND
            lower(job_id) = lower(jobID) AND
            hire_date > hireDate;
    angajat c_angajati%ROWTYPE;

BEGIN
    dbms_output.put_line('Cursor 1');
    OPEN c_angajati(20, 'MK_REP', '1-JUN-02');
    LOOP
        FETCH c_angajati INTO angajat;
        EXIT WHEN c_angajati%NOTFOUND;

        dbms_output.put_line(
            rpad(angajat.department_id, 10) ||
            rpad(angajat.nume, 30) ||
            rpad(angajat.job_id, 15) ||
            rpad(angajat.hire_date, 20)
        );
    END LOOP;
    CLOSE c_angajati;

    dbms_output.put_line('Cursor 2');
    OPEN c_angajati(departamentId => 30, jobId => 'PU_CLERK', hireDate => '1-JUN-02');
    LOOP
        FETCH c_angajati INTO angajat;
        EXIT WHEN c_angajati%NOTFOUND;

        dbms_output.put_line(
            rpad(angajat.department_id, 10) ||
            rpad(angajat.nume, 30) ||
            rpad(angajat.job_id, 15) ||
            rpad(angajat.hire_date, 20)
        );
    END LOOP;
    CLOSE c_angajati;

    dbms_output.put_line('Cursor 3');
    OPEN c_angajati(jobId => 'MK_REP', hireDate => '1-JUN-02', departamentId => 20);
    LOOP
        FETCH c_angajati INTO angajat;
        EXIT WHEN c_angajati%NOTFOUND;

        dbms_output.put_line(
            rpad(angajat.department_id, 10) ||
            rpad(angajat.nume, 30) ||
            rpad(angajat.job_id, 15) ||
            rpad(angajat.hire_date, 20)
        );
    END LOOP;
    CLOSE c_angajati;

    dbms_output.put_line('Cursor 4');
    OPEN c_angajati(30, jobId => 'PU_CLERK', hireDate => '1-JUN-02');
    LOOP
        FETCH c_angajati INTO angajat;
        EXIT WHEN c_angajati%NOTFOUND;

        dbms_output.put_line(
            rpad(angajat.department_id, 10) ||
            rpad(angajat.nume, 30) ||
            rpad(angajat.job_id, 15) ||
            rpad(angajat.hire_date, 20)
        );
    END LOOP;
    CLOSE c_angajati;

    dbms_output.put_line('Cursor 5');
    OPEN c_angajati(30, 'PU_CLERK', hireDate => '1-JUN-02');
    LOOP
        FETCH c_angajati INTO angajat;
        EXIT WHEN c_angajati%NOTFOUND;

        dbms_output.put_line(
            rpad(angajat.department_id, 10) ||
            rpad(angajat.nume, 30) ||
            rpad(angajat.job_id, 15) ||
            rpad(angajat.hire_date, 20)
        );
    END LOOP;
    CLOSE c_angajati;

END;
/    


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

BEGIN
    