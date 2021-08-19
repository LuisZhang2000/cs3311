#!/usr/bin/python3
# COMP3311 20T3 Ass3 ... print name, year, ratings of top N movies

import sys
import psycopg2
#from helpers import whatever, functions, you, need

# define any local helper functions here

# set up some globals

usage = "Usage: best [N]"
db = None

# process command-line args

argc = len(sys.argv)

# manipulate database

if argc > 2:
  print(usage)
  exit(1)

# check if user enters a number
elif argc == 2:
  try:
    val = int(sys.argv[1])
  except ValueError:
    print(usage)
    exit(1)

query = """
select rating, title, start_year 
from Movies 
order by rating desc, title 
"""

try:
  db = psycopg2.connect("dbname=imdb")
  cur = db.cursor()
  cur.execute(query)
  movies = cur.fetchall()
  i = 0
  if len(movies) == 0:
    print("No movies")
    exit(0)
  # if no number specified, print out top 10 
  if argc == 1:
    for movie in movies:
      print(f"{movie[0]} {movie[1]} ({movie[2]})")
      i = i + 1
      if i == 10:
        break
  # print out number of movies specified by argument
  else:
    numMovies = int(sys.argv[1])
    for movie in movies:
      print(f"{movie[0]} {movie[1]} ({movie[2]})")
      i = i + 1
      if i == numMovies:
        break

except psycopg2.Error as err:
  print("DB error: ", err)
finally:
  if db:
    db.close()
    

