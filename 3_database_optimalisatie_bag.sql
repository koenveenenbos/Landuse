-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- In dit script wordt de BAG database geoptimaliseerd. 
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------


-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- Extensies aanmaken
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

CREATE EXTENSION IF NOT EXISTS postgres_fdw;
CREATE EXTENSION IF NOT EXISTS postgis;

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- panden
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

--- Indeces aanmaken voor de panden
--- Index aanmaken over de geometrie
create index pand_geovlak on bagactueel.pand using gist(geovlak);

--- Index aanmaken over de identificatie
create index pand_identificatie on bagactueel.pand using btree(identificatie);

--- Indeces aanmaken voor de verblijfsobjectpanden over de identificatie en gerelateerdpand
create index verblijfsobjectpand_identificatie on bagactueel.verblijfsobjectpand using btree(identificatie);
create index verblijfsobjectpand_gerelateerdpand on bagactueel.verblijfsobjectpand using btree(gerelateerdpand);

--- Index aanmaken voor het verblijfsobjectgebruiksdoel over de identificatie
--- create index verblijfsobjectgebruiksdoel_identificatie on bagactueel.verblijfsobjectgebruiksdoel using btree(identificatie);

Tabel aanmaken voor panden met gebruiksdoel
DROP TABLE IF EXISTS gebruiksdoel_met_verblijfsobject;
CREATE TABLE gebruiksdoel_met_verblijfsobject AS 

--- Tabel vullen
SELECT 
	c.geovlak as geom,
	a.identificatie as id_vbo, 
	b.gerelateerdpand, 
	a.gebruiksdoelverblijfsobject, 
	c.pandstatus, 
	c.bouwjaar, 
	b.begindatumtijdvakgeldigheid,
	c.einddatumtijdvakgeldigheid, 
	c.identificatie,
	c.aanduidingrecordinactief,
	c.geom_valid
	
FROM bagactueel.verblijfsobjectgebruiksdoel as a, bagactueel.verblijfsobjectpand as b, bagactueel.pand as c
WHERE a.identificatie = b.identificatie
AND b.gerelateerdpand = c.identificatie
AND ST_NPoints(c.geovlak) > 4;

/*
SELECT *
FROM gebruiksdoel_met_verblijfsobject 
LIMIT 10;
*/

--- Tabel aanmaken voor de huidige panden zonder filter
DROP TABLE IF EXISTS gebruiksdoel_met_verblijfsobject_current_tmp;
CREATE TABLE gebruiksdoel_met_verblijfsobject_current_tmp AS

--- Tabel vullen
SELECT * 
FROM gebruiksdoel_met_verblijfsobject as a
WHERE a.begindatumtijdvakgeldigheid <= 'now'::text::timestamp without time zone 
AND (a.einddatumtijdvakgeldigheid IS NULL OR a.einddatumtijdvakgeldigheid >= 'now'::text::timestamp without time zone) 
AND a.aanduidingrecordinactief = false AND a.geom_valid = true 
AND a.pandstatus <> 'Niet gerealiseerd pand'::bagactueel.pandstatus 
AND a.pandstatus <> 'Pand gesloopt'::bagactueel.pandstatus;

/*
SELECT *
FROM gebruiksdoel_met_verblijfsobject_current_tmp
WHERE EXTRACT(year FROM einddatumtijdvakgeldigheid) < 2016 
LIMIT 1;
*/

--- Tabel aanmaken voor huidige panden met filter op geometrie
DROP TABLE IF EXISTS gebruiksdoel_met_verblijfsobject_current;
CREATE TABLE gebruiksdoel_met_verblijfsobject_current AS

--- Tabel vullen
SELECT DISTINCT ON (geom) geom, id_vbo, gebruiksdoelverblijfsobject
FROM gebruiksdoel_met_verblijfsobject_current_tmp;

/*
SELECT *
FROM gebruiksdoel_met_verblijfsobject_current
LIMIT 10;
*/

