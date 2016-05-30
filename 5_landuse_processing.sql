-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- PANDEN
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

/*
BRON: BAG
De BAG wordt in twee stappen verdeelt. In stap één zitten alle panden die een functie in de BAG hebben.
In stap twee zitten alle panden die geen functie in BAG hebben.
Het resultaat dat men overhoudt zijn alle actuale panden uit de BAG.
*/

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- PANDEN stap 1  
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

-- Index aanmaken over de pandstatus
- CREATE INDEX pand_incl_functie_pandstatus ON bagactueel.pand USING BTREE(pandstatus);
 
-- Index aanmaken over de einddatum
- CREATE INDEX pand_einddatumtijdvakgeldigheid ON bagactueel.pand USING BTREE(einddatumtijdvakgeldigheid);

-- Index aanmaken over de geometrie
- CREATE INDEX pand_geom ON bagactueel.pand USING GIST(geom);

-- Tabel aanmaken alleen voor de huidige BAG panden
DROP TABLE IF EXISTS data_verwerkt.bag_current;
CREATE TABLE data_verwerkt.bag_current AS

--- Tabel vullen 	
SELECT *
FROM bag_pand_incl_functie;

/*
SELECT * 
FROM data_verwerkt.bag_current  
LIMIT 10;
*/

- Index aanmaken over het gebruiksdoelverblijfsobject 
CREATE INDEX landgebruik_vector_april_2016_gebruiksdoelverblijfsobject ON data_verwerkt.bag_current USING BTREE(gebruiksdoelverblijfsobject);

/*
SELECT DISTINCT gebruiksdoelverblijfsobject 
FROM data_verwerkt.bag_current;
*/

--- Kolommen toevoegen voor de functies
ALTER TABLE data_verwerkt.bag_current ADD COLUMN code_function integer;
ALTER TABLE data_verwerkt.bag_current ADD COLUMN code_function_desc character varying(50);

--- De functie kolommen vullen
UPDATE data_verwerkt.bag_current SET code_function=2,code_function_desc='woonfunctie' WHERE cast(gebruiksdoelverblijfsobject AS text)= 'woonfunctie';
UPDATE data_verwerkt.bag_current SET code_function=3,code_function_desc='celfunctie' WHERE cast(gebruiksdoelverblijfsobject AS text)= 'celfunctie';
UPDATE data_verwerkt.bag_current SET code_function=4,code_function_desc='industriefunctie' WHERE cast(gebruiksdoelverblijfsobject AS text)= 'industriefunctie';
UPDATE data_verwerkt.bag_current SET code_function=5,code_function_desc='kantoorfunctie' WHERE cast(gebruiksdoelverblijfsobject AS text)= 'kantoorfunctie';
UPDATE data_verwerkt.bag_current SET code_function=6,code_function_desc='winkelfunctie' WHERE cast(gebruiksdoelverblijfsobject AS text)= 'winkelfunctie';
UPDATE data_verwerkt.bag_current SET code_function=8,code_function_desc='logiesfunctie' WHERE cast(gebruiksdoelverblijfsobject AS text)= 'logiesfunctie';
UPDATE data_verwerkt.bag_current SET code_function=9,code_function_desc='bijeenkomstfunctie' WHERE cast(gebruiksdoelverblijfsobject AS text)= 'bijeenkomstfunctie';
UPDATE data_verwerkt.bag_current SET code_function=10,code_function_desc='bag sportfunctie' WHERE cast(gebruiksdoelverblijfsobject AS text)= 'sportfunctie';
UPDATE data_verwerkt.bag_current SET code_function=11,code_function_desc='onderwijsfunctie' WHERE cast(gebruiksdoelverblijfsobject AS text)= 'onderwijsfunctie';
UPDATE data_verwerkt.bag_current SET code_function=12,code_function_desc='gezondheidszorgfunctie' WHERE cast(gebruiksdoelverblijfsobject AS text)= 'gezondheidszorgfunctie';
UPDATE data_verwerkt.bag_current SET code_function=13,code_function_desc='overig kleiner dan 50 m2' WHERE cast(gebruiksdoelverblijfsobject AS text)= 'overige gebruiksfunctie' AND ST_AREA(geom) < 50;
UPDATE data_verwerkt.bag_current SET code_function=14,code_function_desc='overig groter dan 50 m2'WHERE cast(gebruiksdoelverblijfsobject AS text)= 'overige gebruiksfunctie' AND ST_AREA(geom) >= 50;

--- Kolommen toevoegen voor de landgebruiksklasse
ALTER TABLE data_verwerkt.bag_current DROP COLUMN IF EXISTS code_physical_landuse;
ALTER TABLE data_verwerkt.bag_current DROP COLUMN IF EXISTS code_physical_landuse_desc;

ALTER TABLE data_verwerkt.bag_current ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_verwerkt.bag_current ADD COLUMN code_physical_landuse_desc character varying(50);

--- De landgebruik kolommen vullen
UPDATE data_verwerkt.bag_current SET code_physical_landuse=1,code_physical_landuse_desc='dak';

/*
SELECT *
FROM data_verwerkt.bag_current 
LIMIT 100;
*/

CREATE INDEX bag_current_geom ON data_verwerkt.bag_current USING gist(geom);

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- PANDEN stap 2 - selectie van alle panden in de bag zonder functie 
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

--- Tabel aanmaken alleen voor de BAG panden zonder functie
DROP TABLE IF EXISTS data_tmp.bag_current_ex_functie;
CREATE TABLE data_tmp.bag_current_ex_functie AS

--- Tabel vullen
SELECT identificatie, bouwjaar, pandstatus, geovlak AS geom
FROM bag_pand_excl_functie AS a
WHERE cast(a.pandstatus AS text) = 'Pand in gebruik' OR cast(a.pandstatus AS text) = 'Pand in gebruik (niet ingemeten)'
 
EXCEPT
SELECT identificatie, bouwjaar, pandstatus, geovlak AS geom
FROM bag_pand_excl_functie 
WHERE date_part('year', einddatumtijdvakgeldigheid) < 2016;

--- Kolommen voor de functies toevoegen
ALTER TABLE data_tmp.bag_current_ex_functie ADD COLUMN code_function integer;
ALTER TABLE data_tmp.bag_current_ex_functie ADD COLUMN code_function_desc character varying(50);

--- De functie kolommen vullen
UPDATE data_tmp.bag_current_ex_functie SET code_function=13,code_function_desc='overig kleiner dan 50 m2' WHERE ST_AREA(geom) < 50;
UPDATE data_tmp.bag_current_ex_functie SET code_function=14,code_function_desc='overig groter dan 50 m2' WHERE ST_AREA(geom) >= 50;

--- Kolommen toevoegen voor de landgebruiksklasse
ALTER TABLE data_tmp.bag_current_ex_functie ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_tmp.bag_current_ex_functie ADD COLUMN code_physical_landuse_desc character varying(50);

--- De landgebruik kolommen vullen 
UPDATE data_tmp.bag_current_ex_functie SET code_physical_landuse=1,code_physical_landuse_desc='dak';

--- Tabel in de goede database aanmaken en vullen
DROP TABLE IF EXISTS data_verwerkt.bag_current_ex_functie;
CREATE TABLE data_verwerkt.bag_current_ex_functie AS 
SELECT * 
FROM data_tmp.bag_current_ex_functie 

/*
SELECT * 
FROM data_verwerkt.bag_current_ex_functie
LIMIT 10
*/

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- Terreinen 
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

/*
BRON: CBS
Resultaat: Alle cbs gebieden behalve het water

1 Verkeersterrein
	10 Spoorterrein
	11 Wegverkeersterrein
	12 Vliegveld
2 Bebouwd terrein
	20 Woonterrein
	21 Terrein voor detailhandel en horeca
	22 Terrein voor openbare voorzieningen
	23 Terrein voor sociaal-culturele voorzieningen
	24 Bedrijventerrein
3 Semi-bebouwd terrein
	30 Stortplaats
	31 Wrakkenopslagplaats
	32 Begraafplaats
	33 Delfstofwinplaats
	34 Bouwterrein
	35 Semi verhard overig terrein
4 Recreatieterrein
	40 Park en plantsoen
	41 Sportterrein
	42 Volkstuin
	43 Dagrecreatief terrein
	44 Verblijfsrecreatief terrein
5 Agrarisch terrein
	50 Terrein voor glastuinbouw
	51 Overig agrarisch terrein
6 Bos en open natuurlijk terrein
	60 Bos
	61 Open droog natuurlijk terrein
	62 Open nat natuurlijk terrein
7 Binnenwater
	70 IJsselmeer/Markermeer
	71 Afgesloten zeearm
	72 Rijn en Maas
	73 Randmeer
	74 Spaarbekken
	75 Recreatief binnenwater
	76 Binnenwater voor delfstofwinning
	77 Vloei- en/of slibveld
	78 Overig binnenwater
8 Buitenwater
	80 Waddenzee, Eems, Dollard
	81 Oosterschelde
	82 Westerschelde
	83 Noordzee
9 Buitenland
	90 Buitenland
*/

--- Indeces aanmaken voor de geometrie en de bg2012 
CREATE INDEX bbg2012_geom ON data_ruw.bbg2012 USING gist(geom);
CREATE INDEX bbg2012_bg2012 ON data_ruw.bbg2012 USING btree(bg2012);

--- Tijdelijke tabel aanmaken voor de CBS gebieden
DROP TABLE IF EXISTS data_tmp.cbs_gebieden;
CREATE TABLE data_tmp.cbs_gebieden AS

