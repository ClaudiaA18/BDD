Laborator9_1
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
																										where job_id = j.job_id), 0) then 1 else 0 end) as P2,
case when (select count(*)
		   from employees esq
		   inner join employees msq on msq.employee_id = esq.manager_id
		   where msq.job_id = j.job_id) > 0 then 1 else 0 end as P3
from employees e
join departments d on e.department_id = d.department_id
join jobs j on e.job_id = j.job_id
join locations l on d.location_id = l.location_id
group by l.city, j.job_title, j.job_id