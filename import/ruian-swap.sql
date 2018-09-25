START TRANSACTION;
DROP TABLE IF EXISTS `adresy_old`;
DROP TABLE IF EXISTS `ulice_old`;
DROP TABLE IF EXISTS `casti_obce_old`;
DROP TABLE IF EXISTS `obce_old`;
DROP TABLE IF EXISTS `version_old`;

RENAME TABLE
  adresy TO adresy_old,
  casti_obce TO casti_obce_old,
  ulice TO ulice_old,
  obce TO obce_old,
  `version` TO version_old;

RENAME TABLE
  adresy_new TO adresy,
  casti_obce_new TO casti_obce,
  ulice_new TO ulice,
  obce_new TO obce,
  version_new TO `version`;

COMMIT;
