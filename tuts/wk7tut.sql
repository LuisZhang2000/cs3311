-- Q1
-- Employee(id:integer, name:text, works_in:integer, salary:integer, ...)
-- Department(id:integer, name:text, manager:integer, ...)
-- Check that a manager must work in the department they manage

-- NOTHING EXISTS:
-- Find the managers for each department
-- Join E / D on their manager
-- works_in department != department id
create assertion manager_works_in_department check (
    not exists (
        select * 
        from Employee e 
            join Department d on (d.manager = e.id)
        where e.works_in <> d.id
    )
);

-- Q2
-- no employee earns more than the manager of their dept.
-- Join employees -> departments -> manager
-- Employee salary < manager salary
create assertion employee_manager_salary check (
    not exists (
        select * 
        from Employee e 
            join Department d on (e.works_in = d.id)
            join Employee mgrs on (d.managers = mgrs.id)
        where e.salary > mgrs.salary
    )
)

-- TRIGGERS
-- Q6
-- How would we implement a primary key constraint on relation R
create table R(a int, b int, c text, primary key(a,b));
create table S(x int primary key, y int);
create table T(j int primary key, k int references S(x));

-- Primary key constraint -> (a,b) must always be unique
-- Every time we insert or update on table R, check a, b are unique
create trigger R_pk_check before insert or update
for each row execute procedure R_pk_check();

