--
-- Openness-metrics schema
-- Implement with $reini=true at ini.php or
--      psql -h localhost -U postgres om_database < openCoherence/src/ini.sql
--

DROP SCHEMA IF EXISTS om CASCADE;
CREATE SCHEMA om;

-- -- -- --
-- NOTES:
--  needs PostgreSQL version 9.3+
--  charging data with srv/php/carga.php
--  using table names with plurals, convention at http://book.cakephp.org/3.0/en/intro/conventions.html
--  Refresh with DROP SCHEMA oc CASCADE; and redo this file without final "global util functions"
-- -- -- --

CREATE TABLE om.license_families(
--
-- Licence families.
-- see https://github.com/ppKrauss/dataset_licenses/blob/master/data/families.csv
--
  fam_id serial PRIMARY KEY,
  fam_name varchar(32) NOT NULL,
  fam_info JSONB,     -- any other metadata.
  kx_sort int NOT NULL DEFAULT 100,
  kx_vec int[][],  -- [version][scope]
  UNIQUE(fam_name)
);


CREATE TABLE om.licenses (
--
-- The licences (metadata)
-- see https://github.com/ppKrauss/dataset_licenses/blob/master/data/licenses.csv
--
  lic_id serial PRIMARY KEY,
  lic_id_label  varchar(32) NOT NULL,   	-- a lower-case short name
  lic_id_version  varchar(32) NOT NULL DEFAULT '', -- in general a float number
  lic_name  varchar(64) NOT NULL,    	-- the standard name
  lic_family  int REFERENCES om.license_families(fam_id),
  lic_id_equiv  int REFERENCES om.licenses(lic_id),
  lic_info jsonB, -- any other metadata.
  lic_modified timestamp DEFAULT now(),
  UNIQUE(lic_id_label,lic_id_version),
  UNIQUE(lic_name)
);


-- --- --- ---
-- BASIC VIEWS

CREATE VIEW om.licenses_full AS
  SELECT l.*, lic_id_label||CASE WHEN lic_id_version!='' THEN '-'||lic_id_version ELSE '' END as lic_id_name,
         f.fam_name, f.fam_info->>'scope' as scope, f.kx_sort, f.kx_vec
  FROM om.licenses l LEFT JOIN om.license_families f ON lic_family=f.fam_id;


-- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
-- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
-- SPECIFIC FUNCS:BEGIN
-- Orthogonal set of functions for microservices and utilities.
--

-- --- --- --- --- --- --- --- --- --- --- --- --- ---
-- SPECIFIC FUNCS, family name handlers v1.0 (all tested!)

CREATE FUNCTION om.famname_format(
  --
  -- Sanitize and normalize a family's name "free string".
  -- Example: SELECT om.famname_format('CC BY-NC-ND');
  --
  text              -- free name
  ) RETURNS text AS $f$
      WITH t AS ( SELECT trim($1) as freename )
      SELECT CASE
               WHEN freename is null OR freename='' THEN NULL
               ELSE trim( lower(regexp_replace(freename, '[\- _]+', '-', 'g')), '-' )
             END
      FROM t;
$f$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION om.famname_to_id(
  --
  -- Get family internal ID (or NULL when not found) from family name.
  --
  text              -- free name
  ) RETURNS int AS $f$
    SELECT fam_id FROM om.license_families WHERE om.famname_format($1)=fam_name;
$f$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION om.famname_to_info(
  --
  -- Get full information (or NULL when not found) from family name.
  -- Example: SELECT om.famname_to_info('cc  BY');
  --
  text              -- free name
  ) RETURNS JSON AS $f$
    SELECT row_to_json(t)
    FROM (  SELECT * FROM om.license_families WHERE om.famname_format($1)=fam_name  ) t;
$f$ LANGUAGE sql IMMUTABLE;



-- --- --- --- --- --- --- --- --- --- --- --- --- ---
-- SPECIFIC FUNCS, family name list handlers v1.0 (all tested!)

CREATE FUNCTION om.famnames_to_ids( text[] ) RETURNS int[] AS $f$
        -- Example: select om.famnames_to_ids('{cc0,cc-by-nc}'::text[]);
	WITH lst AS (SELECT unnest($1) as fname)
	SELECT array_agg(lf.fam_id)
	FROM lst LEFT JOIN om.license_families lf ON om.famname_format(fname)=fam_name;
$f$ LANGUAGE sql IMMUTABLE;

