-- Laborator 3
-- Exercitiul 1
-- Sa se scrie un bloc PL/SQL care selecteaza printr-o colectie urmatoarele informatii:
-- numele complet al angajatului
-- daca are vechime de peste 7 ani
-- bonusul anual, astfel: 
     -- daca are vechime de peste 7 ani, comisionul este de 5%
     -- altfel, comisionul este setat la 0
-- !! Obligatoriu de folosit cursori 
-- practic, cu cursorul selectezi ce vrei sa afisezi, gen le iei cu un for
-- iei hiredate ca sa faci un datediff cu sysdate, ai nevoie de comision ca sa calculezi bonusul

SET serveroutput ON;
DECLARE
    CURSOR c_angajati IS
        SELECT 
            first_name || ' ' || last_name AS nume,
            hire_date,
            commission_pct
        FROM
            employees;
    -- bun, pana aici e ok, am inteles
    angajat c_angajati%ROWTYPE;
    -- variabila de tipul a ce selectezi in cursor
    bonus NUMBER DEFAULT 0;
    -- variabila ca sa cakulezi bonusul
BEGIN
    -- deschid cursorul
    OPEN c_angajati;
    LOOP
        FETCH c_angajati INTO angajat; -- dap, gen ia cate o chestie pe rand din cursor
        -- si cursor = while
        EXIT WHEN c_angajati%NOTFOUND; -- dap
        -- corect
        IF add_months(angajat.hire_date, 84) < SYSDATE THEN
            bonus := 0.05;
        ELSE
            bonus := 0;
        END IF;
        -- afiseaza ce cere
        DBMS_OUTPUT.put_line(
            rpad(angajat.nume, 30) ||
            rpad(CASE WHEN add_months(angajat.hire_date, 84) < SYSDATE THEN 'DA' ELSE 'NU' END, 10) ||
            rpad(TO_CHAR(bonus), 10)
        );
    END LOOP;
    CLOSE c_angajati;
END;
/

-- Exercitiul 2
-- Sa se scrie un bloc PL/SQL care printeaza angajatii care detin venitul maxim din fiecare dep,
-- angajatii care detin venitul minim din fiecare departament
--- si pe cei care au peste media departamentului minim 25 %

SET serveroutput ON;
DECLARE
    CURSOR c_angajati IS
        SELECT 
            d.department_name,
            d.department_id,
            e.employee_id,
            e.first_name || ' ' || e.last_name AS nume,
            e.salary,
            e.commission_pct
        FROM
            employees e
        INNER JOIN
            departments d
        ON
            e.department_id = d.department_id;
    -- ok
    angajat c_angajati%ROWTYPE;
    venit NUMBER;
    venit_max NUMBER;
    venit_min NUMBER;
    venit_med NUMBER;
    venit_min_25 NUMBER;
begin
    -- aflu venit maxim
    -- aflu venit minim
    -- aflu venit mediu (asta cum se mai calculeaza?) (i guess >= avg de chestie + 25/100 * avg chestie ?)
    -- angajat, departamentul lui -> venit max pe departament (max comm si max sal?)
    -- deschid cursorul
    OPEN c_angajati;
    LOOP
        FETCH c_angajati INTO angajat; -- dap, gen ia cate o chestie pe rand din cursor
        -- si cursor = while
        EXIT WHEN c_angajati%NOTFOUND; -- dap
        -- acum iau pe departamentul acela venituri =))
        -- venit maxim
        select
            max(e.salary) + nvl(max(e.commission_pct), 0) * max(e.salary) 
        into
            venit_max
        from
            employees e
        where
            e.employee_id = angajat.department_id;
        -- venit mediu
        select
            avg(salary) + nvl(avg(commission_pct), 0) * avg(salary) 
        into
            venit_med
        from
            employees e
        where
            e.employee_id = angajat.department_id;
        -- venit minim
        select
            min(salary) + nvl(min(commission_pct), 0) * min(salary) 
        into
            venit_min
        from
            employees e
        where
            e.employee_id = angajat.department_id;
        -- >= venit_min + 25%
        venit_min_25 := venit_min + 0.25 * venit_min;
        -- venitul acestui angajat
        venit := angajat.salary + nvl(angajat.commission_pct, 0) * angajat.salary;
        if venit = venit_max THEN
            DBMS_OUTPUT.PUT_LINE(angajat.nume);
        elsif venit = venit_min then
            DBMS_OUTPUT.PUT_LINE(angajat.nume);
        elsif venit = venit_med then
            DBMS_OUTPUT.PUT_LINE(angajat.nume);
        elsif venit >= venit_min_25 THEN
            DBMS_OUTPUT.PUT_LINE(angajat.nume);
        end if;
    END LOOP;
    CLOSE c_angajati;
end;
/