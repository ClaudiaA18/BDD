# Laboratorul 3
Sunt trei tipuri de excepții:
- Predefinite = tratate automat de către sistemul de gestiune;
- Nedefinite = tratate de către sistemul de gestiune, au coduri de eroare tip ORA-….Aceste erori pot fi interceptate și tratate de programator daca li se atașează un nume;
- Definite = definite și tratate de o secvență de program specificată de programator.

## Exceptii predefinite
```
EXCEPTION
	WHEN exception_1 [OR exception_2 ...] THEN statements_1;
	...
	WHEN exception_k [OR exception_k+1 ...] THEN statements_k;
	[WHEN OTHERS THEN statements_n;]
-- la final, inainte de end; :)
```

**Exercitiul 1:**

> id dep de la tastatura si se afiseaza nume_dep
```
set serveroutput on
declare
    id_dep number;
    nume_dep departments.department_name%type;
begin
    id_dep := &iddep;
    select department_name into nume_dep from departments where department_id = id_dep;
    dbms_output.put_line(id_dep||' - '||nume_dep);
end;
/
```
exceptie:
```
Enter value for iddep: 1
old   5:     id_dep := &iddep;
new   5:     id_dep := 1;
declare
*
ERROR at line 1:
ORA-01403: no data found
ORA-06512: at line 6
```

**Exercitiul 2:**

> tratarea exceptiei de la exercitiul 1
```
set serveroutput on
declare
    id_dep number;
    nume_dep departments.department_name%type;
begin
    id_dep := &iddep;
    select department_name into nume_dep from departments where department_id = id_dep;
    dbms_output.put_line(id_dep||' - '||nume_dep);
exception
    when no_data_found then
        dbms_output.put_line(id_dep||' - N/A');
end;
/
```

## Exceptii nedefinite
```
DECLARE
	...
	exception_name EXCEPTION;
	PRAGMA EXCEPTION_INIT(exception_name, 			exception_code);
	...
BEGIN
	...
EXCEPTION
	...
	WHEN exception_name THEN statements;
	...
END;
```
În cazul acestor excepții trebuie asociat codul de eroare cu numele excepției în secțiunea DECLARE a blocului prin cuvintele cheie rezervate PRAGMA EXCEPTION_INIT.
Pentru interpretarea erorilor se folosește funcția de sistem SQLCODE, care returnează următoarele valori:
0 – dacă nu s-a întâlnit o eroare
1 – excepție definită de utilizator
+100 – excepția NO_DATA_FOUND
Valori negative – pentru alte erori ale bazei
Mesajul erorii se afișează cu funcția SQLERRM.

**Exercitiul 3**:

> inserare in tabela employees a unui nou angajat dara sa aiba employye_id
```
set serveroutput on;
declare
    insert_angajat exception;
    pragma exception_init(insert_angajat, -01400);
begin
    insert into employees(first_name, last_name, hire_date, salary)
    values ('Ion', 'Ionescu', '14-aug-2020', 1450);
exception
    when insert_angajat then
        dbms_output.put_line('Nu se accepta inregistrari noi in tabela employees fara employee_id');
        dbms_output.put_line('Cod eroare '||SQLCODE);
        dbms_output.put_line('Mesaj '||SQLERRM);
end;
/
```
output:
```
Nu se accepta inregistrari noi in tabela employees fara employee_id
Cod eroare -1400
Mesaj ORA-01400: cannot insert NULL into ("ABD1"."EMPLOYEES"."EMPLOYEE_ID")
```

Explicatii: 
- PL/SQL generează propriile coduri de eroare în formatul PLS-xxxxx, unde xxxxx este codul de eroare. 
- Acest cod este unic si este diferit de codul ORA-yyyyy generat de SGBD. 
- Cu ajutorul acestui număr se poate identifica definiția erorii folosindu-se documentația ORACLE.
  
**Exercitiul 4**:

> exercitiul 3 dar cu tratare exceptie ce nu a fost declarata

