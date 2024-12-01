-- EXEMPLU CLASIC
-- În ambele cazuri trebuie să avem grijă la constrângeri

-- Exemplu clasic, valorile sunt inserate în ordinea crearii coloanelor
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

-- clonare tabela
-- Tabela clonă va avea coloane care au numele și tipul de date al rezultatului
-- Toate constrângerile și toți indecșii se pierd (nu se știe de existența lor)
SELECT *
INTO [dbo].[EMPLOYEE_CLONE]
FROM [dbo].[EMPLOYEES]
go

-- repopulare clona cu date originale:
INSERT INTO [dbo].[EMPLOYEE_CLONE]
SELECT *
FROM [dbo].[EMPLOYEES]
go

-- Exercitiul 1
-- doar ce este nou de pus in clona
-- deci noi vrem inserted din employee sa il punem in clona
CREATE TRIGGER ceva 
ON [dbo].[EMPLOYEE_CLONE]
FOR INSERT
AS
BEGIN
  SELECT * FROM INSERTED
END
go

-- sau
CREATE TRIGGER ceva2
ON [dbo].[EMPLOYEE_CLONE]
AFTER INSERT
AS
BEGIN
  -- Inserează înregistrările noi în EMPLOYEE_CLONE, doar dacă nu există deja acolo
  INSERT INTO [dbo].[EMPLOYEE_CLONE] (email, employee_id, first_name, last_name, phone_number,
  hire_date, job_id, salary, commission_pct, manager_id, department_id) -- tre sa le dau pe toate
  SELECT email, employee_id, first_name, last_name, phone_number,
  hire_date, job_id, salary, commission_pct, manager_id, department_id
  FROM INSERTED
  WHERE NOT EXISTS (
    SELECT 1 
    FROM [dbo].[EMPLOYEE_CLONE] AS clone
    WHERE employee_id = INSERTED.employee_id
  )
END
GO

-- Exercitiul 2
-- sa se mareasca salariul angajatilor y 15% doar daca sunt intr-un departament care contine un numar par de angajati
UPDATE [dbo].[EMPLOYEE_CLONE]
SET salary = salary + (0.15 * salary)
WHERE department_id IN ( -- buna dimi
    SELECT department_id
    FROM EMPLOYEE_CLONE
    GROUP BY department_id
    HAVING COUNT(*) % 2 = 0
)
go

-- Exercitiul 3
-- sa se stearga angajatii care au departamentul situat in 'US'
delete
from
	[dbo].[EMPLOYEE_CLONE]
where
	employee_id
in (
	select
		employee_id
	from
		EMPLOYEE_CLONE 
	inner join
		departments
	on
		EMPLOYEE_CLONE.department_id = departments.department_id
	inner join
		locations
	on
		departments.location_id = locations.location_id
	where
		locations.country_id = 'US'
)
go

-- Exercitiul 4
-- clonati tabela departaments doar pentru cele care au 'e' in numele lor si apoi folositi truncate pe acea clona
SELECT *
INTO [dbo].[DEPARTMENTS_CLONE]
FROM [dbo].[DEPARTMENTS] where department_name like 'E%'
go

select * from [dbo].[DEPARTMENTS_CLONE]
go

truncate table [dbo].[DEPARTMENTS_CLONE] 
go

MERGE INTO [dbo].[EMPLOYEE_CLONE] AS [Target  ]
USING [dbo].[employees] AS [Source]
	ON Target.[employee_id] = [Source].[employee_id]
WHEN MATCHED
	THEN
		UPDATE
		SET [Target].[salary] = [Source].[SALARY]
WHEN NOT MATCHED
	THEN
		INSERT
		VALUES ([employee_id]
           ,[first_name]
           ,[last_name]
           ,[email]
           ,[phone_number]
           ,[hire_date]
           ,[job_id]
           ,[salary]
           ,[commission_pct]
           ,[manager_id]
           ,[department_id]);
-- Din păcate este nevoie să precizăm toate coloanele/valorile pentru INSERT

-- Exercitiul 5
/*
vrem sa aducem datele modificate inapoi in original (doar salariul si bonusul) folosind merge clona (din clona, logic), doar pentru angajatii care au job ce contine macar/cel putin un 'a' (altfel, nu facem nimic)
*/
MERGE INTO [dbo].[employees] AS t
USING [dbo].[EMPLOYEE_CLONE] AS s
ON t.employee_id = s.employee_id
WHEN MATCHED AND t.job_id LIKE '%A%' THEN -- matched e conditia de match lol
-- gen cand si-a dat match pe conditie (ca altfel, zice ca nu face nimic, deci ce e acolo nu se executa mereu)
-- bonus = comision
    UPDATE SET
        t.salary = s.salary,
        t.commission_pct = s.commission_pct;
go

-- vedem modificarile
SELECT * FROM [dbo].[employees];
go

SELECT *
FROM [dbo].[employees] AS t
WHERE t.job_id LIKE '%A%';
go

-- cursori
-- Declarațiile necesare
DECLARE @TableName NVARCHAR(128);
DECLARE @SQL NVARCHAR(MAX);

-- Crearea cursorului pentru tabelele care sunt considerate clone
DECLARE table_cursor CURSOR FOR
SELECT table_name
FROM information_schema.tables
WHERE table_name LIKE '%_clone';

