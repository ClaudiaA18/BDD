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
    -- deci: luam fiecare angajat pe care l-am pus in tabel
    -- apoi selectez din job history numai pe angajatii care au ca id pe cei care sunt si in tabelul meu 
    -- si gen iau dublurile, dar iau numai o data
    -- ce face ai exact select 1 de mai jos:
    -- select 1 testeaza existenta unor date sau pentru a seta date in proceduri fara sa le acceseze direct 
    -- punem from pentruca ne trebuie conditia din where
    -- avem mai multe schimbari de job si gen nu luam duplicate
   
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
    1 as ceva_altceva -- dupa cum se poate observa, intoarce numai 1
    , 'ana are mere' as altceva_ceva2 -- intoarce asta
from
    employees -- de atatea ori cate inregistrari sunt aici, cred
fetch
    first 5 rows only;
    -- chestia de mai sus iti scrie ana are mere de 5 ori (dar noi vrem numai de 5 ori)