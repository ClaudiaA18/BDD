-- de la Alex (bonus):
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
        into intreg
        from job_history
        where employee_id = angajati(contor).id_angajat
        fetch first 1 rows only;

        dbms_output.Put_line(angajati(contor).numeangajat);
        exception
            when no_data_found then
                null;
    end;
END LOOP;
End;
/

select 1 as ceva_altceva, 'ana are mere' as altceva_ceva2
from employees
fetch first 5 rows only;

-- -------------------------------------------------------------

-- de la Maria:

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
-- TODO
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

-- ------------------------------------------------------------------

/*
Sa se scrie un bloc PL/SQL care printeaza angajatii care detin venitul maxim din fiecare departament sau detin un salariu peste media job-ului lor cu cel putin 15%. Sa se poata face distinctia intre ei.
*/
SET serveroutput ON;
BEGIN
    FOR angajat IN (SELECT e.ename,
                           e.sal + Nvl(e.comm, 0) Venit,
                           e.job,
                           'Venit Maxim'          Criteriu
                    FROM   emp e
                    WHERE  e.sal + Nvl(e.comm, 0) IN (SELECT Max(sal + Nvl(comm,
                                                                 0))
                                                      FROM   emp
                                                      GROUP  BY deptno)
                    UNION
                    SELECT e.ename,
                           e.sal + Nvl(e.comm, 0) Venit,
                           e.job,
                           'Venit Peste Medie'    Criteriu
                    FROM   emp e
                    WHERE  e.sal + Nvl(e.comm, 0) > (SELECT 1.15 * Avg(
                                                            sal + Nvl(comm, 0))
                                                     FROM   emp
                                                     WHERE  job = e.job)) LOOP
        dbms_output.Put_line(Rpad(angajat.ename, 30)
                             || Rpad(angajat.venit, 10)
                             || Rpad(angajat.job, 10)
                             || Rpad(angajat.criteriu, 20));
    END LOOP;
END; 
/

-- -------------------------------------------------------------------

/* Sa se gaseasca nivelul ierarhic maxim
Se considera ca angajatul care nu are niciun angajat subaltern direct (nu este managerul nimanui) are nivelul 0
Managerul lui are nivelul minim 1 (daca mai are un subaltern de nivel x, atunci are maximul dintre x si 1 + x)
*/

-- o luam de jos in sus
-- de sus in jos ar fi problematic, sau ceva de genul ??
set serveroutput ON;

DECLARE
    -- TYPE data_angajat IS TABLE OF employees%ROWTYPE;
    -- variabila_angajat data_angajat;
    nivel_maxim INT DEFAULT 0;
    nivel_curent INT DEFAULT 1;
    manager_curent employees%ROWTYPE;
    id_manager_curent employees.manager_id%TYPE;
BEGIN
    -- asta daca nu faceam cu for
    -- SELECT * 
    -- BULK COLLECT INTO variabila_angajat 
    -- FROM employees
    -- WHERE employee_id NOT IN (SELECT DISTINCT manager_id FROM employees);
    FOR angajat in (
        SELECT * 
        FROM employees
        WHERE employee_id NOT IN (SELECT DISTINCT manager_id 
                                  FROM employees
                                  WHERE manager_id IS NOT NULL)
    )
    LOOP
        -- asta e pentru un singur nivel, deci noi vrem sa facem pentru toate nivelele
        -- asa ca facem cu WHILe
        -- IF angajat.manager_id IS NOT NULL THEN
        --     SELECT *
        --     INTO manager_curent 
        --     FROM employees
        --     WHERE employee_id=angajat.manager_id;
        -- END IF;
        nivel_curent := 1;
        id_manager_curent := angajat.manager_id;

        WHILE (id_manager_curent IS NOT NULL)
            LOOP
                SELECT *
                INTO manager_curent 
                FROM employees
                WHERE employee_id=id_manager_curent;

                IF nivel_maxim < nivel_curent THEN
                nivel_maxim := nivel_curent;
                END IF;
                
                nivel_curent := nivel_curent + 1;
                id_manager_curent := manager_curent.manager_id;
            END LOOP;
        
        -- asta e tot pentru comentariul de mai sus
        -- IF nivel_maxim < nivel_curent THEN
        --     nivel_maxim := nivel_curent;
        -- END IF;

    END LOOP;

    dbms_output.put_line(nivel_maxim);
END;
/

-- ------------------------------------------------------------------

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

-- ----

select c.country_name, string_agg (e.[first_name] + ' ' + e.[last_name], '; ') [ numecomplet]
from employees e
join employees m on e.[manager_id] = m.[employee_id]
join departments d on e.[department_id] = d.[department_id]
join employees mnd on d.[manager_id] = mnd.[employee_id]
join locations l on d.[location_id] = l.[location_id]
join countries c on l.[country_id] = c.[country_id]
where (substring(e.[job_id], 4, len(e.[job_id])) != substring(m.[job_id], 4, len(m.[job_id]))) 
	   or (substring(e.[job_id], 1, 2) != substring(m.[job_id], 1, 2))