-- --- --- --- --- --- --- --- --- --- --- --- --- ---
-- SPECIFIC FUNCS, other family handlers v1.0 (all tested!)

CREATE FUNCTION om.fam_to_info(int) RETURNS JSON AS $f$
    -- info from ID
    SELECT row_to_json(t)
    FROM (  SELECT * FROM om.license_families WHERE $1=fam_id  ) t;
$f$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION om.faminfo_to_degree(
    faminfo JSONB, version int
) RETURNS int AS $f$
	SELECT ($1->>('degreev'||$2::text))::int;
	-- same as lib.norm2(lib.unfold(kx_vec,$2)) only when degree>0
	-- or same as COALESCE(kx_vec[$2][1],0) + ... + COALESCE(kx_vec[$2][3],0)
$f$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION om.famname_to_degree( famnames text[], p_degversion int ) RETURNS int[] AS $f$
        -- Example: select om.famname_to_degree( '{cc0,cc-by-nc,cc by}'::text[] , 2);
	WITH lst AS (SELECT unnest($1) as fname)
	SELECT array_agg(  om.faminfo_to_degree(lf.fam_info,p_degversion)  )
	FROM lst LEFT JOIN om.license_families lf ON om.famname_format(fname)=fam_name;
$f$ LANGUAGE sql IMMUTABLE;
CREATE FUNCTION om.famname_to_degree( famname text, p_degversion int ) RETURNS int AS $f$
	SELECT (om.famname_to_degree( array[$1], $2))[1];
$f$ LANGUAGE sql IMMUTABLE;

-- --- --- --- --- --- --- --- --- --- --- --- --- ---
-- --- --- --- --- --- --- --- --- --- --- --- --- ---
-- SPECIFIC FUNCS, licname handlers v1.0 (all tested!)


CREATE FUNCTION om.licname_format(
  --
  -- Sanitize and normalize a license's name "free string".
  -- Optional version string. Preserves zero in 'CC0', removes 'v' in 'CC-BY v3'.
  --
  text,              -- name (without version when using the second parameter)
  text DEFAULT NULL  -- version or null, filtering non point and numbers.
  ) RETURNS text AS $f$
    WITH t AS (
      SELECT CASE
               WHEN $1 is null OR trim($1)='' THEN NULL
               ELSE trim( lower(regexp_replace($1, '[\- _]+', '-', 'g')), '-' )
             END as p1,
             trim( lower(regexp_replace($2, '[^0-9\.]', '', 'g')) ) AS p2
    ) SELECT CASE
          WHEN p1 IS NULL THEN NULL
	  WHEN p2 IS NOT NULL AND p2>'' THEN p1||'-'||p2
	  ELSE regexp_replace(p1,'(?:[ \-]v([\d\.]+)|([a-z])([1-9]\.?\d*))$','\2-\1\3')
        END
      FROM t;
$f$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION om.licname_cmp(
  --
  -- (internal use) Comapares a supposed standard name with free name with optional separated version.
  --
  text,                  -- standard name
  text,                  -- license partial name or complete name (when without $3)
  text DEFAULT NULL      -- (optional) license version
  ) RETURNS boolean AS $f$
    SELECT rtrim(om.licname_format($2,$3),'.0') = rtrim($1,'.0');
$f$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION om.licname_to_name(
  --
  -- Get official license name (or NULL when not found) from lincense name.
  --
  text,                  -- license partial name or complete name (when without $2)
  text DEFAULT NULL      -- (optional) license version
  ) RETURNS text AS $f$
    SELECT lic_name FROM om.licenses_full WHERE om.licname_cmp(lic_id_name,$1,$2);
$f$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION om.licname_to_id(
  --
  -- Get license internal ID (or NULL when not found) from lincense name.
  --
  text,                  -- license partial name or complete name (when without $2)
  text DEFAULT NULL      -- (optional) license version
  ) RETURNS int AS $f$
    SELECT lic_id FROM om.licenses_full WHERE om.licname_cmp(lic_id_name,$1,$2);
$f$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION om.licname_to_info(
  --
  -- Get full information (or NULL when not found) from lincense name.
  -- Example: SELECT om.licname_get_info('CC-BY-NC4');
  --
  text,                  -- license partial name or complete name (when without $2)
  text DEFAULT NULL      -- (optional) license version
  ) RETURNS JSON AS $f$
    SELECT row_to_json(t)
    FROM (  SELECT * FROM om.licenses_full WHERE om.licname_cmp(lic_id_name,$1,$2)  ) t;
