docker-compose down

echo ""
echo "--> Levantando el contenedor de postgres 12.7..."
echo ""
docker-compose up -d &
sleep 10

echo ""
echo "--> Recreando las tablas en la base covid19..."
echo ""
docker exec postgres-db /usr/local/bin/sql_util.sh

source download_from_link.sh
echo ""
echo "--> Haciendo download de los datasets de Provincias y Departamentos de Argentina..."
echo ""
curl -LO --output-dir "etl/data" "https://infra.datos.gob.ar/catalog/modernizacion/dataset/7/distribution/7.7/download/provincias.csv"
echo ""
curl -LO --output-dir "etl/data" "https://infra.datos.gob.ar/catalog/modernizacion/dataset/7/distribution/7.8/download/departamentos.csv" -P "etl/data"

echo ""
echo "--> Haciendo download de la ultima versión de casos de Covid19 publicados por el gobierno..."
echo ""
download_from_link "https://sisa.msal.gov.ar/datos/descargas/covid-19/files/Covid19Casos.zip" "etl/data"

echo ""
echo "--> Haciendo la transformación y la carga de los datos en la base..."
echo ""
docker run --rm --name python-etl --network covid19_net \
-v /home/jorge/pipeline_covid19/etl/data:/etl/data jdanussi/python-etl:v1

echo ""
echo "--> Generando el reporte..."
echo ""
docker run --rm --name python-report --network covid19_net \
-v /home/jorge/pipeline_covid19/report/sql:/report/sql jdanussi/python-reporter:v1