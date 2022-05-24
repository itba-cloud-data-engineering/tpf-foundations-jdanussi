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


# Transform and Load of data to database
echo ""
echo "--> Filtering, transforming and loading the data to postgres ..."
echo ""
docker run --rm --name python-etl --network covid19_net \
-v $PWD/etl/data:/etl/data jdanussi/python-etl:v1


# Create and output the report
echo ""
echo "--> Creating the report ..."
echo ""
docker run --rm --name python-report --network covid19_net \
-v $PWD/report/sql:/report/sql \
-v $PWD/report/queries.json:/report/queries.json \
-v $PWD/report/output:/report/output \
jdanussi/python-reporter:v1