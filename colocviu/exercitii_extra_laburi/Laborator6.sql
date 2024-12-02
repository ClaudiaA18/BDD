-- Laboratorul 6
/*
	Pentru fiecare functie sa se calculeze urmatoarele statistici:
		1. cati angajati au salariul peste jumate din grila posibila (in jobs ai salMin si salMax)
		2. cat de popular este acest job (facem un rank per departament si este cu atat mai popular cu cat sunt mai multi oameni cu acest job in departament)
		3. daca exista sansa de promovare sau salariala sau ca si pozitie (promovare salariala = mai este macar 10% pana la salMax si 
			promovare ca pozitie = exista un manager de dep care are aceeasi functie ca si noi + nu sunt deja manager)
*/
-- cte
-- stai ca rezolvaea asta pare foarte ezoterica
WITH ceva AS (
    SELECT 
        J.JOB_TITLE AS functie, 
        E.DEPARTMENT_ID AS id_dep,
        COUNT(*) AS nr_ang
    FROM JOBS J
    JOIN
        EMPLOYEES E
    ON
        J.JOB_ID = E.JOB_ID
    GROUP BY
        J.JOB_TITLE,
        E.DEPARTMENT_ID
    order by 1 desc
), 
altceva AS (
    SELECT 
        main.functie, 
        main.id_dep, 
        (
            SELECT
                COUNT(*) 
            FROM
                ceva sq 
            WHERE
                main.id_dep = sq.id_dep
            AND
                main.functie != sq.functie
            AND main.nr_ang > sq.nr_ang
        ) AS rang
    FROM ceva main
)
SELECT 
    functie, 
    id_dep, 
    rang
FROM altceva
GROUP BY functie, id_dep, rang
fetch first 1 row only;


-- hai ca fac in stilul meu =)))
/*
	Pentru fiecare functie sa se calculeze urmatoarele statistici:
		1. cati angajati au salariul peste jumate din grila posibila (in jobs ai salMin si salMax)
		2. cat de popular este acest job (facem un rank per departament si este cu atat mai popular cu cat sunt mai multi oameni cu acest job in departament)
		3. daca exista sansa de promovare salariala sau ca si pozitie (promovare salariala = mai este macar 10% pana la salMax si 
			promovare ca pozitie = exista un manager de dep care are aceeasi functie ca si noi + nu sunt deja manager)
*/

-- 1.
set serveroutput on;
DECLARE
    nr_ang NUMBER;
BEGIN
    FOR functie IN (
        SELECT
            job_id
        FROM
            jobs
    )
    LOOP
        SELECT
            COUNT(*)
        INTO
            nr_ang
        FROM
            employees e
        WHERE
            upper(e.job_id) = upper(functie.job_id)
        AND 
        ((e.salary > (
            SELECT
                MAX(sq.max_salary)
            FROM
                jobs sq
            WHERE
                upper(sq.job_id) = upper(functie.job_id)
        )) or (e.salary > (
            SELECT
                MAX(sq2.min_salary)
            FROM
                jobs sq2
            WHERE
                upper(sq2.job_id) = upper(functie.job_id)
        ))
        );
        
        dbms_output.put_line(functie.job_id || ': ' || nr_ang);
    END LOOP;
END;
/

-- 2.
DECLARE
    nr_ang NUMBER;
    dept_id NUMBER;
    maxnum number;
BEGIN
    -- pentru fiecare functie
    FOR functie IN (
        SELECT
            job_id
        FROM
            jobs
    )
    LOOP
        -- iau fiecare departament si numar insi din acel departament care au acea functie -> duh!
        FOR department IN (
            SELECT
                e.DEPARTMENT_ID
            FROM
                employees e
            WHERE
                upper(e.job_id) = upper(functie.job_id)
            GROUP BY
                e.DEPARTMENT_ID
        )
        LOOP
            select
                COUNT(*)
            into
                nr_ang
            from
                employees emp
            WHERE
                emp.DEPARTMENT_ID = department.department_id
            and
                emp.JOB_ID = functie.job_id;
            DBMS_OUTPUT.PUT_LINE(functie.job_id||' '||nr_ang);
        END LOOP;
    END LOOP;
END;
/

/* 3. daca exista sansa de promovare salariala sau ca si pozitie 
(promovare salariala = mai este macar 10% pana la salMax si 
promovare ca pozitie = exista un manager de dep care are aceeasi functie ca si noi + nu sunt deja manager)
*/
set serveroutput on;
DECLARE
    max_sal NUMBER;
    max_sal_10 NUMBER;
    nume_ang VARCHAR2(50);
    exista_manager NUMBER;
    exista_manager_dept NUMBER;
BEGIN
    FOR functie IN (
        SELECT
            job_id,
            max_salary
        FROM
            jobs
    )
    LOOP
        max_sal_10 := functie.max_salary - 0.1 * functie.max_salary;

        FOR angajat IN (
            SELECT
                e.employee_id,
                e.salary,
                e.first_name || ' ' || e.last_name AS nume,
                e.manager_id
            FROM
                employees e
            WHERE
                UPPER(e.job_id) = UPPER(functie.job_id)
        )
        LOOP
            IF angajat.salary = max_sal_10 THEN
                nume_ang := angajat.nume;
                DBMS_OUTPUT.PUT_LINE(nume_ang || ' primeste marire salariala.');
            END IF;

            SELECT COUNT(*)
            INTO exista_manager
            FROM employees m
            WHERE m.employee_id = angajat.manager_id;

            -- Verifica daca exista un manager de departament cu acelasi job_id ca functia curenta
            SELECT COUNT(*)
            INTO exista_manager_dept
            FROM employees m
            WHERE m.employee_id IN (
                SELECT d.manager_id
                FROM departments d
                WHERE d.department_id IN (
                    SELECT e.department_id
                    FROM employees e
                    WHERE e.job_id = functie.job_id
                )
            );

            -- Verifica conditiile
            IF exista_manager > 0 AND exista_manager_dept > 0 THEN
                DBMS_OUTPUT.PUT_LINE(angajat.nume || ' are sansa la promovare ca pozitie.');
            END IF;
        
        END LOOP;
    END LOOP;
END;
/