$f$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION om.lic_to_info(int) RETURNS JSON AS $f$
    SELECT row_to_json(t)
    FROM (  SELECT * FROM om.licenses_full WHERE lic_id=$1  ) t;
$f$ LANGUAGE sql IMMUTABLE;

-- --- --- --- --- --- --- --- --- --- --- --- --- ---
-- SPECIFIC FUNCS, licnames (array of) handlers v1.0 (all tested!)

CREATE FUNCTION om.licname_to_name( varchar[] ) RETURNS varchar[] AS $f$
        -- Example: select om.licname_to_name('{cc0 1,apache2}'::text[])
	WITH lst AS (SELECT unnest($1) as name)
	SELECT array_agg(lf.lic_name)
	FROM lst LEFT JOIN om.licenses_full lf ON om.licname_cmp(lf.lic_id_name,lst.name);
$f$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION om.licname_to_id( text[] ) RETURNS int[] AS $f$
        -- Example: select om.licname_to_id('{cc0 1,apache2}'::text[])
	WITH lst AS (SELECT unnest($1) as name)
	SELECT array_agg(lf.lic_id)
	FROM lst LEFT JOIN om.licenses_full lf ON om.licname_cmp(lf.lic_id_name,lst.name);
$f$ LANGUAGE sql IMMUTABLE;

-------
-- DEPENDENTS


-- --- --- ---
-- generic for family and license names.

CREATE FUNCTION om.nameqts_std( JSON , is_family boolean DEFAULT false) RETURNS JSON AS $f$
	-- Convert any kind of list of names (array or key-quantity object) into standard one;
	-- when is_family=fase is license name, else family name.
	-- Like lib.aggsum(), for standardize family of license names.
	-- Example: SELECT om.nameqts_std( '{"CC by":999,"CC-BY-NC":55,"CC-BY-nc":15}'::json , true);
	SELECT json_object(array_agg(stdname),array_agg(qt::text))
	FROM (
		WITH lst AS (
			SELECT CASE WHEN is_family THEN om.famname_format(key) ELSE om.licname_format(key) END as stdname,
				value::float as qt
			FROM json_each_text(  $1  )
		) SELECT stdname, sum(qt) as qt
		  FROM lst
		  GROUP BY 1
	) as t;
$f$ LANGUAGE sql IMMUTABLE;


CREATE or replace FUNCTION om.scopeqts_calc( JSON[], int default 2 ) RETURNS JSON AS $f$
	-- input by [{scope,deg,perc}]
	SELECT array_to_json(array_agg( row_to_json(t3) ))
	FROM (
		WITH t AS ( SELECT unnest($1) as rec)
		SELECT *, 100.0*avg_global/perc_global as avg_scope -- avgdeg
		  FROM (
			SELECT scope, sum(perc) as perc_global, sum(deg*perc/100.0) as avg_global
			FROM t, json_to_record(rec) d(scope text, deg float, perc float)
			GROUP BY 1
		) t2
	) t3;
$f$ LANGUAGE sql IMMUTABLE;

CREATE or replace FUNCTION om.scopeqts_calc( JSON, int default 2 ) RETURNS JSON AS $f$
	WITH t AS ( SELECT json_array_elements($1) as rec)
	SELECT om.scopeqts_calc( array_agg(rec), $2 ) FROM t;
$f$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION om.famqts_calc( JSON, int default 2 ) RETURNS JSON AS $f$
   -- Complete calc and characterization of a list (of families in array or key-val of family-quantity in object).
   -- Input sanitized by om.nameqts_std()
   -- Example: SELECT om.famqts_calc( '{"CC-by":3,"CC by sa":5,"CC-BY":15,"CC-BY":5}'::json , 2);
   SELECT row_to_json(t2) FROM (
	SELECT 'family' as aggtype,
	       max(tot) as qt_tot,
	       $2 as deg_version,
	       sum(CASE WHEN t.id=1 THEN 0 ELSE 1 END) as n_valids,
	       count(*) as n,
	       sum(t.deg::float*t.perc/100.0) as deg_avg,
	       om.scopeqts_calc(  array_agg(json_object(array['scope',t.scope,'deg',deg::text,'perc',perc::text]))  ) as scopes,
	       array_agg( row_to_json(t) ) as list  -- each family
	FROM (
		WITH lst AS (
		  SELECT key as name, value::int as qt
		  FROM json_each_text(  om.nameqts_std( $1 , true)  )
		) SELECT COALESCE(fam_id,1) as id,
			COALESCE(fam_name,'(unknowed)') as name,
			COALESCE(fam_info->>'scope','(err)') as scope,
			lst.qt,   tt.tot,
			om.faminfo_to_degree(fam_info,$2) as deg,
			(100.0*lst.qt::float/tt.tot::float) as perc
		  FROM om.license_families lf RIGHT JOIN lst ON lst.name=lf.fam_name,
			(select sum(qt::int)::float as tot FROM lst) tt
		  ORDER BY COALESCE(lf.kx_sort,-990) DESC
	) t
   ) t2;