group by c.country_name

-- ------------------------------------------------------------------

/*
	Pentru fiecare functie sa se calculeze urmatoarele statistici:
		1. cati angajati au salariul peste jumate din grila posibila (in jobs ai salMin si salMax)
		2. cat de popular este acest job (facem un rank per departament si este cu atat mai popular cu cat sunt mai multi oameni cu acest job in departament)
		3. daca exista sansa de promovare sau salariala sau ca si pozitie (promovare salariala = mai este macar 10% pana la salMax si 
			promovare ca pozitie = exista un manager de dep care are aceeasi functie ca si noi + nu sunt deja manager)
*/

WITH 
INFO_JOBS AS
(
	SELECT J.[JOB_TITLE] AS TITLU, E.DEPARTMENT_ID AS DEP,
	--	RANK () OVER (PARTITION BY E.[DEPARTMENT_ID] ORDER BY COUNT(*)) AS POPULARITATE
	COUNT(*) AS NUMAR_PERS
	FROM JOBS J
	JOIN EMPLOYEES E ON J.[JOB_ID] = E.[JOB_ID]
	GROUP BY JOB_TITLE, DEPARTMENT_ID
	--	ORDER BY 2, 3
), 
INFO_RANK AS (
	--	SQ = SUBQUERY
	--	rank custom mai jos
	SELECT TITLU, DEP , (SELECT COUNT(*) 
						FROM INFO_JOBS IJSQ 
						WHERE IJ.[DEP] = IJSQ.[DEP]
						AND IJ.TITLU != IJSQ.[TITLU]
						AND IJ.NUMAR_PERS > IJSQ.NUMAR_PERS) AS RANK_SPECIAL --DESC FARA EGALITATE
	FROM INFO_JOBS IJ
)


SELECT TITLU, STRING_AGG(CONVERT(varchar, DEP) + ':' + CONVERT(varchar, RANK_SPECIAL), ';') --DESC FARA EGALITATE
FROM INFO_RANK
GROUP BY TITLU

-- --------------------------------------------------------------------

--Folosind blocuri de PL/SQL sau T-SQL vrem ca pentru fiecare locatie(oras) vrem sa aflam:
--- Care este cel mai bine platit job = 1p
--- Care este job-ul cel mai des schimbat (functia schimbata in job_history, daca nu e niciuna puneti "-") = 2p
--- Care este job-ul cu cea mai mare margine de promovare (ne uitam cat se mai poate aloca din grila salariala, vedem ce procent este salaril actual ca suma fata de count*sal_max) = 3p
--- Care este job-ul cel mai performant (1p de performanta / angajat daca are:
--salariul minim 70% din sal_max,
--venitul minim 75%
--macar un manager cu acel job)
--Sugestie Afisare:
--NumeLocatie,CelMaiBinePlatitJob,JobCeaMaiMareMargine,JobPerformantaMaxima
--Southlake,Programmer,Programmer,Programmer

with best_paid_job as (
	select l.city as "City", coalesce(j.job_title, '-') as "Best paid job"
	from employees e
	join departments d on e.department_id = d.department_id
	join jobs j on e.job_id = j.job_id
	right outer join locations l on d.location_id = l.location_id
	group by l.city, e.salary, j.job_title, l.location_id
	having e.salary = (
		select max(salary) 
		from employees ee 
		join departments dd on ee.department_id = dd.department_id 
		where dd.location_id = l.location_id
		) 
	or j.job_title is null
), 

changes_per_locations_ as (
	select count(*) as JobChanges, d.location_id, jh.job_id 
	from job_history jh
	join departments d on d.department_id = jh.department_id
	group by d.location_id, jh.job_id 
), 

changes_per_locations as (
	select coalesce(j.job_title, '-') as JobTitle, l.city, coalesce(c.JobChanges, 0) as JobChanges
	from changes_per_locations_ c
	join jobs j on c.job_id = j.job_id
	right outer join locations l on c.location_id = l.location_id
	where c.JobChanges = (
		select max(JobChanges)
		from changes_per_locations_
		where location_id = c.location_id
	) or j.job_title is null
)

select c1.City, c1.[Best paid job], c2.JobTitle
from best_paid_job c1
join changes_per_locations c2 on c1.City = c2.city

with margins as (
	select 
	l.city as City, 
	j.job_title as JobTitle,
	coalesce(1 - AVG(e.salary / j.max_salary), 0) as margine
	from employees e
	join departments d on e.department_id = d.department_id
	join jobs j on e.job_id = j.job_id
	right outer join locations l on d.location_id = l.location_id
	group by l.city, j.job_title
)

select mm.city, coalesce(JobTitle, '-') as JobTitle
from margins mm
right outer join locations l on mm.city = l.city
where margine = (
	select max(margine)
	from margins m
	where m.city = city
) or mm.JobTitle is null;

