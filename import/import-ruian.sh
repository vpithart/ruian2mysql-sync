#!/bin/bash

source .env || source .env.example {
  echo "Configuration (.env) file missing"
  echo "You may want to:"
  echo " cp .env.example .env"
  echo " $EDITOR .env"
  exit 1
}

TMPDIR=ruian-import-$$

cleanup()
{
  set +e
  cd /tmp
  rm -f $TMPDIR/*.zip 2>/dev/null
  rm -fr $TMPDIR/CSV 2>/dev/null
  rmdir $TMPDIR 2>/dev/null
}

interrupted()
{
  echo "Caught Signal ... cleaning up, quitting."
  cleanup
  exit 1
}

WD=$(pwd)

(
  set -e

  trap interrupted 1 2 3 6

  cd /tmp
  mkdir $TMPDIR
  cd $TMPDIR

  LASTDATE=`date -d "$(date +%Y-%m-01) -1 day" +%Y%m%d`
  # LASTDATE=20180731
  NAME="${LASTDATE}_OB_ADR_csv.zip"

  URL="http://vdp.cuzk.cz/vymenny_format/csv/$NAME"

  echo "Downloading address list from $URL..."
  wget "$URL"
  echo "Unpacking $NAME..."
  unzip -q -o ${NAME}

  NUM_FILES=$(find ./CSV/ -type f | wc -l | tr -d '\n')

  echo "Databaze initialization..."
  export MYSQL_PWD="$PASSWORD"
  mysql -h${HOST} -P${PORT} -u${USER} ${DB} < "$WD/import/ruian-init.sql"
  echo "Importing ${NUM_FILES} file(s) from $NAME into MySQL ${USER}@${HOST}:${PORT}/${DB}"
  find ./CSV/ -type f | while read line
  do
    mysql -h${HOST} -P${PORT} -u${USER} --local_infile=1 ${DB} -e "LOAD DATA LOCAL INFILE '$line' INTO TABLE ruian_adresy_new CHARACTER SET cp1250 FIELDS TERMINATED BY ';' IGNORE 1 LINES"
    :
  done
  echo "... done."

  echo "Transformations..."
  mysql -h${HOST} -P${PORT} -u${USER} ${DB} < "$WD/import/ruian-transform.sql"
  echo "... done"

  MAXDIFFPCT=5.0
  ABORT=0
  echo "Still within means?"
  printf ' %-18s %8s %8s %8s\n' 'table' 'before' 'after' 'delta'
  for TABLE in ruian_adresy ruian_ulice ruian_casti_obce ruian_obce
  do
    WAS=$(mysql -h${HOST} -P${PORT} -u${USER} ${DB} -e "SELECT COUNT(*) FROM $TABLE" --skip-column-names)
    IS=$(mysql -h${HOST} -P${PORT} -u${USER} ${DB} -e "SELECT COUNT(*) FROM ${TABLE}_new" --skip-column-names)
    let DELTA=$(( ($IS) - ($WAS) )) || true
    if [ "$WAS" = "0" ]; then PERCENTAGE="0"; else PERCENTAGE=$(echo "scale=2; 100*$DELTA/$WAS" | bc); fi
    [ $(echo "$PERCENTAGE < -$MAXDIFFPCT"|bc) = 1 -o $(echo "$PERCENTAGE > $MAXDIFFPCT"|bc) = 1 ] && OFFLIMIT=1 || OFFLIMIT=0
    printf ' %-18s %8u %8u %8d (%.2f%%)' $TABLE $WAS $IS $DELTA $PERCENTAGE
    if [ $OFFLIMIT != 0 ]; then
      ABORT=1
      echo -n " <-- too much difference"
    fi
    echo
  done

  [ $ABORT = 1 ] && {
    echo "Too much difference, aborting the import"
    exit 2
  }

  echo "Swapover: ruian_*_new -> ruian_* -> ruian_*_old..."
  mysql -h${HOST} -P${PORT} -u${USER} ${DB} < "$WD/import/ruian-swap.sql"
  echo "...done"
)
cleanup
exit 1
