-- COMP3311 20T3 Assignment 1
-- Calendar schema
-- Written by Luis Zhang

-- Types

create type AccessibilityType as enum ('read-write','read-only','none');
create type InviteStatus as enum ('invited','accepted','declined');
create type VisiblityType as enum ('public', 'private');
create type DayType as enum ('Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun');

-- add more types/domains if you want

-- Tables

create table Users (
	id          serial,
	email       text not null unique,
	name        text not null,
    passwd      text not null,
    is_admin    boolean not null,    
	primary key (id)
);

create table Groups (
	id                  serial,
	name                text not null,
    owner               integer not null,
	primary key (id),
    foreign key (owner) references Users(id)
);

create table Calendars (
	id                  serial,
	name                text not null,
	colour              text not null,
    default_access      AccessibilityType not null, 
    owner               integer not null, 
	primary key (id),
    foreign key (owner) references Users(id)
);

create table Events (  
    id              serial,
	title           text not null,
	startTime       time,
    endTime         time,
    visibility      VisiblityType not null, 
    location        text,
    part_of         integer not null, 
    created_by      integer not null, 
	primary key (id),
    foreign key (created_by) references Users(id),
    foreign key (part_of) references Calendars(id)
);

create table OneDayEvents (
    id          integer primary key,
    date        date not null,
    foreign key (id) references Events(id)
);

create table SpanningEvents (
    id              integer primary key,
    start_date      date not null,
    end_date        date not null,
    foreign key (id) references Events(id)
);

create table RecurringEvents (
    id              integer primary key,
    start_date      date not null,
    end_date        date,   
    ntimes          integer check (ntimes > 1),
    foreign key (id) references Events(id)
);

create table WeeklyEvents (
    id                  integer primary key,
    day_of_week         DayType not null, 
    frequency           integer not null check (frequency > 0),
    foreign key (id) references RecurringEvents(id)
);

create table MonthlyByDayEvents (
    id                  integer primary key,
    day_of_week         DayType not null, 
    week_in_month       integer not null check (week_in_month >= 1 and week_in_month <= 5),
    foreign key (id) references RecurringEvents(id)
);

create table MonthlyByDateEvents (
    id                  integer primary key,
    date_in_month       integer not null check (date_in_month >= 1 and date_in_month <= 31),
    foreign key (id) references RecurringEvents(id)
);

create table AnnualEvents (
    id          integer primary key,
    date        date not null,  
    foreign key (id) references RecurringEvents(id)
);

-- SQL cannot capture participation or disjoint-ness constraints of the event subclasses

create table Member (  
    user_id     integer references Users(id),
    group_id    integer references Groups(id), 
    primary key (user_id, group_id)
);

create table Subscribed (   
    user_id         integer references Users(id),
    calendar_id     integer references Calendars(id),
    colour          text,
    primary key (user_id, calendar_id)
);

create table Accessibility ( 
    user_id         integer references Users(id),
    calendar_id     integer references Calendars(id),
    access          AccessibilityType not null,
    primary key (user_id, calendar_id)
);

create table Invited (  
    user_id         integer references Users(id),
    event_id        integer references Events(id),
    status          InviteStatus not null,
    primary key (user_id, event_id)
);

create table Alarms (
    event_id        integer references Events(id),
    alarm           integer, 
    primary key (event_id, alarm)
);
