-- COMP3311 20T3 Assignment 2

-- Q1: students who've studied many courses
-- select unswid and name from People where Student has studied > 65 courses
-- group by the person
create or replace view Q1(unswid,name)
as
   select p.unswid, p.name from People p, Course_enrolments c
   where c.student = p.id 
   group by p.unswid, p.name 
   having count(c.student) > 65
;

-- Q2: numbers of students, staff and both
-- select count of students, count of staff and count of both 
create or replace view Q2(nstudents,nstaff,nboth)
as 
select
    (select count(*) 
    from Students stu
    left join Staff stf on stu.id = stf.id
    where stf.id is null),

    (select count(*) 
    from Staff stf
    left join Students stu on stf.id = stu.id
    where stu.id is null),

    (select count(*) 
    from Students stu, Staff stf 
    where stu.id = stf.id)
;

-- Q3: prolific Course Convenor(s)
-- select LIC name and no. of courses they have been LIC for 
-- where LIC.role = "Course Convenor"
create or replace view Q3(name,ncourses)
as
   select p.name, count(*) as ncourses 
   from People p
      join Staff s on s.id = p.id
      join Course_staff cs on cs.staff = p.id
      join Staff_roles sr on sr.id = cs.role
   where sr.name = 'Course Convenor'
   group by p.name
   order by ncourses desc
   limit 1
;      

-- Q4: Comp Sci students in 05s2 and 17s1
-- select People.unswid and People.name where enrolled in 3978 degree in 05s2
create or replace view Q4a(id,name)
as
select ppl.unswid, ppl.name from People ppl
   join Program_enrolments pe on pe.student = ppl.id
   join Programs p on p.id = pe.program
   join Terms t on t.id = pe.term
where t.year = '2005' and t.session = 'S2' and p.code = '3978'
;

create or replace view Q4b(id,name)
as
select ppl.unswid, ppl.name from People ppl
   join Program_enrolments pe on pe.student = ppl.id
   join Programs p on p.id = pe.program
   join Terms t on t.id = pe.term
where t.year = '2017' and p.code = '3778' and (t.session = 'S1' or t.session = 'T1')
;

-- Q5: most "committee"d faculty
create or replace view Q5(name)
as
   select most_committeed.name 
   from
      (select count(*) as commitee_count, orgunits.name from orgunits 
      join
         (select facultyOf(orgunits.id) as id from orgunits 
            left join orgunit_types on orgunits.utype = orgunit_types.id
            group by orgunits.id, orgunit_types.name
            having orgunit_types.name = 'Committee'
            order by id
         ) as faculties
      on orgunits.id = faculties.id
      group by orgunits.name
      order by commitee_count desc
      limit 1
      ) as most_committeed
;

-- Q6: nameOf function

create or replace function
   Q6(id integer) returns text
as $$
    select p.name from People p where p.id = $1 or p.unswid = $1;
$$ language sql;

-- Q7: offerings of a subject

create or replace view Subject_code(code, term, convenor)
as
select sbj.code, termname(t.id), p.name from Staff_roles sr
   join Course_staff cs on sr.id = cs.role
   join Courses c on c.id = cs.course
   join Subjects sbj on sbj.id = c.subject
   join Terms t on c.term = t.id 
   join People p on p.id = cs.staff
where sr.name = 'Course Convenor';

create or replace function
   Q7(subject text)
     returns table (subject text, term text, convenor text)
as $$
   select text(sc.code), sc.term, sc.convenor from Subject_code sc where sc.code = $1;
$$ language sql;

-- Q8: transcript

create or replace function
   Q8(zid integer) returns setof TranscriptRecord
as $$
declare
   r TranscriptRecord;
   wamValue integer := 0;        -- weightedSum / totalUOC
   UOCpassed integer := 0;       -- sum of UOC for all subjects passed
   totalUOC integer := 0;        -- sum of UOC for all subjects attempted in transcript (including failed sbjs)
   weightedSum integer := 0;     -- sum of mark * UOC for all subjects in transcript
begin
   perform s.id 
   from Students s join People p on s.id = p.id 
   where p.unswid = zid;
   if (not found) then
      raise exception 'Student not found';
   end if;
   for r in 
      select sbj.code, termname(t.id), pr.code, substr(sbj.name, 1, 20), ce.mark, ce.grade, sbj.uoc
      from People p
         -- join the tables containing relevant info needed to store in each record
         join Students s on s.id = p.id
         join Course_enrolments ce on ce.student = s.id
         join Courses c on ce.course = c.id
         join Subjects sbj on sbj.id = c.subject
         join Terms t on t.id = c.term
         join Program_enrolments pe on pe.student = s.id
         join Programs pr on pr.id = pe.program
      where p.unswid = zid
      order by sbj.code
   loop
      if (r.grade in ('SY', 'XE', 'T', 'PE')) then
         -- if course has null mark but has SY, XE, T, or PE grade, include UOC in UOCpassed only
         UOCpassed := UOCpassed + r.uoc;
      elsif (r.mark is not null) then
         if (r.grade in ('SY', 'PT', 'PC', 'PS', 'CR', 'DN', 'HD', 'A', 'B', 'C', 'RC', 'RS')) then
            -- only display UOC value if student passed the course
            UOCpassed := UOCpassed + r.uoc;
         end if;
         -- do WAM calculations (failed courses included)
         totalUOC := totalUOC + r.uoc;
         weightedSum := weightedSum + (r.mark * r.uoc);
      end if;
      return next r;
   end loop;

   -- At the end of the transcript, add an extra TranscriptRecord containing wam and uoc
   if (totalUOC = 0) then
      -- If no courses have been completed:
      r := (null, null, null, 'No WAM available', null, null, null);
   else 
      r := (null, null, null, 'Overall WAM/UOC', wamValue, null, UOCpassed);
   end if;
   return next r;
end;
$$ language plpgsql;

-- Q9: members of academic object group
-- write a function that takes the ID of an acad obj group 
-- and returns the code for all members of the acad obj group including child groups
create or replace function
   Q9(gid integer) returns setof AcObjRecord
as $$
declare
   r AcObjRecord;
   obj_type text;    -- academic object's type e.g. subject, stream, program
	obj_code text;    -- academic object's code e.g. COMP3311, SENGA1, 3978
   obj_defby text;   -- how the group is defined
   obj_defn text;    -- where queries or patterns are given
begin
   select aog.gtype, aog.gdefby, aog.definition 
   into obj_type, obj_defby, obj_defn
   from Acad_object_groups aog
   where aog.id = $1;

   -- if obj_type is select, 
   -- don't handle patterns with 'FREE', 'GEN' or 'F=' as a substring
   if (obj_type = 'subject') then
      for obj_code in 
         select distinct sbj.code 
         from Subjects sbj
         where sbj.code not like 'FREE%' and sbj.code not like 'GEN%' and sbj.code not like 'F=%'
         group by sbj.code
         order by sbj.code
      loop
         r := (obj_type, obj_code);
         return next r;
      end loop;

   elsif (obj_type = 'stream') then
      for obj_code in 
         select distinct st.code 
         from Streams st 
         group by st.code
         order by st.code
      loop
         r := (obj_type, obj_code);
         return next r;
      end loop;

   else 
      for obj_code in 
         select distinct p.code 
         from Programs p
         group by p.code
         order by p.code
      loop
         r := (obj_type, obj_code);
         return next r;
      end loop;
   end if;
end;
$$ language plpgsql;

-- Q10: follow-on courses

create or replace function
   Q10(code text) returns setof text
as $$
...
$$ language plpgsql;
