# Dump table
import sys
import sqlite3

if (len(sys.argv)<2) :
    print("This script prints the list of tables of a sqlite file. It dumps the table if the name is specified.")
    print("[Path to file.db] [optional: name of the table to be dumped]")
    sys.exit(0)

pathFile = sys.argv[1] 
con = sqlite3.connect(pathFile)
cur = con.cursor()

if (len(sys.argv)<3) :
    cur.execute("SELECT * FROM sqlite_master WHERE type='table'")
    data = cur.fetchall()
    for c1, c2, c3, c4, c5 in data:
        print(c2)


else :
    tableName = sys.argv[2]
    cur.execute("SELECT * FROM "+tableName)
    data = cur.fetchall()
    for key, value in data:
        print(key+" : "+value)



con.close()