FROM postgres:alpine3.15

# Init script to create user/rol and database on postgres first run
COPY init_user_db.sh /docker-entrypoint-initdb.d

# Utility script to run DDL tasks on the database (Ex. Create /Alter tables)
# The script executes the files located in /sql/*.sql in alphabetical order.
# The *.sql files must be provisioned to the container via a local mounted volume.
COPY sql_util.sh /usr/local/bin

# Expose default postgres port
EXPOSE 5432