create function R_pk_check() returns trigger
as $$
begin
    -- a or b cannot be null
    if (new.a is null or new.b is null) then
        raise exception 'A or B is null';
    end if;

    -- if we're updating, if a or b haven't changed, do nothing
    if (TG_OP = 'UPDATE' and (old.a = new.a and old.b = new.b) then
        return;
    end if;

    -- find if a duplicate record already exists
    select * from R where a = new.a and b = new.b;
    if (found) then
        raise exception 'Duplicate PK'
    end if;
end;
$$ language plpgsql;

create table S(x int primary key, y int);
create table T(j int primary key, k int references S(x));
-- How would we implement a foreign key constraint on T.k and S.x
-- When T is updated/inserted, need k to refer to a key in S -> trigger 1
-- When S is deleted/updated, need to make sure nothing in T refers to x -> trigger 2


create trigger T_fk_check before insert or update
for each row execute procedure T_fk_check();

create function T_fk_check() returns trigger
as $$
begin
    select * from S where x = new.k;
    if (found) then
        raise exception 'Non-existent S.x key in T';
    end if;
end;
$$ language plpgsql;

-- assuming that we don't want "on delete cascade" semantics

create trigger S_refs_check before delete or update on S
for each row execute procedure S_refs_check();

create function S_refs_check() returns trigger
as $$
begin
    if (TG_OP = 'UPDATE' and old.x = new.x) then
        return;
    end if;
    select * from T where k = old.x;
    if (found) then 
        raise exception 'References to S.x from T';
    end if;
end;
$$ language plpgsql;

-- Q7
-- explain difference between these two triggers
-- assuming S contains PK(1,2,3,4,5,6,7,8,9)
create trigger updateS1 after update on S
for each row execute procedure updateS();

create trigger updateS2 after update on S
for each statement execute procedure updateS();

update S set y = y + 1 where x = 5;
-- we are updating a single record (x=5 is a PK)
-- for each row / for each statement -> do the same thing

update S set y = y + 1 where x > 5;
-- records 6, 7, 8, 9 are updating
-- for each row: calls the trigger function for every changed row, i.e.
-- 6 -> call updateS1
-- 7 -> call updateS1
-- 8 -> call updateS1
-- 9 -> call updateS1

-- for each statement
-- SQL statement updates 6,7,8,9
-- updateS2 is then called
-- for each statement calls the trigger once after the rows have been changed

-- Q9
Emp(empname:text, salary:integer, last_date:timestamp, last_usr:text)
-- define a trigger that ensures that whenever a row
-- is inserted/updated, current username and time are stamped
-- stamp_user(), stamp_time()
-- also make sure employee name is not null and salary > 0

create trigger stamp before insert or update on Emp
for each row execute procedure emp_stamp();

create or replace function emp_stamp() returns trigger
as $$
begin
    if (new.empname is null or new.salary is null or new.salary < 0) then
        raise exception 'Cannot have null emp/salary or negative salary';
    end if;
    new.last_date := stamp_time();
    new.last_user := stamp_user();
    return new;
end;
$$ language plpgsql;

-- Q10
Enrolment(course:char(8), sid:integer, mark:integer)
Course(code:char(8), lic:text, quota:integer, numStudes:integer);

-- when an enrolment is inserted, add 1 to numStudes -> trigger 1
-- when an enrolment is updated, do something based off the update -> trigger 2
-- when an enrolment is deleted, remove 1 from numStudes -> trigger 3

create or replace function ins_stu() returns trigger
as $$
begin
    update Course set numStudes = numStudes + 1 where code = new.course;
    return new;
end;
$$ language plpgsql;

create or replace function del_stu() returns trigger
as $$
begin
    update Course set numStudes = numStudes - 1 where code = old.course;
    return new;
end;
$$ language plpgsql;

create or replace function upd_stu() returns trigger
as $$
begin
    update Course set numStudes = numStudes - 1 where code = old.course;
    update Course set numStudes = numStudes + 1 where code = new.course;
    return new;
end;
$$ language plpgsql;

create or replace function chk_quo() returns trigger
as $$
declare
    quota_filled boolean;
begin
    select into quota_filled (numStudes > quota)
    from Course where code = new.course;
    if (quota_filled) then
        raise exception 'Class is full'
    end if;
    return new;
end;
$$ language plpgsql;

-- check if the course a student is enrolling in is full
create trigger check_quota before insert or update on Enrolment
    for each row execute procedure chk_quo();

create trigger add_student after insert on Enrolment 
    for each row execute procedure ins_stu();

create trigger rm_student after delete on Enrolment 
    for each row execute procedure del_stu();    

create trigger upd_student after update on Enrolment 
    for each row execute procedure upd_stu();

-- Q11
Shipments(id:integer, customer:integer, isbn:text, ship_date:timestamp)
Editions(isbn:text, title:text, publisher:integer, published:date, ...)
Stock(isbn:text, numInStock:integer, numSold:integer)
Customer(id:integer, name:text, ...)

-- check customer exists in customer table
-- check ISBN exists in Editions table 
-- update stock table (for insert)
-- update stock table (for update if ISBN is being updated)
-- for update: calculate new shipment ID (max of all shipment IDs + 1)

create or replace function new_shipment() returns trigger
as $$
declare
    shipment_id integer;
begin
    -- check customer exists in customer table
    select * from Customer where id = new.customer
    if not found then
        raise exception 'Customer not found'
    end if;

    -- check isbn exists in editions table
    select * from Editions where isbn = new.isbn
    if not found then
        raise exception 'ISBN not found'
    end if;

    -- new shipment update stock
    if (TG_OP = 'INSERT') then 
        update Stock set numInStock = numInStock - 1 where isbn = new.isbn 
        update Stock set numSold = numSold + 1 where isbn = new.isbn 
    -- existing shipment update stock
    -- only want to modify stock for existing shipments if the isbn changes
    elsif old.isbn <> new.isbn then
        update Stock set numInStock = numInStock - 1 where isbn = old.isbn 
        update Stock set numSold = numSold - 1 where isbn = old.isbn 
        update Stock set numInStock = numInStock + 1 where isbn = new.isbn 
        update Stock set numSold = numSold + 1 where isbn = new.isbn 

    -- update shipment table
    right_now := now();
    new.ship_date := right_now;

    -- generate shipment ID
    select into shipment_id max(id) from Shipments;
    shipment_id := shipment_id + 1;
    new.id = shipment_id;
    return new;
    
end;
$$ language plpgsql;