$f$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION om.famqts_calc( JSON[], int default 2 ) RETURNS JSON AS $f$
	WITH lst AS (SELECT unnest($1) as x )
	SELECT om.famqts_calc(  json_object(array_agg(key), array_agg(qt::text)), $2 )
	FROM (
	  SELECT  key , sum(value::float) as qt
	  FROM lst, json_each_text(x) t
	  GROUP BY key
	) t2;
$f$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION om.famqts_calc( text[], int default 2 ) RETURNS JSON AS $f$
	WITH lst AS (SELECT unnest($1) as name )
	SELECT om.famqts_calc(  json_object(array_agg(name), array_agg(qt::text)), $2 )
	FROM (
	  SELECT name, count(*)::int as qt -- later use group by famname_format(name)
	  FROM lst GROUP BY 1
	) t2;
$f$ LANGUAGE sql IMMUTABLE;


CREATE or replace FUNCTION om.licqts_calc( JSON, int default 2 ) RETURNS JSON AS $f$
   -- Complete calc and characterization of a list of licenses (in simple array or license-quantity in object).
   -- Input sanitized by om.nameqts_std()
   -- Example: SELECT om.licqts_calc( '{"CC-by2":3,"CC by sa-4":5,"CC-BY-3":15,"CC-BY2":5}'::json , 2);
   SELECT row_to_json(t2) FROM (
	SELECT 'license' as aggtype,
	       max(tot) as qt_tot,
	       $2 as deg_version,
	       sum(CASE WHEN t.id=1 THEN 0 ELSE 1 END) as n_valids,
	       count(*) as n,
	       om.famqts_calc(  array_agg(json_object(array[t.family,t.qt::text])), $2  ) as families,
	       array_agg( row_to_json(t) ) as list  -- each license
	FROM (
		WITH lst AS (
		  SELECT key as name, value::int as qt
		  FROM json_each_text(  om.nameqts_std( $1 , true)  )
		) SELECT COALESCE(lic_id,1) as id,
			COALESCE(lf.lic_id_name,'(unknowed)') as name,
			COALESCE(lf.fam_name,'(unassoc)') as family,
			lst.qt,   tt.tot,
			(100.0*lst.qt::float/tt.tot::float) as perc
		  FROM om.licenses_full lf RIGHT JOIN lst ON om.licname_cmp(lf.lic_id_name,lst.name),
			(select sum(qt::int)::float as tot FROM lst) tt
		  ORDER BY lf.lic_id_name
	) t
   ) t2;
$f$ LANGUAGE sql IMMUTABLE;


-- --- --- --- --- --- --- --- ---
-- SPECIFIC FUNCS, extra conversion

CREATE TYPE om.licget_idqt_aux AS (name varchar, qt int);

CREATE FUNCTION om.nameqt_to_idqt(
  --
  -- Get license internal IDs from lincense names+quantities in a JSON array of objects [{name,qt}].
  -- Example: SELECT  om.nameqt_to_idqt('[{"name":"Apache 2","qt":32},{"name":"CC-BY-3","qt":2}]'::JSON);
  -- NOTE: with with unnest(om.licget_idqt()) or array_to_json(om.licget_idqt())
  JSON  -- the name list
  ) RETURNS JSON[] AS $f$
	WITH lst AS (SELECT * FROM json_populate_recordset(null::om.licget_idqt_aux,$1))
	SELECT array_agg(row_to_json(t)) FROM (
		SELECT lf.lic_id, lf.lic_name, lf.lic_family, lst.qt
		FROM lst LEFT JOIN om.licenses_full lf ON om.licname_cmp(lf.lic_id_name,lst.name)
	) t;
