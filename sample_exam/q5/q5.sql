-- COMP3311 20T3 Final Exam
-- Q5: show "cards" awarded against a given team

-- ... helper views and/or functions go here ...

drop function if exists q5(text);
drop type if exists RedYellow;

create type RedYellow as (nreds integer, nyellows integer);


create or replace function RedCards(text) returns setof text
as $$
select t.country, count(c.id)
from Players p
    join Cards c on (c.givento = p.id)
    join Teams t on (t.id = p.memberof)
where c.cardtype = 'red' and t.country = $1
group by t.country
$$ language sql;


create or replace function YellowCards(text) returns setof text
as $$
select p.name
from Players p
    left outer join Cards c on (c.givento = p.id)
    join Teams t on (t.id = p.memberof)
where t.country = $1 and c.cardtype = 'yellow'
$$ language sql;

-- takes in the name of a team 
-- return total number of red cards and yellow cards of that team

create or replace function
	Q5(_team text) returns RedYellow
as $$
declare
	reds 		integer
	yellows 	integer
	result 		RedYellow
begin

end;
$$ language plpgsql
;


select t.country, count(c.id)
from Players p
    join Cards c on (c.givento = p.id)
    join Teams t on (t.id = p.memberof)
where c.cardtype = 'red' 
group by t.country






