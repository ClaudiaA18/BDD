-- Ex. 1 Să se scrie un pachet p_angajare, care conține o funcție și o procedură, pentru a face o listă cu angajații care au comision și au venit în firmă înaintea șefului direct. Șeful direct al unui angajat este specificat în coloana manager_id. Procedura va afișa rezultatele.

CREATE OR REPLACE PACKAGE p_angajare AS
    CURSOR dept(did NUMBER) IS
        SELECT department_id
        FROM departments
        WHERE department_id = did
        ORDER BY 1;
    FUNCTION Vechime(hdate_ang date, hdate_sef date) RETURN BOOLEAN;
    PROCEDURE Listare;
END p_angajare;
/
CREATE OR REPLACE PACKAGE BODY p_angajare AS
    FUNCTION Vechime(hdate_ang date, hdate_sef date) 
    RETURN BOOLEAN AS
    BEGIN
        IF hdate_ang < hdate_sef THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    END Vechime;
    PROCEDURE Listare 
    IS
        CURSOR c_ang IS
            SELECT 
                e.first_name || ' ' || e.last_name AS nume_ang,
                e.hire_date hdate_ang,
                e.commission_pct com_ang,
                e.department_id dep_ang,
                s.first_name || ' ' || s.last_name AS nume_sef,
                s.hire_date hdate_sef,
                s.department_id dep_sef
            FROM employees e
            LEFT OUTER JOIN employees s 
                ON e.manager_id = s.employee_id;
        w_c c_ang%ROWTYPE;
        d_ang departments.department_id%TYPE;
    END Listare;
END p_angajare;

/*Sa se afiseze tarile care au unul sau mai multi din urmatorii factori de risc si sa se listeze numele factorilor de risc:
    - Factor de risc 1 -> managerul are angajati din alt departament decat cel in care este el (afisati numele managerilor)
    - Factor de risc 2 -> managerii au un range salarial de cel putin doua ori mai mare decat oricare din rangeurile salariale ale celor de sub ei ()
    - Factor de risc 3 -> in acea tara se gaseste cel putin un angajat care nu are o functie compatibila sau cu managerul lui direct sau cu managerul de departamentul de care tine
                - (un stock manager este compatibil cu orice angajat din acel departament si cu orice alt manager)
Header afisare: nume tara + factor de risc 1 + factor de risc 2 + factor de risc 3
*/

/*
HEADER:
    nume tara
    manageri cu risc 1
    manageri cu risc 2
    angajati incompatibili
*/

SET SERVEROUTPUT ON;

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
                COALESCE(risk1(country_info.country_id), ' ') || ', ' ||
                COALESCE(risk2(country_info.country_id), ' ') || ', ' ||
                COALESCE(risk3(country_info.country_id), ' ')
            );     
        EXCEPTION
            WHEN OTHERS THEN 
                dbms_output.PUT_LINE(country_info.country_name || ', ' || ' , , ');
        END; 
    END LOOP;  
END; 
/


