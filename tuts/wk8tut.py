#!usr/bin/python3
import argparse
import sys
import psycopg2

# Opening a connection
def do_stuff(class_roll, subject, term, conn):
    # Get a cursor from the database (this is the object we use to query the database)
    cursor = conn.cursor

    # check if term exists
    termExists = "select id from Terms where termName(id) = %s"
    cursor.execute(termExists, [term])
    if cursor.fetchone() is None:
        print("Invalid term {term}")
        return

    # check if subject exists
    subjectExists = "select id from Subjects where code = %s"
    cursor.execute(subjectExists, [subject])
    res = cursor.fetchone()
    if res is None:
        print("Invalid subject {subject}")
        return
    _, subject_name = res

    # check if course is offered in that term
    courseTermOffering = "select * from Courses where subject = %s and term = %s"
    cursor.execute(courseTermOffering, [subject, term])
    res = cursor.fetchone()
    if res is None:
        print(f"{subject} not offered in {term}")


    # Write a skeleton of our query
    # Prefer to write one big query over many small queries
    query = """ 
        select p.unswid, p.family, p.given
        from Subjects s
            join Courses c on (c.subject = s.id)
            join Terms t on (c.term = t.id)
            join Course_enrolments e on (c.id = e.course) 
            join People p on (e.student = p.id)
        where s.code = %s and termName(t.id) = %s
        order by p.family, p.given
    """

    # Execute the query
    cursor.execute(query, [subject, term])
    print(f"{subject} {term} {subject_name}")

    # Fetch all and manipulate the results
    results = cursor.fetchall()
    if len(results) > 0:
        for result in results:
            zid, surname, firstname = result
            print(f"{zid} {surname} {firstname}")
    else:
        print("No students")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("subject")
    parser.add_argument("term")
    # or alternatively use sys.argv
    args = parser.parse_args()

    conn = None

    # Set up a connection with the database
    try:
        conn = psycopg2.connect("dbname=mymy2")
        do_stuff(args.subject, args.term, conn)
    except psycopg2.Error as err:
        print(f"database error {err}")
    finally:
        if conn:
            conn.close()
        