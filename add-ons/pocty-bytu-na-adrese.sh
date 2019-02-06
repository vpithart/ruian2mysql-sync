#!/bin/bash
#
# Import parametru "pocet_bytu" z RUIAN do tabulky ruian.adresa
# (pridaji se tam dva sloupce: objekt_kod a pocet_bytu)
#
# pouziti:
#  ./import/pocty-bytu-na-adrese.sh <ID_OBCE>
#  ./import/pocty-bytu-na-adrese.sh 554782 # Praha
#  ./import/pocty-bytu-na-adrese.sh 537683 # Poděbrady
# ID_OBCE je cislo ktere najdes na http://vdp.cuzk.cz/vdp/ruian/obce/vyhledej
#
# ♥ 2018 <vpithart@lhota.hkfree.org>

source .env || {
  echo "Configuration (.env) file missing"
  echo "You may want to:"
  echo " cp .env.example .env"
  echo " $EDITOR .env"
  exit 1
}

OBEC_KOD="$1"
if [ -z "$OBEC_KOD" ]; then
  echo "Pouziti: $0 <ID_OBCE>"
  echo "ID_OBCE je cislo ktere najdes na http://vdp.cuzk.cz/vdp/ruian/obce/vyhledej"
  exit
fi

TMPDIR=/tmp/ruian-import-$$

