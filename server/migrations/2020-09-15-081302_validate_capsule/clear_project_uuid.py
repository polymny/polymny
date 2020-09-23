#!/usr/bin/env python
# -*- coding: utf-8 -*-
import sys
import re
import psycopg2


UUID_REGEXP ='(__\w{8}-\w{4}-\w{4}-\w{4}-\w{12})'



def replace_name( sample):
    if re.search(UUID_REGEXP, sample, re.I):
        res = re.split(UUID_REGEXP, sample, re.I)[0]
        print("replace {} by {}".format(sample,res))
        return res
    else:
        return None


def update_project(conn,project_name, pid):
    sql =sql = """ UPDATE projects
                SET project_name = %s
                WHERE id = %s"""
    try :
        # create a new cursor
        cur = conn.cursor()
        # execute the UPDATE  statement
        cur.execute(sql, (project_name, pid))
        # get the number of updated rows
        updated_rows = cur.rowcount
        # Commit the changes to the database
        conn.commit()
        # Close communication with the PostgreSQL database
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)

def update_capsule(conn,name, cid):
    sql =sql = """ UPDATE capsules
                SET name = %s
                WHERE id = %s"""
    try :
        # create a new cursor
        cur = conn.cursor()
        # execute the UPDATE  statement
        cur.execute(sql, (name, cid))
        # get the number of updated rows
        updated_rows = cur.rowcount
        # Commit the changes to the database
        conn.commit()
        # Close communication with the PostgreSQL database
        cur.close()
    except (Exception, psycopg2.DatabaseError) as error:
        print(error)


def main(argv):
    """ Main program """
    try:
        url = argv.pop()
        conn = psycopg2.connect(url)
        # create a psycopg2 cursor that can execute queries
        cursor = conn.cursor()
        # run a SELECT statement - no data in there, but we can try it
        cursor.execute("""SELECT id, project_name from projects""")
        rows = cursor.fetchall()
        cursor.close()
        for  (pid, project_name) in rows:
            res = replace_name(project_name)
            if res :
                update_project(conn, res, pid)

        cursor = conn.cursor()
        cursor.execute("""SELECT id, name from capsules""")
        rows = cursor.fetchall()
        cursor.close()
        for  (cid, name) in rows:
            res = replace_name(name)
            if res :
                update_capsule(conn, res, cid)

    except Exception as e:

        print("Uh oh, can't connect. Invalid dbname, user or password?")
        print(e)
    finally:
        conn.close()



    return 0

if __name__ == "__main__":
    main(sys.argv[1:])
