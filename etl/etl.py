# Imports
import pandas as pd
from sqlalchemy import create_engine
import os

# Get current working directory
cwd = os.getcwd()

# Instantiate sqlachemy.create_engine object
engine = create_engine('postgresql://covid19_user:covid19_pass@postgres-db:5432/covid19')


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

# Drop rows with na values in the PK
df.dropna(subset=['state_id'], inplace=True)

# Drop rows for duplicates values in the PK
df.drop_duplicates(subset=['state_id'], inplace=True)

# Replace some long state name for shorter versions
df.loc[ df['state_id'] == 94, 'state_name'] = 'Tierra del Fuego'
df.loc[ df['state_id'] == 2, 'state_name'] = 'CABA'

# Save the data from dataframe to postgres table "state"
df.to_sql(
    'state', 
    engine,
    schema='public',
    index=False,
    if_exists='append'
)


# Read from csv "departamentos.csv'"
df = pd.read_csv(f'{cwd}/data/departamentos.csv')

# Select a subset of columns
columns = ['id', 'nombre', 'provincia_id']
df = pd.DataFrame(df, columns=columns)

# Rename columns
df. rename(columns = {
    'id':'department_id', 
    'nombre':'department_name', 
    'provincia_id':'state_id'},
    inplace = True)

# Drop rows with na values in the PK
df.dropna(subset=['department_id'], inplace=True)

# Drop rows for duplicates values in the PK
df.drop_duplicates(subset=['department_id'], inplace=True)

# Save the data from dataframe to postgres table "department"
df.to_sql(
    'department', 
    engine,
    schema='public',
    index=False, 
    if_exists='append' 
)


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