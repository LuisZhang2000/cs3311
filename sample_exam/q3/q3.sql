-- COMP3311 20T3 Final Exam
-- Q3: team(s) with most players who have never scored a goal

-- ... helpers go here ...

create or replace view PlayersAndGoals(name, country, ngoals)
as
select p.name, t.country, count(g.id) from Players p
    left outer join Goals g on (g.scoredby = p.id)  -- include players with 0 goals
    join Teams t on (p.memberof = t.id)
group by p.name, t.country
order by count(g.id)
;

create or replace view GoallessPlayers(country, nplayers)
as
select country, count(*) from PlayersAndGoals
where ngoals = 0
group by country
order by count(*) desc
;

create or replace view Q3(team,nplayers)
as
select country, nplayers from GoallessPlayers
where nplayers = (select max(nplayers) from GoallessPlayers)
;

