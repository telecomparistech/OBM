#!/bin/sh
###############################################################################
# OBM - File : install_obmdb_1.2.pgsql.sh                                     #
#     - Desc : PostgreSQL Database 1.2 installation script                    #
# 2005-06-08 AliaSource                                                       #
###############################################################################
# $Id$
###############################################################################

# Lit le fichier de configuration global obm_conf.ini
# Code repris du fichier www/scripts/2.4/install_db_2.4.sh d'Aliamin
function getVal () {
   echo Recherche $1
   VALUE=`grep ^$1\ *= ../../conf/obm_conf.ini | cut -d= -f2 | tr -d '^ ' | tr -d '" '`
   echo $VALUE
}

# Lecture des parametres de connexion a la BD
getVal user
U=$VALUE

getVal password
P=$VALUE

getVal db
DB=$VALUE

getVal lang
OBM_LANG=$VALUE

echo "*** Parameters used : PostgreSQL"
echo "database = $DB"
echo "database user = $U"
echo "database password = $P"
echo "install lang = $OBM_LANG"


# We search for PHP interpreter (different name on Debian, RedHat, Mandrake)
PHP=`which php4 2> /dev/null`
if [ $? != 0 ]; then
  PHP=`which php 2> /dev/null`
  if [ $? != 0 ]; then
    PHP=`which php-cgi 2> /dev/null`
    if [ $? != 0 ]; then
      echo "Can't find php interpreter"
      exit
    fi
  fi
fi
echo $PHP : PHP interpreter found

echo "*** Document repository creation"
$PHP install_document_2.0.php || (echo $?; exit $?)


echo "*** Database creation"

#echo "  Delete old database if exists"
#psql -U $U template1 -c "DROP DATABASE $DB"

## XXXXXX obm postgres user creation ?

#echo "  Create new $DB database"
#psql -U $U template1 -c "CREATE DATABASE $DB with owner = $U"

echo "  Create new $DB database model"
psql -U $U $DB < create_obmdb_2.0.pgsql.sql


echo "*** Database filling"

# Dictionnary data insertion
echo "  Dictionnary data insertion"
cat postgres-pre.sql data-$OBM_LANG/obmdb_ref_2.0.sql | psql -U $U $DB

# Company Naf Code data insertion
echo "  Company Naf Code data insertion"
cat postgres-pre.sql data-$OBM_LANG/obmdb_nafcode_2.0.sql | psql -U $U $DB

# Test data insertion
echo "  Test data insertion"
cat postgres-pre.sql obmdb_test_values_2.0.sql | psql -U $U $DB

# Default preferences data insertion
echo "Default preferences data insertion"
cat postgres-pre.sql obmdb_default_values_2.0.sql | psql -U $U $DB 

# Update default lang to .ini value
echo "Default preferences data insertion"
echo "UPDATE UserObmPref set userobmpref_value='$OBM_LANG' where userobmpref_option='set_lang'" | psql -U $U $DB 


echo "*** Data checking and validation"

# Set the current dir to php/admin_data (to resolve includes then)
cd ../../php/admin_data

# Update calculated values
echo "  Update calculated values"
$PHP admin_data_index.php -a data_update

# Update phonetics ans approximative searches
echo "  Update phonetics and approximative searches"
$PHP admin_data_index.php -a sound_aka_update
