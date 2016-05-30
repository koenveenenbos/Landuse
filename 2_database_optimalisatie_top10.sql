-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- In dit script wordt de top10nl database geoptimaliseerd. 
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
---- wegdeel vlak
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

-- De kolom voor de geometrie toevoegen
ALTER TABLE top10nl.wegdeel_vlak DROP COLUMN IF EXISTS geom;
ALTER TABLE top10nl.wegdeel_vlak ADD COLUMN geom geometry;

-- De geometrie kolom vullen
UPDATE top10nl.wegdeel_vlak set geom=ST_GeomFROMEWKB(wkb_geometry);

De geometrie omzetten naar het Nederlandse coördinaten stelsel
ALTER TABLE top10nl.wegdeel_vlak
  ALTER COLUMN geom TYPE geometry(POLYGON, 0) 
    USING ST_SetSRID(geom,28992);
    
-- Index aanmaken over de geometrie
CREATE INDEX wegdeel_vlak_geom ON top10nl.wegdeel_vlak USING gist(geom);

/*
SELECT * 
FROM top10nl.wegdeel_vlak
LIMIT 10;
*/

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- waterdeel vlak
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

-- De kolom voor de geometrie toevoegen
ALTER TABLE top10nl.waterdeel_vlak DROP COLUMN IF EXISTS geom;
ALTER TABLE top10nl.waterdeel_vlak ADD COLUMN geom geometry;

-- De geometrie kolom vullen
UPDATE top10nl.waterdeel_vlak set geom=ST_GeomFROMEWKB(wkb_geometry);

-- De geometrie omzetten naar het Nederlandse coördinaten stelsel
ALTER TABLE top10nl.waterdeel_vlak
  ALTER COLUMN geom TYPE geometry(POLYGON, 0) 
    USING ST_SetSRID(geom,28992);
    
-- Index aanmaken over de geometrie
CREATE INDEX waterdeel_vlak_geom ON top10nl.waterdeel_vlak USING gist(geom);

/* 
SELECT * 
FROM top10nl.waterdeel_vlak
LIMIT 10;
*/
 
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- terreindeel vlak
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------


-- De kolom voor de geometrie toevoegen
ALTER TABLE top10nl.terrein_vlak DROP COLUMN IF EXISTS geom;
ALTER TABLE top10nl.terrein_vlak ADD COLUMN geom geometry;

-- De geometrie kolom vullen
UPDATE top10nl.terrein_vlak SET geom=ST_GeomFROMEWKB(wkb_geometry);

-- De geometrie omzetten naar het Nederlandse coördinaten stelsel
ALTER TABLE top10nl.terrein_vlak
  ALTER COLUMN geom TYPE geometry(POLYGON, 0) 
    USING ST_SetSRID(geom,28992);
    
-- Indeces aanmaken over de geometrie en typelandgebruik
CREATE INDEX terrein_vlak_geom ON top10nl.terrein_vlak USING gist(geom);
CREATE INDEX terrein_vlak_typelandgebruik ON top10nl.terrein_vlak USING btree(typelandgebruik);

/*
SELECT distinct typelandgebruik 
FROM top10nl.terrein_vlak
LIMIT 10;
*/

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- gebouw vlak
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

-- De kolom voor de geometrie toevoegen
ALTER TABLE top10nl.gebouw_vlak DROP COLUMN IF EXISTS geom;
ALTER TABLE top10nl.gebouw_vlak ADD COLUMN geom geometry;

-- De geometrie kolom vullen
UPDATE top10nl.gebouw_vlak set geom=ST_GeomFROMEWKB(wkb_geometry);

-- De geometrie omzetten naar het Nederlandse coördinaten stelsel
ALTER TABLE top10nl.gebouw_vlak
  ALTER COLUMN geom TYPE geometry(POLYGON, 0) 
    USING ST_SetSRID(geom,28992);

-- Index aanmaken over de geometrie
CREATE INDEX gebouw_vlak_geom ON top10nl.gebouw_vlak USING gist(geom);

-- -- Indeces aanmaken over de visualisatiecode en het typegebouw
CREATE INDEX gebouw_vlak_visualisatiecode ON top10nl.gebouw_vlak USING btree(visualisatiecode);
CREATE INDEX gebouw_vlak_typegebouw1 ON top10nl.gebouw_vlak USING btree(typegebouw);

-- SELECT distinct visualisatiecode FROM top10nl.gebouw_vlak;
-- SELECT distinct typegebouw FROM top10nl.gebouw_vlak;

/*
SELECT * 
FROM top10nl.gebouw_vlak 
LIMIT 10;
*/

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- waterdeel lopen
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

-- De kolom voor de geometrie toevoegen
ALTER TABLE top10nl.waterdeel_lijn DROP COLUMN IF EXISTS geom;
ALTER TABLE top10nl.waterdeel_lijn ADD COLUMN geom geometry;

-- De geometrie kolom vullen
UPDATE top10nl.waterdeel_lijn set geom=ST_GeomFROMEWKB(wkb_geometry);

-- De geometrie omzetten naar het Nederlandse coördinaten stelsel
ALTER TABLE top10nl.waterdeel_lijn
  ALTER COLUMN geom TYPE geometry(LINESTRING, 0) 
    USING ST_SetSRID(geom,28992);

-- Index aanmaken over de geometrie
CREATE INDEX waterdeel_lijn_geom ON top10nl.waterdeel_lijn USING gist(geom);

-- Index aanmaken over de breedteklasse
CREATE INDEX waterdeel_lijn_breedteklasse ON top10nl.waterdeel_lijn USING btree(breedteklasse);
ALTER TABLE top10nl.waterdeel_lijn ADD COLUMN bufferbreedte numeric;
UPDATE top10nl.waterdeel_lijn SET bufferbreedte=2.25 WHERE cast(breedteklasse as text)= '3 - 6 meter';
UPDATE top10nl.waterdeel_lijn SET bufferbreedte=0.75 WHERE cast(breedteklasse as text)= '0,5 - 3 meter';
UPDATE top10nl.waterdeel_lijn SET bufferbreedte=0.5 WHERE cast(breedteklasse as text) is null;

/*
SELECT distinct breedteklasse 
FROM top10nl.waterdeel_lijn;
*/

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- waterlopen_buffer
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

--- Tabel voor de buffer rond de waterlijnen
DROP TABLE IF EXISTS top10nl.waterlopen_buffer;
CREATE TABLE top10nl.waterlopen_buffer AS

-- Tabel vullen 
SELECT ST_Buffer(a.geom, a.bufferbreedte) as geom
FROM top10nl.waterdeel_lijn as a;

/*
SELECT * 
FROM top10nl.waterlopen_buffer 
LIMIT 10;
*/

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
---- waterlopen_buffer_except
-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------

--- Tabel maken voor alle waterlijnen die niet overlappen met de watervlakken
DROP TABLE IF EXISTS top10nl.waterlopen_buffer_except;
CREATE TABLE top10nl.waterlopen_buffer_except AS

-- Tabel vulen
SELECT ST_Buffer(a.geom, a.bufferbreedte) as geom
FROM top10nl.waterdeel_lijn as a

EXCEPT
SELECT ST_Buffer(a.geom, a.bufferbreedte) as geom
FROM top10nl.waterdeel_lijn as a, waterdeel_vlak as b
WHERE a.geom && b.geom
AND ST_Intersects(ST_Buffer(a.geom, 5), b.geom);

/*
SELECT * 
FROM top10nl.waterlopen_buffer_except 
LIMIT 10;
*/

-------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------
