SET sql_mode = '';

-- obce
DROP TABLE IF EXISTS obce_new;
CREATE TABLE obce_new
  SELECT
    obec_id as id,
    nazev_obce as nazev
  FROM `adresy_new`
  GROUP BY obec_id;
ALTER TABLE `obce_new` ADD PRIMARY KEY `id` (`id`);
ALTER TABLE `adresy_new` DROP `nazev_obce`;
CREATE TABLE IF NOT EXISTS obce LIKE obce_new;

-- casti_obce
DROP TABLE IF EXISTS casti_obce_new;
CREATE TABLE casti_obce_new
  SELECT
    casti_obce_id as id,
    obec_id as obec_id,
    nazev_casti_obce as nazev,
    psc,
    nazev_momc,
    nazev_mop
  FROM `adresy_new`
  GROUP BY casti_obce_id;
UPDATE `adresy_new`
SET nazev_ulice = nazev_casti_obce
WHERE nazev_ulice = '';
ALTER TABLE `adresy_new` DROP `nazev_casti_obce`, DROP `psc`, DROP `nazev_momc`, DROP `nazev_mop`;
ALTER TABLE `casti_obce_new` ADD PRIMARY KEY `id` (`id`), ADD INDEX `obec_id` (`obec_id`);
CREATE TABLE IF NOT EXISTS casti_obce LIKE casti_obce_new;

-- ulice
DROP TABLE IF EXISTS ulice_new;
CREATE TABLE ulice_new
  SELECT
    ulice_id AS id,
    casti_obce_id,
    obec_id,
    nazev_ulice
  FROM `adresy_new`
  GROUP BY obec_id, nazev_ulice;
DELETE FROM ulice_new WHERE id=0;
ALTER TABLE `ulice_new`
  ADD PRIMARY KEY `id` (`id`),
  ADD INDEX `casti_obce_id` (`casti_obce_id`),
  ADD INDEX `obec_id` (`obec_id`);
CREATE TABLE IF NOT EXISTS ulice LIKE ulice_new;

-- indices for adresy
ALTER TABLE `adresy_new`
  ADD INDEX `casti_obce_id` (`casti_obce_id`),
  ADD INDEX `obec_id` (`obec_id`),
  ADD INDEX `nazev_ulice` (`nazev_ulice`(4)),
  ADD INDEX `ulice_id` (`ulice_id`);