--- CBS gebieden tabel vullen
SELECT * FROM data_ruw.bbg2012 
WHERE 
bg2012 = 10
OR bg2012 = 11
OR bg2012 = 12
OR bg2012 = 20
OR bg2012 = 21
OR bg2012 = 22
OR bg2012 = 23
OR bg2012 = 24
OR bg2012 = 30
OR bg2012 = 31
OR bg2012 = 32
OR bg2012 = 33
OR bg2012 = 34
OR bg2012 = 35
OR bg2012 = 40
OR bg2012 = 41
OR bg2012 = 42
OR bg2012 = 43
OR bg2012 = 44
OR bg2012 = 50
OR bg2012 = 51
OR bg2012 = 60
OR bg2012 = 61
OR bg2012 = 62
;

--- Kolommen voor de functies toevegen 
ALTER TABLE data_tmp.cbs_gebieden ADD COLUMN code_function integer;
ALTER TABLE data_tmp.cbs_gebieden ADD COLUMN code_function_desc character varying(50);
 
--- De functie kolommen vullen 
UPDATE data_tmp.cbs_gebieden SET code_function=147,code_function_desc='spoorberm' WHERE bg2012 = 10;
UPDATE data_tmp.cbs_gebieden SET code_function=148,code_function_desc='wegberm' WHERE bg2012 = 11;
UPDATE data_tmp.cbs_gebieden SET code_function=149,code_function_desc='vliegveld' WHERE bg2012 = 12;
UPDATE data_tmp.cbs_gebieden SET code_function=16,code_function_desc='woongebied' WHERE bg2012 = 20;
UPDATE data_tmp.cbs_gebieden SET code_function=17,code_function_desc='winkelgebied' WHERE bg2012 = 21;
UPDATE data_tmp.cbs_gebieden SET code_function=18,code_function_desc='openbaar terrein' WHERE bg2012 = 22;
UPDATE data_tmp.cbs_gebieden SET code_function=18,code_function_desc='openbaar terrein' WHERE bg2012 = 23;
UPDATE data_tmp.cbs_gebieden SET code_function=19,code_function_desc='bedrijventerrein' WHERE bg2012 = 24;
UPDATE data_tmp.cbs_gebieden SET code_function=125,code_function_desc='stortplaats' WHERE bg2012 = 30;
UPDATE data_tmp.cbs_gebieden SET code_function=126,code_function_desc='wrakkenopslagplaats' WHERE bg2012 = 31;
UPDATE data_tmp.cbs_gebieden SET code_function=118,code_function_desc='begraafplaats' WHERE bg2012 = 32;
UPDATE data_tmp.cbs_gebieden SET code_function=128,code_function_desc='delfstofwinplaats' WHERE bg2012 = 33;
UPDATE data_tmp.cbs_gebieden SET code_function=129,code_function_desc='bouwterrein' WHERE bg2012 = 34;
UPDATE data_tmp.cbs_gebieden SET code_function=130,code_function_desc='semi-verhard overig terrein' WHERE bg2012 = 35;
UPDATE data_tmp.cbs_gebieden SET code_function=121,code_function_desc='park en plantsoen' WHERE bg2012 = 40;
UPDATE data_tmp.cbs_gebieden SET code_function=150,code_function_desc='sportterrein' WHERE bg2012 = 41;
UPDATE data_tmp.cbs_gebieden SET code_function=122,code_function_desc='volkstuin' WHERE bg2012 = 42;
UPDATE data_tmp.cbs_gebieden SET code_function=123,code_function_desc='dagrecreatief terrein' WHERE bg2012 = 43;
UPDATE data_tmp.cbs_gebieden SET code_function=124,code_function_desc='verblijfsrecreatief terrein' WHERE bg2012 = 44;
UPDATE data_tmp.cbs_gebieden SET code_function=119,code_function_desc='glastuinbouwterrein' WHERE bg2012 = 50;
UPDATE data_tmp.cbs_gebieden SET code_function=120,code_function_desc='erf' WHERE bg2012 = 51;
UPDATE data_tmp.cbs_gebieden SET code_function=60,code_function_desc='bos' WHERE bg2012 = 60;
UPDATE data_tmp.cbs_gebieden SET code_function=134,code_function_desc='open droog natuurlijk terrein' WHERE bg2012 = 61;
UPDATE data_tmp.cbs_gebieden SET code_function=135,code_function_desc='open nat natuurlijk terrein' WHERE bg2012 = 62;

--- Index maken voor de functie namen
CREATE INDEX cbs_gebieden_code_function_desc ON data_tmp.cbs_gebieden USING btree(code_function_desc);

/*
SELECT DISTINCT code_function_desc, code_function, bg2012 
FROM data_tmp.cbs_gebieden 
ORDER BY code_function;
*/

--- Kolommen toevoegen voor de landgebruiksklasse
ALTER TABLE data_tmp.cbs_gebieden ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_tmp.cbs_gebieden ADD COLUMN code_physical_landuse_desc character varying(50);

--- De landgebruik kolommen vullen 
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=254,code_physical_landuse_desc='weg onbekend' WHERE bg2012 = 10;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=254,code_physical_landuse_desc='weg onbekend' WHERE bg2012 = 11;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=254,code_physical_landuse_desc='weg onbekend' WHERE bg2012 = 12;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=16,code_physical_landuse_desc='bebouwd' WHERE bg2012 = 20;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=16,code_physical_landuse_desc='bebouwd' WHERE bg2012 = 21;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=16,code_physical_landuse_desc='bebouwd' WHERE bg2012 = 22;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=16,code_physical_landuse_desc='bebouwd' WHERE bg2012 = 23;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=16,code_physical_landuse_desc='bebouwd' WHERE bg2012 = 24;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=125,code_physical_landuse_desc='open verharding' WHERE bg2012 = 30;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=126,code_physical_landuse_desc='open verharding' WHERE bg2012 = 31;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=127,code_physical_landuse_desc='onverhard' WHERE bg2012 = 32;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=127,code_physical_landuse_desc='onverhard' WHERE bg2012 = 33;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=127,code_physical_landuse_desc='onverhard' WHERE bg2012 = 34;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=125,code_physical_landuse_desc='open verharding' WHERE bg2012 = 35;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=121,code_physical_landuse_desc='groen' WHERE bg2012 = 40;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=22,code_physical_landuse_desc='gras' WHERE bg2012 = 41;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=122,code_physical_landuse_desc='tuin' WHERE bg2012 = 42;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=123,code_physical_landuse_desc='onbekend' WHERE bg2012 = 43;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=124,code_physical_landuse_desc='bebouwd' WHERE bg2012 = 44;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=16,code_physical_landuse_desc='bebouwd' WHERE bg2012 = 50;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=16,code_physical_landuse_desc='bebouwd' WHERE bg2012 = 51;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=60,code_physical_landuse_desc='bomen' WHERE bg2012 = 60;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=134,code_physical_landuse_desc='open droog natuurlijk terrein' WHERE bg2012 = 61;
UPDATE data_tmp.cbs_gebieden SET code_physical_landuse=135,code_physical_landuse_desc='open nat natuurlijk terrein' WHERE bg2012 = 62;

--- Index aanmaken voor het functienummer
CREATE INDEX cbs_gebieden_code_function ON data_tmp.cbs_gebieden USING btree(code_function);

/*
SELECT DISTINCT code_physical_landuse_desc
FROM data_tmp.cbs_gebieden;
*/

--- Index aanmaken over de klasse uit het bestandbodemgebruik (bg2012)
CREATE INDEX cbs_gebieden_BG2012 ON data_tmp.cbs_gebieden USING btree(bg2012);

--- Tabel in de goede database aanmaken en vullen
DROP TABLE IF EXISTS data_verwerkt.cbs_gebieden;
CREATE TABLE data_verwerkt.cbs_gebieden AS

--- Tabel vulen
SELECT *
FROM data_tmp.cbs_gebieden

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Sportvelden 
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

/*
BRON: OSM
Resultaat: alle sportvelden uit OSM
*/

--- Tabel aanmaken voor de sportvelden
DROP TABLE IF EXISTS data_verwerkt.osm_sportvelden_nl;
CREATE TABLE data_verwerkt.osm_sportvelden_nl AS

--- Tabel vullen
SELECT ST_Transform(way, 28992) AS geom, leisure, sport
FROM osm_polygons
WHERE leisure = 'sports_centre' 
OR leisure = 'stadium' 
OR leisure = 'pitch' 
OR leisure = 'track';

--- Index aanmaken voor de vrije tijd (leisure)
CREATE INDEX osm_sportvelden_nl_leisure ON data_verwerkt.osm_sportvelden_nl USING btree(leisure);

--- Index aanmaken voor sport
CREATE INDEX osm_sportvelden_nl_sport ON data_verwerkt.osm_sportvelden_nl USING btree(sport);

--- Kolommen toevoegen voor de functies
ALTER TABLE data_verwerkt.osm_sportvelden_nl ADD COLUMN code_function integer;
ALTER TABLE data_verwerkt.osm_sportvelden_nl ADD COLUMN code_function_desc character varying(50);

