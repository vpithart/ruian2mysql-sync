SET sql_mode = '';

-- indices for adresa
ALTER TABLE `adresa_new`
  ADD INDEX `adresa_cobce_id` (`cobce_kod`),
  ADD INDEX `adresa_obec_id` (`obec_kod`),
  ADD INDEX `adresa_ulice_id` (`ulice_kod`),
  ADD INDEX `adresa_nazev_ulice` (`nazev_ulice`);

-- obec
DROP TABLE IF EXISTS obec_new;
CREATE TABLE obec_new
  SELECT
    obec_kod,
    nazev_obce as nazev
  FROM `adresa_new`
  GROUP BY obec_kod;
ALTER TABLE `obec_new` ADD PRIMARY KEY `id` (`obec_kod`);
ALTER TABLE `adresa_new` DROP `nazev_obce`;
CREATE TABLE IF NOT EXISTS obec LIKE obec_new;

-- cobce
DROP TABLE IF EXISTS cobce_new;
CREATE TABLE cobce_new
  SELECT
    cobce_kod,
    obec_kod,
    nazev_cobce as nazev,
    nazev_momc,
    nazev_mop
  FROM `adresa_new`
  GROUP BY cobce_kod;
UPDATE `adresa_new` SET nazev_ulice = nazev_cobce WHERE nazev_ulice = '';
ALTER TABLE `adresa_new` DROP `nazev_cobce`, DROP `nazev_momc`, DROP `nazev_mop`;
ALTER TABLE `cobce_new` ADD PRIMARY KEY `id` (`cobce_kod`), ADD INDEX `cobce_obec_kod` (`obec_kod`);
CREATE TABLE IF NOT EXISTS cobce LIKE cobce_new;

-- ulice
DROP TABLE IF EXISTS ulice_new;
CREATE TABLE ulice_new
  SELECT
    ulice_kod,
    cobce_kod,
    obec_kod,
    nazev_ulice as nazev
  FROM `adresa_new`
  WHERE ulice_kod>0
  GROUP BY obec_kod, cobce_kod, nazev_ulice;

ALTER TABLE `ulice_new`
  ADD INDEX `ulice_ulice_id` (`ulice_kod`),
  ADD INDEX `ulice_cobce_id` (`cobce_kod`),
  ADD INDEX `ulice_obec_id` (`obec_kod`);
CREATE TABLE IF NOT EXISTS ulice LIKE ulice_new;
