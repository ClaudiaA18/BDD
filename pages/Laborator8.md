# Laboratorul 8 - DML, cursori, functii si proceduri

## Data Manipulation language (DML) si Data Definition Language (DDL)
- `insert` (DML)
- `update` (DML)
- `delete` (DML)
- `truncate` (DDL)
- `merge` (DDL)

### `insert`
- `insert into` - inserare valori in tabela definita
- `select <whatever> into` - creaza o noua tabela
```
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
```
- clonare tabela employees
```
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
```

**Exercitiul 1:**

> doar ce este nou, dpdv al employee_id
```
-- deci noi vrem inserted din employee sa il punem in clona
CREATE TRIGGER ceva 
ON [dbo].[EMPLOYEE_CLONE]
FOR INSERT
AS
BEGIN
  SELECT * FROM INSERTED
END
go

-- i tried sth
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

-- fetch status not found si nu stiu ce, care este exact ca in oracle
-- ok
```

### `update`
- modifica datele dintr-o tabela deja existenta, respectand constrangerile
- accepta join-uri pentru satisfacerea unor conditii mai complicate

**Exercitiul 2:**

> sa se mareasca salariul angajatilor y 15% doar daca sunt intr-un departament care contine un numar par de angajati
```
UPDATE [dbo].[EMPLOYEE_CLONE]
SET salary = salary + (0.15 * salary)
WHERE department_id IN ( -- buna dimi
    SELECT department_id
    FROM EMPLOYEE_CLONE
    GROUP BY department_id
    HAVING COUNT(*) % 2 = 0
)
go
```

### `delete`
- sterge date dintr-o tabela
- accepta joinuri
- e important sa avem conditieeeee!!! *altfel, avem un `truncate` suboptim care poate fi executat pe tabele care nu au chei primare*

**Exercitiul 3:**

> sa se stearga angajatii care au departamentul situat in 'US'
```
delete from [dbo].[EMPLOYEE_CLONE] where employee_id in (select employee_id from EMPLOYEE_CLONE 
inner join departments on EMPLOYEE_CLONE.department_id = departments.department_id
inner join locations on departments.location_id = locations.location_id where locations.country_id = 'US')
go

```

### `truncate`
- un `delete` mult mai rapid (nu poate sterge tabele care au chei primare)
```
truncate table tabel
```

**Exercitiul 4**:

> clonati tabela departaments doar pentru cele care au 'e' in numele lor si apoi folositi `truncate` pe acea clona
```
SELECT *
INTO [dbo].[DEPARTMENTS_CLONE]
FROM [dbo].[DEPARTMENTS] where department_name like 'E%'
go

select * from [dbo].[DEPARTMENTS_CLONE]
go

truncate table [dbo].[DEPARTMENTS_CLONE] 
go

```

### `merge`
- in functie de conditia de potrivire, in cazul in care exista randuri ce pot fi legate, se poate face `update` sau `delete`, altfel `insert`
- Daca vrem sa aducem datele noi din clona, in cazul in care angajatul exista deja, i se da un bonus, salariul din tabelul original
```
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
```

**Exercitiul 5:**

> vrem sa aducem datele modificate inapoi in original (doar salariul si bonusul) folosind `merge` clona (din clona, logic), doar pentru angajatii care au job ce contine macar/cel putin un 'a' (altfel, nu facem nimic)
```
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

```

## Cursori
- este raspunsul la intrebarea *Exista instructiuni repetitive* (fiind un `while` mai fancy)
- se folosesc de niste tabele temporare stocate in memorie -> pentru optimizari trebuie sa ii inchidem si dealocam de fiecare data dupa ce ii folosim
- Dynamic SQL este o meoda prin care putem scrie ceva generic folosindu-ne de variabile de tipul `nvarchar`.
- acest tip de cod trebuie sa respecte ANSI SQL (+ variabile + iterativ) (nu este foarte performant, tho)
- Daca, de exemplu, vrem sa scapam de clone, folosind `truncate` si cursori
```
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

```

**Exercitiul 6**

> nu este suficient sa stergem numai tabelele, ci si sa scapam de ele (de tot) -> drop
```
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
```

- deci, sintaxa la cursor
```
-- declarare si punere date in cursor
DECLARE nume_cursor CURSOR FOR
SELECT
	coloane
FROM
	tabel
WHERE
	conditie
ORDER BY coloana;
-- sau orice alt query

-- deschidere cursor
OPEN nume_cursor;

-- preluare date din cursor
DECLARE
	@variabila1 tip1;
-- pot fi mai multe variabile (de preferat cate coloane am selectat, daca nu e cu sql dinamic)

FETCH NEXT FROM
	nume_cursor
INTO
	@variabila1;
WHILE @@FETCH_STATUS = 0
BEGIN
    -- do sth
    -- fetch pentru următorul rând în loop, caci nu se face automat
    FETCH NEXT FROM nume_cursor INTO @variabila1;
END

-- inchidere cursor
CLOSE nume_cursor;
DEALLOCATE nume_cursor;

```