--- De functie kolommen vullen
UPDATE data_verwerkt.osm_sportvelden_nl SET code_function=20,code_function_desc='sportcentrum' WHERE cast(leisure AS text)= 'sports_centre';
UPDATE data_verwerkt.osm_sportvelden_nl SET code_function=21,code_function_desc='stadion' WHERE cast(leisure AS text)= 'stadium';
UPDATE data_verwerkt.osm_sportvelden_nl SET code_function=22,code_function_desc='sportveld' WHERE cast(leisure AS text)= 'pitch';
UPDATE data_verwerkt.osm_sportvelden_nl SET code_function=23,code_function_desc='atletiekbaan' WHERE cast(leisure AS text)= 'track' and cast(sport AS text)= 'athletics'; 
UPDATE data_verwerkt.osm_sportvelden_nl SET code_function=24,code_function_desc='tennisbaan' WHERE cast(leisure AS text)= 'track' and cast(sport AS text) = 'tennis';
UPDATE data_verwerkt.osm_sportvelden_nl SET code_function=25,code_function_desc='sportbaan' WHERE cast(leisure AS text)= 'track' and code_function IS NULL;

--- Kolommen toevoegen voor de landgebruiksklasse
ALTER TABLE data_verwerkt.osm_sportvelden_nl ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_verwerkt.osm_sportvelden_nl ADD COLUMN code_physical_landuse_desc character varying(50);

--- De landgebruik kolommen vullen 
UPDATE data_verwerkt.osm_sportvelden_nl SET code_physical_landuse=1,code_physical_landuse_desc='dak' WHERE cast(leisure AS text)= 'sports_centre';
UPDATE data_verwerkt.osm_sportvelden_nl SET code_physical_landuse=1,code_physical_landuse_desc='dak' WHERE cast(leisure AS text)= 'stadium';
UPDATE data_verwerkt.osm_sportvelden_nl SET code_physical_landuse=22,code_physical_landuse_desc='gras' WHERE cast(leisure AS text)= 'pitch';
UPDATE data_verwerkt.osm_sportvelden_nl SET code_physical_landuse=23,code_physical_landuse_desc='tartan' WHERE cast(leisure AS text)= 'track' and cast(sport AS text)= 'athletics'; 
UPDATE data_verwerkt.osm_sportvelden_nl SET code_physical_landuse=23,code_physical_landuse_desc='tartan' WHERE cast(leisure AS text)= 'track' and cast(sport AS text) = 'tennis';
UPDATE data_verwerkt.osm_sportvelden_nl SET code_physical_landuse=25,code_physical_landuse_desc='verhard' WHERE cast(leisure AS text)= 'track' and code_physical_landuse IS NULL;

/*
SELECT * 
FROM data_verwerkt.osm_sportvelden_nl
LIMIT 10;
*/

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Watervlakken 
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

/*
BRON: cbs en top10nl
Resultaat: alle watervlakken van het cbs en uit top10nl
*/

------------------------
--- CBS watervlakken --- 
------------------------

/*
7 Binnenwater
	70 IJsselmeer/Markermeer
	71 Afgesloten zeearm
	72 Rijn en Maas
	73 Randmeer
	74 Spaarbekken
	75 Recreatief binnenwater
	76 Binnenwater voor delfstofwinning
	77 Vloei- en/of slibveld
	78 Overig binnenwater
8 Buitenwater
	80 Waddenzee, Eems, Dollard
	81 Oosterschelde
	82 Westerschelde
	83 Noordzee
*/

--- Tijdelijke tabel aanmaken voor de CBS gebieden
DROP TABLE IF EXISTS data_tmp.cbs_water;
CREATE TABLE data_tmp.cbs_water AS

--- CBS gebieden tabel vullen
SELECT geom, bg2012 
FROM data_ruw.bbg2012 
WHERE 
bg2012 = 70
OR bg2012 = 71
OR bg2012 = 72
OR bg2012 = 73
OR bg2012 = 74
OR bg2012 = 75
OR bg2012 = 76
OR bg2012 = 77
OR bg2012 = 78
OR bg2012 = 80
OR bg2012 = 81
OR bg2012 = 82
OR bg2012 = 83

/*
SELECT *
FROM data_tmp.cbs_water
LIMIT 10;
*/

--- Index aanmaken over de geometrie voor de water vlakken
DROP INDEX IF EXISTS cbs_water_geom;
CREATE INDEX cbs_water_geom ON data_tmp.cbs_water USING gist(geom);

--- Kolommen toevoegen voor de functies
ALTER TABLE data_tmp.cbs_water ADD COLUMN code_function integer;
ALTER TABLE data_tmp.cbs_water ADD COLUMN code_function_desc character varying(50);
 
--- Functie kolommen vullen
UPDATE data_tmp.cbs_water SET code_function=144,code_function_desc='water';
 
--- Kolommen toevoegen voor de landgebruiksklasse
ALTER TABLE data_tmp.cbs_water ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_tmp.cbs_water ADD COLUMN code_physical_landuse_desc character varying(50);
 
--- De Landgebruiks kolommen vullen
UPDATE data_tmp.cbs_water SET code_physical_landuse=29,code_physical_landuse_desc='water';

/*
SELECT *
FROM data_tmp.cbs_water
LIMIT 10;
*/

ALTER TABLE data_tmp.cbs_water DROP COLUMN bg2012;

/*
SELECT *
FROM data_tmp.cbs_water
LIMIT 10;
*/

--------------------------
--- top10 watervlakken --- 
--------------------------

--- Tijdelijke tabel aanmaken voor water vlakken
DROP TABLE IF EXISTS data_tmp.top10_water;
CREATE TABLE data_tmp.top10_water AS

--- Tabel vullen
SELECT hoofdafwatering, functie, voorkomen, typewater, geom
FROM top10_waterdeel_vlak;

/*
SELECT *
FROM data_tmp.top10_water
LIMIT 10;
*/

--- Index aanmaken over de geometrie voor de water vlakken
DROP INDEX IF EXISTS top10_water_geom;
CREATE INDEX top10_water_geom ON data_tmp.top10_water USING gist(geom);

--- Kolommen toevoegen voor de functies
ALTER TABLE data_tmp.top10_water ADD COLUMN code_function integer;
ALTER TABLE data_tmp.top10_water ADD COLUMN code_function_desc character varying(50);
 
--- Functie kolommen vullen
UPDATE data_tmp.top10_water SET code_function=144,code_function_desc='water';
 
--- Kolommen toevoegen voor de landgebruiksklasse
ALTER TABLE data_tmp.top10_water ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_tmp.top10_water ADD COLUMN code_physical_landuse_desc character varying(50);
 
--- De Landgebruiks kolommen vullen
UPDATE data_tmp.top10_water SET code_physical_landuse=29,code_physical_landuse_desc='water';

/*
SELECT * 
FROM data_tmp.top10_water
LIMIT 10;
*/

ALTER TABLE data_tmp.top10_water DROP COLUMN hoofdafwatering;
ALTER TABLE data_tmp.top10_water DROP COLUMN functie;
ALTER TABLE data_tmp.top10_water DROP COLUMN voorkomen;
ALTER TABLE data_tmp.top10_water DROP COLUMN typewater;

/*
SELECT * 
FROM data_tmp.top10_water
LIMIT 10;
*/
 
---------------------------
--- totaal watervlakken --- 
---------------------------

DROP TABLE IF EXISTS data_tmp.cbs_top10_water;
CREATE TABLE data_tmp.cbs_top10_water (geom geometry, code_function INTEGER, code_function_desc VARCHAR (50), code_physical_landuse INTEGER, code_physical_landuse_desc VARCHAR (50));
INSERT INTO data_tmp.cbs_top10_water(geom, code_function, code_function_desc, code_physical_landuse, code_physical_landuse_desc)
SELECT geom, code_function, code_function_desc, code_physical_landuse, code_physical_landuse_desc
FROM data_tmp.cbs_water;

INSERT INTO data_tmp.cbs_top10_water(geom, code_function, code_function_desc, code_physical_landuse, code_physical_landuse_desc)
SELECT geom, code_function, code_function_desc, code_physical_landuse, code_physical_landuse_desc
FROM data_tmp.top10_water

DROP TABLE IF EXISTS data_verwerkt.cbs_top10_water;
CREATE TABLE data_verwerkt.cbs_top10_water AS
SELECT *
FROM data_tmp.cbs_top10_water

/*
SELECT *
FROM data_tmp.cbs_top10_water
LIMIT 10;
*/

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Bermen (= watervlakken als buffer) 
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

/*
BRON: top10nl
Resultaat: buffer om de watervlakken (geldt als berm)
*/

--- Tabel aanmaken voor de (water)bermen
DROP TABLE IF EXISTS data_verwerkt.top10_bermen;
CREATE TABLE data_verwerkt.top10_bermen AS

--- (water)bermen tabel vullen
SELECT ST_Buffer(a.geom, 10) AS geom
FROM data_verwerkt.top10_water AS a;
  
--- Kolommen toevoegen voor de functies
ALTER TABLE data_verwerkt.top10_bermen ADD COLUMN code_function integer;
ALTER TABLE data_verwerkt.top10_bermen ADD COLUMN code_function_desc character varying(50);

--- De functie kolommen vullen
UPDATE data_verwerkt.top10_bermen SET code_function=146,code_function_desc='berm';

--- Kolommen toevoegen voor de landgebruiksklasse
ALTER TABLE data_verwerkt.top10_bermen ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_verwerkt.top10_bermen ADD COLUMN code_physical_landuse_desc character varying(50);
 
--- De Landgebruiks kolommen vullen
UPDATE data_verwerkt.top10_bermen SET code_physical_landuse=146,code_physical_landuse_desc='waterberm';

/*
SELECT * 
FROM data_verwerkt.top10_bermen 
LIMIT 10;
*/

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Waterlopen als buffer 
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

/*
BRON: top10nl
Resultaat: buffer om de waterlijnen
*/

--- Tabel aanmaken voor de buffer om het water
DROP TABLE IF EXISTS data_verwerkt.top10_waterlopen_buffer;
CREATE TABLE data_verwerkt.top10_waterlopen_buffer AS

