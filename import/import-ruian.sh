#!/bin/bash

source .env || {
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

  MYSQL="mysql -h${HOST} -P${PORT} -u${USER} ${DB}"
  export MYSQL_PWD="$PASSWORD"

  LASTDATE=`date -d "$(date +%Y-%m-01) -1 day" +%Y%m%d`
  HAVE_VERSION=$($MYSQL --skip-column-names -e "SELECT version FROM version LIMIT 1" 2>/dev/null || true)

  if [ "$HAVE_VERSION" = "$LASTDATE" ]
  then
    HAVE_VERSION_DATE=$($MYSQL --skip-column-names -e "SELECT importedAt FROM version LIMIT 1")
    echo "Version $HAVE_VERSION already imported (at $HAVE_VERSION_DATE), quitting."
    exit 3
  fi

  NAME="${LASTDATE}_OB_ADR_csv.zip"
  URL="http://vdp.cuzk.cz/vymenny_format/csv/$NAME"

  echo "Downloading address list from $URL..."
  wget "$URL"
  echo "Unpacking $NAME..."
  unzip -q -o ${NAME}

  NUM_FILES=$(find ./CSV/ -type f | wc -l | tr -d '\n')

  echo "Importing ${NUM_FILES} file(s) from $NAME into MySQL ${USER}@${HOST}:${PORT}/${DB}"
  $MYSQL < "$WD/import/ruian-init.sql"
  find ./CSV/ -type f | while read FILENAME
  do
    $MYSQL --local_infile=1 -e "LOAD DATA LOCAL INFILE '$FILENAME' INTO TABLE ruian_adresy_new CHARACTER SET cp1250 FIELDS TERMINATED BY ';' IGNORE 1 LINES"
  done
  $MYSQL --local_infile=1 -e "INSERT INTO version_new (version) VALUES ('$LASTDATE')"
  echo "... done."

  echo "Transformations..."
  $MYSQL < "$WD/import/ruian-transform.sql"
  echo "... done"

  MAXDIFFPCT=5.0
  ABORT=0
  echo "Still within means?"
  printf ' %-18s %8s %8s %8s\n' 'table' 'before' 'after' 'delta'
  for TABLE in ruian_adresy ruian_ulice ruian_casti_obce ruian_obce
  do
    WAS=$($MYSQL -e "SELECT COUNT(*) FROM $TABLE" --skip-column-names 2>/dev/null || echo '0')
    IS=$($MYSQL -e "SELECT COUNT(*) FROM ${TABLE}_new" --skip-column-names)
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
  $MYSQL < "$WD/import/ruian-swap.sql"
  echo "...done"
)
cleanup
exit 1
