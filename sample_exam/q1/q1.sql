-- COMP3311 20T3 Final Exam
-- Q1: view of teams and #matches

-- ... helper views (if any) go here ...

create or replace view Q1(team,nmatches)
as
-- select country name of each team and no. matches played
select t.country, count(*) 
from Teams t
    join Involves i on (i.team = t.id)
group by t.country
;