--- Tabel vullen
SELECT a.*
FROM top10_waterlopen_buffer AS a;

--- Index aanmaken over de geometrie 
CREATE INDEX top10_waterlopen_buffer_geom ON data_verwerkt.top10_waterlopen_buffer  USING gist(geom);

--- Kolommen toevoegen voor de functies
ALTER TABLE data_verwerkt.top10_waterlopen_buffer ADD COLUMN code_function integer;
ALTER TABLE data_verwerkt.top10_waterlopen_buffer ADD COLUMN code_function_desc character varying(50);

--- De functie kolommen vullen
UPDATE data_verwerkt.top10_waterlopen_buffer SET code_function=144,code_function_desc='binnenwater' ;

--- Kolommen toevoegen de landgebuiks klasse
ALTER TABLE data_verwerkt.top10_waterlopen_buffer ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_verwerkt.top10_waterlopen_buffer ADD COLUMN code_physical_landuse_desc character varying(50);

--- De landgebruiks kolommen vullen
UPDATE data_verwerkt.top10_waterlopen_buffer SET code_physical_landuse=29,code_physical_landuse_desc='water';

/*
SELECT * 
FROM data_verwerkt.top10_waterlopen_buffer 
LIMIT 10;
*/

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Wegvlakken 
-----------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------- 

/*
BRON: top10nl
Resultaat: alle wegvlakken uit top10nl
*/

--- Tabel aanmaken voor de wegen
DROP TABLE IF EXISTS data_verwerkt.top10_wegen;
CREATE TABLE data_verwerkt.top10_wegen AS

--- Tabel vullen
SELECT status, verhardingstype, tdncode, visualisatiecode, geom
FROM top10_wegdeel_vlak
WHERE status = 'in gebruik';
 
--- Index aanmaken over de verhardingstype 
CREATE INDEX top10_wegen_verhardingstype ON data_verwerkt.top10_wegen USING btree(verhardingstype);

/*
SELECT DISTINCT verhardingstype
FROM data_verwerkt.top10_wegen;
*/

--- Kolommen toevoegen voor de landgebruiksklasse
ALTER TABLE data_verwerkt.top10_wegen ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_verwerkt.top10_wegen ADD COLUMN code_physical_landuse_desc character varying(50);
 
--- De Landgebruiks kolommen vullen
UPDATE data_verwerkt.top10_wegen SET code_physical_landuse=6,code_physical_landuse_desc='weg verhard' WHERE cast(verhardingstype AS text)= 'verhard';
UPDATE data_verwerkt.top10_wegen SET code_physical_landuse=254,code_physical_landuse_desc='weg onbekend' WHERE cast(verhardingstype AS text)= 'onbekend';
UPDATE data_verwerkt.top10_wegen SET code_physical_landuse=13,code_physical_landuse_desc='weg onverhard' WHERE cast(verhardingstype AS text)= 'onverhard';
UPDATE data_verwerkt.top10_wegen SET code_physical_landuse=7,code_physical_landuse_desc='weg half verhard' WHERE cast(verhardingstype AS text)= 'half verhard';

--- Kolommen toevoegen voor de functies
ALTER TABLE data_verwerkt.top10_wegen ADD COLUMN code_function integer;
ALTER TABLE data_verwerkt.top10_wegen ADD COLUMN code_function_desc character varying(50);

/*
SELECT * 
FROM data_verwerkt.top10_wegen 
LIMIT 10;
*/

/* uit de documentatie van de top 10:
visualisatie code 	type weg				hoofdverkeersgebruik		type infrastructuur			verhardings type			geometrie type
10000			startbaan, landingsbaan		n.v.t						n.v.t						n.v.t						n.v.t
10100			rolbaan, platform			n.v.t						n.v.t						n.v.t						n.v.t
10200			autosnelweg					n.v.t 						n.v.t						n.v.t						n.v.t
10300			hoofdweg					snelverkeer					n.v.t						n.v.t						n.v.t
10310			hoofdweg 					<> snelverkeer				n.v.t						n.v.t						n.v.t
10400			regionale weg				snelverkeer					n.v.t						n.v.t						n.v.t
10410			regionale weg 				<> snelverkeer				n.v.t						n.v.t						n.v.t
10500			lokale weg					snelverkeer					n.v.t						n.v.t						n.v.t
10510			lokale weg 					<> snelverkeer				n.v.t						n.v.t						n.v.t
10600			straat						n.v.t.						n.v.t						n.v.t						n.v.t
10100			overig						vliegverkeer				n.v.t						n.v.t						n.v.t
10700			overig						busverkeer					n.v.t						n.v.t						n.v.t
10710			overig						gemengd verkeer				n.v.t.						'verhard' of 'onbekend'		n.v.t
10720			overig						gemengd verkeer				n.v.t.						half verhard				n.v.t
10730			overig						gemengd verkeer				n.v.t.						onverhard					n.v.t
10740			overig						fietsers, bromfietsers		n.v.t.						n.v.t.						n.v.t.
10750			overig						voetgangers 				<> overig verkeersgebied	n.v.t.						n.v.t
10760			overig						voetgangers					overig verkeersgebied		n.v.t.						n.v.t.
10770			overig						ruiters						n.v.t						n.v.t						n.v.t
10780			overig						parkeren					n.v.t						n.v.t.						n.v.t
10790			overig 						overig						n.v.t						n.v.t.						n.v.t
*/

--- De functie kolommen vullen
UPDATE data_verwerkt.top10_wegen SET code_function=251,code_function_desc='primaire weg' WHERE visualisatiecode= 10200;
UPDATE data_verwerkt.top10_wegen SET code_function=251,code_function_desc='primaire weg' WHERE visualisatiecode= 10300;
UPDATE data_verwerkt.top10_wegen SET code_function=251,code_function_desc='primaire weg' WHERE visualisatiecode= 10310;
UPDATE data_verwerkt.top10_wegen SET code_function=252,code_function_desc='secundaire weg' WHERE visualisatiecode= 10400;
UPDATE data_verwerkt.top10_wegen SET code_function=252,code_function_desc='secundaire weg' WHERE visualisatiecode= 10410;
UPDATE data_verwerkt.top10_wegen SET code_function=253,code_function_desc='tertiaire weg' WHERE visualisatiecode= 10500;
UPDATE data_verwerkt.top10_wegen SET code_function=253,code_function_desc='tertiaire weg' WHERE visualisatiecode= 10510;
UPDATE data_verwerkt.top10_wegen SET code_function=253,code_function_desc='tertiaire weg' WHERE visualisatiecode= 10600;

--- De functie kolommen worden opgevuld met overig als er niks wordt gevonden.
UPDATE data_verwerkt.top10_wegen SET code_function=254,code_function_desc='overige weg' WHERE code_function is null;

/*
SELECT * 
FROM data_verwerkt.top10_wegen 
LIMIT 10;
*/

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Spoor top10 
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

/*
BRON: top10nl
Resultaat: alle spoorvlakken uit top10nl
*/

--- Tabel aanmaken voor de sporen 
DROP TABLE IF EXISTS data_verwerkt.top10_spoor;
CREATE TABLE data_verwerkt.top10_spoor AS

--- Tabel vullen
SELECT *
FROM top10_terrein_vlak
WHERE typelandgebruik LIKE '%spoor%';

/*
SELECT * 
FROM data_verwerkt.top10_spoor  
LIMIT 10;
*/

/*
SELECT DISTINCT typelandgebruik 
FROM data_verwerkt.top10_spoor;
*/

--- Index aanmaken over het typelandgebruik
CREATE INDEX top10_spoor_landgebruik ON data_verwerkt.top10_spoor USING btree(typelandgebruik);

--- Kolommen toevoegen voor de functies
ALTER TABLE data_verwerkt.top10_spoor ADD COLUMN code_function integer;
ALTER TABLE data_verwerkt.top10_spoor ADD COLUMN code_function_desc character varying(50);

--- De functie kolommen vullen
UPDATE data_verwerkt.top10_spoor SET code_function=34,code_function_desc='spoor' WHERE cast(typelandgebruik AS text) LIKE '%spoor%';

--- Kolommen toevoegen voor de landgebruiksklasse
ALTER TABLE data_verwerkt.top10_spoor ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_verwerkt.top10_spoor ADD COLUMN code_physical_landuse_desc character varying(50);

--- De Landgebruiks kolommen vullen
UPDATE data_verwerkt.top10_spoor SET code_physical_landuse=34,code_physical_landuse_desc='spoor' WHERE cast(typelandgebruik AS text) LIKE '%spoor%';

/*
SELECT * 
FROM data_verwerkt.top10_spoor 
LIMIT 10;
*/

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Bos top10 
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

/*
BRON: top10nl
Resultaat: alle bosvlakken uit top10nl
*/

--- Tabel aanmaken voor het bos
DROP TABLE IF EXISTS data_verwerkt.top10_bos;
CREATE TABLE data_verwerkt.top10_bos AS

--- Tabel vullen
SELECT *
FROM top10_terrein_vlak
WHERE typelandgebruik LIKE '%bos%' or typelandgebruik = 'populieren';

--- Index aanmaken over het typelandgebruik 
CREATE INDEX top10_bos_landgebruik ON data_verwerkt.top10_bos USING btree(typelandgebruik);

--- Index aanmaken over de geometrie
DROP INDEX IF EXISTS top10_bos_geom;
CREATE INDEX top10_bos_geom ON data_verwerkt.top10_bos USING GIST(geom);

