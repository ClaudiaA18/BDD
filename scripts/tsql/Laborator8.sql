-- EXEMPLU CLASIC
-- În ambele cazuri trebuie să avem grijă la constrângeri

-- Exemplu clasic, valorile sunt inserate în ordinea de creare a coloanelor
INSERT INTO [dbo].[employees] -- Dacă omitem coloanele, trebuie să respectăm tipul de date
VALUES (
	3 -- Valoare coloana 1
	,'NEW' -- Valoare coloana 2
	,'EMPLOYEE' -- Valoare coloana 3
	,'newemployee@exhample.com' -- Valoare coloana 4
	,'+40712345679' -- Valoare coloana 5
	,'2020-11-22' -- Valoare coloana 6
	,'FI_MGR' -- Valoare coloana 7
	,15002 -- Valoare coloana 8
	,NULL -- Valoare coloana 9
	,NULL -- Valoare coloana 10
	,100 -- Valoare coloana 11
	)
GO

-- Când specificăm numele coloanei, ordinea o alegem noi
INSERT INTO [dbo].[employees]
           ([employee_id]
           ,[first_name]
           ,[last_name]
           ,[email]
           ,[phone_number]
           ,[hire_date]
           ,[job_id]
           ,[salary]
           ,[commission_pct]
           ,[manager_id]
           ,[department_id]) -- Putem să precizăm una sau mai multe coloane
VALUES (
	2 -- Valoare coloana 1
	,'NEW' -- Valoare coloana 2
	,'EMPLOYEE' -- Valoare coloana 3
	,'new.employee@exhample.com' -- Valoare coloana 4
	,'+40712345678' -- Valoare coloana 5
	,'2020-11-22' -- Valoare coloana 6
	,'FI_MGR' -- Valoare coloana 7
	,15000 -- Valoare coloana 8
	,NULL -- Valoare coloana 9
	,NULL -- Valoare coloana 10
	,100 -- Valoare coloana 11
	)
GO


-- Tabela clonă va avea coloane care au numele și tipul de date al rezultatului
-- Toate constrângerile și toți indecșii se pierd (nu se știe de existența lor)
SELECT *
INTO [dbo].[employees_clone]
FROM [dbo].[employees]

INSERT INTO [dbo].[employees_clone]
SELECT *
FROM [dbo].[employees]

-- Ex. 1 Ștergere a tabelei [employees_clone] dacă există, apoi clonare și inserare doar a angajaților noi

SELECT * FROM [dbo].[employees_clone];

INSERT INTO [dbo].[employees_clone]
SELECT * 
FROM [dbo].[employees] AS src
WHERE NOT EXISTS (
    SELECT 1 
    FROM [dbo].[employees_clone] AS dest
    WHERE dest.employee_id = src.employee_id
);
SELECT * FROM [dbo].[employees_clone];

-- Ex. 2 Mărirea salariului angajaților cu 15% doar dacă sunt într-un departament 
-- ce conține un număr par de angajați
UPDATE e
SET e.salary = e.salary * 1.15
FROM [dbo].[employees] e
INNER JOIN (
    SELECT department_id
    FROM [dbo].[employees]
    GROUP BY department_id
    HAVING COUNT(employee_id) % 2 = 0 
) d ON e.department_id = d.department_id;

SELECT * FROM [dbo].[employees];

-- Ex. 3 Ștergerea angajaților din [employees_clone] care au departamentul situat în “US”
DELETE e
FROM [dbo].[employees_clone] e
INNER JOIN [dbo].[departments] d ON e.department_id = d.department_id
INNER JOIN [dbo].[locations] l ON d.location_id = l.location_id
WHERE l.country_id = 'US';

SELECT * FROM [dbo].[employees_clone];

-- Ex. 4 Clonarea tabelei [departments] doar pentru departamentele care au litera "E" 
-- în numele lor și apoi golirea ei folosind TRUNCATE

SELECT *
INTO [dbo].[departments_clone]
FROM [dbo].[departments]
WHERE department_name LIKE '%E%';

TRUNCATE TABLE [dbo].[departments_clone];
SELECT * FROM [dbo].[departments_clone];

-- Ex. 5 Sincronizarea salariului și bonusului în [employees] din [employees_clone]
-- doar pentru angajații cu un [job_id] ce conține litera "A"
MERGE INTO [dbo].[employees] AS t
USING [dbo].[employees_clone] AS s
ON t.employee_id = s.employee_id
WHEN MATCHED AND t.job_id LIKE '%A%' THEN
    UPDATE SET
        t.salary = s.salary,
        t.commission_pct = s.commission_pct;

SELECT * FROM [dbo].[employees];

SELECT *
FROM [dbo].[employees] AS t
WHERE t.job_id LIKE '%A%';


-- Ex. 6 Ne dăm seama că nu este suficient să ștergem tabelele, dorim și să scăpăm de ele. 
-- Scrieți o clauză care face asta. (folosiți DROP)
DECLARE @SQL NVARCHAR(500);
DECLARE @Cursor CURSOR;

-- Inițializarea cursorului pentru a găsi toate tabelele care conțin "CLONE" în nume
SET @Cursor = CURSOR FAST_FORWARD FOR 
    SELECT 'DROP TABLE [' + TABLE_SCHEMA + '].[' + TABLE_NAME + ']'
    FROM INFORMATION_SCHEMA.TABLES
    WHERE TABLE_NAME LIKE '%CLONE';

-- Deschiderea cursorului și rularea comenzii de DROP pentru fiecare tabel găsit
OPEN @Cursor;
FETCH NEXT FROM @Cursor INTO @SQL;

WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT @SQL;  -- Afișează comanda pentru verificare
    EXEC sp_executesql @SQL;
    FETCH NEXT FROM @Cursor INTO @SQL;
END

-- Închiderea și dealocarea cursorului
CLOSE @Cursor;
DEALLOCATE @Cursor;

-- Ex. 7 Scrieți o funcție care întoarce salariul unui angajat și modificați funcția de mai sus.

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
