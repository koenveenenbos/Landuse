-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- In dit script worden alle foreign data wrappers gedefinieerd die nodig zijn voor de landgebruikskaart
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
---- Foreign Data Wrapper Top10
-------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------- 
 
---DROP SERVER IF EXISTS top10nl_april_2016 CASCADE;
CREATE SERVER top10nl_april_2016 
FOREIGN DATA WRAPPER postgres_fdw 
OPTIONS (dbname 'top10nl_april_2016', host 'Server');
 
DROP USER MAPPING IF EXISTS FOR Naam SERVER top10nl_april_2016_db;

CREATE USER MAPPING for Naam
  SERVER top10nl_april_2016_db
  OPTIONS (USER 'Naam', password 'Wachtwoord');

-------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------- 
---- Top10 Watervlakken
------------------------------------------------------------------------------------------------------------------- 
------------------------------------------------------------------------------------------------------------------- 

DROP FOREIGN TABLE IF EXISTS top10_waterdeel_vlak;
CREATE FOREIGN TABLE top10_waterdeel_vlak
  (
  ogc_fid serial NOT NULL,
  gml_id character varying,
  wkb_geometry geometry,
  fid integer,
  namespace character varying,
  lokaalid character varying,
  brontype character varying,
  bronactualiteit  character varying,
  bronbeschrijving  character varying,
  bronnauwkeurigheid double precision,
  objectbegintijd character varying,
  objecteindtijd character varying,
  tijdstipregistratie character varying,
  eindregistratie character varying,
  tdncode integer,
  visualisatiecode integer,
  mutatietype character varying,
  typewater character varying,
  breedteklasse character varying,
  hoofdafwatering character varying,
  fysiekvoorkomen character varying,
  voorkomen character varying,
  hoogteniveau integer,
  functie character varying,
  getijdeinvloed character varying,
  vaarwegklasse character varying,
  naamofficieel character varying,
  naamnl character varying,
  naamfries character varying,
  isbagnaam character varying,
  sluisnaam character varying,
  brugnaam character varying,
  geom geometry
  )
  SERVER top10nl_april_2016_db OPTIONS (schema_name 'top10nl', table_name 'waterdeel_vlak');

/*
SELECT * 
FROM top10_waterdeel_vlak 
LIMIT 10;
*/  

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- Top10 waterlopen_buffer
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

DROP FOREIGN TABLE IF EXISTS top10_waterlopen_buffer CASCADE;
CREATE FOREIGN TABLE top10_waterlopen_buffer
(
geom geometry
   )
   SERVER top10nl_april_2016_db OPTIONS (schema_name 'top10nl', table_name 'waterlopen_buffer');

/*
SELECT * 
FROM top10_waterlopen_buffer 
LIMIT 10;
*/ 

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- Top10 wegdeel_vlak
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

DROP FOREIGN TABLE IF EXISTS top10_wegdeel_vlak;
CREATE FOREIGN TABLE top10_wegdeel_vlak
  (
  ogc_fid serial NOT NULL,
  wkb_geometry geometry,
  gml_id character varying,
  fid integer,
  namespace character varying,
  lokaalid character varying,
  brontype character varying,
  bronactualiteit  character varying,
  bronbeschrijving  character varying,
  bronnauwkeurigheid double precision,
  objectbegintijd character varying,
  objecteindtijd character varying,
  tijdstipregistratie character varying,
  eindregistratie character varying,
  tdncode integer,
  visualisatiecode integer,
  mutatietype character varying,
  typeinfrastructuur character varying,
  typeweg character varying,
  hoofdverkeersgebruik character varying,
  fysiekvoorkomen character varying,
  verhardingsbreedteklasse character varying,
  gescheidenrijbaan character varying,
  verhardingstype character varying,
  aantalrijstroken integer,
  hoogteniveau integer,
  status character varying,
  naam character varying,
  isbagnaam character varying,
  awegnummer character varying,
  nwegnummer character varying,
  ewegnummer character varying,
  swegnummer character varying,
  afritnummer character varying,
  afritnaam character varying,
  knooppuntnaam character varying,
  brugnaam character varying,
  tunnelnaam character varying,
  geom geometry
  )
  SERVER top10nl_april_2016_db OPTIONS (schema_name 'top10nl', table_name 'wegdeel_vlak');

/* 
SELECT * 
FROM top10_wegdeel_vlak
LIMIT 10;
*/ 

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- Top10 terrein_vlak
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

DROP FOREIGN TABLE IF EXISTS top10_terrein_vlak;
CREATE FOREIGN TABLE top10_terrein_vlak
  (
  ogc_fid serial NOT NULL,
  wkb_geometry geometry,
  gml_id character varying,
  fid integer,
  namespace character varying,
  lokaalid character varying,
  bronactualiteit character varying,
  bronbeschrijving character varying,
  bronnauwkeurigheid double precision,
  objectbegintijd character varying,
  objecteindtijd character varying,
  tijdstipregistratie character varying,
  eindregistratie character varying,
  tdncode integer,
  visualisatiecode integer,
  mutatietype character varying,
  typelandgebruik character varying,
  fysiekvoorkomen character varying,
  voorkomen character varying,
  hoogteniveau integer,
  naam character varying,
  geom geometry
  )
  SERVER top10nl_april_2016_db OPTIONS (schema_name 'top10nl', table_name 'terrein_vlak');

