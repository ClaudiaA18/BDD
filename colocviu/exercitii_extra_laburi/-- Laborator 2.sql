-- Laborator 2
-- Sa se gaseasaca toti angajatii care au avut macar o schimbare de job
set serveroutput ON;
DECLARE
    type ref_angajati is RECORD(
        id_angajat employees.employee_id%type,
        numeangajat VarChar2(50)
    );
    type colectie_angajati is table of ref_angajati;
    angajati colectie_angajati;
    intreg integer;
BEGIN
    SELECT 
        employees.employee_id, 
        employees.first_name || ' ' || employees.last_name
        bulk collect into angajati
    FROM 
        employees; 

    FOR contor in angajati.first .. angajati.last LOOP
        BEGIN
            select 1 
            into
                intreg
            from
                job_history
            where
                employee_id = angajati(contor).id_angajat
            fetch
                first 1 rows only;
            -- deci asa iei angajat cu for gen

            dbms_output.Put_line(angajati(contor).numeangajat);
            exception
                when no_data_found then
                    null;
        end;
    END LOOP;
End;
/

select
    1 as ceva_altceva
    , 'ana are mere' as altceva_ceva2
from
    employees
fetch
    first 5 rows only;
    -- chestia de mai sus iti scrie ana are mere de 5 ori? 