cleanup()
{
  set +e
  echo 'DROP TABLE tmp_adresni_misto, tmp_stavebni_objekt' | $MYSQL
  rm -f $TMPDIR/*.csv 2>/dev/null
  rmdir $TMPDIR 2>/dev/null
}

interrupted()
{
  echo "Caught Signal ... cleaning up, quitting."
  cleanup
  exit 1
}

WD=$(pwd)

MYSQL="mysql -h${HOST} -P${PORT} -u${USER} ${DB}"
export MYSQL_PWD="$PASSWORD"

# toto muze selhat, kdyz tam uz ty columny jsou - nevadi
echo -n "MySQL: ALTER TABLE adresa ..."
echo "ALTER TABLE adresa ADD COLUMN objekt_kod INT(11) DEFAULT NULL; CREATE INDEX adresa_objekt_id ON adresa(objekt_kod);" | $MYSQL 2>/dev/null
echo "ALTER TABLE adresa ADD COLUMN pocet_bytu SMALLINT(4) DEFAULT NULL;" | $MYSQL 2>/dev/null
echo " done"

(
  set -e

  trap interrupted 1 2 3 6

  echo -n "MySQL: CREATE TABLEs (tmp_adresni_misto,tmp_stavebni_objekt) ..."

  cat <<EOF | $MYSQL
  DROP TABLE IF EXISTS tmp_adresni_misto;
  CREATE TABLE tmp_adresni_misto (
    adresa_kod INT(11) NOT NULL,
    objekt_kod INT(11) NOT NULL
  );
  DROP TABLE IF EXISTS tmp_stavebni_objekt;
  CREATE TABLE tmp_stavebni_objekt (
    objekt_kod INT(11) NOT NULL,
    pocet_bytu SMALLINT(4) DEFAULT NULL
  );
  CREATE INDEX am_objekt_id ON tmp_adresni_misto(objekt_kod);
  CREATE INDEX am_adresa_id ON tmp_adresni_misto(adresa_kod);
  CREATE INDEX obj_objekt ON tmp_stavebni_objekt(objekt_kod);
EOF
  echo " done"

  mkdir $TMPDIR

  LASTDATE=`date -d "$(date +%Y-%m-01) -1 day" +%Y%m%d`
  [ -n "$2" ] && LASTDATE=$2

  NAME="${LASTDATE}_OB_${OBEC_KOD}_UKSH.xml"
  EXT="zip"

  if [ ! -s "/tmp/$NAME.$EXT" ]
  then
    URL="http://vdp.cuzk.cz/vymenny_format/soucasna/$NAME.$EXT"
    echo "Downloading from $URL..."
    wget --progress dot:mega -O /tmp/$NAME.$EXT "$URL"
  else
    echo "Using /tmp/$NAME.$EXT"
  fi

  cd /tmp
  unzip -o $NAME.$EXT # assumes one file: 20190131_OB_554782_UKSH.xml.zip -> 20190131_OB_554782_UKSH.xml
  cd - >/dev/null
  echo -n "Importing from $NAME into MySQL ${USER}@${HOST}:${PORT}/${DB}/tmp_adresni_misto ..."
  cat /tmp/$NAME | add-ons/parse-OB-adresni-mista.pl > $TMPDIR/adrmista.csv
  RECORDS=$(cat $TMPDIR/adrmista.csv | wc -l | tr -d '\n')
  echo -n " (XML parsed: $RECORDS records)"
  $MYSQL --local_infile=1 -e "LOAD DATA LOCAL INFILE '$TMPDIR/adrmista.csv' INTO TABLE tmp_adresni_misto FIELDS TERMINATED BY ',' IGNORE 0 LINES"
  echo " (SQL loaded)."

  echo -n "Importing from $NAME into MySQL ${USER}@${HOST}:${PORT}/${DB}/tmp_stavebni_objekt ..."
  cat /tmp/$NAME | add-ons/parse-OB-stavebni-objekty.pl > $TMPDIR/stavebniobjekty.csv
  RECORDS=$(cat $TMPDIR/stavebniobjekty.csv | wc -l | tr -d '\n')
  echo -n " (XML parsed: $RECORDS records)"
  $MYSQL --local_infile=1 -e "LOAD DATA LOCAL INFILE '$TMPDIR/stavebniobjekty.csv' INTO TABLE tmp_stavebni_objekt FIELDS TERMINATED BY ',' IGNORE 0 LINES"
  echo " (SQL loaded)."

  echo -n "MySQL copy data tmp_adresni_misto -> ruian.adresa (objekt_kod) ..."
  echo "UPDATE adresa a LEFT JOIN tmp_adresni_misto am ON a.adresa_kod=am.adresa_kod SET a.objekt_kod=am.objekt_kod WHERE a.obec_kod=${OBEC_KOD};" | $MYSQL
  echo " done"
  echo -n "MySQL copy data tmp_stavebni_objekt -> ruian.adresa (pocet_bytu) ..."
  echo "UPDATE adresa a LEFT JOIN tmp_stavebni_objekt so ON a.objekt_kod=so.objekt_kod SET a.pocet_bytu=so.pocet_bytu WHERE a.obec_kod=${OBEC_KOD};" | $MYSQL
  echo " done"

  echo "Finished."

  rm /tmp/$NAME
  # keep the downloaded .zip intentionally
)
cleanup
exit 0

# -- testovaci dotaz Praha
# SELECT adresa_kod, nazev_ulice, cislo_domovni, cislo_orientacni, objekt_kod, pocet_bytu FROM adresa
# WHERE obec_kod=554782 AND (
#    (nazev_ulice = 'Anglická' AND cislo_domovni = 136)
# OR (nazev_ulice = 'Podskalská' and cislo_domovni = 1290)
# OR (nazev_ulice = 'Třebešovská' and cislo_domovni in (2251, 2252, 2253, 2254, 2255, 2256))
# ) ORDER BY nazev_ulice, cislo_domovni, cislo_orientacni;

# -- testovaci dotaz Podebrady
# SELECT adresa_kod, nazev_ulice, cislo_domovni, cislo_orientacni, objekt_kod, pocet_bytu FROM adresa
# WHERE obec_kod=537683
# ORDER BY nazev_ulice, cislo_domovni, cislo_orientacni;

# -- testovaci dotaz Libcice n. Vltavou
# SELECT adresa_kod, nazev_ulice, cislo_domovni, cislo_orientacni, objekt_kod, pocet_bytu FROM adresa
# WHERE obec_kod=539414
# ORDER BY nazev_ulice, cislo_domovni, cislo_orientacni;