--- Kolommen toevoegen voor de functies
ALTER TABLE data_verwerkt.top10_bos ADD COLUMN code_function integer;
ALTER TABLE data_verwerkt.top10_bos ADD COLUMN code_function_desc character varying(50);
 
--- De functie kolommen vullen
UPDATE data_verwerkt.top10_bos SET code_function=39,code_function_desc='bos / natuur' WHERE cast(typelandgebruik AS text)= 'bos: gemengd bos';
UPDATE data_verwerkt.top10_bos SET code_function=118,code_function_desc='begraafplaats' WHERE cast(typelandgebruik AS text)= 'dodenakker met bos';
UPDATE data_verwerkt.top10_bos SET code_function=39,code_function_desc='bos / natuur' WHERE cast(typelandgebruik AS text)= 'bos: griend';
UPDATE data_verwerkt.top10_bos SET code_function=39,code_function_desc='bos / natuur' WHERE cast(typelandgebruik AS text)= 'populieren';
UPDATE data_verwerkt.top10_bos SET code_function=39,code_function_desc='bos / natuur' WHERE cast(typelandgebruik AS text)= 'bos: loofbos';
UPDATE data_verwerkt.top10_bos SET code_function=39,code_function_desc='bos / natuur' WHERE cast(typelandgebruik AS text)= 'bos: naaldbos';

--- Kolommen toevoegen voor de landgebruiksklasse
ALTER TABLE data_verwerkt.top10_bos ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_verwerkt.top10_bos ADD COLUMN code_physical_landuse_desc character varying(50);
 
--- De landgebruiks kolommen vullen
UPDATE data_verwerkt.top10_bos SET code_physical_landuse=39,code_physical_landuse_desc='gemengd bos' WHERE cast(typelandgebruik AS text)= 'bos: gemengd bos';
UPDATE data_verwerkt.top10_bos SET code_physical_landuse=118,code_physical_landuse_desc='gras met bomen' WHERE cast(typelandgebruik AS text)= 'dodenakker met bos';
UPDATE data_verwerkt.top10_bos SET code_physical_landuse=41,code_physical_landuse_desc='griend' WHERE cast(typelandgebruik AS text)= 'bos: griend';
UPDATE data_verwerkt.top10_bos SET code_physical_landuse=43,code_physical_landuse_desc='populieren' WHERE cast(typelandgebruik AS text)= 'populieren';
UPDATE data_verwerkt.top10_bos SET code_physical_landuse=40,code_physical_landuse_desc='loofbos' WHERE cast(typelandgebruik AS text)= 'bos: loofbos';
UPDATE data_verwerkt.top10_bos SET code_physical_landuse=42,code_physical_landuse_desc='naaldbos' WHERE cast(typelandgebruik AS text)= 'bos: naaldbos';

/*
SELECT * 
FROM data_verwerkt.top10_bos 
LIMIT 10;
*/

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Gras top10
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

/*
BRON: top10nl
Resultaat: alle grasvlakken uit top10nl
*/

--- Tabel aanmaken voor het gras
DROP TABLE IF EXISTS data_verwerkt.top10_gras;
CREATE TABLE data_verwerkt.top10_gras AS

--- Tabel vullen
SELECT *
FROM top10_terrein_vlak
WHERE typelandgebruik LIKE '%gras%';

--- Index maken over het typelandgebruik
CREATE INDEX top10_gras_landgebruik ON data_verwerkt.top10_gras USING btree(typelandgebruik);

/*
SELECT DISTINCT typelandgebruik 
FROM data_verwerkt.top10_gras;
*/

--- Kolommen toevoegen voor de functies
ALTER TABLE data_verwerkt.top10_gras ADD COLUMN code_function integer;
ALTER TABLE data_verwerkt.top10_gras ADD COLUMN code_function_desc character varying(50);

--- De functie kolommen vulen
UPDATE data_verwerkt.top10_gras SET code_function=27,code_function_desc='gras' WHERE cast(typelandgebruik AS text)= 'grasland';

--- Kolommen toevoegen voor de landgebruiksklasse
ALTER TABLE data_verwerkt.top10_gras ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_verwerkt.top10_gras ADD COLUMN code_physical_landuse_desc character varying(50);
 
--- De landgebruiks kolommen vullen
UPDATE data_verwerkt.top10_gras SET code_physical_landuse=22,code_physical_landuse_desc='gras' WHERE cast(typelandgebruik AS text)= 'grasland';

/*
SELECT * 
FROM data_verwerkt.top10_gras 
LIMIT 100;
*/

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Gewaspercelen (BRP Gewassen)  
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

/*
BRON: BRP gewaspercelen
Resultaat: alle gewaspercelen uit de BRP
*/

--- Tabel aanmaken voor de BRP gewaspercelen
DROP TABLE IF EXISTS data_verwerkt.brp_gewassen;
CREATE TABLE data_verwerkt.brp_gewassen AS

--- Tabel vullen
SELECT *
FROM data_ruw.brp_gewaspercelen_2015;

--- Index aanmaken over de geometrie 
DROP INDEX IF EXISTS brp_gewassen_geom;
CREATE INDEX brp_gewassen_geom ON data_verwerkt.brp_gewassen USING GIST(geom);

/*
SELECT * 
FROM data_verwerkt.brp_gewassen 
LIMIT 10;
*/

--- Index aanmaken over de gewascategrie (gws_gewasc)
CREATE INDEX brp_gewassen_gws_gewasc ON data_verwerkt.brp_gewassen USING btree (gws_gewasc);

/*
SELECT DISTINCT gws_gewasc 
FROM data_verwerkt.brp_gewassen 
ORDER BY gws_gewasc desc;
*/

--- Kolommen toevoegen voor de functies
ALTER TABLE data_verwerkt.brp_gewassen ADD COLUMN code_function integer;
ALTER TABLE data_verwerkt.brp_gewassen ADD COLUMN code_function_desc character varying(50);

--- Indeces aanamken over het landgebruik nummer (code_physical_landuse) en de gewas catergorie (gws_gewas)
CREATE INDEX brp_gewassen_code_physical_landuse ON data_verwerkt.brp_gewassen USING btree (code_physical_landuse);
CREATE INDEX brp_gewassen_code_gws_gewasc ON data_verwerkt.brp_gewassen USING btree (gws_gewasc);

