-- Exercitiul 1
-- numele si functia unui angajat cu id data de la tastatura
set serveroutput on
declare
	/* & = citire 
	de la tastatura */
	idemp number(6) := &id;
	nume varchar(50);
	-- %type = variabila sa ia tipul coloanei
	functie jobs.job_title%type;
begin
	select
		first_name||' '||last_name, job_title
		-- nu mai pui aliasuri ca o sa pui ce selectezi in variabile =)
		-- into este folosit fix pentru asta ^
	into
		nume, functie
	from
		employees natural join jobs
	where
		employee_id = idemp;
	dbms_output.put_line('Numele angajatului este: '|| nume || ' si are functia '||functie);
exception
	-- in cazul in cae nu se gasesc date de catre select, sa intoarce no_data+found
	when no_data_found then
		dbms_output.put_line('Nu s-a gasit nimeni cu id-ul '||idemp);
end;
/

-- Exercitiul 2
-- se adauga un ang cu niste date care are ca manager pe primul cu cei mai multi ang si apoi i se adauga un comision se da job_id de la tastatura; data_ang = sysdate;

set serveroutput on
define id = 1000 
-- pe acesta sigur nu-l avem
define fname = 'ion'
define lname = 'Ionescu'
define jid = 'it_prog'
declare
	idd employees.employee_id%type := &id;
	jid employees.job_id%type := upper('&jid');
	-- le ia pe cele de mai sus cred
	mgr_id number(6);
begin
	begin
		select
			manager_id
		into	
			mgr_id
		from
			employees
		where
			job_id = upper(jid)
		group by
			manager_id
		having
			count(*) = (
				select
					max(cnt)
				from
					(
					select
						count(*) cnt
					from
						employees
					where
						job_id = jid
					group by
						manager_id
					)
				)
		order by
			manager_id
		fetch first 1 rows only;
		exception
			when no_data_found then
				dbms_output.put_line('Nu s-a gasit functia '||jid);
		end;
		-- aici, mai sus, mi-am pregatit datele aka am aflat managerul ptr noul angajat
		declare
			fname employees.first_name%type := '&fname';
			lname employees.last_name%type := '&lname';
			email employees.email%type;
			sal number(8,2) := 2123.85;
		begin
			email := upper(substr(fname, 0, 1) || lname);
			insert into
			employees(employee_id, first_name, last_name, salary, email, hire_date, job_id)
			values(idd,initcap(fname), initcap(lname), sal, email, sysdate, jid);
		end;
		declare
			commission employees.commission_pct%type := 0.5;
		begin
			update
				employees
			set
				commission_pct = commission
			where employee_id = idd;
		
		end;
		exception
			when others then
				dbms_output.put_line('Err: '||SQLERRM);
end;
/
undefine id;
undefine fname;
undefine lname;
undefine jid;
select * from employees where employee_id = 1000;
delete from employees where employee_id = 1000;

-- Exercitiul 3
-- la fel ca exercutiul 2, dar cu blocuri imbricate
set serveroutput on
define id = 1000 
-- pe acesta sigur nu-l avem
define fname = 'ion'
define lname = 'Ionescu'
define jid = 'it_prog'
declare
	jid employees.job_id%type := upper('&jid');
	-- le ia pe cele de mai sus cred
	mgr_id number(6);
begin
	select
		manager_id
	into	
		mgr_id
	from
		employees
	where
		job_id = upper(jid)
	group by
		manager_id
	having
		count(*) = (
			select
				max(cnt)
			from
			(
				select
					count(*) cnt
				from
					employees
				where
					job_id = jid
				group by
					manager_id
			)
		)
	order by
		manager_id
	fetch first 1 rows only;
	-- aici, mai sus, mi-am pregatit datele aka am aflat managerul ptr noul angajat
	declare
		fname employees.first_name%type := '&fname';
		lname employees.last_name%type := '&lname';
		email employees.email%type;
		idd employees.employee_id%type := &id;
		sal number(8,2) := 2123.85;
	begin
		email := upper(substr(fname, 0, 1) || lname);
		insert into
		employees(employee_id, first_name, last_name, salary, email, hire_date, job_id)
			values(idd,initcap(fname), initcap(lname), sal, email, sysdate, jid);
		declare
			commission employees.commission_pct%type := 0.5;
		begin
			update
				employees
			set
				commission_pct = commission
			where employee_id = idd;
		
		end;
		exception
			when others then
				dbms_output.put_line('Err: '||SQLERRM);
		end;
		exception
			when no_data_found then
				dbms_output.put_line('Nu a gasit functia'||jid);