-- nu merge
select l.city as "City", j.job_title as JobTitle,
sum(case when e.salary >= 0.7 * j.max_salary then 1 else 0 end) as P1,
--sum(case when e.salary + coalesce(e.salary * e.commission_pct, 0) >= 0.75 * j.max_salary + coalesce(e.salary * (select max(commission_pct)
--																											from employees
--																											where job_id = j.job_id), 0) then 1 else 0 end) as P2,
case when (select count(*)
		   from employees esq
		   inner join employees msq on msq.employee_id = esq.manager_id
		   where msq.job_id = j.job_id) > 0 then 1 else 0 end as P3
from employees e
join departments d on e.department_id = d.department_id
join jobs j on e.job_id = j.job_id
join locations l on d.location_id = l.location_id
group by l.city, j.job_title, j.job_id

-- de la Alex
-- pentru fiecare functie vrem sa vedem urmatoarele informatii
-- 1. popularitatea in fiecare departament (sales, 10:1; 20:2; 50:3) (se gaseste in dep 10, 20, 50, cea mai populara e 10, apoi 20 apoi 50, gen dupa count) - 1p
-- 2. daca pentru functie exista sansa de promovare, adica pentru un angajat se mai poate mari salariul macar cu 10% si sa fie in continuare sub salmax (sa ramana in grila) - 3p
-- sau exista un manager sau manager de departament (cu functia lui: 2 tipuri de promovari (bani si resp))
-- daca angajatul nu este un manager, sa nu fie deja manager 
-- 3. in medie, nu se aloca foarte multi bani pentru aceasta functie, adica este maxim 60% dintre (salmin+salmax)/2 - 2p

-- cursor peste ang si faci ceva cu grila
-- manager si ...
-- contor cu cursor si vedem daca exista, la 1
-- noi vrem pe functii nu pe angajati, deci dam un where pe.... sau dau ca param intr-o functie si apelam fct 
-- where jobid = 
-- fara cursori n-ai nico sansa
-- select mostrous cu groiup by job
-- nu am fct nici macar partea de manager id
-- si mai trebui manager id din departm si 
-- functie ca sa fac cu un select si dam ca aparam jid si ...

-- ??
declare @sql nvarchar(500)

declare @Cursor
declare @first_name NVARCHAR(50)
declare @lastt_name NVARCHAR(50)
declare @min_sal int
declare @max_sal int
declare @salary int
declare @eid int
declare @exists int = 0
declare @empJID varchar(50)
declare @manJID varchar(50)
declare @num int

set
	@Cursor = CURSOR FAST_FORWARD FOR
	SELECT e.salary, e.employee_id, max_salary, min_salary, e.job_id, m.job_id
	from employees e
	join jobs j on e.job_id = j.job_id
	join employees m on e.manager_id = m.employee_id
	where e.job_id = 'IT_PROG';

open @Cursor
fetch next from @Cursor into @sakaey, @eid, @did, @max_sal, @min_sal
while (@@FETCH_STATUS = 0 or @exists = 0)
begin
	if (@salary * 1.1 <= @max_sal)
		set @exists = 1
	if (@empJID = @manJID)
		set @exists = 1
	select @num = count(employee_id)
	from employees
	-- where department_id = @did
	where manager_id = @eid;
	-- if @num >= 1
	if (@empJID = @manJID and @num = 0)
		set @exists = 1
		
fetch next from @Cursor into @salary, @eid, @max_sal, @min_sal, @empJID, @manJID
end
close @Cursor

if (@exists = 1)
print('200 - ok')
deallocate @Cursor

-- Ex. 2
declare @SQL NVARCHAR(500)

declare @Cursor CURSOR
declare @first_name NVARCHAR(50)
declare @last_name NVARCHAR(50)
declare @max_sal INT
declare @min_sal INT
declare @salary INT
declare @eid INT
declare @exists INT
declare @empJID VARCHAR(20)
declare @manJID VARCHAR(20)
declare @num INT

SET @Cursor = CURSOR FAST_FORWARD FOR 
    SELECT e.salary, e.employee_id, max_salary, min_salary, e.job_id, m.job_id
    FROM employees e
    JOIN jobs j on e.job_id = j.job_id
    JOIN employees m on e.manager_id = m.employee_id
   

OPEN @Cursor
FETCH NEXT FROM @Cursor INTO @salary, @eid, @max_sal, @min_sal, @empJID, @manJID
WHILE (@@FETCH_STATUS = 0 OR @exists = 0)
BEGIN
    if (@salary * 1.1 <= @max_sal)
        set @exists = 1
    if (@empJID = @manJID)
        set @exists = 1
    SELECT @num = COUNT(employee_id)
    FROM employees
    WHERE manager_id = @eid
    if (@empJID = @manJID AND @num > 0)
        set @exists = 1
    FETCH NEXT FROM @Cursor INTO @salary, @eid, @max_sal, @min_sal, @empJID, @manJID
END
CLOSE @Cursor

if (@exists = 1)
    print 'Exista sansa de promovare'
else
    print 'Nu exista sansa de promovare'

DEALLOCATE @Cursor