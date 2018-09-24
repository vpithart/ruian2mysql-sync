START TRANSACTION;
DROP TABLE IF EXISTS `ruian_adresy_old`;
DROP TABLE IF EXISTS `ruian_ulice_old`;
DROP TABLE IF EXISTS `ruian_casti_obce_old`;
DROP TABLE IF EXISTS `ruian_obce_old`;

RENAME TABLE
  ruian_adresy TO ruian_adresy_old,
  ruian_casti_obce TO ruian_casti_obce_old,
  ruian_ulice TO ruian_ulice_old,
  ruian_obce TO ruian_obce_old;

RENAME TABLE
  ruian_adresy_new TO ruian_adresy,
  ruian_casti_obce_new TO ruian_casti_obce,
  ruian_ulice_new TO ruian_ulice,
  ruian_obce_new TO ruian_obce;

COMMIT;