$f$ LANGUAGE sql IMMUTABLE;


-- --- --- --- --- --- --- --- --- ---
-- SPECIFIC FUNCS, counters v1.0 (ok!)


CREATE FUNCTION om.scope_idx(varchar) RETURNS int AS $f$
  -- (internal use function) only 3 scopes in use
  SELECT CASE lower($1) WHEN 'od' THEN 1 WHEN 'oa' THEN 2 ELSE 3 END;
$f$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION om.scope_count_bylicenseids(
  --

-- FALTA REVER

  -- Count for each scope, and calculate average factors.
  -- Example: SELECT om.scope_count_bylicenseids( om.licget_id('{CC-BY-NC-4, CC-BY-4, CC-BY-NC-ND-4}'::text[]), array[83,14,3] );
  --
  int[],                     -- list of license IDs (repeated or not)
  int[] DEFAULT NULL::int[]  -- counters of correspondent licenses (NULL is "all 1")
  ) RETURNS JSON AS $f$
	WITH lst AS (SELECT unnest($1) as id, CASE WHEN $2 IS NULL THEN 1 ELSE unnest($2) END as n)
		SELECT json_agg(row_to_json(tt)) FROM (
			SELECT  lf.scope, array[
					sum(lf.kx_vec[1][om.scope_idx(lf.scope)]*n),
					sum(lf.kx_vec[2][om.scope_idx(lf.scope)]*n),
					sum(lf.kx_vec[3][om.scope_idx(lf.scope)]*n) ] as degmult_v,
				sum(lst.n)::int as n
			FROM lst LEFT JOIN om.licenses_full lf ON lst.id=lf.lic_id
			GROUP BY 1
		) as tt;
$f$ LANGUAGE sql IMMUTABLE;


CREATE FUNCTION om.family_count_bylicenseids(
  --
  -- Sum counts over license families. Count for each family, and calculate total itens of that family.
  -- FALTA NULL listar as licenças não-encontradas.
  -- Example: SELECT om.family_count_bylicenseids( om.licget_id('{CC-BY3, CC-BY4, CC-BY-NC-ND-3}'::text[]), array[22,45,12] );
  --
  int[],                     -- list of license IDs (repeated or not)
  int[] DEFAULT NULL::int[]  -- list of counters of correspondent license IDs (NULL is "all 1")
  ) RETURNS JSON -- array of objects {fam_id,fam_name,tot,n}
  AS $f$
	WITH lst AS (
	  SELECT id,n[idx] as n
	  FROM unnest($1) WITH ORDINALITY t(id, idx), (
		SELECT CASE WHEN $2 IS NULL THEN array_fill(1, ARRAY[array_length($1,1)]) ELSE $2 END as n
	  ) tt
	) SELECT json_agg(row_to_json(tt)) FROM (
			SELECT  lf.lic_family as fam_id, lf.fam_name, sum(lst.n)::int as tot, count(*) as n
			FROM lst LEFT JOIN om.licenses_full lf ON lst.id=lf.lic_id
			GROUP BY 1,2
		) as tt;
$f$ LANGUAGE sql IMMUTABLE;

CREATE FUNCTION om.family_count_bylicenseids(
  --
  -- Do om.scope_count_bylicenseids(int[]) from JSON array of {name,qt}  or {lic_id,qt} (qt=1 when not exist).
  -- Example-1: SELECT om.family_count_bylicenseids( '[{"name":"CC-by2","qt":32},{"name":"CC-BY-v3","qt":5}]'::JSON );
  -- Example-2: SELECT om.family_count_bylicenseids( '[{"lic_id":22,"qt":32},{"lic_id":23,"name":"CC-BY-v3","qt":23}]'::JSON );
  JSON  -- uniform array of {name,qt} or {lic_id,qt}.
) RETURNS JSON AS $f$
  WITH idqt AS (  SELECT CASE
			WHEN ($1->0->>'lic_id') IS NULL THEN unnest( om.nameqt_to_idqt($1) )
			ELSE json_array_elements($1)
		  END as r
  ) SELECT om.family_count_bylicenseids(  array_agg((r->>'lic_id')::int), array_agg((r->>'qt')::int) )
    FROM idqt;
$f$ LANGUAGE sql IMMUTABLE;



--
-- SPECIFIC FUNCS:END
-- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
-- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---

-- -- -- -- --
-- MANUT VIEWS