end;
/
undefine id;
undefine fname;
undefine lname;
undefine jid;
select * from employees where employee_id = 1000;
delete from employees where employee_id = 1000;

-- Exercitiul 4
-- se da id de la tastatura si se cere nume_ang cu venit_orar, departament si zile_lucrate
set server output on
declare
	nume_ang nvarchar2(45);
	id_dep integer;
	dname varchar(20);
	dataAng date;
	idAng number(6) := &id;
	venit float;
	zileLucrate number(10);
	venitOrar real;
	zileLuna constant smallint := 21;
begin
	select
		department_id,
		first_name||' '||last_name,
		salary + nvl(commission_pct, 0)*salary,
		hire_date
	into
		id_dep,
		nume_ang,
		venit,
		dataAng
	from
		employees
	where
		employee_id = idAng;
	select
		department_name
	into
		dname
	from
		departments
	where
		department_id = id_dep;
	venitOrar := round(venit/(zileLuna*8), 2);
	zileLucrate := sysdate - dataAng;
	dbms_output.put_line(nume_ang||' are un venit orar de '||venitOrar||' si face parte din departamentul '||dname|| '.' || chr(13) || chr(10) || 'A lucrat in firma un numar total de '||zileLucrate|| ' zile.');
exception
	when no_data_found then
		dbms_output.put_line('Nu s-a gasit un astfel de angajat');
end;
/

-- Exercitiul 5
-- se da id de la tastatura si se cere numele, functia, departamentul si locatia departamentului (adresa completa)
set serveroutput on;
declare
	prenume_ang employees.first_name%type;
	nume_ang employees.last_name%type;
	venit employees.salary%type;
	id_dept employees.department_id%type;
	dept_row departments%rowtype;
	location_row locations%rowtype;
	country_row countries%rowtype;
	region_row regions%rowtype;
begin
	select
		department_id,
		first_name,
		last_name, 
		salary+nvl(commission_pct,0)*salary
	into
		id_dept,
		prenume_ang,
		nume_ang,
		venit
	from
		employees
	where
		employee_id=&id;
	select d.* into dept_row from departments d
	where department_id = id_dept;
	select l.* into location_row from locations l
	where l.location_id = dept_row.location_id;
	select c.* into country_row from countries c
	where c.country_id = location_row.country_id;
	select r.* into region_row from regions r
	where r.region_id = country_row.region_id;
	dbms_output.put_line(prenume_ang||' '||nume_ang||' face parte din departamentul '||dept_row.department_name||' din '||location_row.city||', '||location_row.state_province||', '||country_row.country_name||', '||region_row.region_name);
-- mamaaaa
exception
	when no_data_found then
		dbms_output.put_line('Nu exista angajat cu acest id!');
end;
/

-- Exercitiul 6
-- informatii despre ultimul angajat in 2001
set serveroutput on
declare
	nume_ang varchar2(20);
	functie string(30);
	max_data date;
	start_date date := '1-JAN-2001';
	end_date date := '31-DEC-2001';
begin
	select
		first_name||' '||last_name,
		job_title
	into
		nume_ang,
		functie
	from
		employees
	natural join
		jobs
	where
		hire_date =
		(select
			max(hire_date)
		from employees
		where hire_date between start_date and end_date
		);
	dbms_output.put_line('Angajatul cautat este '||nume_ang||' si are functia '||functie);
