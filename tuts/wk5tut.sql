-- BASIC FUNCTION STUFF
-- Q1: Square root functions
create or replace function sqr(n integer) returns integer
as $$
begin 
    return n * n;
end;
$$ language plpgsql;

-- Will this work if you do:
-- select sqr(5.0);  ->  No, 5.0 is a float, not an int
-- select(5.0::integer);  ->  Yes, 5.0 is being typecasted to int
-- select sqr('5');  ->  Yes, postgres can convert strings to ints for some reason but not numerics

-- Q2: Spread function
create or replace function spread(str text) returns text
as $$
declare
    result text := '';
    i integer;
begin 
    i := 1
    for i in 1 .. length(str) loop
        result := result || substr(str, i, 1) || ' '
    end loop;
    return result;
end;
$$ language plpgsql;

-- Q3: return first positive n integers
create or replace function seq(n integer) returns setof integer
as $$
declare
    i integer;
begin 
    for i in 1 .. n loop 
        return next i;
    end loop;
end; 
$$ language plpgsql;

-- Q4:

-- Q5: Given a function seq(int, int, int) (start, end, step).
-- Reimplement seq(n) as an sql function

-- sql function -> parameterised select statement
create or replace function seq(integer) returns setof integer 
as $$
    select * from seq(1, $1, 1);
$$ language sql;


-- Q6: write factorial as a SQL function 
-- assuming a product aggregate exists + seq
create or replace function fac(integer) returns integer
as $$
    select product(*) from seq(1, $1, 1)
$$ language sql;


-- Q7: return a string of all names of bars in a given suburb
-- address only has a suburb

-- write a select statement that returns the names of all bars in a suburb
-- select * from Bars where address = suburb 
-- loop through the results of this query and add it to a string
create or replace function hotelsIn(_addr text) returns text
as $$
declare
    result text := "";
    r record;
begin 
    for r in select * from bars where addr = _addr
    loop 
        result := result || r.name || e'\n'
    end loop;
    return result;
end; 
$$ language plpgsql;

-- If i wanted a table not a giant string

create or replace function hotelsIn(_addr text) returns text
as $$
    select * from bars where addr = $1
$$ language sql;

-- Q8: return name of all hotels in suburb
-- or return 'There are no hotels in (suburb)'

-- need to figure out how many hotels are in a suburb
-- select count(*) from Bars where address = {}
create or replace function hotelsIn(_addr text) returns text
as $$
declare
    howMany integer;
    r record;
    result text := '';
begin 
    select count(*) into howMany from Bars where address = _addr;
    if (howMany = 0) then
        return'"There are no hotels in ' || _addr;
    end if;

    for r in select * from bars where addr = _addr
    loop 
        result := result || r.name || e'\n'
    end loop;
    return result;
end; 
$$ language plpgsql;

-- Q10: redo Q7 but return a table instead as a SQL function
create or replace function hotelsIn(_addr text) returns text
as $$
    select * from bars where addr = $1
$$ language sql;

-- Q11: redo Q7 but return a set of records -> List of Bars
create or replace function hotelsIn(_addr text) returns setof Bars
as $$
declare
    r record;
begin 
    for r in select * from Bars where addr = _addr
    loop
        return next r;
    end loop;
    return;
end; 
$$ language plpgsql;

-- Bank Example

Branches(location:text, address:text, assets:real)
Accounts(holder:text, branch:text, balance:real)
Customers(name:text, address:text)
Employees(id:integer, name:text, salary:real)

-- Q12
-- a: return salary of an employee as plpgsql and sql function
-- select salary from Employees where name = {}
create or replace function empSal(text) returns real
as $$
    select salary from Employees where name = $1         
$$ language sql;


create or replace function empSal(text) returns real
as $$
declare
    _sal real;
begin
    select salary into _sal from Employees where name = $1    
    return _sal;
end;
$$ language plpgsql;

-- b: details of particular branch location
create or replace function branchDeets(text) returns Branches
as $$
    select * from Branches where location = $1;        
$$ language sql;


create or replace function branchDeets(text) returns Branches
as $$
declare
    result Branches;
begin
    select * into result from Branches where location = $1;
    return result;
end
$$ language plpgsql;

-- c: employee names earning more than salary
create or replace function enmpsWithSal(real) returns setof text
as $$
    select name from Employees where salary > $1;        
$$ language sql;


create or replace function enmpsWithSal(real) returns setof text
as $$
declare
    r record;
begin
    for r in select * from Employees where salary > $1
    loop
        return next r.name;
    end loop;
    return;
end;
$$ language plpgsql;

-- d: details of highly paid employees
create or replace function highlyPaid(real) returns setof Employees
as $$
    select * from Employees where salary > $1;        
$$ language sql;

create or replace function highlyPaid(real) returns setof Employees
as $$
declare
    r record;
begin
    for r in select * from Employees where salary > $1
    loop
        return next r;
    end loop;
    return;
end;
$$ language plpgsql;




as $$
declare
begin 

end; 
$$ language plpgsql;