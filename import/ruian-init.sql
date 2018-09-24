DROP TABLE IF EXISTS `ruian_adresy_new`;
CREATE TABLE `ruian_adresy_new` (
  `id`                      INT(11)        NOT NULL,
  `obec_id`                 INT(11)        NOT NULL,
  `nazev_obce`              VARCHAR(64)    NOT NULL,
  `momc_id`                 INT(11)    NOT NULL,
  `nazev_momc`              VARCHAR(64)    NOT NULL,
  `mop_id`                  INT(11)    NOT NULL,
  `nazev_mop`               VARCHAR(64)    NOT NULL,
  `casti_obce_id`           INT(11)        NOT NULL,
  `nazev_casti_obce`        VARCHAR(64)    NOT NULL,
  `ulice_id`                INT(11)    NOT NULL,
  `nazev_ulice`             VARCHAR(64)    NOT NULL,
  `typ_so`                  VARCHAR(16)    NOT NULL,
  `cislo_domovni`           INT(11)        NOT NULL,
  `cislo_orientacni`        INT(11)        NOT NULL,
  `znak_cisla_orientacniho` VARCHAR(4)     NOT NULL,
  `psc`                     MEDIUMINT(9)   NOT NULL,
  `souradnice_y`            DECIMAL(12, 2) NOT NULL,
  `souradnice_x`            DECIMAL(12, 2) NOT NULL,
  `plati_od`                DATETIME       NOT NULL,
  PRIMARY KEY (`id`)
)
ENGINE = InnoDB;

DROP TABLE IF EXISTS `version_new`;
CREATE TABLE `version_new` (
  version char(8),
  importedAt timestamp
)
ENGINE = InnoDB;

CREATE TABLE IF NOT EXISTS ruian_adresy LIKE ruian_adresy_new;
CREATE TABLE IF NOT EXISTS `version` LIKE version_new;