exception
	when no_data_found then
		dbms_output.put_line('Nu a fost nimeni angajat in 2001!');
	when too_many_rows then
		dbms_output.put_line('Sunt mai multe angajari pentru data maxima!');
end;
/

-- Exercitiul 7
-- care angajat are o anumita vechime
set serveroutput on
declare
	nume_ang varchar(42);
	functie jobs.job_title%type;
	data date;
	vechime interval year(2) to month;
begin
	vechime := interval '19-5' year to month;
	dbms_output.put_line('Vechimea solicitata = '||vechime);
	select
		hire_date
	into
		data
	from
		employees
	where
		hire_date < sysdate - vechime;
	dbms_output.put_line('Data maxima '||data);
	select
		first_name||' '||last_name,
		job_title
	into
		nume_ang,
		functie
	from
		employees
	natural join
		jobs
	where
		hire_date = data;
	dbms_output.put_line('Angajatul cu vechimea cautata este '||nume_ang||' si are functia '||functie);
exception
	when no_data_found then
		dbms_output.put_line('Nu exista niciun angajat cu astfel de vechime!');
	when too_many_rows then
		dbms_output.put_line('Sunt mai multi angajati cu aceasta vechime!');
end;
/

-- Exercitiul 8
-- numar angajari pe un an dat de la tastatura
set serveroutput on
declare
	nume_ang varchar2(45);
	functie jobs.job_title%type;
	an number(4) := &an;
	angajari number;
begin
	select
		count(*)
	into
		angajari
	from
		employees
	natural join
		jobs
	where
		extract(year from hire_date) = an;
	dbms_output.put_line('In anul '||an||' au avut loc '||angajari|| ' angajari');
exception
	when no_data_found then
		dbms_output.put_line('Nu exista angajari in anul '||an);
	when too_many_rows then
		dbms_output.put_line('Sunt '||angajari ||' in anul '||an);
end;
/

-- Exercitiul 9
-- departament, nume, data_angajarii si comision cu id dat de la tastatura
set serveroutput on
declare
	nume_dept departments.department_name%type;
	id_ang employees.employee_id%type;
	nume_ang varchar(50);
	comm number(10);
	data_ang date;
begin
	id_ang := &id_ang;
	begin
		select
			dep.department_name,
			emp.first_name||' '||emp.last_name,
			emp.hire_date,
			emp.salary * nvl(emp.commission_pct, 0)
		into
			nume_dept,
			nume_ang,
			data_ang,
			comm
		from
			employees emp
		left join
			departments dep
		on
			emp.department_id = dep.department_id
		where employee_id = id_ang;
		dbms_output.put_line(rpad('Nume dep', 30, ' ')||rpad('Nume',30,' ')||rpad('Data ang',15,' ')||lpad('Comision',10,' '));
		dbms_output.put_line(rpad(nvl(nume_dept,'N/A'),30,' ')||rpad(nume_ang,30,' ')||rpad(data_ang,15,' ')||lpad(comm,10,' '));		
	exception
		when no_data_found then null;
	end;
end;
/

-- Exercitiul 10
-- suma veniturilor ang cu aceeasi functie si acelasi departament
set serveroutput on
declare
	nume_dep departments.department_name%type;
	sum_venit employees.salary%type;
	functie jobs.job_title%type;
begin
	select
		dep.department_name,
		job.job_title,
		sum(emp.salary + emp.salary * nvl(commission_pct, 0))
	into
		nume_dep,
		functie,
		sum_venit
	from
		employees emp
	natural join
		jobs job
	right outer join
		departments dep
	on
		emp.department_id = dep.department_id
	where
		dep.department_id = &id
	and
		job_id = upper('&jid')
	group by
		dep.department_name,
		job.job_title;
	dbms_output.put_line('Suma veniturilor in departamentul '||nume_dep||' pentru functia '||functie||' este '||to_char(sum_venit));
exception
	when no_data_found then
		dbms_output.put_line('No data found!');
end;
/
