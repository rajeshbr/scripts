#!/bin/bash
### change the values below where needed.....
DBNAMES=""
HOST="--host="
USER="--user="
PASSWORD="--password="
BACKUP_DIR="./"

#### you can change these values but they are optional....
OPTIONS="--default-character-set=latin1 --complete-insert --no-create-info --compact -q"
RESTORESCRIPT="$BACKUP_DIR/__restoreData.sql"
DATE=`/bin/date '+%y%m%d_%H%M%S'`

#### make no changes after this....
#### start script ####
echo removing old temporary files if they exists...
rm -f ${BACKUP_DIR}/*.sql > /dev/null 2>&1
rm -f ${BACKUP_DIR}/*.tar > /dev/null 2>&1
cd ${BACKUP_DIR}

for DB in $DBNAMES
do
    echo "=========================================="
    echo ${DB}
    echo "=========================================="
    echo 'SET FOREIGN_KEY_CHECKS=0;' > $RESTORESCRIPT

    mysqldump --no-data $HOST $USER $PASSWORD $DB > ${BACKUP_DIR}/__createTables.sql
    echo 'source __createTables.sql;' >> $RESTORESCRIPT

    for TABLE in `mysql $HOST $USER $PASSWORD $DB -e 'show tables' | egrep -v 'Tables_in_' `; do
        TABLENAME=$(echo $TABLE|awk '{ printf "%s", $0 }')
        FILENAME="${TABLENAME}.sql"
        echo Dumping $TABLENAME
        echo 'source' $FILENAME';' >> $RESTORESCRIPT
        mysqldump $OPTIONS $HOST $USER $PASSWORD $DB $TABLENAME > ${BACKUP_DIR}/${FILENAME}
    done

    echo 'SET FOREIGN_KEY_CHECKS=1;' >> $RESTORESCRIPT

    echo making tar...
    tar -cf ${DB}_${DATE}.tar *.sql  > /dev/null 2>&1

    echo compressing...
    gzip -9 ${DB}_${DATE}.tar > /dev/null 2>&1

    echo removing temporary files...
    rm -f ${BACKUP_DIR}/*.sql > /dev/null 2>&1
    rm -f ${BACKUP_DIR}/*.tar > /dev/null 2>&1

    echo "done with " $DB
done

echo "=========================================="
echo "            done with all database!       "
echo "=========================================="
