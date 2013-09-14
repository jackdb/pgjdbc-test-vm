# Create user 'test':
$PSQL -c "CREATE USER test WITH PASSWORD 'test'"

# Create SSL databases:
for db in $DB_LIST
do
  $PSQL -c "CREATE DATABASE $db WITH OWNER test"
done
