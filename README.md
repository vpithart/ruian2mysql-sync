# RUIAN to MySQL synchronization cron job

Cronjob to synchronize RÚIAN (Czech geolocation data) into local MySQL every month.

- (EN) https://wiki.openstreetmap.org/wiki/RUIAN
- (CZ) Registr územní identifikace, adres a nemovitostí (RUIAN)

The Czech Office for Surveying, Mapping and Cadastre (ČÚZK) offers a simple CSV file to download every month. It covers all the country's street addresses including gegraphic coordinates. The file is typically available on 1st or 2nd day of every month.

This script, `import-ruian.sh`, downloads and imports the new file as soon as it's ready, and then does nothing for rest of the month.

## Installation

1) clone, or unpack the archive into `/opt`
```sh
cd /opt
git clone https://github.com/vpithart/ruian2mysql-sync.git
```

2) configure your MySQL server credentials
```sql
CREATE DATABASE ruian;
CREATE USER `ruian-import`@`localhost` IDENTIFIED BY "haven't I told you to keep it secret?";
GRANT ALL on ruian.* TO `ruian-import`@`localhost`;
```
3) give the MySQL connection credentials to the script
```sh
cd /opt/ruian2mysql-sync
cp .env.example .env
```

```sh
# Example of /opt/ruian2mysql-sync/.env
USER="ruian-import"
PASSWORD="haven't I told you to keep it secret?"
DB="ruian"
HOST="localhost"
PORT=3306
```

4) edit your crontab (`crontab -e`) and add following line:
```
00 06   * * *     cd /opt/ruian2mysql-sync && ./import/import-ruian.sh 2>&1 | logger -t ruian2mysql-sync
```

## Troubleshooting

- Can you access the CUZK website from the server you have this script installed on?
```sh
wget -O- http://vdp.cuzk.cz/vymenny_format/csv/20180831_OB_ADR_csv.zip
```

- It's safe to run the script as many times as you want
```sh
cd /opt/ruian2mysql-sync && ./import/import-ruian.sh
```

- Still not there?
```sh
cd /opt/ruian2mysql-sync && bash -x import/import-ruian.sh
```

## What's under the hood
Where the data comes from? See http://nahlizenidokn.cuzk.cz/StahniAdresniMistaRUIAN.aspx

Where the data goes to? Into your local MySQL database. The importer populates following tables:
- ruain_obce (municipalities)
- ruian_ulice (streets)
- ruian_casti_obce (neighbourhoods)
- ruian_adresy (street addresses)
