SET sql_mode = '';

-- obce
DROP TABLE IF EXISTS ruian_obce_new;
CREATE TABLE ruian_obce_new
  SELECT
    obec_id as id,
    nazev_obce as nazev
  FROM `ruian_adresy_new`
  GROUP BY obec_id;
ALTER TABLE `ruian_obce_new` ADD PRIMARY KEY `id` (`id`);
ALTER TABLE `ruian_adresy_new` DROP `nazev_obce`;

-- casti_obce
DROP TABLE IF EXISTS ruian_casti_obce_new;
CREATE TABLE ruian_casti_obce_new
  SELECT
    casti_obce_id as id,
    obec_id as obec_id,
    nazev_casti_obce as nazev,
    psc,
    nazev_momc,
    nazev_mop
  FROM `ruian_adresy_new`
  GROUP BY casti_obce_id;
UPDATE `ruian_adresy_new`
SET nazev_ulice = nazev_casti_obce
WHERE nazev_ulice = '';
ALTER TABLE `ruian_adresy_new` DROP `nazev_casti_obce`, DROP `psc`, DROP `nazev_momc`, DROP `nazev_mop`;
ALTER TABLE `ruian_casti_obce_new` ADD PRIMARY KEY `id` (`id`), ADD INDEX `obec_id` (`obec_id`);

-- ulice
DROP TABLE IF EXISTS ruian_ulice_new;
CREATE TABLE ruian_ulice_new
  SELECT
    ulice_id AS id,
    casti_obce_id,
    obec_id,
    nazev_ulice
  FROM `ruian_adresy_new`
  GROUP BY obec_id, nazev_ulice;
DELETE FROM ruian_ulice_new WHERE id=0;
ALTER TABLE `ruian_ulice_new`
  ADD PRIMARY KEY `id` (`id`),
  ADD INDEX `casti_obce_id` (`casti_obce_id`),
  ADD INDEX `obec_id` (`obec_id`);

-- indices for adresy
ALTER TABLE `ruian_adresy_new`
  ADD INDEX `casti_obce_id` (`casti_obce_id`),
  ADD INDEX `obec_id` (`obec_id`),
  ADD INDEX `nazev_ulice` (`nazev_ulice`(4)),
  ADD INDEX `ulice_id` (`ulice_id`);