/*
SELECT * 
FROM top10_terrein_vlak
LIMIT 10;
*/  

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- Top10 gebouw_vlak
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

DROP FOREIGN TABLE IF EXISTS  top10_gebouw_vlak;
CREATE FOREIGN TABLE top10_gebouw_vlak
  (
  ogc_fid serial NOT NULL,
  wkb_geometry geometry,
  gml_id character varying,
  fid integer,
  namespace character varying,
  lokaalid character varying,
  brontype character varying,
  bronactualiteit character varying,
  bronbeschrijving character varying,
  bronnauwkeurigheid double precision,
  objectbegintijd character varying,
  objecteindtijd character varying,
  tijdstipregistratie character varying,
  eindregistratie character varying,
  tdncode integer,
  visualisatiecode integer,
  mutatietype character varying,
  typegebouw character varying,
  fysiekvoorkomen character varying,
  hoogteklasse character varying,
  hoogteniveau integer,
  hoogte double precision,
  status character varying,
  soortnaam character varying,
  naam character varying,
  gebruiksdoel character varying,
  geom geometry
  )
  SERVER top10nl_april_2016_db OPTIONS (schema_name 'top10nl', table_name 'gebouw_vlak');

/*
SELECT * 
FROM top10_gebouw_vlak
LIMIT 10;
*/  

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- Foreign Data Wrapper BAG
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

---DROP SERVER IF EXISTS bag_import_april_2016_db CASCADE;
CREATE SERVER bag_import_april_2016_db
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (dbname 'bag_import_april_2016', host 'Server');

DROP USER MAPPING IF EXISTS FOR Naam SERVER bag_import_april_2016_db;

  CREATE USER MAPPING for Naam
  SERVER bag_import_april_2016_db
  OPTIONS (USER 'Naam', password 'Wachtwoord');

DROP FOREIGN TABLE IF EXISTS bag_pand_excl_functie;
CREATE FOREIGN TABLE bag_pand_excl_functie
  (
  gid integer,
  identificatie numeric(16,0),
  aanduidingrecordinactief boolean,
  aanduidingrecordcorrectie integer,
  officieel boolean,
  inonderzoek boolean,
  begindatumtijdvakgeldigheid timestamp without time zone,
  einddatumtijdvakgeldigheid timestamp without time zone,
  documentnummer character varying(20),
  documentdatum date,
  pandstatus character varying(100),
  bouwjaar numeric(4,0),
  geom_valid boolean,
  geovlak geometry
  )
  SERVER bag_import_april_2016_db OPTIONS (schema_name 'bagactueel', table_name 'pand');

/*
SELECT * 
FROM bag_pand_excl_functie 
LIMIT 10
*/

DROP FOREIGN TABLE IF EXISTS bag_pand_incl_functie;
CREATE FOREIGN TABLE bag_pand_incl_functie
  (
  id_vbo numeric(16,0),
  gebruiksdoelverblijfsobject character varying(100),
  geom geometry
  )
  SERVER bag_import_april_2016_db OPTIONS (schema_name 'public', table_name 'gebruiksdoel_met_verblijfsobject_current');

/*
SELECT * 
FROM bag_pand_incl_functie 
LIMIT 10
*/

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- Foreign Data Wrapper OSM
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

---DROP SERVER IF EXISTS osm_april_2016_db CASCADE;
CREATE SERVER osm_april_2016_db_db
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (dbname 'osm_april_2016_db', host 'Server');

DROP USER MAPPING IF EXISTS FOR Naam SERVER osm_april_2016_db;

  CREATE USER MAPPING for Naam
  SERVER osm_april_2016_db
  OPTIONS (USER 'Naam', password 'Wachtwoord');

DROP FOREIGN TABLE IF EXISTS osm_polygons;
CREATE FOREIGN TABLE public.osm_polygons
  (
  osm_id bigint,
  access text,
  "addr:housename" text,
  "addr:housenumber" text,
  "addr:interpolation" text,
  admin_level text,
  aerialway text,
  aeroway text,
  amenity text,
  area text,
  barrier text,
  bicycle text,
  brand text,
  bridge text,
  boundary text,
  building text,
  construction text,
  covered text,
  culvert text,
  cutting text,
  denomination text,
  disused text,
  embankment text,
  foot text,
  "generator:source" text,
  harbour text,
  highway text,
  historic text,
  horse text,
  intermittent text,
  junction text,
  landuse text,
  layer text,
  leisure text,
  lock text,
  man_made text,
  maxspeed text,
  military text,
  motorcar text,
  name text,
  "natural" text,
  office text,
  oneway text,
  operator text,
  place text,
  population text,
  power text,
  power_source text,
  public_transport text,
  railway text,
  ref text,
  religion text,
  route text,
  service text,
  shop text,
  sport text,
  surface text,
  toll text,
  tourism text,
  "tower:type" text,
  tracktype text,
  tunnel text,
  water text,
  waterway text,
  wetland text,
  width text,
  wood text,
  z_order integer,
  way_area real,
  way geometry
  )
  SERVER osm_april_2016_db OPTIONS (schema_name 'public',table_name 'planet_osm_polygon');

/*
SELECT *
FROM osm_polygons 
LIMIT 10;
*/

