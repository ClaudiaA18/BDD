-- Folosind blocuri de PL/SQL sau T-SQL vrem ca pentru fiecare locatie(oras) vrem sa aflam:
-- - Care este cel mai bine platit job = 1p

create or alter function get_best_paid_job(@location_id int)

returns varchar(100) AS
begin
    declare @returns varchar(100);
    with location_stats as(
        select e.job_id, e.salary
        from employees e
        join departments d ON e.department_id = d.department_id
        where d.location_id = @location_id
    )
    select @returns=job_id
    from location_stats
    where salary = (select max(salary) from location_stats)
    
    return @returns;
end;
go

select 
    city, 
    coalesce(dbo.get_best_paid_job(location_id), '-') as best_paid_job
from locations;
go

-- - Care este job-ul cel mai des schimbat (functia schimbata in job_history, daca nu e niciuna puneti "-") = 2p
create or alter function get_most_changed_job(@location_id int)
returns varchar(100)
as
begin
    declare @most_changed_job varchar(100);

    with job_changes as (
        select 
            j.job_title,
            count(jh.employee_id) as changes_count
        from job_history jh
        join jobs j on jh.job_id = j.job_id
        join departments d on jh.department_id = d.department_id
        where d.location_id = @location_id
        group by j.job_title
    )

    select top 1
        @most_changed_job = job_title
    from job_changes
    order by changes_count desc;

    return @most_changed_job;
end;
go

select 
    l.city as location,
    coalesce(dbo.get_most_changed_job(l.location_id), '-') as most_changed_job
from locations l;
go


-- - Care este job-ul cu cea mai mare margine de promovare (ne uitam cat se mai poate aloca din grila salariala, vedem ce procent este salariul actual ca suma fata de (count*sal_max) = 3p
create or alter function get_job_max_promotion(@location_id int)
returns varchar(100)
as
begin
    declare @job_max varchar(100);

    with salary as (
        select 
            j.job_title,
            count(e.employee_id) as employee_count,
            sum(e.salary) as total_salary,
            (count(e.employee_id) * j.max_salary) as max_possible_salary,
            (1.0 - (sum(e.salary) * 1.0) / (count(e.employee_id) * j.max_salary)) as margin
        from employees e
        join jobs j on e.job_id = j.job_id
        join departments d on e.department_id = d.department_id
        where d.location_id = @location_id
        group by j.job_title, j.max_salary
    )
    select top 1
        @job_max  = job_title
    from salary
    order by margin desc;

    return @job_max;
end;
go

select 
    l.city as location,
    coalesce(dbo.get_job_max_promotion(l.location_id), '-') as job_max_promotion
from locations l;
go

-- - Care este job-ul cel mai performant (1p de performanta / angajat daca are:
					-- salariul minim 70% din sal_max,
					-- venitul minim 75% din sal_max,
					-- macar un manager cu acel job)

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
		select *
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
	select top 1 job_id, max(p3) + sum(p1 + p2) whatever from ceva group by job_id
	order by 2 desc
go


-- Sugestie Afisare:
-- NumeLocatie,CelMaiBinePlatitJob,JobCeaMaiMareMargine,JobPerformantaMaxima
-- Southlake,Programmer,Programmer,Programmer

select 
    l.city as Location,
    coalesce(dbo.get_best_paid_job(l.location_id), '-') as BestPaidJob,
    coalesce(dbo.get_most_changed_job(l.location_id), '-') as MostChangedJob,
    coalesce(dbo.get_job_max_promotion(l.location_id), '-') as JobWithMaxMargin,
    coalesce(dbo.get_best_performing_job(l.location_id), '-') as BestPerformingJob
from
    locations l;

go