CREATE VIEW om.manut1_namelabel_inconsistence AS
 -- checks duplication suspects (corrects renaming lic_name, lic_version or label) by string analysis.
 -- Typical exception: BSD-2-Clause.
	WITH full2 AS (SELECT *,om.licname_format(lic_name) as stdname FROM om.licenses_full)
	SELECT lic_id, lic_name, lic_id_name, stdname FROM full2
	WHERE stdname!=lic_id_name;

CREATE VIEW om.manut2_suspect_repetition AS
  -- check name duplication in a maintainer context, when valid to suppose UNIQUE(maintainer,lic_family,lic_version)
  -- Typical exceptions: CC0-1.0 and CC-PDM-1.0, have same family and same versions but are distinct CC licenses.
  SELECT lic_info->>'maintainer' as maintainer, lic_family, lic_id_version,
	count(*) as n_instances, array_agg(lic_name) as names
  FROM om.licenses WHERE lic_family IS NOT NULL AND lic_info->>'maintainer'>''
  GROUP BY 1,2,3
  HAVING COUNT(*)>1;



-----------------
-----------------
-- COMPLEMENTS
-----------------



-- -- --
-- TRIGGERS


CREATE FUNCTION om.license_families_refresh() RETURNS trigger AS $script$
    --
    -- Cache refresh
    -- NOTE: the kx_vec updates need to check conventions and how many degreeN are defined.
    --
    DECLARE
       J JSONB;
    BEGIN
        IF NEW.fam_info IS NOT NULL THEN
		J = NEW.fam_info;
		NEW.kx_sort=J->>'sort';
		NEW.kx_vec = array[ CASE
			 WHEN J->>'scope'='od' THEN ARRAY[(J->>'degreev1')::int,NULL,NULL]
			 WHEN J->>'scope'='oa' THEN ARRAY[NULL,(J->>'degreev1')::int,NULL]
			 ELSE ARRAY[NULL,NULL,(J->>'degreev1')::int]
			END, CASE
			 WHEN J->>'scope'='od' THEN ARRAY[(J->>'degreev2')::int,NULL,NULL]
			 WHEN J->>'scope'='oa' THEN ARRAY[NULL,(J->>'degreev2')::int,NULL]
			 ELSE ARRAY[NULL,NULL,(J->>'degreev2')::int]
			END, CASE
			 WHEN J->>'scope'='rt' THEN ARRAY[NULL,NULL,(J->>'degreev3')::int]
			 ELSE ARRAY[NULL,(J->>'degreev3')::int,NULL]
			END, CASE
			 WHEN J->>'scope'='od' THEN ARRAY[NEW.kx_sort,NULL,NULL]
			 WHEN J->>'scope'='oa' THEN ARRAY[NULL,NEW.kx_sort,NULL]
			 ELSE ARRAY[NULL, NULL, CASE WHEN J->>'scope'='(err)' THEN NULL ELSE NEW.kx_sort END]
			END
			];
        END IF;
        RETURN NEW;
    END;
$script$ LANGUAGE plpgsql;

CREATE TRIGGER license_families_refresh BEFORE INSERT OR UPDATE ON om.license_families
    FOR EACH ROW EXECUTE PROCEDURE om.license_families_refresh();

-- -- --
-- UPSERTS

CREATE FUNCTION om.licenses_upsert(
   p_label text, p_version text, p_name text, p_family text, p_equiv_name text DEFAULT NULL, p_info JSONB DEFAULT NULL
) RETURNS integer AS $$
DECLARE
  q_fam_id int DEFAULT NULL;
  q_id  int;  -- or bigint?
  q_equiv_id int DEFAULT NULL;
