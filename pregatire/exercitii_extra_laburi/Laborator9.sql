-- Laborator9
-- Folosind blocuri de PL/SQL sau T-SQL vrem ca pentru fiecare locatie(oras) vrem sa aflam:
---     - Care este cel mai bine platit job = 1p
---     - Care este job-ul cel mai des schimbat (functia schimbata in job_history, daca nu e niciuna puneti "-") = 2p
---     - Care este job-ul cu cea mai mare margine de promovare (ne uitam cat se mai poate aloca din grila salariala, vedem ce procent este salaril actual ca suma fata de count*sal_max) = 3p
---     - Care este job-ul cel mai performant (1p de performanta / angajat daca are:
--          - salariul minim 70% din sal_max,
--          - venitul minim 75%
--          - macar un manager cu acel job)
-- Sugestie Afisare:
-- NumeLocatie,CelMaiBinePlatitJob,JobCeaMaiMareMargine,JobPerformantaMaxima
-- Southlake,Programmer,Programmer,Programmer

-- 1.
with best_paid_job as (
	select
        l.city as oras, -- oras
        coalesce(j.job_title, '-') as platit_bine -- job
	from
        employees e -- din employees tre sa ajungem la oras =))
	join
        departments d
    on
        e.department_id = d.department_id
	join
        jobs j
    on
        e.job_id = j.job_id
	right outer join
        locations l
    on
        d.location_id = l.location_id
	group by
        l.city, -- iei in functie de ce ai in select
        e.salary, -- iei in functie de ce va urma pe having =))
        j.job_title,
        l.location_id -- vezi having de mai jos
	having e.salary = (
		select
            max(salary) 
		from
            employees ee 
		join
            departments dd on ee.department_id = dd.department_id 
		where
            dd.location_id = l.location_id
		) 
	OR 
        j.job_title is null
), 
-- toate sunt cte-uri, noi le am facut functii =)
-- 2.
changes_per_locations_ as (
	select
        count(*) as JobChanges, -- le numara 
        -- so ia numarul de schimbari pe cate o locatie (ar fi fost prea hardcire daca ar fi cautat din prima orasul, ig)
        d.location_id,
        jh.job_id  -- iti trebuie ptr job title mai jos =))) aici ai numai istoric 
	from
        job_history jh
	join
        departments d
    on
        d.department_id = jh.department_id
	group by
        d.location_id,
        jh.job_id  -- faci in functie de ce ai pe select =))
), 
changes_per_locations as (
	select
        coalesce(j.job_title, '-') as JobTitle,
        l.city as oras,
        coalesce(c.JobChanges, 0) as JobChanges -- ce a numarat mai sus
	from
        changes_per_locations_ c
	join
        jobs j
    on
        c.job_id = j.job_id
	right outer join
        locations l
    on
        c.location_id = l.location_id -- ok
	where c.JobChanges = ( -- vrea maximul!!!
		select
            max(JobChanges)
		from
            changes_per_locations_
		where
            location_id = c.location_id
	) or j.job_title is null
)
select
    c1.oras,
    c1.platit_bine,
    c2.JobTitle as schimbat
from
    best_paid_job c1
join
    changes_per_locations c2
on
    c1.oras = c2.oras;

-- 3. are este job-ul cu cea mai mare margine de promovare 
-- (ne uitam cat se mai poate aloca din grila salariala, 
-- vedem ce procent este salariul actual ca suma fata de count*sal_max)
with margins as (
	select 
	    l.city as oras, -- gen ce se cere
	    j.job_title as job,
	    coalesce(1 - AVG(e.salary / j.max_salary), 0) as margine --? nu stiu ce formula e asta help
        -- mate left the chat :')
        -- procent salariu actual din maxim ^
        -- margine = 1 - medie aparent
	from
        employees e -- din employees tre sa ajungem la oras =)) bafta
	join
        departments d
    on
        e.department_id = d.department_id
	join
        jobs j
    on
        e.job_id = j.job_id
	right outer join
        locations l
    on
        d.location_id = l.location_id
	group by
        l.city, -- grupezi in functie de ce ai pe select si vrei sa afli 
        j.job_title -- da =)
)
select
    mm.oras as oras,
    coalesce(job, '-') as job
from
    margins mm
right outer join
    locations l
on
    mm.oras = l.city
