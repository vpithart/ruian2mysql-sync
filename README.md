# RUIAN to MySQL synchronization cron job

- (EN) https://wiki.openstreetmap.org/wiki/RUIAN
- (CZ) Registr územní identifikace, adres a nemovitostí (RUIAN)

## Script for one-off data import

Imports RUIAN address data from

    http://nahlizenidokn.cuzk.cz/StahniAdresniMistaRUIAN.aspx

into your local MySQL database. Populates following tables:
- ruain_obce (municipalities)
- ruian_ulice (streets)
- ruian_casti_obce (neighbourhoods)
- ruian_adresy (street addresses)

# Installation

- clone, or unpack the archive
- (either) configure your MySQL server
```sql
CREATE DATABASE ruian;
CREATE USER `ruian-import`@`localhost` IDENTIFIED BY "ruian--import";
GRANT ALL on ruian.* TO `ruian-import`@`localhost`;
```
- (or) set your exeisting MySQL server credentials
```bash
cp .env.example .env
$EDITOR .env
```

# One-off import
```
./import/import-ruian.sh
```

# Periodic import via task scheduler - cron

Edit your crontab using `crontab -e` and add following line:
```
00 06   * * * * *    cd /opt/ruian2mysql-sync && ./import/import-ruian.sh
```
