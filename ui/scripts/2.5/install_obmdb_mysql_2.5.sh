#!/bin/bash

test $# -eq 5 || {
    echo "usage: $0 db user password lang installation type"
    exit 1
}

db=$1
user=$2
pw=$3
obm_lang=$4
obm_installation_type=$5

if [ $obm_installation_type = "full" ]; then

  echo "*** Database creation"
  
  echo "  Delete old database if exists"
  mysql -u $user -p$pw -e "DROP DATABASE IF EXISTS $db"
  
  echo "  Create new $db database"
  mysql -u $user -p$pw -e "CREATE DATABASE $db CHARACTER SET utf8 COLLATE utf8_general_ci"
fi

echo "  Create new $db database model"
mysql -u $user -p$pw $db < create_obmdb_2.5.mysql.sql
test $? -eq 0 || {
    echo "error running mysql script"
    exit 1
}
echo "*** Database filling"

# Default data insertion
mysql --default-character-set='UTF8' -u $user -p$pw $db < obmdb_default_values_2.5.sql
test $? -eq 0 || {
    echo "error running mysql script"
    exit 1
}

# Dictionnary data insertion
echo "  Dictionnary data insertion"
mysql --default-character-set='UTF8' -u $user -p$pw $db < data-$obm_lang/obmdb_ref_2.5.sql
test $? -eq 0 || {
    echo "error running mysql script"
    exit 1
}

# Company Naf Code data insertion
echo "  Company Naf Code data insertion"
mysql --default-character-set='UTF8' -u $user -p$pw $db < data-$obm_lang/obmdb_nafcode_2.5.sql
test $? -eq 0 || {
    echo "error running mysql script"
    exit 1
}

# Preferences data insertion & Update default lang to .ini value
echo "  Default preferences data insertion"
mysql --default-character-set='UTF8' -u $user -p$pw $db < obmdb_prefs_values_2.5.sql
test $? -eq 0 || {
    echo "error running mysql script"
    exit 1
}

echo "UPDATE UserObmPref set userobmpref_value='$obm_lang' where userobmpref_option='set_lang'" | mysql -u $user -p$pw $db 

mysql --default-character-set='UTF8' -u ${user} -p$pw ${db} \
  < "updates/update-2.5.0~1.mysql.sql" >> /tmp/data_insert.log 2>&1

mysql --default-character-set='UTF8' -u ${user} -p$pw ${db} \
  < "updates/update-2.5.1~alpha1.mysql.sql" >> /tmp/data_insert.log 2>&1

echo "DONE."