where margine = ( -- vrei jobul din oras cu cea mai mare margine 
	select
        max(margine)
	from
        margins m
	where m.oras = oras -- da
) or mm.job is null;

-- sau alte rezolvari la primele 3, dar cu functii =)

-- 1.
CREATE OR REPLACE FUNCTION get_best_paid_job(location_idd IN NUMBER)
RETURN varchar2
IS
-- declare
    returns varchar2(100);
BEGIN
   with location_stats as (
		select
			e.job_id,
			e.salary
		from
			employees e
		join
			departments d
		on
			e.department_id = d.department_id
		where
            d.location_id = location_idd
	)
    select
        job_id
    into
        returns
    from
        location_stats
    where
        salary = (
            select
                max(salary)
            from
                location_stats
    );
    return returns;
end;
/
select
	city
	, nvl(
		get_best_paid_job(location_id), '-'
	) best_paid_job
from
	locations;


-- 2.
create or REPLACE FUNCTION job_changed(p_location_id varchar2)
    return varchar2
as 
    returns varchar2(100);
    num_changes number;
BEGIN
    select
        count(*)
    INTO
        num_changes
    from
        job_history j
    join
        departments d
    on
        j.department_id = d.department_id
    where
        d.location_id = p_location_id
    group by
        j.job_id
    order by 1 DESC
    fetch first 1 rows only;

    select
        distinct(job_id)
    INTO
        returns
    from
        job_history j
    join
        departments d
    on
        j.department_id = d.department_id
    where
        d.location_id = p_location_id
    group by
        j.job_id
    HAVING
        count(*) = num_changes
    order by 1 DESC
    fetch first 1 rows only;

    return returns;
end;
/
select
    city
    ,nvl(job_changed(location_id), '-') as job_changed
from
    locations;
/

-- 3. 
-- in jobs avem min si max, iar nuj unde avem salariu lui -> si vedem cau cu cat mai poate creste salariul;
-- unim employees si jobs
-- tre sa normalizam, ca altfel aflam sal max si da la toti 
-- cea mai corexta -> min in loc de max -> grija la sens
create or replace function job_best_margin(location_idd int)
    return VARCHAR2
as
    returns varchar2(100);
begin
	select 
		e.job_id
    into
        returns
	from
		employees e
	join
		jobs j
	on
		e.job_id = j.job_id
	join
        departments d
    on
        e.department_id = d.department_id
	where
        d.location_id = location_idd
	group by
        e.job_id
	order by
        max((j.max_salary - e.salary) / j.max_salary) desc
    fetch first 1 rows only;
	return returns;
end;
/
select 
	city 
	,nvl(job_best_margin(location_id), '-') job_best_margin
from
	locations;

-- sau

CREATE OR REPLACE FUNCTION cevaa RETURN VARCHAR2 AS
    v_job_id VARCHAR2(100);
    v_max_margin NUMBER;
BEGIN
    SELECT e.job_id, MAX((j.max_salary - e.salary) / j.max_salary)
    INTO v_job_id, v_max_margin -- Store the results into variables
    FROM employees e
    JOIN jobs j ON e.job_id = j.job_id
    GROUP BY e.job_id
    ORDER BY 2 DESC
    FETCH FIRST 1 ROW ONLY;

    RETURN v_job_id; -- Return the job_id with the maximum margin
END cevaa;
/
SELECT cevaa() FROM dual;
/

-- 4.
with  ceva as
(select 
	e.job_id,  
	case 
		when e.salary >= 0.70 * j.max_salary  then 1 else 0
	end p1,
	case 
		when 
			(e.salary + coalesce(e.commission_pct, 0) * e.salary) >= 0.75 * (1 +
			coalesce((select 
					max(e1.commission_pct)
					from employees e1
					),0) * j.max_salary) 
		then 1 else 0
	end p2,
	case 
		when exists(
		select * -- ne uitam pe existenta, nu conteaza daca e distinct sau nu gen ca la amnageri in general -> its okay, de aia n-a zis cutarel nimic :')
		from employees sq 
		join 
		employees sq2 
		on sq.employee_id = sq2.manager_id
		where sq.job_id = e.job_id
		) then 1 else 0
	end p3
from
	employees e
join jobs j
on
	e.job_id = j.job_id
	)
	select job_id, max(p3) + sum(p1 + p2) whatever from ceva group by job_id
	order by 2 desc
    fetch first 1 rows only;
    /