-- Deschiderea cursorului și preluarea primului tabel
OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @TableName;

-- Iterarea prin toate tabelele clone
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Construirea și executarea instrucțiunii SQL dinamice pentru TRUNCATE
    SET @SQL = N'TRUNCATE TABLE ' + QUOTENAME(@TableName);
    EXEC sp_executesql @SQL;

    -- Trecerea la următorul tabel
    FETCH NEXT FROM table_cursor INTO @TableName;
END;

-- Închiderea și dezalocarea cursorului
CLOSE table_cursor;
DEALLOCATE table_cursor;

-- Exercitiul 6
-- nu este suficient sa stergem numai tabelele, ci si sa scapam de ele (de tot) -> drop
DECLARE @SQL NVARCHAR(500)
 
DECLARE @Cursor CURSOR
 
SET @Cursor = CURSOR FAST_FORWARD FOR SELECT  'DROP TABLE [' + TABLE_SCHEMA + '].[' +  TABLE_NAME + ']' FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME LIKE '%CLONE'
 
 
OPEN @Cursor FETCH NEXT FROM @Cursor INTO @SQL
 
WHILE (@@FETCH_STATUS = 0)
BEGIN
print(@SQL)
EXEC sp_executesql @SQL
FETCH NEXT FROM @Cursor INTO @SQL
END
 
CLOSE @Cursor 
 
DEALLOCATE @Cursor
 
GO

-- Exercitiul 7
/*
functie ce primeste ca parametru id_ang si salariu (default salariu angajat respectiv) si returneaza numarul angajatilor subordonati lui, care au salariul <= cu acel salariu dat ca parametru
*/
CREATE FUNCTION f(@id INT)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @returns DECIMAL(10,2);

    SELECT @Salary = salary
    FROM employees
    WHERE employee_id = @id;

    RETURN @returns;
END;

-- Exercitiul 8
-- de modificat 7 ca sa intoarca si salariul unui angajat
CREATE FUNCTION f(@mgr_id INT, @salariu DECIMAL(10,2) = NULL)
RETURNS INT
AS
BEGIN
    -- Verificăm dacă salariul a fost specificat, altfel îl preluăm pentru angajatul dat
    IF @salariu IS NULL
    BEGIN
	select @salariu = e.manager_id from employees e where e.manager_id = @mgr_id;
    END

    -- Dacă salariul managerului nu poate fi determinat, întoarcem 0
    IF @salariu IS NULL
        RETURN 0;

    -- selectam subordonații cu salariu mai mic sau egal
    DECLARE @returns INT;
    SELECT @returns = COUNT(*)
    FROM employees
    WHERE manager_id = @mgr_id AND salary <= @salariu;

    RETURN @returns;
END;

-- Exercitiul 9
/*
sa se creeze procedura [dbo].[DEPT_MGR_INFO] care are ca parametru de intrare id_dep si ca valoare returnata nume_dep si insereaza intr-o alta tabela urmatoarele

id fiecare manager care lucreaza in acel departament (si are macar/cel putin un subaltern)
nume manager
numar angajati in subordine, care au salariul <= decat el
data executie procedura
*/
CREATE TABLE ceva(
    mgr_id INT,
    nume_mgr NVARCHAR(255),
    nr_sub INT,
    data_exec DATETIME,
    nume_dep NVARCHAR(255)
);

CREATE FUNCTION dbo.cati_sub(@mgr_id INT)
RETURNS INT
AS
BEGIN
    DECLARE
	@nr_sub INT;
    SELECT
	@nr_sub = COUNT(*)
    FROM
	employees
    WHERE
	manager_id = @mgr_id
    AND
	salary <= (
		SELECT
			salary
		FROM
			employees
		WHERE
			employee_id = @mgr_id);
    RETURN @nr_sub;
END;

CREATE PROCEDURE dbo.DEPT_MGR_INFO
    @id_dep INT
AS
BEGIN    
    DECLARE
	@nume_dep NVARCHAR(255);

    SELECT
	@nume_dep = department_name
    FROM
	departments
    WHERE
	department_id = @id_dep;
  
    IF @nume_dep IS NULL
        RETURN;

    INSERT INTO dbo.ceva (mgr_id, nume_mgr, nr_sub, data_exec, nume_dep)
    SELECT 
        e.manager_id AS mgr_id,
        (m.first_name + ' ' + m.last_name) AS nume_mgr,
        dbo.cati_sub(e.manager_id) AS nr_sub,
        GETDATE() AS data_exec,
        @nume_dep AS nume_dep
    FROM
	employees e
    INNER JOIN
	employees m
    ON
	e.manager_id = m.employee_id
    WHERE
	e.department_id = @id_dep
    GROUP BY
	e.manager_id,
	m.first_name,
	m.last_name
    HAVING
	COUNT(e.employee_id) > 1;
END;
go

-- Exercitiul 10
-- daca vrem sa folosim procedura anterioara, o vom atasa la tabela dbo.employees
CREATE TRIGGER [dbo].[INSERARE_ISTORIC_E] ON [dbo].[EMPLOYEE]
AFTER INSERT, UPDATE, DELETE
AS
EXEC [DEPT_MGR_INFO];
GO
	
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
