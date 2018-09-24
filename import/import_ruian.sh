#!/bin/bash

LASTDATE=`date -d "$(date +%Y-%m-01) -1 day" +%Y%m%d`

NAME="${LASTDATE}_OB_ADR_csv.zip"
NAME_STRUKT="${LASTDATE}_strukt_ADR.csv.zip"

CESTA_K_CSV="./CSV"  ## cesta, kde jsi rozbalil archiv (cesta až k souborům)
CESTA_K_CSV_STRUKT="./strukturovane-CSV"  ## cesta, kde se rozbalil archiv struktury
SEZNAM="/tmp/seznam.txt"     ## může zůstat přednastaveno, je to jen dočasný soubor

source .env || {
  echo "Configuration (.env) file missing"
  exit 1
}

echo "Stahuji seznam adres..."
wget "http://vdp.cuzk.cz/vymenny_format/csv/$NAME"
unzip -o ${NAME}
rm ${NAME}

echo "Inicializace databaze..."
mysql -h${HOST} -P${PORT} -u${USER} -p${PASSWORD} ${DB} < ruian_init.sql

# seznam souborů pro import
find ${CESTA_K_CSV} -type f > ${SEZNAM}
# import
echo "Importuji soubry do databaze"
while read line; do
  mysql -h${HOST} -P${PORT} -u${USER} -p${PASSWORD} --local_infile=1 ${DB} -e "LOAD DATA LOCAL INFILE '$line' INTO TABLE ruian_adresy CHARACTER SET cp1250 FIELDS TERMINATED BY ';' IGNORE 1 LINES"
done < ${SEZNAM}
echo "... hotovo."


echo "Aplikuji transformace na databazi..."
mysql -h${HOST} -P${PORT} -u${USER} -p${PASSWORD} ${DB} < ruian_transform.sql
echo "... hotovo"


rm ${SEZNAM};
rm -rf ${CESTA_K_CSV}
exit;