- sintaxa cursor pentru sql dinamic
```
DECLARE
	@variabila1 tip1;
	@variabila2 nvarchar(50);
	@SQL NVARCHAR(MAX);

DECLARE nume_cursor CURSOR FOR
<query>

OPEN nume_cursor;

FETCH NEXT FROM nume_cusror INTO @variabila1, @variabila2;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Construirea interogării SQL dinamice
    SET @SQL = N'<query>';
	-- de exemplu: SET @SQL = N'UPDATE Employees SET Name = ''' + REPLACE(@variabila2, ' ', '') + ''' WHERE ID = ' + CAST(@variabila1 AS NVARCHAR(10)) + ';';
    
    -- Executarea interogării SQL dinamice
    EXEC sp_executesql @SQL;
    
    -- Trecem la următorul rând
    FETCH NEXT FROM nume_cursor INTO @variabila1, @variabila2;
END

CLOSE nume_cursor;
DEALLOCATE nume_cursor;

```

## Functii, proceduri stocate si triggere
- functiile sunt read-only
- procedurile, in schimb, au drepturi depline
- in TSQL nu avem blocuri speciale pentru a declara variabile (putem sa le declaram oriunde ;) ) singura restrictive fiind vizibilitatea (!)
- `create or alter` (syntactic sugar ;) ) (la fel ca si `create or replace` (atentie la cuvinte) din pl/sql) pentru functii, proceduri stocate, triggere, vederi

### Functii
- pot primi sau nu parametrii
- valoarea returnata are un tip
- de folosit `begin` si `end`

**Exercitiul 7:**

> functie ce primeste ca parametru id_ang si salariu (default salariu angajat respectiv) si returneaza numarul angajatilor subordonati lui, care au salariul <= cu acel salariu dat ca parametru
```
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

```

- deci, sintaxa la functii:
```
create function nume(@parametru tip_parametru)
returns tip_returnat
as
begin
	declare
		@variabila_returnata tip_returnat;
		-- alte variabile
	
	-- do sth

	return @variabila_returnata;
end;
go
	
```

**Exercitiul 8:**

> de modificat 7 ca sa intoarca salariul unui angajat
```
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
```
- deci, daca vrei sa faci select ... into ... from ... where ... etc etc din pl/sql in transact sql, va trebui sa faci asa:
```
declare @ceva tip;
select @ceva = coloana from .... where ... etc etc
```
- asta pentru ca `select ... into ...` iti face o alta tabela :`)

### Proceduri stocate
- sunt un mod optim de a pastra cod ce va fi executat de mai multe ori
- sunt optimizate in spate (de catre compilator?) in functie de planul lor de executie ;)
- black-box; oferim doar drepturi de executie si acces granular
- avem in plus, un fel de try and catch pentru exceptii :D :
	- `begin try` si `end try`
	- `begin catch` si `end catch`

**Exercitiul 9:**

> sa se creeze procedura [dbo].[DEPT_MGR_INFO] care are ca parametru de intrare id_dep si ca valoare returnata nume_dep si insereaza intr-o alta tabela urmatoarele
> 	- id fiecare manager care lucreaza in acel departament (si are macar/cel putin un subaltern)
> 	- nume manager
> 	- numar angajati in subordine, care au salariul <= decat el
>	- data executie procedura
```
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

```
- deci, sintaxa la proceduri:
```
CREATE PROCEDURE dbo.nume
    @parametru tip_parametru
AS
BEGIN    
    DECLARE
	@variabila NVARCHAR(255);

   -- do sth
END;

```

### Trigger
- e o metoda de a executa anumite instructiuni in momentul in care pe o tabela se executa:
	- `insert` -> `inserted`
	- `delete` -> `deleted`
	- `update` -> `inserted` cele noi si `deleted` la cele vechi
- exista 2 tipuri:
	- `after` ce se executa dupa operatia propriu-zisa si schimbarile apar daca e cu succes
	- `instead of` se executa in locul operatiei
	- fata de pl/sql, aparent, nu exista trigger de tipul `before` =(

**Exercitiul 10:**

> daca vrem sa folosim procedura anterioara, o vom atasa la tabela dbo.employees
```
CREATE TRIGGER [dbo].[INSERARE_ISTORIC_E] ON [dbo].[EMPLOYEE]
AFTER INSERT, UPDATE, DELETE
AS
EXEC [DEPT_MGR_INFO];
GO
```

- deci, sintaxa la triggeri:
```
CREATE TRIGGER dbo.nume ON tabel
AFTER INSERT, UPDATE, DELETE
AS
EXEC procedura;
-- sau pui tu acolo un query, eventual il pui intre un begin si un end
GO
```