BEGIN
	IF p_equiv_name IS NOT NULL AND trim(p_equiv_name)!='' THEN
		SELECT lic_id INTO q_equiv_id
		FROM om.licenses WHERE  p_equiv_name=lic_name OR (p_equiv_name=lic_id_label||'-'||lic_id_version);
		IF q_equiv_id IS NULL THEN
			RAISE EXCEPTION 'licence equiv-name for % not found (no label-vers or name=%).',p_name,p_equiv_name;
		END IF;
	END IF;

	IF p_family IS NOT NULL AND trim(p_family)!='' THEN
		SELECT fam_id INTO q_fam_id FROM om.license_families WHERE fam_name=p_family;
		IF (q_fam_id is NULL) THEN
			RAISE EXCEPTION 'family % not found.',p_family;
		END IF;
	END IF;

	SELECT lic_id INTO q_id FROM om.licenses WHERE p_name=lic_name;
	IF q_id IS NOT NULL THEN -- UPDATE
		UPDATE om.licenses
		SET  lic_id_label=p_label, lic_id_version=p_version, lic_name=p_name,
		     lic_family=q_fam_id, lic_id_equiv=q_equiv_id, lic_info=p_info, lic_modified=now()
		WHERE lic_id = q_id;
	ELSE -- INSERT
		INSERT INTO om.licenses (lic_id_label, lic_id_version, lic_name, lic_family, lic_id_equiv, lic_info)
		VALUES (p_label, p_version, p_name, q_fam_id, q_equiv_id, p_info)
		RETURNING lic_id INTO q_id;
	END IF;
	RETURN q_id;
END;
$$ LANGUAGE plpgsql;

--------------------------------
--------------------------------
-- STD INSERTS

INSERT INTO om.license_families(fam_name,fam_info) VALUES
  ('(unknowed)', '{"scope":"(err)","sort":-990,"degreev1":null,"degreev2":null,"degreev3":null}'::JSONB)
  ,('(other)',    '{"scope":"(err)","sort":-995,"degreev1":null,"degreev2":null,"degreev3":null}'::JSONB)
  ,('(unassoc)',  '{"scope":"(err)","sort":-999,"degreev1":null,"degreev2":null,"degreev3":null}'::JSONB)
;
SELECT om.licenses_upsert('(unknowed)','','(unknowed or not-checked license)','(unknowed)',NULL,'{"is_ref":2}'::JSONB);
SELECT om.licenses_upsert('(other)','','(other license, can be change with updates)','(other)',NULL,'{"is_ref":0}'::JSONB);

--------------------------------
--------------------------------
--------------------------------

CREATE SCHEMA IF NOT EXISTS lib; -- used in other projects, check if all updated and compatible


-- -- -- --
-- MADLIB (simplified) like functions
-- See http://doc.madlib.net/latest/group__grp__array.html
-- and http://doc.madlib.net/latest/linalg_8sql__in.html

CREATE or replace FUNCTION lib.unfold( m anyarray, idx1 int DEFAULT 1, idx2 int DEFAULT NULL) RETURNS anyarray AS $f$
        -- A kind of unnest, only for handling multidimensional array as an array-of-array.
        -- The idx2 parameter changes the behaviour, is used for (unfolded) slicing.
	WITH item AS (SELECT unnest($1[$2:(CASE WHEN $3 IS NULL THEN $2 ELSE $3 END)]) as x)
	SELECT array_agg(x) FROM item;
$f$ LANGUAGE sql IMMUTABLE;

CREATE or replace FUNCTION lib.array_min(
    v anyarray
) RETURNS anyelement AS $f$
	WITH t AS (SELECT unnest(v) as x)
	SELECT MIN(x) FROM t;
$f$ LANGUAGE sql IMMUTABLE;

CREATE or replace FUNCTION lib.array_max(
    v anyarray
) RETURNS anyelement AS $f$
	WITH t AS (SELECT unnest(v) as x)
	SELECT MAX(x) FROM t;
$f$ LANGUAGE sql IMMUTABLE;

CREATE or replace FUNCTION lib.array_scalar_mult(
    v anyarray, s anyelement
) RETURNS anyarray AS $f$
	WITH t AS (SELECT unnest(v) as x)
	SELECT array_agg(x*s) FROM t;
$f$ LANGUAGE sql IMMUTABLE;

CREATE or replace FUNCTION lib.array_mean(
    v anyarray
) RETURNS float AS $f$
	WITH t AS (SELECT unnest(v) as x)
	SELECT AVG(x)::float FROM t;
$f$ LANGUAGE sql IMMUTABLE;

CREATE or replace FUNCTION lib.array_stddev(
    v anyarray
) RETURNS float AS $f$
	WITH t AS (SELECT unnest(v) as x)
	SELECT stddev_samp(x)::float FROM t;
$f$ LANGUAGE sql IMMUTABLE;

CREATE or replace FUNCTION lib.array_mult(
    v1 anyarray, v2 anyarray
) RETURNS anyarray AS $f$
	WITH ab AS ( -- secure unnest(v1) as a, unnest(v2) as b
		SELECT a, b[idx] as b
		FROM unnest(v1) WITH ORDINALITY t(a, idx), (SELECT v2 as b) tt
	) SELECT array_agg(a*b) FROM ab;