```
set serveroutput on;
declare
    insert_angajat exception;
    pragma exception_init(insert_angajat, -01400);
begin
    insert into employees(first_name, last_name, hire_date, salary)
    values('Ion', 'Ionescu', '14-aug-2020', 1450);
exception
    when insert_angajat then
        dbms_output.put_line('Nu se acceota inserari noi in tabela employees fara employee_id');
        dbms_output.put_line('Cod eroare '||SQLCODE);
        dbms_output.put_line('Mesaj '||SQLERRM);
    when exceptie_eronata then null;
end;
/
```

output:
```
ERROR at line 12:
ORA-06550: line 12, column 10:
PLS-00201: identifier 'EXCEPTIE_ERONATA' must be declared
ORA-06550: line 0, column 0:
PL/SQL: Compilation unit analysis terminated
```
## Exceptii definite

```
DECLARE
	...
	exception_name EXCEPTION
	...
BEGIN
	...
	IF condition THEN 
		RAISE exception_name
	END IF;
	...
EXCEPTION
	...
	WHEN exception_name THEN statements;
	...
END;
```

- Excepțiile definite trebuie declarate în DECLARE și generate explicit cu RAISE.
- Declararea și interceptarea excepțiilor definite de programator impun următoarele acțiuni:
  - Declararea excepției în secțiunea DECLARE.
  - Utilizarea instrucțiunii RAISE pentru generarea excepției în secțiunea de execuție a blocului: RAISE exception_name
  - Tratarea excepției în secțiunea EXCEPTION.
  
**Exercitiul 5**:

> pentru angajatii dintr-un departament, al carui id este de la tastatura, care au un comision null, sa se genereze o exceptie definita

```
set serveroutput on;
declare
    idDepartament number;
    contor number := 100;
    numeAngajat employees.first_name%type;
    comision employees.commission_pct%type;
    dataAngajare employees.hire_date%type;
    lipsaComision exception;
begin
    idDepartament := &deptId;
    dbms_output.put_line(rpad('Nume', 15,' ')||rpad('Data_ang',20,' ')||lpad('Comision',15,' '));
    dbms_output.put_line(rpad('=', 15,'=')||rpad('=',20,'=')||lpad('=',15,'='));
    loop
        contor := contor + 1;
        begin
            select
                first_name || ' ' || last_name,
                hire_date,
                commission_pct
            into
                numeAngajat, dataAngajare, comision
            from
                employees
            where
                department_id = idDepartament
            and
                employee_id = contor;
            if comision is null then
                raise lipsaComision;
            end if;
            dbms_output.put_line(rpad(numeAngajat, 15, ' ')||rpad(dataAngajare, 20, ' ')||lpad(comision, 15, ' '));
        exception
            when lipsaComision then
                dbms_output.put_line(rpad(numeAngajat, 15, ' ')||rpad(dataAngajare, 20, ' ')||lpad('lipsa comision', 15, ' '));
            when no_data_found then null;
            when others then null;
        end;
        exit when contor = 300;
    end loop;
end;
/
```

- excepția nu se declanșează pe o eroare, ci se verifică în IF dacă comisionul angajatului este null.
- Dacă o excepție este generată într-un bloc, iar acesta nu are EXCEPTION, sau nu se dorește tratarea ei în blocul în care este generată, atunci ea poate fi tratată în blocul superior sau în blocul apelant.

**Exercitiul 6**:

> tratare exceptie de mai devreme in blocul principal
```
set serveroutput on;
declare
    idDepartament number;
    contor number := 100;
    numeAngajat employees.first_name%type;
    comision employees.commission_pct%type;
    dataAngajare employees.hire_date%type;
    lipsaComision exception;
begin
    idDepartament := &deptId;
    dbms_output.put_line(rpad('nume',15,' ')||rpad('data_ang',20,' ')||lpad('comision',15,' '));
    dbms_output.put_line(rpad('=',15,'=')||rpad('=',20,'=')||lpad('=',15,'='));
    loop
        contor := contor + 1;
        begin
            select
                first_name || ' ' || last_name,
                hire_date,
                commission_pct
            into
                numeAngajat,
                dataAngajare,
                comision
            from
                employees
            where
                department_id = idDepartament
            and
                employee_id = contor;
            if comision is null then
                raise lipsaComision;
            end if;
            dbms_output.put_line(rpad(numeAngajat,15,' ')||rpad(dataAngajare,20,' ')||lpad(comision,15,' '));
        exception
            when no_data_found then null;
        end;
        exit when contor = 300;
    end loop;
exception
    when lipsaComision then
        dbms_output.put_line(rpad(numeAngajat,15,' ')||rpad(dataAngajare,20,' ')||lpad('lipsa comision',15,' '));
end;
/
```

Pentru a intercepta erorile de sistem, există procedura stocată RAISE_APPLICATION_ERROR.
Aceasta permite transmiterea erorilor din proceduri stocate, dar poate fi folosită și în alte situații pentru transmiterea excepțiilor către procedurile apelate.
```
	raise_application_error(error_number, message [, {TRUE | FALSE}]);
```
**Exercitiul 7**:

> pentru un angajat care nu are comision, sa se defineasca o exceptie ce e tratata in momentul generarii si are codul -20100
```
set serveroutput on;
declare
    id employees.employee_id%type;
    comision employees.commission_pct%type;
    lipsaComision exception;
    pragma exception_init(lipsaComision, -20100);
begin
    id := &id;
    select
        commission_pct
    into
        comision
    from
        employees
    where employee_id = id;
    if comision is null then
        raise_application_error(-20100, 'Ang nu are comision!');
    end if;
exception
    when lipsaComision then
        dbms_output.put_line('Ang nu are comision');
        dbms_output.put_line('Cod err: '||SQLCODE);
        dbms_output.put_line('Msg: '||SQLERRM);
end;
/
```

**Exercitiul 8**:

> suma veniturilor dintr-un departament pe o anumita functie
```
set serveroutput on;
declare
    iddep departments.department_id%type;
    numedep departments.department_name%type;
    salariu employees.salary%type;
    functie employees.job_id%type;
begin
    iddep := &iddep;
    functie := '&functie';
    select
        sum(salary + salary * nvl(commission_pct, 0))
    into
        salariu
    from
        employees
    where
        department_id = iddep
    and
        upper(job_id) = upper(functie)
    group by
        department_id;
    
    select
        department_name
    into
        numedep
    from
        departments
    where
        department_id = iddep;

    dbms_output.put_line('Suma veniturilor din departamentul '||numedep||' este '||to_char(salariu));
exception
    when no_data_found then
        dbms_output.put_line('In departamentul '||numedep||' nu exista angajati cu functia '||functie);
end;
/
```

> daca scoti group by din primul select si apelezi aia pentru iddep = 1 si functie SA_REP,
> excepția s-a declanșat numai pentru departamentul 1, cu toate că departamentul 10 nu are
> niciun angajat cu funcția SA_REP. În mod normal, SELECT ar trebui să declanșeze o
> excepție, dar funcția SUM întoarce o valoare null, astfel încât nu se declanșează
> excepția predefinită no_data_found. => mare grija la construire cereri!

 ```
set serveroutput on;
declare
    iddep departments.department_id%type;
    numedep departments.department_name%type;
    salariu employees.salary%type;
    functie employees.job_id%type;
begin
    iddep := &iddep;
    functie := '&functie';
    select
        sum(salary + salary * nvl(commission_pct, 0))
    into
        salariu
    from
        employees
    where
        department_id = iddep
    and
        upper(job_id) = upper(functie);
    
    select
        department_name
    into
        numedep
    from
        departments
    where
        department_id = iddep;

    dbms_output.put_line('Suma veniturilor din departamentul '||numedep||' este '||to_char(salariu));
exception
    when no_data_found then
        dbms_output.put_line('In departamentul '||numedep||' nu exista angajati cu functia '||functie);
end;
/
```
