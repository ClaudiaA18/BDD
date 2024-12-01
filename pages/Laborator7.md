# Laborator 7 - SQL Server
## Interogari
### Sintaxa
```
[WITH] --CTE
SELECT
[INTO] -- Putem folosi rezultatul instruțiunii select pentru a popula o tabelă deja existentă
[FROM] -- Sursa sau sursele de date de date
[[[CROSS]|[INNER]|[LEFT|RIGHT|FULL OUTER]] JOIN] -- Putem folosi mai multe surse de date cu condiții speciale
[WHERE] -- Condițiile de filtrare a datelor deja existente
[GROUP BY] -- Agregarea datelor deja existente până în acest punct
[HAVING] -- Condiții pentru noile grupări
[ORDER BY] -- Ordonare, se pot folosi alias  * uri

-- comentarii
-- Primul
-- mod
-- Aici trebuie să avem caractele speciale '--' pe fiecare rând.
 
/*
Al
doilea
mod
 
Aici trebuie doar să deschidem comentariul înainte de primul rând 
și să-l închidem după ultimul.
Nu este nevoie să avem vreun string special pe fiecare rând.
*/
```

****

```
SELECT  N'Aceasta este o clauză cât se poate de validă'
```

**Exercitiul 1:**

> de ce am folosit N inainte de sirul constant? (mai sus)
```
SELECT N'Motivul pentru care am folosit litera N înaintea șirului de caractere este pentru a specifica că șirul este în format Unicode, asigurând astfel reprezentarea corectă a oricărui caracter din șir, inclusiv caractere speciale non-ASCII.'
```

## Coloane, top si alias
- oricate coloane
- la fel ca la oracle, `*` pentru toate sau separate prin `,`
- ceva ce ti ar face SSMS automat, cu top, ca sa vezi [anumite] coloane

```
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
```
la fel de bine merge si asta ;)
```
select
	top(1000)
from
	[hr].[dbo].[employees]
go
```
- alias cu spatiu" (N)VARCHAR
```
SELECT  'Un Alias poate fi specificat în acest mod'  [Modul1]
--Cu sau fără spațiu/Paranteze Drepte
 
,'Sau așa'  AS  'Modul 2'
```

**Exercitiul 2:**

> clauza ce intoarce 2 coloane, cu alias
```
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
```

## Surse de date, `where` si `join`
- `where` este la fel in toate limbajele
- nu tine cont de aliasuri (bafta)
- este importanta ordinea operatorilor
- datele fie sunt adause si apoi filtrate, fie sunt aduse deja filtrate
- exista mai multe tipuri de `join`: cross join (produs cartezian), inner join, left, right, full outer join
- produs cartezian:
```
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

```

## CTE (Common Table Expression)
- mod de a aduce date pentru o clauza inainte de o executa efectiv
```
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
```

## Subclauze
- o clauza in interiorul altei clauze si se poate folosi de valorile din nivelurile superioare
- nivel maxim: 32

**Exercitiul 5:**

> clauza care intoarce numele angajatilor care sunt manageri
```
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
```

## Grupari, `agregate` si `having`
- in afara de count(*), functiile de agregare ignora valori null
- exemple
	- approx_count_distinct
	- avg
	- count
	- max
	- min
	- sum
	- var (variatie)
	- stdev (deviatie standard)
	- stringagg (ia toate expresiile din linii si le face un singur string)
- mai sunt si alte functii care apar numai impreuna cu `group by` (dispare notiunea de individ si apare notiunea de intreg) 
- `having`: `where` pe `group by` =))
```
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
```

## `order by`
- sorteaza datele dupa obtinerea lor
- top tine cont de ordine
- ascendenta (implicit) sau descendenta (daca folosesti desc)
- sortare pe mai multe crietrii, lista despratita prin virgula
- tine cont de alias (este executata la final)
```
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
```
- sau
```
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
```

## `Union`, `except`, `intersect`
- operatori definiti special pentru multimi
- fiecare coloana trebuie sa fie de acelasi tip
- ordinea conteaza (trebuie sa coincide la fiecare multime)!!! -> parantezeeeee!!!
- [numele] coloane(lor) este/sunt dat(e) de primul tabel
```
(
  (
    SELECT 'Ana are Mere'
    UNION
    SELECT 'Dar are si Pere'
  )
  EXCEPT
  (
    SELECT 'Ana nu are Mere'
  )
)
INTERSECT
(
  SELECT 'Ana are Mere'
)
```

**Exerctiul 7:**

> sa se genereze textul de mai jos folsind union de 3 ori
```
-- output
Ana are Mere
Ana are Mere
Ana are MERE
Ana are MERE
Ana are Mere
Ana are Mere
```

```
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
```

**Exercitiul 8:**

> pentru fiecare departament pentru care deviatia standard este intre 1 si 1.5 aflati:
>	- numele departamentului
> 	- numele angajatilor din acel departament
>	- grila salariala minima din acel departament
>	- grila salariala maxima din acel departament
```
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

```

## Variabile
- aparent exista si aici variabile, chit ca e orientat tabel (adica, nu ai tipuri!)
- trebuie sa tinem cont de duarta de viata/scope
```
-- Putem să declarăm variabile fără valoare
DECLARE @VAR_WITH_NO_VALUE NVARCHAR(MAX);
-- Sau care au deja valoare
DECLARE @VAR_WITH_VALUE NVARCHAR(MAX) = N'Se știe';
 
-- Se poate seta în mod explicit valoare unei variabile
SET @VAR_WITH_NO_VALUE = NULL;-- Atenție la tip
 
-- Se poate seta ca rezultat al unei clauze, oricare ar fi el
SELECT TOP 1 @VAR_WITH_VALUE = N'Se știe'
FROM [hr].[dbo].[EMPLOYEES];
 
-- Putem afișa valoare unei variabile
PRINT (@VAR_WITH_NO_VALUE);
PRINT (@VAR_WITH_VALUE);
```