$f$ LANGUAGE sql IMMUTABLE;

CREATE or replace  FUNCTION lib.array_div(
    v1 anyarray, v2 anyarray
) RETURNS anyarray AS $f$
	WITH ab AS ( -- secure unnest(v1) as a, unnest(v2) as b
		SELECT a, b[idx] as b
		FROM unnest(v1) WITH ORDINALITY t(a, idx), (SELECT v2 as b) tt
	) SELECT array_agg(case when b!=0 THEN a/b ELSE NULL END) FROM ab;
$f$ LANGUAGE sql IMMUTABLE;

---
CREATE or replace FUNCTION lib.array_dot(
    v1 anyarray, v2 anyarray
) RETURNS float AS $f$
	WITH t AS (SELECT unnest( lib.array_mult(v1,v2) ) as x)
	SELECT SUM (x)::float FROM t;
$f$ LANGUAGE sql IMMUTABLE;

CREATE or replace FUNCTION lib.norm1(  --vector magnitude (non normalized)
    v anyarray
) RETURNS float AS $f$
	SELECT lib.array_dot(v,v)::float;
$f$ LANGUAGE sql IMMUTABLE;

CREATE or replace FUNCTION lib.norm2(  --vector Euclidian norm.
    v anyarray
) RETURNS float AS $f$
	SELECT SQRT( lib.array_dot(v,v)::float );
$f$ LANGUAGE sql IMMUTABLE;

-- -- --
-- JSON workarounds



CREATE OR REPLACE FUNCTION lib.keyval_aggsum( JSON ) RETURNS JSON AS $f$
	-- Example: select lib.aggsum('{"A":2,"A":3,"B":3}'::json)
	SELECT json_object(array_agg(key),array_agg(qt::text))
	FROM (
		WITH lst AS (
			SELECT key, value::float as qt
			FROM json_each_text($1)
		)
		SELECT  key, sum(qt)::float as qt
		FROM lst
		GROUP BY key
	) tt1
$f$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION lib.array_aggsum( JSON ) RETURNS JSON AS $f$
	-- example: select lib.aggsum('["A","B","B","A","A","A","B"]'::json)
	SELECT json_object(array_agg(jkey),array_agg(qt::text))
	FROM (
		WITH lst AS (
		   SELECT trim(jkey::text,'"') as jkey FROM json_array_elements($1) as jkey
		) SELECT  jkey, count(*) as qt
		  FROM lst
		  GROUP BY 1
	) tt1
$f$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION lib.aggsum( JSON ) RETURNS JSON AS $f$
	-- Aggregates distinct keys by sum of its quantities. Array or key-value object.
DECLARE
  tmp int;
BEGIN
	tmp = json_array_length($1); -- triggs error when not array
	RETURN lib.array_aggsum($1);
EXCEPTION
    WHEN OTHERS THEN RETURN lib.keyval_aggsum($1);
END;
$f$ LANGUAGE plpgsql IMMUTABLE;



-- -- -- --
-- ADM

CREATE TABLE IF NOT EXISTS lib.table_datapackages(
--
-- Describes tables as in resources/schema of OKFN's Tabular Data Packages standard.
-- One for each table.
-- See http://data.okfn.org/doc/tabular-data-package
--
  oid oid not null PRIMARY KEY,  -- use 'schema.tablename'::regclass::oid to insert
  info JSONB,     -- 'path', 'title' and 'schema' of the resource in datapackage.json
  -- schema description valid for json and sql attributes that matches the names
  kx_name varchar(120) -- cache for name when not see json
);

CREATE OR REPLACE FUNCTION lib.to_oid(
--
-- Like to_regclass(rel_name), gets OID from table name, complete-name, or schema-name pair.
-- See exception and "NULL alternatives" at http://stackoverflow.com/a/24089729/287948
--
	text,  text DEFAULT NULL
) RETURNS oid AS $BODY$
  SELECT (CASE WHEN $2 IS NULL THEN $1 ELSE $1||'.'||$2 END)::regclass::oid;
$BODY$ LANGUAGE sql IMMUTABLE;

CREATE OR REPLACE FUNCTION lib.from_oid(oid) RETURNS text AS $$
   SELECT pg_catalog.textin(pg_catalog.regclassout($1));
$$ LANGUAGE SQL;
