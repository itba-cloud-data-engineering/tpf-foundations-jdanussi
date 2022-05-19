import psycopg2
from config.config import config

import pandas as pd
from pandas import DataFrame

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


def query(title, query):
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

    print('\n' + title)
    print("=" * 60)
    print(df.to_string(index=False))
    print('\n')

    if conn is not None:
        conn.close()



if __name__ == '__main__':

    BASE_DIR = os.path.dirname(os.path.abspath(__file__))
    SQL_DIR = os.path.join(BASE_DIR, 'sql/') 

    print('\n')
    print('==========================================================================================')
    print('=========     COVID-19. Casos registrados en la República Argentina año 2022     =========')
    print('==========================================================================================')
    print('Fuente: https://datos.gob.ar/dataset/salud-covid-19-casos-registrados-republica-argentina ')
    print('\n')

    query(
        title='Casos confirmados por mes:',
        query='query1.sql'
        )
    
    query(
        title='Casos confirmados por semana para los últimos 2 meses:',
        query='query2.sql'
        )

    query(
        title='Casos confirmados en el último mes agrupados por Sexo:',
        query='query3.sql'
        )

    query(
        title='Casos confirmados en el último mes agrupados por Edad:',
        query='query4.sql'
        )
    
    query(
        title='Casos confirmados en el último mes agrupados por Localidad:',
        query='query5.sql'
        )