--- De landgebruiks kolommen vullen
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '174';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '233';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '234';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '235';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '236';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '237';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '238';
UPDATE data_verwerkt.brp_gewassen SET code_function=55,code_function_desc='Peulvruchten' WHERE gws_gewasc= '241';
UPDATE data_verwerkt.brp_gewassen SET code_function=55,code_function_desc='Peulvruchten' WHERE gws_gewasc= '242';
UPDATE data_verwerkt.brp_gewassen SET code_function=55,code_function_desc='Peulvruchten' WHERE gws_gewasc= '244';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '246';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '247';
UPDATE data_verwerkt.brp_gewassen SET code_function=50,code_function_desc='Bieten' WHERE gws_gewasc= '256';
UPDATE data_verwerkt.brp_gewassen SET code_function=50,code_function_desc='Bieten' WHERE gws_gewasc= '257';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '258';
UPDATE data_verwerkt.brp_gewassen SET code_function=94,code_function_desc='Mais' WHERE gws_gewasc= '259';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '262';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '263';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '265';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '266';
UPDATE data_verwerkt.brp_gewassen SET code_function=55,code_function_desc='Peulvruchten' WHERE gws_gewasc= '308';
UPDATE data_verwerkt.brp_gewassen SET code_function=55,code_function_desc='Peulvruchten' WHERE gws_gewasc= '311';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '314';
UPDATE data_verwerkt.brp_gewassen SET code_function=94,code_function_desc='Mais' WHERE gws_gewasc= '316';
UPDATE data_verwerkt.brp_gewassen SET code_function=94,code_function_desc='Mais' WHERE gws_gewasc= '317';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '331';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '332';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '333';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '334';
UPDATE data_verwerkt.brp_gewassen SET code_function=70,code_function_desc='Natuur' WHERE gws_gewasc= '335';
UPDATE data_verwerkt.brp_gewassen SET code_function=70,code_function_desc='Natuur' WHERE gws_gewasc= '343';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '344';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '345';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '346';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '347';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '370';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '372';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '375';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '381';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '382';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '383';
UPDATE data_verwerkt.brp_gewassen SET code_function=81,code_function_desc='Groenbemesters' WHERE gws_gewasc= '426';
UPDATE data_verwerkt.brp_gewassen SET code_function=81,code_function_desc='Groenbemesters' WHERE gws_gewasc= '427';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '428';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '511';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '515';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '516';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '652';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '653';
UPDATE data_verwerkt.brp_gewassen SET code_function=70,code_function_desc='Natuur' WHERE gws_gewasc= '654';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '655';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '662';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '663';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '664';
UPDATE data_verwerkt.brp_gewassen SET code_function=55,code_function_desc='Peulvruchten' WHERE gws_gewasc= '665';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '666';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '669';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '670';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '671';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '794';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '795';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '796';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '799';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '800';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '801';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '803';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '804';
UPDATE data_verwerkt.brp_gewassen SET code_function=94,code_function_desc='Mais' WHERE gws_gewasc= '814';
UPDATE data_verwerkt.brp_gewassen SET code_function=55,code_function_desc='Peulvruchten' WHERE gws_gewasc= '853';
UPDATE data_verwerkt.brp_gewassen SET code_function=55,code_function_desc='Peulvruchten' WHERE gws_gewasc= '854';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '863';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '864';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '944';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '964';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '965';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '967';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '968';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '970';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '973';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '976';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '979';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '982';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '985';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '988';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '991';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '992';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '994';
UPDATE data_verwerkt.brp_gewassen SET code_function=53,code_function_desc='Bloembollen' WHERE gws_gewasc= '997';
UPDATE data_verwerkt.brp_gewassen SET code_function=53,code_function_desc='Bloembollen' WHERE gws_gewasc= '998';
UPDATE data_verwerkt.brp_gewassen SET code_function=53,code_function_desc='Bloembollen' WHERE gws_gewasc= '999';
UPDATE data_verwerkt.brp_gewassen SET code_function=53,code_function_desc='Bloembollen' WHERE gws_gewasc= '1000';
UPDATE data_verwerkt.brp_gewassen SET code_function=53,code_function_desc='Bloembollen' WHERE gws_gewasc= '1001';
UPDATE data_verwerkt.brp_gewassen SET code_function=53,code_function_desc='Bloembollen' WHERE gws_gewasc= '1002';
UPDATE data_verwerkt.brp_gewassen SET code_function=53,code_function_desc='Bloembollen' WHERE gws_gewasc= '1003';
UPDATE data_verwerkt.brp_gewassen SET code_function=53,code_function_desc='Bloembollen' WHERE gws_gewasc= '1004';
UPDATE data_verwerkt.brp_gewassen SET code_function=53,code_function_desc='Bloembollen' WHERE gws_gewasc= '1005';
UPDATE data_verwerkt.brp_gewassen SET code_function=53,code_function_desc='Bloembollen' WHERE gws_gewasc= '1006';
UPDATE data_verwerkt.brp_gewassen SET code_function=53,code_function_desc='Bloembollen' WHERE gws_gewasc= '1007';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '1067';
UPDATE data_verwerkt.brp_gewassen SET code_function=59,code_function_desc='Kwekerij' WHERE gws_gewasc= '1068';
UPDATE data_verwerkt.brp_gewassen SET code_function=70,code_function_desc='Natuur' WHERE gws_gewasc= '1069';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '1070';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '1071';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '1072';
UPDATE data_verwerkt.brp_gewassen SET code_function=59,code_function_desc='Kwekerij' WHERE gws_gewasc= '1073';
UPDATE data_verwerkt.brp_gewassen SET code_function=59,code_function_desc='Kwekerij' WHERE gws_gewasc= '1074';
UPDATE data_verwerkt.brp_gewassen SET code_function=59,code_function_desc='Kwekerij' WHERE gws_gewasc= '1075';
UPDATE data_verwerkt.brp_gewassen SET code_function=59,code_function_desc='Kwekerij' WHERE gws_gewasc= '1076';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1077';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1078';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1079';
UPDATE data_verwerkt.brp_gewassen SET code_function=59,code_function_desc='Kwekerij' WHERE gws_gewasc= '1080';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '1081';
UPDATE data_verwerkt.brp_gewassen SET code_function=59,code_function_desc='Kwekerij' WHERE gws_gewasc= '1082';
UPDATE data_verwerkt.brp_gewassen SET code_function=70,code_function_desc='Natuur' WHERE gws_gewasc= '1083';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '1084';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '1085';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '1086';
UPDATE data_verwerkt.brp_gewassen SET code_function=59,code_function_desc='Kwekerij' WHERE gws_gewasc= '1087';
UPDATE data_verwerkt.brp_gewassen SET code_function=59,code_function_desc='Kwekerij' WHERE gws_gewasc= '1088';
UPDATE data_verwerkt.brp_gewassen SET code_function=59,code_function_desc='Kwekerij' WHERE gws_gewasc= '1089';
UPDATE data_verwerkt.brp_gewassen SET code_function=59,code_function_desc='Kwekerij' WHERE gws_gewasc= '1090';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1091';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1093';
UPDATE data_verwerkt.brp_gewassen SET code_function=59,code_function_desc='Kwekerij' WHERE gws_gewasc= '1094';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1095';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1096';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1097';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1098';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1099';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1100';
UPDATE data_verwerkt.brp_gewassen SET code_function=65,code_function_desc='Braakliggend' WHERE gws_gewasc= '1574';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1869';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1870';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1872';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1873';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '1874';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '1876';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '1921';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '1922';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '1923';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '1925';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '1931';
UPDATE data_verwerkt.brp_gewassen SET code_function=60,code_function_desc='Bos' WHERE gws_gewasc= '1936';
UPDATE data_verwerkt.brp_gewassen SET code_function=44,code_function_desc='Aardappelen' WHERE gws_gewasc= '1949';
UPDATE data_verwerkt.brp_gewassen SET code_function=44,code_function_desc='Aardappelen' WHERE gws_gewasc= '2014';
UPDATE data_verwerkt.brp_gewassen SET code_function=44,code_function_desc='Aardappelen' WHERE gws_gewasc= '2015';
UPDATE data_verwerkt.brp_gewassen SET code_function=44,code_function_desc='Aardappelen' WHERE gws_gewasc= '2016';
UPDATE data_verwerkt.brp_gewassen SET code_function=44,code_function_desc='Aardappelen' WHERE gws_gewasc= '2017';
UPDATE data_verwerkt.brp_gewassen SET code_function=44,code_function_desc='Aardappelen' WHERE gws_gewasc= '2025';
UPDATE data_verwerkt.brp_gewassen SET code_function=94,code_function_desc='Mais' WHERE gws_gewasc= '2032';
UPDATE data_verwerkt.brp_gewassen SET code_function=65,code_function_desc='Braakliggend' WHERE gws_gewasc= '2033';
UPDATE data_verwerkt.brp_gewassen SET code_function=65,code_function_desc='Braakliggend' WHERE gws_gewasc= '2300';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '2325';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '2326';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '2327';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '2328';
UPDATE data_verwerkt.brp_gewassen SET code_function=72,code_function_desc='Hoogstam' WHERE gws_gewasc= '2645';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '2652';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '2700';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '2701';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '2702';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '2703';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '2704';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '2705';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '2706';
UPDATE data_verwerkt.brp_gewassen SET code_function=71,code_function_desc='Fruitteelt' WHERE gws_gewasc= '2707';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2708';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2709';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2710';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2711';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2712';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2713';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2714';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2715';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2716';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2717';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2719';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2720';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2721';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2723';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2724';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '2725';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '2726';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '2727';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2729';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2731';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2732';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2735';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2736';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '2737';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '2739';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '2740';
UPDATE data_verwerkt.brp_gewassen SET code_function=50,code_function_desc='Bieten' WHERE gws_gewasc= '2741';
UPDATE data_verwerkt.brp_gewassen SET code_function=50,code_function_desc='Bieten' WHERE gws_gewasc= '2742';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2743';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2744';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2745';
UPDATE data_verwerkt.brp_gewassen SET code_function=55,code_function_desc='Peulvruchten' WHERE gws_gewasc= '2747';
UPDATE data_verwerkt.brp_gewassen SET code_function=55,code_function_desc='Peulvruchten' WHERE gws_gewasc= '2748';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2749';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2750';
UPDATE data_verwerkt.brp_gewassen SET code_function=55,code_function_desc='Peulvruchten' WHERE gws_gewasc= '2751';
UPDATE data_verwerkt.brp_gewassen SET code_function=55,code_function_desc='Peulvruchten' WHERE gws_gewasc= '2752';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2753';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2755';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2756';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '2757';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '2758';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '2759';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '2761';
UPDATE data_verwerkt.brp_gewassen SET code_function=66,code_function_desc='Knol en Bolgewassen' WHERE gws_gewasc= '2762';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2763';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2765';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2766';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2767';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2768';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2769';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2771';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2772';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2773';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2774';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2775';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2776';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2777';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2778';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2779';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2780';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2781';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2782';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2783';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2784';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2785';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2786';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2787';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2788';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2789';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2790';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2791';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2792';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2793';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '2794';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '3501';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '3502';
UPDATE data_verwerkt.brp_gewassen SET code_function=67,code_function_desc='Overige akkerbouwgewassen' WHERE gws_gewasc= '3504';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '3505';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '3506';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '3507';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '3508';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '3509';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '3510';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '3512';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '3513';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '3516';
UPDATE data_verwerkt.brp_gewassen SET code_function=54,code_function_desc='Bloemen' WHERE gws_gewasc= '3517';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '3519';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '3522';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '3523';
UPDATE data_verwerkt.brp_gewassen SET code_function=27,code_function_desc='Gras' WHERE gws_gewasc= '3524';
UPDATE data_verwerkt.brp_gewassen SET code_function=52,code_function_desc='Granen' WHERE gws_gewasc= '3736';

--- Het is niet nodig de naam van de landgebruiksklasse te genereren deze wordt overgenomen uit de gws_gewas kolom
--- Kolommen toevoegen voor de landgebruiksklasse
ALTER TABLE data_verwerkt.brp_gewassen ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_verwerkt.brp_gewassen ADD COLUMN code_physical_landuse_desc character varying(100);

