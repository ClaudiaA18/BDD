-- Laboratorul 8
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