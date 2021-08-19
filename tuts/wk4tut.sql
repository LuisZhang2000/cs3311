-- WEEK 4 SQL CONSTRAINTS, UPDATES AND QUERIES

-- Q1. Order of table declarations does matter. Anything that refers to something else needs to be after whatever it refers to.

-- Q2. 
update Employees
set salary = 0.8 * salary
where age < 25

-- Q3.
update Employees
set salary = 1.1 * salary
where e.eid in
    (select e.eid
    from Employees e join WorksIn w on (e.eid = w.eid )
        join Departments d on (w.did = d.did)
    where d.dname = "Sales")

-- Q4

create table Departments (
      did     integer primary key,
      dname   text,
      budget  real,
      manager integer not null references Employees(eid)
);

-- Q5

create table Employees (
      eid     integer primary key,
      ename   text,
      age     integer,
      salary  real check (salary >= 10),
      primary key (eid)
);

-- Q6

create table Employees (
      eid     integer primary key,
      ename   text,
      age     integer,
      salary  real check (salary >= 10),
      primary key (eid)
      constraint MaxFullTimeCheck
                check 1.0 >= (
                    select sum(w.percent) from WorksIn w where w.eid = eid
                )
);

-- Q12
select s.sname
from Suppliers s join Catalog c on (s.sid = c.sid)
    join Parts p (c.pid = p.pid)
where p.colour = "red"

-- Q13
select s.sid
from Suppliers s join Catalog c on (s.sid = c.sid)
    join Parts p (c.pid = p.pid)
where p.colour = "red" or p.colour = "green"

-- Q14
select s.sid
from Suppliers s join Catalog c on (s.sid = c.sid)
    join Parts p (c.pid = p.pid)
where p.colour = "red" or s.address = "221 Packer Street"

-- Q15
(select s.sid
from Suppliers s join Catalog c on (s.sid = c.sid)
    join Parts p (c.pid = p.pid)
where p.colour = "red")
intersect
(select s.sid
from Suppliers s join Catalog c on (s.sid = c.sid)
    join Parts p (c.pid = p.pid)
where p.colour = "green")
-- get suppliers who supply red parts
-- get suppliers who supply green parts
-- intersect those tables together

-- Q16: suppliers who supply every part
-- for each supplier find out the parts they supply
-- Set (parts that supplier supplies) - Set (all parts) = 0

-- select suppliers where the set difference is 0
select s.id
from Suppliers s 
where not exists (
    (select pid from Part)
    except
    (select c.pid from Catalog c where c.sid = s.sid)
)

-- Q18: suppliers who supply every part that is red or green
select s.id
from Suppliers s 
where not exists (
    (select pid from Part where p.colour = 'red' or p.colour = 'green')
    except
    (select c.pid from Catalog c where c.sid = s.sid)
)

-- Q19: supply every red part or supply every green part or both
-- Suppliers who supply every red part U suppliers who supply every green part 
(select s.id
from Suppliers s 
where not exists (
    (select pid from Part where p.colour = 'red')
    except
    (select c.pid from Catalog c where c.sid = s.sid)
))
union
(select s.id
from Suppliers s 
where not exists (
    (select pid from Part where p.colour = 'green')
    except
    (select c.pid from Catalog c where c.sid = s.sid)
))

-- Q20: