START TRANSACTION;
DROP TABLE IF EXISTS `adresa_old`;
DROP TABLE IF EXISTS `ulice_old`;
DROP TABLE IF EXISTS `cobce_old`;
DROP TABLE IF EXISTS `obec_old`;
DROP TABLE IF EXISTS `version_old`;

RENAME TABLE
  adresa TO adresa_old,
  cobce TO cobce_old,
  ulice TO ulice_old,
  obec TO obec_old,
  `version` TO version_old;

RENAME TABLE
  adresa_new TO adresa,
  cobce_new TO cobce,
  ulice_new TO ulice,
  obec_new TO obec,
  version_new TO `version`;

COMMIT;
