import psycopg2
from config.config import config

import pandas as pd

import datetime
import json
import os


def connect():
    """ Connect to the PostgreSQL database server """
    conn = None
    try:
        # read connection parameters
        params = config()

        # connect to the PostgreSQL server
        conn = psycopg2.connect(**params)

        return conn

    except (Exception, psycopg2.DatabaseError) as error:
        print(error)


def query_execute(title, query):
    """ Execution of sql statements and output the results"""
    conn = connect()

    # create a cursor
    cur = conn.cursor()

    # execute a statement
    sql=open(SQL_DIR + query, "r").read()
    cur.execute(sql)

    df = pd.DataFrame(cur.fetchall())
    colnames = [desc[0] for desc in cur.description]
    df.columns = colnames

    f.write('\n' + title + '\n') 
    f.write("=" * 70 + '\n')
    f.write(df.to_string(index=False))
    f.write('\n\n')
    
    if conn is not None:
        conn.close()



if __name__ == '__main__':

    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    SQL_DIR = os.path.join(BASE_DIR, 'sql/') 
    OUTPUT_DIR = os.path.join(BASE_DIR, 'output/') 

    # Opening JSON file
    with open('queries.json') as json_file:
        queries = json.load(json_file)
  
    # Save report to file
    report = f"{OUTPUT_DIR}report_" + datetime.datetime.now().strftime("%Y%m%d_%H%M%S")

    with open(report + '.txt', 'w') as f:
        
        f.write('\n')
        f.write('========================================================================================= \n')
        f.write('COVID-19. Casos registrados en la República Argentina año 2022 \n')
        f.write('Fuente: https://datos.gob.ar/dataset/salud-covid-19-casos-registrados-republica-argentina \n')
        f.write('========================================================================================= \n')

        for query in queries.values():
            query_execute(query['title'], query['query'])

    # Print report to screen    
    with open(report + '.txt', 'r') as f:
        contents = f.read()
        print(contents)
