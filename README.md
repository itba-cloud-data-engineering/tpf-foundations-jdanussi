# Trabajo Práctico Final Foundations
## ITBA - Cloud Data Engineering
<br>

### Resumen

Se creo un pipeline de datos utlizando Docker, PostgresSQL, Python y SQLAlchemy. La aplicación descarga el dataset de casos de Covid19 registrados en Argentina desde el año 2020 ( https://datos.gob.ar/dataset/salud-covid-19-casos-registrados-republica-argentina ) y datasets adicionales con datos geográficos de Localidades y Departamentos del país.  
Sobre los datos obtenidos se aplican filtros y transformaciones antes de ser cargados en una base Postgres. Finalmente se ejecutan consultas sobre la base de datos y se presentan por pantalla los siguientes resultados:

- Casos confirmados totales para el año en curso.

- Casos confirmados por mes para el año en curso.

- Casos confirmados por semana para los últimos 2 meses.

- Casos confirmados en el último mes agrupados por ***Sexo*** y ***Edad***. 

- Casos confirmados en el último mes agrupados por ***Localidad***. 
<br><br>  


El pipeline está compuesto por los siguientes contenedores Docker:

- **Contenedor de Base de Datos PostgreSQL (postgres-db)**: Ejecuta el servicio de PosgresSQL exponiendo el puerto TCP 5432 por defecto, inicializando durante el arranque una nueva base de datos, usuario/rol y las tablas necesarias.  

- **Contenedor ETL (python-etl)**: Ejecuta el script de Python **etl.py** que toma los archivos CSV de los datasets descargados y utilizando SQLAlchemy y Pandas, se aplican filtros y transformaciones sobre los datos antes de cargarlos en la base.

- **Contendor de Reporte (python-reporter)**: Ejecuta el script de Python **report.py** que realiza consultas sql sobre la base de datos y presenta los resultados por pantalla. 

El pipeline es orquestado por el script de shell **pipeline_covid19.sh** que concatena las tareas a realizar.<br><br>  

  
### Contenedor de Base de Datos PostgreSQL (postgres-db)

Para construir este contenedor se utilizó la imagen Docker oficial [postgres:alpine3.15](https://hub.docker.com/layers/postgres/library/postgres/alpine3.15/images/sha256-8222f913d0a4ea8f7a825556555dbeedd5a0c1544896e351f3b3a18095c0f209?context=explore) que se basa en la versión 14.3 de PostgreSQL.  

Los archivos y directorios relacionados con esta parte de la aplicación son:

![postgres-db tree](images/tree-01-postgres-db.png)  


Se utiliza el siguiente Dockerfile para generar otra imagen levemente customizada que incorpora los scripts de inicialización de base de datos y de creación de tablas.


    FROM postgres:alpine3.15

    # Init script to create user/rol and database on postgres first run
    COPY init_user_db.sh /docker-entrypoint-initdb.d

    # Utility script to run DDL tasks on the database (Ex. Create /Alter tables)
    # The script executes the files located in /sql/*.sql in alphabetical order.
    # The *.sql files must be provisioned to the container via a local mounted volume.
    COPY sql_util.sh /usr/local/bin

    # Expose default postgres port
    EXPOSE 5432
  

El script de inicialización **init_user_db.sh** crea la base de datos **covid19** y un usuario específico **covid19_user** al que se le asignan todos los privilegios sobre la misma:

    #!/bin/bash
    set -e

    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER"<<-EOSQL
        CREATE ROLE covid19_user WITH LOGIN PASSWORD 'covid19_pass';
        CREATE DATABASE covid19;
        GRANT ALL PRIVILEGES ON DATABASE covid19 TO covid19_user;
    EOSQL


El script **sql_util.sh** crea las tablas necesarias, ejecutando en orden alfabético los archivos ***.sql** de sentencias que se provisionan al contenedor por medio del montaje de un directorio del host local:

    #!/bin/bash
    set -e

    for file in /sql/*; do
        psql -U covid19_user -d covid19 -f "$file"
    done
   

Este script es de uso general y puede utilizarse para realizar tareas de DDL sobre la base de datos. Para ello hay que ubicar los archivos de sentencias ***.sql** en el directorio del host local que mapea al volumen **/sql/** del contenedor y ejecutar

    $ docker exec -it postgres-db /usr/local/bin/sql_util.sh
   
Se utilizan 2 archivos de creación de tablas para mostrar que **sql_util.sh** es capaz de realizar un procesamiento múltiple.

Script **01_create_tables.sql**:  

    -- Recreate table 'state'
    DROP TABLE if exists state cascade;
    CREATE TABLE state (
        state_id INT NOT NULL,
        state_name varchar(100) NOT NULL,
        timestamp timestamp default current_timestamp,
        PRIMARY KEY (state_id)
    );

    -- Recreate table 'department'
    DROP TABLE if exists department cascade;
    CREATE TABLE IF NOT EXISTS department (
        department_id INT NOT NULL,
        department_name varchar(450) NOT NULL,
        state_id INT NOT NULL,
        timestamp timestamp default current_timestamp,
        PRIMARY KEY (department_id),
        CONSTRAINT fk_state FOREIGN KEY(state_id) REFERENCES state(state_id)
    );

Script **02_create_more_tables.sql**:  

    -- Recreate table 'covid19_case'
    DROP TABLE if exists covid19_case cascade;
    CREATE TABLE IF NOT EXISTS covid19_case (
        covid_case_id SERIAL,
        covid_case_csv_id INT NOT NULL,
        gender_id CHAR(2),
        age INT,
        symptoms_start_date DATE,
        registration_date DATE,
        death_date DATE,
        respiratory_assistance CHAR(2),
        registration_state_id INT NOT NULL,
        clasification varchar(50),
        residence_state_id INT NOT NULL,
        diagnosis_date DATE,
        residence_department_id INT,
        last_update DATE,
        timestamp timestamp default current_timestamp,
        PRIMARY KEY (covid_case_id),
        CONSTRAINT fk_state FOREIGN KEY(registration_state_id) REFERENCES state(state_id)
    );

Se muestra a continuación el diagrama entidad-relación de las 3 tablas, con los campos elegidos. 

![ER diagram](images/ER_diagram.png)  
  
En la sección de ETL se explican algunas deciciones tomadas para establecer este modelo.

El contenedor se ejecuta por medio de docker-compose, utilizando el siguiente archivo **yalm**:

    version: '3.7'
    services:
      db:
        image: jdanussi/postgres-db:v1
          build:
            context: ./postgres-db
            dockerfile: Dockerfile
          container_name: postgres-db
          hostname: postgres-db
          environment:
            - POSTGRES_USER=postgres
            - POSTGRES_PASSWORD=postgres123
          ports:
            - "5432:5432"
          volumes:
            - ./postgres-data:/var/lib/postgresql/data
            - ./sql:/sql

    networks:
      default:
        name: covid19_net



A continuación se destacan algunas secciones.

Se realiza un **build** de la imagen durante el lanzamiento del contenedor

    image: jdanussi/postgres-db:v1
      build:
        context: ./postgres-db
        dockerfile: Dockerfile

Se montan 2 volúmenes

    volumes:
      - ./postgres-data:/var/lib/postgresql/data
      - ./sql:/sql


- la carpeta del host local **postgres-data/** se mapea a la carpeta del contenedor **/var/lib/postgresql/data** (ruta por defecto para la base de datos en postgreSQL). Esto permite que los datos almacenados en la base persistan al contenedor cuando este se apague o elimine.

- La carpeta **./sql** que contiene los scripts de creación de tablas, se mapea a la carpeta del mismo nombre dentro del contendor.  

Se crea la red **covid19_net** que luego va a ser referenciada en el lanzamiento de los otros contenedores

    networks:
      default:
        name: covid19_net

<br><br>


### Contenedor ETL (python-etl)

Para este contenedor se utilizó la imagen Docker oficial [python:3.10.4-slim](https://hub.docker.com/layers/python/library/python/3.10.4-slim/images/sha256-009b035378e9a3224e0f203feecc61509836445088f31c232d1e606ff7aa4a5e?context=explore). 
El contenedor ejecuta el script **etl.py** que toma los archivos CSV de los datasets descargados y utilizando SQLAlchemy y Pandas, aplica filtros y transformaciones sobre los datos antes de cargarlos en la base.

En la primera parte importamos las dependencias y establecemos la conexión a la base de datos

    # Imports
    import pandas as pd
    from sqlalchemy import create_engine
    import os

    # Get current working directory
    cwd = os.getcwd()

    # Instantiate sqlachemy.create_engine object
    engine = create_engine('postgresql://covid19_user:covid19_pass@postgres-db:5432/covid19')


Luego cargamos el CSV en una Dataframe de Pandas, seleccionando y renombrando las columnas que nos interesan

    # Read from csv "provincias.csv'"
    df = pd.read_csv(f'{cwd}/data/provincias.csv')

    # Select a subset of columns
    columns = ['id', 'nombre']
    df = pd.DataFrame(df, columns=columns)

    # Rename columns
    df. rename(columns = {
        'id':'state_id', 
        'nombre':'state_name'}, 
        inplace = True)


Descartamos los registros duplicados y (por las dudas!) aquellos que no contengan un dato numérico en la Primary Key 

    # Drop rows with na values in the PK
    df.dropna(subset=['state_id'], inplace=True)

    # Drop rows for duplicates values in the PK
    df.drop_duplicates(subset=['state_id'], inplace=True)

Reemplazamos el nombre de 2 localidades por versiones más cortas, para que no rompan el reporte

    # Replace some long state name for shorter versions
    df.loc[ df['state_id'] == 94, 'state_name'] = 'Tierra del Fuego'
    df.loc[ df['state_id'] == 2, 'state_name'] = 'CABA'

Y finalmente el Dataframe se carga a la tabla **state** de la base de datos

    # Save the data from dataframe to postgres table "state"
    df.to_sql(
        'state', 
        engine,
        schema='public',
        index=False,
        if_exists='append'
    )

Para el dataset **Departamentos.csv** se realiza practicamente lo mismo, con la salvedad que no se cambia el nombre de ningún departamento.

Como el dataset **Covid19Casos.csv** contiene aproximadamente 29 millones de registros, se trata la transformación y carga de datos por lotes o "chunks", para no saturar la memoria del equipo local donde se construyó y ejecutó el pipeline.

Se setean lotes de 30000 registros para cada uno de los cuales:
- Se seleccionan y renombran columnas.
- Se descartan registros con valores no númericos en la PK del CSV (**covid_case_csv_id**).
- Se descartan los registros que no correspondan al año en curso.
- Se descartan los registros que tengan valor de localidad (**registration_state_id = 0**)
- Se descartan los registros que no tengan valor de "Edad". 
- Se cambia el tipo de la columna **age** de float a entero.

A continuación se muestra el código mencionado:

    # Iterable to read "chunksize=30000" rows at a time from the CSV file

    columns = [
        'id_evento_caso', 'sexo', 'edad', 'fecha_inicio_sintomas', 'fecha_apertura',
        'fecha_fallecimiento', 'asistencia_respiratoria_mecanica', 'carga_provincia_id',
        'clasificacion_resumen', 'residencia_provincia_id', 'fecha_diagnostico',
        'residencia_departamento_id', 'ultima_actualizacion']


    # Read from csv "Covid19Casos.csv"
    for df in pd.read_csv(f'{cwd}/data/Covid19Casos.csv', chunksize=30000):

        # Select a subset of columns
        df = pd.DataFrame(df, columns=columns)

        # Rename columns
        df.rename(columns = {
            'id_evento_caso':'covid_case_csv_id',
            'sexo':'gender_id',
            'edad':'age',
            'fecha_inicio_sintomas':'symptoms_start_date',
            'fecha_apertura':'registration_date',
            'fecha_fallecimiento':'death_date',
            'asistencia_respiratoria_mecanica':'respiratory_assistance',
            'carga_provincia_id':'registration_state_id', 
            'clasificacion_resumen':'clasification',
            'residencia_provincia_id':'residence_state_id',
            'fecha_diagnostico':'diagnosis_date', 
            'residencia_departamento_id':'residence_department_id', 
            'ultima_actualizacion':'last_update'},
            inplace = True)
        
        try:
            # Drop rows with na values in "covid_case_csv_id" column
            df.dropna(subset=['covid_case_csv_id'], inplace=True)

            # Select only rows for the current year
            df.drop(df[df.registration_date.str[:4] != '2022'].index,  inplace = True)

            # Drop rows for duplicates values in "covid_case_csv_id" column
            df.drop_duplicates(subset=['covid_case_csv_id'], inplace=True)

            # Drop rows "registration_state_id" = 0 (not in "state" table)
            df.drop(df[df['registration_state_id'] == 0].index, inplace = True)

            # Drop rows without "age"
            df.dropna(subset=['age'], inplace=True)
        
            # Change the type of "age" column to integer
            df['age'] = df['age'].astype('int64')
        
            # Save the data from dataframe to postgres table "covid19_case"
            df.to_sql(
                'covid19_case', 
                engine,
                schema='public',
                index=False,
                if_exists='append' 
                )
        except:
            raise


#### Registros duplicados

Los registros duplicados generaban errores de base de datos (duplicidad de Primary Key) al tratar de hacer el insert con **df.to_sql**<br> 
Pese a los chequeos que se realizan en cada lote para descartar duplicados, no fué posible deshacerse del problema. Se probaron chunksizes de 10000, 20000 y 30000 registros sin conseguir ubicar a los duplicados dentro de un mismo lote para ser descartados. Claramente estos registros están "alejados" entre si en el dataset y nada garantiza que si un chunksize determinado resuelva el problema actual, en un futuro, cuando se actualice el dataset, vuelva a generarse el mismo problema.<br>

Si se carga **todo** el dataset en Pandas, eliminar los duplicados es sencillo. Pero no era una opción dada la limitante de memoria del equipo local que corrió el pipeline.<br>

Se utilizó por tanto la estrategia de crear otra PK (**covid_case_id**) de tipo **SERIAL**, almacenando el id original del CSV en el campo **covid_case_csv_id** de tipo **INT NOT NULL** pero sin ningún otro constraint.<br> 

Una vez finalizada la carga del dataset en la tabla **covid19_case**, se eliminan los duplicados como sigue:

    # Delete duplicates on "covid_case_csv_id"
    with engine.connect() as connection:
        connection.execute("""
        DELETE FROM covid19_case a USING (
          SELECT MIN(covid_case_id) as covid_case_id, covid_case_csv_id
            FROM covid19_case 
            GROUP BY covid_case_csv_id HAVING COUNT(*) > 1
          ) b
          WHERE a.covid_case_csv_id = b.covid_case_csv_id
          AND a.covid_case_id <> b.covid_case_id;
        """)

<br><br>


### Contendor de Reporte (python-reporter)

Para este contenedor se utilizó la misma imagen [python:3.10.4-slim](https://hub.docker.com/layers/python/library/python/3.10.4-slim/images/sha256-009b035378e9a3224e0f203feecc61509836445088f31c232d1e606ff7aa4a5e?context=explore) que para el caso anterior. 
El contenedor corre el script **report.py** que recoje del directorio **sql/** las queries a ajecutar contra la base de datos, imprimiendo por pantalla los resultados.

A continuación se describe rápidamente el código.

Se importan dependencias y se define la función **connect()** para conectar a la base de datos y la **query_execute()** que es la encargada de ejecutar las queries sql 

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
        f.write("=" * 76 + '\n')
        f.write(df.to_string(index=False))
        f.write('\n\n')
        
        if conn is not None:
            conn.close()


Y en la parte principal, se genera la salida por pantalla:

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

<br><br>


### Script orquestador **pipeline_covid19.sh**

Todo el pipeline es orquestado por el script de shell **pipeline_covid19.sh** que se encarga de ejecutar las tareas en forma secuencial, para que cada contenedor tenga lo que necesita al momento de correr.<br>

En la primera parte se hace un restart del contenedor de base de datos, inicializando la base, el usuario y las tablas

    # Restart database container
    docker-compose down

    echo ""
    echo "--> Starting the postgres Docker container ..."
    echo ""
    docker-compose up -d &
    sleep 10

    echo ""
    echo "--> Initializing the database, user/rol and tables ..."
    echo ""
    docker exec postgres-db /usr/local/bin/sql_util.sh


Luego se realiza la descarga de los datasets desde la página oficial del gobierno. Se utiliza **curl** para la descarga de los CSV de localidades y departamentos, y el script utilitario **download_from_link.sh** que además de la descarga, hace la descompresión del .zip.

    # Download the datasets
    source download_from_link.sh
    echo ""
    echo "--> Downloading the geographic datasets ..."
    echo ""
    curl -LO --output-dir "etl/data" "https://infra.datos.gob.ar/catalog/modernizacion/dataset/7/distribution/7.7/download/provincias.csv"
    echo ""
    curl -LO --output-dir "etl/data" "https://infra.datos.gob.ar/catalog/modernizacion/dataset/7/distribution/7.8/download/departamentos.csv" -P "etl/data"

    echo ""
    echo "--> Downloading the last version of Covid19 dataset ..."
    echo ""
    download_from_link "https://sisa.msal.gov.ar/datos/descargas/covid-19/files/Covid19Casos.zip" "etl/data"


Una vez finalizada la descarga, se ejecuta el contenedor **python-etl** que realiza la transformación y carga de los datos en la base

    # Transform and Load of data to database
    echo ""
    echo "--> Filtering, transforming and loading the data to postgres ..."
    echo ""
    docker run --rm --name python-etl --network covid19_net \
    -v $PWD/etl/data:/etl/data jdanussi/python-etl:v1


Por último se ejecuta el reporte

    # Create and output the report
    echo ""
    echo "--> Creating the report ..."
    echo ""
    docker run --rm --name python-report --network covid19_net \
    -v $PWD/report/sql:/report/sql \
    -v $PWD/report/queries.json:/report/queries.json \
    -v $PWD/report/output:/report/output \
    jdanussi/python-reporter:v1

<br>

El pipeline se lanza ejecutando

    $ bash pipeline_covid19.sh

A genera el reporte que se muestra a continuación:

    ========================================================================================= 
    COVID-19. Casos registrados en la República Argentina año 2022 
    Fuente: https://datos.gob.ar/dataset/salud-covid-19-casos-registrados-republica-argentina 
    ========================================================================================= 

    Fecha de última actualización de los datos:
    ======================================================================
    last_update
    2022-05-22


    Total de casos confirmados en el año:
    ======================================================================
    year  total_cases
    2022    3,375,343


    Casos confirmados por mes:
    ======================================================================
    registration_month  total_cases %_total_cases
               2022-01    2,673,465       79.21 %
               2022-02      450,214       13.34 %
               2022-03      126,057       03.73 %
               2022-04       40,504       01.20 %
               2022-05       85,103       02.52 %


    Casos confirmados por semana para los últimos 2 meses:
    ======================================================================
    registration_week  total_cases  %_change
           2022-03-28        2,370  000.00 %
           2022-04-04       10,020  322.78 %
           2022-04-11        7,358 -026.57 %
           2022-04-18       10,413  041.52 %
           2022-04-25       10,981  005.45 %
           2022-05-02       17,713  061.31 %
           2022-05-09       32,571  083.88 %
           2022-05-16       34,181  004.94 %


    Casos confirmados en el último mes agrupados por Sexo:
    ======================================================================
    last_registration_month  gender  total_cases %_total_cases
                    2022-05  Female    1,802,149       53.39 %
                    2022-05    Male    1,568,722       46.48 %
                    2022-05 no_data        4,472       00.13 %


    Casos confirmados en el último mes agrupados por Edad:
    ======================================================================
    last_registration_month age_segment  total_cases %_total_cases
                    2022-05        0<20      339,036       10.04 %
                    2022-05       20-39    1,571,903       46.57 %
                    2022-05       40-59    1,032,776       30.60 %
                    2022-05       60-79      371,959       11.02 %
                    2022-05         >80       59,669       01.77 %


    Casos confirmados en el último mes agrupados por Localidad:
    ======================================================================
    last_registration_month          state_name  total_cases %_total_cases
                    2022-05        Buenos Aires    1,324,121       39.84 %
                    2022-05                CABA      438,581       13.20 %
                    2022-05             Córdoba      372,120       11.20 %
                    2022-05            Santa Fe      249,505       07.51 %
                    2022-05             Tucumán      107,781       03.24 %
                    2022-05             Mendoza       97,814       02.94 %
                    2022-05            San Juan       73,811       02.22 %
                    2022-05               Chaco       63,196       01.90 %
                    2022-05          Entre Ríos       60,087       01.81 %
                    2022-05               Salta       59,656       01.79 %
                    2022-05               Jujuy       53,014       01.60 %
                    2022-05             Formosa       50,490       01.52 %
                    2022-05             Neuquén       48,108       01.45 %
                    2022-05 Santiago del Estero       39,202       01.18 %
                    2022-05           Río Negro       38,587       01.16 %
                    2022-05            Misiones       37,589       01.13 %
                    2022-05          Corrientes       36,371       01.09 %
                    2022-05            La Pampa       36,127       01.09 %
                    2022-05              Chubut       32,666       00.98 %
                    2022-05           Catamarca       29,713       00.89 %
                    2022-05          Santa Cruz       25,199       00.76 %
                    2022-05            La Rioja       21,405       00.64 %
                    2022-05            San Luis       14,719       00.44 %
                    2022-05    Tierra del Fuego       13,643       00.41 %


<br>

### Docker Hub
Las imágenes Docker utilizadas en el pipeline se encuentran publicadas en Docker Hub<br>
https://hub.docker.com/

<br>

### GitHub

Todo el código se puede hallar en GitHub:<br>
https://github.com/itba-cloud-data-engineering/tpf-foundations-jdanussi

<br><br>

### Cuestiones para mejorar

Seguramente son muchas las mejoras que se pueden hacer, pero se me ocurren como principales las siguientes:
<br>

1. Que el pipeline sea capaz de incorporar datos nuevos de forma diferencial, por medio de **upserts**. Actualmente reconstruye ***la base con sus tablas*** en cada corrida.<br>

2. Se exponen credenciales en los Dockerfiles y en el archivo de **docker-compose.yml**. Habría que gestionar estos datos mediante variables de entorno para evitar que las credenciales queden expuestas en los repositorios.<br>

3. En **etl.py** habría que incorporar un método que realice la descarga de los datasets. Actualmente esta tarea se realiza con scripts de shell por fuera del contenedor. Estaría bueno encapsular toda la función de ETL en el contendor **python-etl**.<br>