--- De landgebruiks kolommen vullen
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1000';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1001';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1002';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1003';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1004';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1005';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1006';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1007';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1067';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1068';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1069';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1070';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1071';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1072';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1073';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1074';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1075';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1076';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1077';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1078';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1079';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1080';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1081';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1082';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1083';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1084';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1085';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1086';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1087';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1088';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1089';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1090';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1091';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1093';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1094';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1095';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1096';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1097';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1098';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1099';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1100';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1574';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '174';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1869';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1870';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1872';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1873';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1874';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1876';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1921';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1922';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1923';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1925';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1931';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1936';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '1949';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2014';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2015';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2016';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2017';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2025';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2032';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2033';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2300';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2325';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2326';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2327';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2328';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '233';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '234';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '235';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '236';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '237';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '238';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '241';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '242';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '244';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '246';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '247';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '256';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '257';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '258';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '259';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '262';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '263';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2645';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '265';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2652';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '266';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2700';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2701';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2702';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2703';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2704';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2705';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2706';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2707';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2708';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2709';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2710';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2711';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2712';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2713';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2714';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2715';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2716';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2717';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2719';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2720';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2721';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2723';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2724';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2725';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2726';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2727';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2729';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2731';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2732';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2735';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2736';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2737';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2739';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2740';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2741';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2742';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2743';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2744';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2745';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2747';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2748';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2749';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2750';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2751';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2752';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2753';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2755';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2756';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2757';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2758';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2759';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2761';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2762';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2763';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2765';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2766';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2767';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2768';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2769';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2771';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2772';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2773';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2774';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2775';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2776';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2777';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2778';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2779';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2780';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2781';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2782';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2783';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2784';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2785';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2786';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2787';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2788';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2789';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2790';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2791';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2792';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2793';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '2794';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '308';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '311';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '314';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '316';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '317';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '331';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '332';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '333';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '334';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '335';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '343';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '344';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '345';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '346';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '347';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3501';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3502';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3504';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3505';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3506';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3507';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3508';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3509';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3510';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3512';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3513';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3516';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3517';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3519';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3522';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3523';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3524';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '370';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '372';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '3736';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '375';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '381';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '382';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '383';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '426';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '427';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '428';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '511';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '515';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '516';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '652';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '653';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '654';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '655';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '662';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '663';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '664';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '665';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '666';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '669';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '670';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '671';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '794';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '795';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '796';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '799';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '800';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '801';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '803';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '804';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '814';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '853';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '854';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '863';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '864';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '944';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '964';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '965';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '967';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '968';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '970';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '973';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '976';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '979';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '982';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '985';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '988';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '991';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '992';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '994';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '997';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '998';
UPDATE data_verwerkt.brp_gewassen SET code_physical_landuse=code_function,code_physical_landuse_desc=code_function_desc WHERE gws_gewasc= '999';

/*
SELECT DISTINCT code_physical_landuse, code_physical_landuse_desc
FROM data_verwerkt.brp_gewassen ORDER BY code_physical_landuse_desc;
*/

/*
SELECT * 
FROM data_verwerkt.brp_gewassen 
LIMIT 10;
*/

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Parkeerterreinen uit OSM 
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

/*
BRON: OSM
Resultaat: alle parkeerterreinnen uit osm
*/

--- Tabel aanmaken voor de parkeerterreinen
DROP TABLE IF EXISTS data_verwerkt.osm_parkeerterreinen_nl;
CREATE TABLE data_verwerkt.osm_parkeerterreinen_nl AS 

--- Tabel vullen
SELECT ST_Transform(way, 28992) AS geom, amenity, surface
FROM osm_polygons
WHERE amenity LIKE '%parking%';

--- Index aanmaken over de geometrie
CREATE INDEX osm_parkeerterreinen_nl_geom ON data_verwerkt.osm_parkeerterreinen_nl USING gist(geom);

--- Kolommen toevoegen voor de functies
ALTER TABLE data_verwerkt.osm_parkeerterreinen_nl ADD COLUMN code_function integer;
ALTER TABLE data_verwerkt.osm_parkeerterreinen_nl ADD COLUMN code_function_desc character varying(50);

--- De functie kolommen vullen
UPDATE data_verwerkt.osm_parkeerterreinen_nl SET code_function=249,code_function_desc='parkeerterrein' ;

--- Kolommen toevoegen voor de landgebruiksklasse
ALTER TABLE data_verwerkt.osm_parkeerterreinen_nl ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_verwerkt.osm_parkeerterreinen_nl ADD COLUMN code_physical_landuse_desc character varying(50);

--- De landgebruiks kolommen vullen
UPDATE data_verwerkt.osm_parkeerterreinen_nl SET code_physical_landuse=10,code_physical_landuse_desc='parkeerterrein' ;

/*
SELECT * 
FROM data_verwerkt.osm_parkeerterreinen_nl 
LIMIT 100;
*/

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Transformatorhuisjes en watertanks  
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

/*
BRON: top10nl
Resultaat: alle transformatiehuisjes en watertanks op glastuinbouwterrein uit top10nl
*/

DROP TABLE IF EXISTS data_tmp.top10_transformator;
CREATE TABLE data_tmp.top10_transformator AS

SELECT typegebouw, geom AS geom
FROM top10_gebouw_vlak
WHERE typegebouw = '(1:transformatorstation)'; 

/*
SELECT *
FROM data_tmp.top10_transformator
LIMIT 10;
*/

DROP TABLE IF EXISTS data_tmp.top10_tank;
CREATE TABLE data_tmp.top10_tank AS

SELECT typegebouw, geom AS geom
FROM top10_gebouw_vlak
WHERE typegebouw = '(1:tank)'; 

/*
SELECT *
FROM data_tmp.top10_tank
LIMIT 10;
*/

DROP TABLE IF EXISTS data_tmp.cbs_glastuinbouwterrein;
CREATE TABLE data_tmp.cbs_glastuinbouwterrein AS

SELECT code_function_desc, geom AS geom
FROM data_tmp.cbs_gebieden
WHERE code_function_desc = 'glastuinbouwterrein';

/*
SELECT *
FROM data_tmp.cbs_glastuinbouwterrein
LIMIT 10;
*/

DROP TABLE IF EXISTS data_tmp.top10_tank_glastuinbouw;
CREATE TABLE data_tmp.top10_tank_glastuinbouw AS

SELECT a.typegebouw, a.geom AS geom
FROM data_tmp.top10_tank AS a, data_tmp.cbs_glastuinbouwterrein AS b
WHERE a.geom && b.geom;

/*
SELECT *
FROM data_tmp.top10_tank_glastuinbouw
LIMIT 10;
*/

--- Dit kan in een latere versie worden uitgewerkt.
/*
DROP TABLE IF EXISTS data_tmp.cbs_erf;
CREATE TABLE data_tmp.cbs_erf AS

SELECT code_function_desc, geom AS geom
FROM data_tmp.cbs_gebieden
WHERE code_function_desc = 'erf';

SELECT *
FROM data_tmp.cbs_erf
LIMIT 10;

DROP TABLE IF EXISTS data_tmp.top10_tank_erf;
CREATE TABLE data_tmp.top10_tank_erf AS

SELECT a.typegebouw, a.geom AS geom
FROM data_tmp.top10_tank AS a, data_tmp.cbs_erf AS b
WHERE b.geom && a.geom;

SELECT *
FROM data_tmp.top10_tank_erf
LIMIT 10;
*/
---

DROP TABLE IF EXISTS data_verwerkt.top10_transformator_tank;
CREATE TABLE data_verwerkt.top10_transformator_tank (typegebouw VARCHAR (255), geom geometry);
INSERT INTO data_verwerkt.top10_transformator_tank(typegebouw, geom)
SELECT typegebouw, geom
FROM data_tmp.top10_transformator;
 
INSERT INTO data_verwerkt.top10_transformator_tank(typegebouw, geom)
SELECT typegebouw, geom
FROM data_tmp.top10_tank_glastuinbouw;

--- Dit kan in een latere versie worden uitgewerkt.
/*
INSERT INTO data_verwerkt.top10_transformator_tank(typegebouw, geom)
SELECT typegebouw, geom
FROM data_tmp.top10_tank_erf;
*/
--- 

/*
SELECT *
FROM data_verwerkt.top10_transformator_tank
LIMIT 100;
*/

--- Kolommen toevoegen voor de functies 
ALTER TABLE data_verwerkt.top10_transformator_tank ADD COLUMN code_function integer;
ALTER TABLE data_verwerkt.top10_transformator_tank ADD COLUMN code_function_desc character varying(50);
 
--- De functie kolommen vullen 
UPDATE data_verwerkt.top10_transformator_tank SET code_function=131,code_function_desc='transformatorstation' WHERE typegebouw = '(1:transformatorstation)';
UPDATE data_verwerkt.top10_transformator_tank SET code_function=132,code_function_desc='watertank' WHERE typegebouw = '(1:tank)' ;

--- Kolommen toevoegen voor de landgebruiksklasse 
ALTER TABLE data_verwerkt.top10_transformator_tank ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_verwerkt.top10_transformator_tank ADD COLUMN code_physical_landuse_desc character varying(50);

--- De landgebruiks kolommen vullen
UPDATE data_verwerkt.top10_transformator_tank SET code_physical_landuse=1,code_physical_landuse_desc='dak' WHERE typegebouw = '(1:transformatorstation)' ;
UPDATE data_verwerkt.top10_transformator_tank SET code_physical_landuse=29,code_physical_landuse_desc='water' WHERE typegebouw = '(1:tank)' ;

/*
SELECT * 
FROM data_verwerkt.top10_transformator_tank 
LIMIT 100;
*/

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Kassen tabel 
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

/*
BRON: top10nl
Resultaat: alle kassen uit top10nl
*/

--- Tabel aanmaken voor de kassen en warenhuizen
DROP TABLE IF EXISTS data_tmp.top10_kassen_warenhuizen;
CREATE TABLE data_tmp.top10_kassen_warenhuizen AS

--- Tabel vullen
SELECT *
FROM top10_gebouw_vlak
WHERE typegebouw = '(1:kas, warenhuis)';

