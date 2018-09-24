#!/bin/bash

source .env || {
  echo "Configuration (.env) file missing"
  exit 1
}

trap interrupted 1 2 3 6

cleanup()
{
  set +e
  rm -f /tmp/ruian-import-$$/*.zip 2>/dev/null
  rm -fr /tmp/ruian-import-$$/CSV 2>/dev/null
  rmdir /tmp/ruian-import-$$ 2>/dev/null
}

interrupted()
{
  echo "Caught Signal ... cleaning up, quitting."
  cleanup
  exit 1
}

[ -n "$0" ] && DB="$1"

set -e

WD=$(pwd)
cd /tmp
mkdir ruian-import-$$
cd ruian-import-$$

LASTDATE=`date -d "$(date +%Y-%m-01) -1 day" +%Y%m%d`
NAME="${LASTDATE}_OB_ADR_csv.zip"

URL="http://vdp.cuzk.cz/vymenny_format/csv/$NAME"

echo "Downloading address list from $URL"

wget "$URL"
unzip -o ${NAME}

echo "Databaze initialization..."

export MYSQL_PWD="$PASSWORD"

mysql -h${HOST} -P${PORT} -u${USER} ${DB} < "$WD/import/ruian-init.sql"

NUM_FILES=$(find ./CSV/ -type f | wc -l | tr -d '\n')

echo "Importing ${NUM_FILES} file(s) from $NAME into MySQL ${USER}@${HOST}:${PORT}/${DB}"

find ./CSV/ -type f | while read line
do
  mysql -h${HOST} -P${PORT} -u${USER} --local_infile=1 ${DB} -e "LOAD DATA LOCAL INFILE '$line' INTO TABLE ruian_adresy CHARACTER SET cp1250 FIELDS TERMINATED BY ';' IGNORE 1 LINES"
done
echo "... done."

echo "Transformations..."
mysql -h${HOST} -P${PORT} -u${USER} ${DB} < "$WD/import/ruian-transform.sql"
echo "... done"

cleanup

exit 0
