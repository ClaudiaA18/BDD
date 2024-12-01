-- Exercitiul 1
SELECT  N'Aceasta este o clauză cât se poate de validă'
-- de ce am folosit N inainte de sirul constant? (mai sus)
SELECT N'Motivul pentru care am folosit litera N înaintea șirului de caractere este pentru a specifica că șirul este în format Unicode, asigurând astfel reprezentarea corectă a oricărui caracter din șir, inclusiv caractere speciale non-ASCII.'

select
	top(1000) [employee_id]
	, [first_name]
	, [last_name]
	, [email]
	, [phone_number]
	, [hire_date]
	, [job_id]
	, [salary]
	, [commission_pct]
	, [manager_id]
	, [department_id]
from
	[hr].[dbo].[employees]
go

select
	top(1000)
from
	[hr].[dbo].[employees]
go

SELECT  'Un Alias poate fi specificat în acest mod'  [Modul1]
--Cu sau fără spațiu/Paranteze Drepte
 
,'Sau așa'  AS  'Modul 2'

-- Exercitiul 2
-- clauza ce intoarce 2 coloane, cu alias
select
	e.employee_id as id
	e.commission_pct [comision]
from
	employees e
go

/* nu mai avem diacritice pentru ca sistemul sau mediul in care a fost scrisa
 sau rulata interogarea nu suporta sau nu este configurat pentru Unicode.
Acest lucru poate fi vazut in medii care nu utilizeaza prefixul N pentru siruri de caractere
*/

-- Exercitiul 3
-- pentru fiecare angajat, cate un manager
select
	e.first_name + ' ' + e.last_name as nume_ang
	, m.first_name + ' ' + m.last_name as nume_mgr
from
	employees e
	, employees m
go

-- vrem acum numai angajatul cu managerul lui pe un self join
select
	e.first_name + ' ' + e.last_name as nume_ang
	, m.first_name + ' ' + m.last_name as nume_mgr
from
	employees e
	, employees m
where
	e.manager_id = m.employee_id
go

-- sau
select
	e.first_name + ' ' + e.last_name as nume_ang
	, m.first_name + ' ' + m.last_name as nume_mgr
from
	employees e
join
	employees m
on
	e.manager_id = m.employee_id
go

-- inner poate lipsi, la fel si la outer fiind nevoie numai de left, right, full

-- avem o problema: nu sunt adusi toti angajatii -> rezolvare: 
SELECT
    e.first_name + ' ' + e.last_name AS nume_ang,
    COALESCE(m.first_name + ' ' + m.last_name, 'N/A') AS nume_mgr
-- putem avea null
FROM
    employees e
LEFT JOIN
    employees m ON e.manager_id = m.employee_id;
GO

-- Exercitiul 4
with ceva as (
	select
		e.employee_id
		, e.first_name + ' ' + e.last_name as nume_ang
		, d.department_name as numedep
		, e.manager_id
	from
		employees e
	inner join
		departments d
	on
		d.department_id = e.department_id
)
select
	e.nume_ang
	, e.nume_dep as numedep_ang
	, m.nume_ang as nume_mgr
	, m.nume_dep as numedep_mgr
from
	ceva e
inner join
	ceva m
on
	e.manager_id = m.employee_id
go

-- la fel, nu avem toate datele (pentru ca putem avea si angajati fara manager) + fara cte 
-- deci, interogari identice in inner join -> returneaza acelasi lucru
SELECT
    e.first_name + ' ' + e.last_name AS nume_ang,
    d.department_name AS numedep_ang,
    COALESCE(m.first_name + ' ' + m.last_name, 'N/A') AS nume_mgr,
    COALESCE(dm.department_name, 'N/A') AS numedep_mgr
FROM
    employees e
LEFT JOIN
    employees m ON e.manager_id = m.employee_id
LEFT JOIN
    departments d ON e.department_id = d.department_id
LEFT JOIN
    departments dm ON m.department_id = dm.department_id;
GO	

-- Exercitiul 5
/*
clauza care intoarce numele angajatilor care sunt manageri
*/
-- clasic
select
	m.first_name + ' ' + m.last_name as nume_mgr
from
	employees e
inner join
	employees m
where
	m.employee_id = e.manager_id
go

-- cu subclauza
SELECT 
    e.first_name + ' ' + e.last_name AS nume_angajat
FROM 
    employees e
WHERE 
    EXISTS (
        SELECT 1
        FROM employees m
        WHERE m.manager_id = e.employee_id
    );
go

-- Exercitiul 6
/* pentru fiecare departament, vrem sa aflam"
	- numele departamentului
	- numarul de angajati din acel departament
	- numele angajatilor in acel departament
	- BONUS: numele managerului de departament (cu subclauze)
*/
select
	d.department_name as nume_dep
	, count(d.department_name) as nrang
	, stringagg(e.first_name + ' ' + e.last_name, ' | ') as nume_ang
from
	departments d
inner join
	employees e
on
	d.department_id = e.department_id
group by
	d.department_name
having
	count(d.department_name) % 2 = 1;
go

-- si cu bonus
select
	d.department_name as nume_dep
	, count(d.department_name) as nrang
	, stringagg(e.first_name + ' ' + e.last_name, ' | ') as nume_ang
	, (
		select
			sq.first_name + ' ' + sq.last_name
		from
			employees sq
		where
			sq.employee_id = d.manager_id
) as nume_mgr
from
	departments d
inner join
	employees e
on
	d.department_id = e.department_id
group by
	d.department_name
having
	count(d.department_name) % 2 = 1;
go

select
	d.department_name as nume_dep
	, count(d.department_name) as nrang
	, stringagg(e.first_name + ' ' + e.last_name, ' | ') as nume_ang
from
	departments d
inner join
	employees e
on
	d.department_id = e.department_id
group by
	d.department_name
having
	count(d.department_name) % 2 = 1
order by nume_ang desc;
go

-- sau

select
	d.department_name as nume_dep
	, count(d.department_name) as nrang
	, stringagg(e.first_name + ' ' + e.last_name, ' | ') as nume_ang
from
	departments d
inner join
	employees e
on
	d.department_id = e.department_id
group by
	d.department_name
having
	count(d.department_name) % 2 = 1
order by count(d.department_name) desc;   
go

-- Exercitiul 7
/*
sa se genereze textul de mai jos folsind union de 3 ori
Ana are Mere
Ana are Mere
Ana are MERE
Ana are MERE
Ana are Mere
Ana are Mere
*/
-- rezolvare
SELECT 'Ana are Mere' AS Text
UNION
-- Blocul 2
SELECT 'Ana are MERE'
UNION
-- Blocul 3
SELECT 'Ana are Mere'
UNION
-- Blocul 4
SELECT 'Ana are MERE';
go

-- Exercitiul 8
/*
pentru fiecare departament pentru care deviatia standard este intre 1 si 1.5 aflati:
- numele departamentului
- numele angajatilor din acel departament
- grila salariala minima din acel departament
- grila salariala maxima din acel departament
*/
-- anumit termeni sunt folositi doar ca sa ne sperie ;)
-- pare monsruos, nu e monstruos =))
select
	d.department_name
	, stringagg(e.first_name + ' ' + e.last_name, ' | ') as nume_ang
	, min(e.salary) as salmin
	, max(e.salary) as salmax 
from	
	employees e
join
	departments d
on
	e.department_id = d.department_id
group by
	d.department_name
having
	stdev(e.salary) between 1 and 1.5;
go

