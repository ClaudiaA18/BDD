-- Laborator 4

/* Sa se gaseasca nivelul ierarhic maxim
Se considera ca angajatul care nu are niciun angajat subaltern direct (nu este managerul nimanui) are nivelul 0
Managerul lui are nivelul minim 1 (daca mai are un subaltern de nivel x, atunci are maximul dintre x si 1 + x)
*/
set serveroutput ON;

DECLARE
    nivel_maxim INT DEFAULT 0;
    nivel_curent INT DEFAULT 1;
    manager_curent employees%ROWTYPE;
    id_manager_curent employees.manager_id%TYPE;
    -- hai ca merge si fara cursor
    -- cum s-ar face cu cursor
BEGIN
    -- ia fiecare angajat care nu se afla in lista de manageri (mai pe scurt care nu e manager)
    -- ca sa afli managerii poti sa faci atat join pe self, cat si comanda de mai jos din subquery
    FOR angajat in (
        SELECT * 
        FROM employees
        WHERE employee_id NOT IN (SELECT DISTINCT manager_id 
                                  FROM employees
                                  WHERE manager_id IS NOT NULL)
    )
    LOOP
        -- asta e pentru un singur nivel, deci noi vrem sa facem pentru toate nivelele
        -- asa ca facem cu while
        -- aici exista si while-while, nu neaparat cursor
        -- cursorul e un fel de while, true

        -- IF angajat.manager_id IS NOT NULL THEN -- daca are manager
        --     SELECT *
        --     INTO manager_curent  -- punem aici managerul
        --     FROM employees
        --     WHERE employee_id = angajat.manager_id;
        -- END IF;
        nivel_curent := 1; -- init cnt
        id_manager_curent := angajat.manager_id;

        WHILE (id_manager_curent IS NOT NULL)
            LOOP
                SELECT *
                INTO 
                    manager_curent 
                FROM
                    employees
                WHERE
                    employee_id = id_manager_curent;
                -- da; are sens;

                IF nivel_maxim < nivel_curent THEN
                -- basic ^
                    nivel_maxim := nivel_curent;
                END IF;
                
                nivel_curent := nivel_curent + 1; -- basic
                id_manager_curent := manager_curent.manager_id; -- da
            END LOOP;
    END LOOP;
    dbms_output.put_line(nivel_maxim);
END;
/