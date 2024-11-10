# Laboratorul 3
Sunt trei tipuri de excepții:
- Predefinite = tratate automat de către sistemul de gestiune;
- Nedefinite = tratate de către sistemul de gestiune, au coduri de eroare tip ORA-….Aceste erori pot fi interceptate și tratate de programator daca li se atașează un nume;
- Definite = definite și tratate de o secvență de program specificată de programator.
```
EXCEPTION
	WHEN exception_1 [OR exception_2 ...] THEN statements_1;
	...
	WHEN exception_k [OR exception_k+1 ...] THEN statements_k;
	[WHEN OTHERS THEN statements_n;]
-- la final, inainte de end; :)
```

**Exercitiul 1:**

> id dep de la tastatura si se af nume_dep
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

> tratarea erorii de la exercitiul 1
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