CREATE INDEX bag_current_ex_functie_geom ON data_verwerkt.bag_current_ex_functie USING gist(geom);
CREATE INDEX top10_kassen_warenhuizen_geom ON data_tmp.top10_kassen_warenhuizen USING gist(geom);

--- Tabel aanmaken voor alleen de kassen
DROP SEQUENCE IF EXISTS nummering; 
CREATE SEQUENCE nummering; 

DROP TABLE IF EXISTS data_verwerkt.top10_kassen;
CREATE TABLE data_verwerkt.top10_kassen AS

--- Tabel vullen
SELECT a.geom AS geom, nextval('nummering') AS gid, b.typegebouw
FROM data_verwerkt.bag_current_ex_functie AS a,
data_tmp.top10_kassen_warenhuizen AS b,
data_tmp.cbs_gebieden AS c
WHERE a.geom && b.geom 
AND c.geom && a.geom
AND ST_Intersects(a.geom, b.geom)
AND (c.code_function = 119 OR c.code_function = 120 or c.code_function = 19) --- code 119 is de code voor glastuinbouw, 120 is de code voor erf en 19 is de code voor bedrijventerrein

--- Kolommen toevoegen voor de functies 
ALTER TABLE data_verwerkt.top10_kassen ADD COLUMN code_function integer;
ALTER TABLE data_verwerkt.top10_kassen ADD COLUMN code_function_desc character varying(50);

--- De functie kolommen vullen 
UPDATE data_verwerkt.top10_kassen SET code_function=133,code_function_desc='kas';

--- Kolommen toevoegen voor de landgebruiksklasse 
ALTER TABLE data_verwerkt.top10_kassen ADD COLUMN code_physical_landuse integer;
ALTER TABLE data_verwerkt.top10_kassen ADD COLUMN code_physical_landuse_desc character varying(50);

--- De landgebruiks kolommen vullen
UPDATE data_verwerkt.top10_kassen SET code_physical_landuse=2,code_physical_landuse_desc='kasdak' 


/*
SELECT * 
FROM data_verwerkt.top10_kassen 
LIMIT 100;
*/

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Indeces aanmaken voor het geval ze niet bestaan
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

--- Indices aanmaken voor de verwerkte tabellen
CREATE INDEX bag_current_geom ON data_verwerkt.bag_current USING gist(geom);
CREATE INDEX bag_current_ex_functie_geom ON data_verwerkt.bag_current_ex_functie USING gist(geom);
CREATE INDEX brp_gewassen_geom ON data_verwerkt.brp_gewassen USING gist(geom);
CREATE INDEX cbs_gebieden_geom ON data_verwerkt.cbs_gebieden USING gist(geom);
CREATE INDEX cbs_top10_water_geom ON data_verwerkt.cbs_top10_water USING gist(geom);
CREATE INDEX osm_sportvelden_nl_geom ON data_verwerkt.osm_sportvelden_nl USING gist(geom);
CREATE INDEX osm_parkeerterreinen_nl_geom ON data_verwerkt.osm_parkeerterreinen_nl USING gist(geom);
CREATE INDEX top10_bermen_geom ON data_verwerkt.top10_bermen USING gist(geom);
CREATE INDEX top10_bos_geom ON data_verwerkt.top10_bos USING gist(geom);
CREATE INDEX top10_gras_geom ON data_verwerkt.top10_gras USING gist(geom);
CREATE INDEX top10_kassen_geom ON data_verwerkt.top10_kassen USING gist(geom);
CREATE INDEX top10_spoor_geom ON data_verwerkt.top10_spoor USING gist(geom);
CREATE INDEX top10_transformator_tank_geom ON data_verwerkt.top10_transformator_tank USING gist(geom);
CREATE INDEX top10_waterlopen_buffer_geom ON data_verwerkt.top10_waterlopen_buffer USING gist(geom);
CREATE INDEX top10_wegen_geom ON data_verwerkt.top10_wegen USING gist(geom);

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Test voor de gemeente Utrecht
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

--- Tabel voor de kassen van Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_top10_kassen;
CREATE TABLE data_tmp.utrecht_top10_kassen AS
--- Tabel vullen
SELECT a.* 
FROM data_verwerkt.top10_kassen AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

--- Tabel voor de BAG van Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_bag;
CREATE TABLE data_tmp.utrecht_bag AS
--- Tabel vullen
SELECT a.* 
FROM data_verwerkt.bag_current AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

--- Tabel voor de BAG zonder functie van Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_bag_current_ex_functie;
CREATE TABLE data_tmp.utrecht_bag_current_ex_functie AS
--- Tabel vullen
SELECT a.* 
FROM data_verwerkt.bag_current_ex_functie AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

--- Tabel voor de transformatorhuisjes van Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_top10_transformator_tank;
CREATE TABLE data_tmp.utrecht_top10_transformator_tank AS
--- Tabel vullen
SELECT a.* 
FROM data_verwerkt.top10_transformator_tank AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

--- Tabel voor de wegen van Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_top10_wegen;
CREATE TABLE data_tmp.utrecht_top10_wegen AS
--- Tabel vullen
SELECT a.* 
FROM data_verwerkt.top10_wegen AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

--- Tabel voor het water van Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_cbs_top10_water;
CREATE TABLE data_tmp.utrecht_cbs_top10_water AS
--- Tabel vullen
SELECT a.* 
FROM data_verwerkt.cbs_top10_water AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

--- Tabel voor het water met buffer van Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_top10_waterlopen_buffer;
CREATE TABLE data_tmp.utrecht_top10_waterlopen_buffer AS
--- Tabel vullen
SELECT a.*
FROM data_verwerkt.top10_waterlopen_buffer AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

--- Tabel voor de gras van Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_top10_gras;
CREATE TABLE data_tmp.utrecht_top10_gras AS
--- Tabel vullen
SELECT a.* 
FROM data_verwerkt.top10_gras AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

--- Tabel voor de BRP gewassen uit Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_brp_gewassen;
CREATE TABLE data_tmp.utrecht_brp_gewassen AS
--- Tabel vullen
SELECT a.* 
FROM data_verwerkt.brp_gewassen AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

--- Tabel voor de parkeerterreinen van Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_osm_parkeerterreinen_nl;
CREATE TABLE data_tmp.utrecht_osm_parkeerterreinen_nl AS
--- Tabel vullen
SELECT a.* 
FROM data_verwerkt.osm_parkeerterreinen_nl AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

--- Tabel voor het bos van Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_top10_bos;
CREATE TABLE data_tmp.utrecht_top10_bos AS
--- Tabel vullen
SELECT a.* 
FROM data_verwerkt.top10_bos AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

--- Tabel voor de sportvelden van Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_osm_sportvelden_nl;
CREATE TABLE data_tmp.utrecht_osm_sportvelden_nl AS
--- Tabel vullen
SELECT a.* 
FROM data_verwerkt.osm_sportvelden_nl AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

--- Tabel voor de spoor van Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_top10_spoor;
CREATE TABLE data_tmp.utrecht_top10_spoor AS
--- Tabel vullen
SELECT a.* 
FROM data_verwerkt.top10_spoor AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

--- Tabel voor de CBS gebieden van Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_cbs_gebieden;
CREATE TABLE data_tmp.utrecht_cbs_gebieden AS
--- Tabel vullen
SELECT a.* 
FROM data_verwerkt.cbs_gebieden AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

--- Tabel voor de bermen van Utrecht aanmaken
DROP TABLE IF EXISTS data_tmp.utrecht_top10_bermen;
CREATE TABLE data_tmp.utrecht_top10_bermen AS
--- Tabel vullen
SELECT a.* 
FROM data_verwerkt.top10_bermen AS a, data_ruw.gemeente_utrecht AS b 
WHERE a.geom && b.geom;

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Controles
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

SELECT DISTINCT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.bag_current ORDER BY code_function;
SELECT DISTINCT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.bag_current_ex_functie ORDER BY code_function;
SELECT DISTINCT code_function_desc,code_function,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.brp_gewassen ORDER BY code_function_desc;
SELECT DISTINCT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.cbs_gebieden ORDER BY code_function;
SELECT DISTINCT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.cbs_top10_water;
SELECT DISTINCT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.osm_sportvelden_nl ORDER BY code_function;
SELECT DISTINCT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.osm_parkeerterreinen_nl;
SELECT DISTINCT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.top10_bermen;
SELECT DISTINCT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.top10_bos ORDER BY code_physical_landuse;
SELECT DISTINCT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.top10_gras;
SELECT DISTINCT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.top10_kassen;
SELECT DISTINCT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.top10_spoor;
SELECT DISTINCT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.top10_transformator_tank ORDER BY code_function;
SELECT DISTINCT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.top10_waterlopen_buffer;
SELECT DISTINCT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc FROM data_verwerkt.top10_wegen ORDER BY code_physical_landuse;

-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------
-- Controle van de kolommen
-----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------

SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.bag_current LIMIT 1;
SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.bag_current_ex_functie LIMIT 1;
SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.brp_gewassen LIMIT 1;
SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.cbs_gebieden LIMIT 1;
SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.cbs_top10_water LIMIT 1;
SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.osm_parkeerterreinen_nl LIMIT 1;
SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.osm_sportvelden_nl LIMIT 1;
SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.top10_kassen LIMIT 1;
SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.top10_bermen LIMIT 1;
SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.top10_bos LIMIT 1;
SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.top10_transfotmator_tank LIMIT 1;
SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.top10_gras LIMIT 1;
SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.top10_spoor LIMIT 1;
SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.top10_waterlopen_buffer LIMIT 1;
SELECT code_function,code_function_desc,code_physical_landuse,code_physical_landuse_desc from data_verwerkt.top10_wegen LIMIT 1;
