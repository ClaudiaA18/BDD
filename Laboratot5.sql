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
