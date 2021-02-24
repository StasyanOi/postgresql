--------------------------------------------------------------------------------------------------------------------
--CREATE AND DELETE TABLES | SELECT UPDATE INSERT DELETE DATA-------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------

DROP TABLE IF EXISTS weather;
DROP TABLE IF EXISTS cities;

CREATE TABLE cities
(
    name     varchar(80) primary key,
    location point
);

CREATE TABLE weather
(
    city    varchar(80) references cities (name),
    temp_lo int,
    temp_hi int,
    prcp    real,
    date    date
);

-- INSERT
INSERT INTO cities (name, location)
VALUES ('Moscow', '(123.1, 321.4)');
INSERT INTO cities (name, location)
VALUES ('Saint-Petersburg', '(223.1, 687.4)');
INSERT INTO cities (name, location)
VALUES ('Novgorod', '(234.1, 881.4)');
INSERT INTO cities (name, location)
VALUES ('Samara', '(777.1, 111.4)');

INSERT INTO weather (city, temp_lo, temp_hi, prcp, date)
VALUES ('Moscow', 0, 30, 0.6, '2020-12-28');
INSERT INTO weather (city, temp_lo, temp_hi, prcp, date)
VALUES ('Saint-Petersburg', -10, 20, 0.7, '2020-12-29');
INSERT INTO weather (city, temp_lo, temp_hi, prcp, date)
VALUES ('Saint-Petersburg', -9, 21, 0.66, '2020-11-29');
INSERT INTO weather (city, temp_hi, prcp, date)
VALUES ('Novgorod', 25, 0.65, '2020-12-30');
INSERT INTO weather (city, temp_lo, temp_hi, prcp, date)
VALUES ('Petrozavodsk', -7, 22, 0.68, '2020-12-31');

-- UPDATE
UPDATE weather
SET temp_lo = temp_lo - 1,
    temp_hi = temp_hi + 1
WHERE city = 'Saint-Petersburg';

UPDATE weather
SET temp_hi = 20
WHERE city = 'Saint-Petersburg'
  and temp_lo = -11;

-- DELETE
DELETE
FROM weather
where city = 'Saint-Petersburg'
  and temp_hi = 22;

-- GET (SELECT)
SELECT *
from cities;

SELECT *
from weather;
SELECT name, location
from cities;

SELECT city, temp_lo, temp_hi, prcp, date
from weather;
SELECT name, location
from cities
where name = 'Saint-Petersburg';

SELECT city, temp_lo, temp_hi, prcp, date
from weather
where city = 'Saint-Petersburg';

SELECT city, temp_lo, temp_hi, prcp, date
from weather
where temp_hi < 30
order by temp_lo desc;

SELECT *
from weather,
     cities;

SELECT *
from weather,
     cities
where name = city;

--------------------------------------------------------------------------------------------------------------------------
--JOINING TABLES----------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------
SELECT city, temp_lo as low, temp_hi as high, prcp as precipitation, date, name, location
from weather
         inner join
     cities
     on (city = name);

SELECT *
from weather
         left join
     cities
     on (city = name);

SELECT *
from weather
         left outer join
     cities
     on (city = name);

SELECT *
from weather
         right join
     cities
     on (city = name);

SELECT *
from weather
         right outer join
     cities
     on (city = name);

SELECT *
from weather
         full join
     cities
     on (city = name);

SELECT *
from weather
         full outer join
     cities
     on (city = name);


-----------------------------------------------------------------------------------------------------------------------------
--AGGREGATION | GROUPING BY | WINDOWING (GROUP ROWS AND FOR GROUP BY - COLLAPSE THEM)------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-- Aggregate functions (GROUP BY | HAVING) GROUP BY - groups rows and collapses them into 1 (must have an aggregate function)
-- WHERE - for row selection, HAVING - for group selection after GROUP BY

SELECT count(*)
from cities;

SELECT *
from weather
where temp_hi = (SELECT max(temp_hi) from weather);

SELECT *
from weather
where temp_lo = (SELECT min(temp_lo) from weather);

SELECT avg(temp_hi)
from weather;

SELECT sum(temp_lo)
from weather;

SELECT city, max(temp_lo)
FROM weather
GROUP BY city;

SELECT city, max(temp_lo)
FROM weather
GROUP BY city
HAVING max(temp_lo) < 0;

SELECT city, max(temp_lo)
FROM weather
WHERE city LIKE 'S%'
GROUP BY city
HAVING max(temp_lo) < 0;

-- WINDOWED FUNCTIONS  - LIKE GROUP BY BUT WITHOUT COLLAPSING ROWS

SELECT city, temp_lo, temp_hi, prcp, date, avg(temp_lo) OVER (PARTITION BY city)
FROM weather;

SELECT city, temp_hi, avg(temp_hi) OVER (PARTITION BY city ORDER BY temp_hi DESC ) as avrage_high
from weather;

SELECT city, temp_hi, avg(temp_hi) OVER w
FROM weather WINDOW w AS (PARTITION BY city ORDER BY temp_hi DESC);

-----------------------------------------------------------------------------------------------------------------------------
--CREATE VIEWS (QUERY ALIASES)---------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------

CREATE VIEW city_weather as
SELECT city, temp_lo, temp_hi, prcp, date, name, location
from weather,
     cities
where city = name;

DROP VIEW city_weather;

SELECT *
FROM city_weather;

SELECT *
FROM cities;
SELECT *
FROM weather;

-----------------------------------------------------------------------------------------------------------------------------
--TRANSACTIONS (POSTGRESQL HAS 3 ISOLATION LVLS (NO READ UNCOMMITTED))---------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------

INSERT INTO cities (name, location)
VALUES ('test', '(1.0, 1.0)');
BEGIN;
INSERT INTO weather (city, temp_lo, temp_hi, prcp, date)
VALUES ('test', 1, 1, 1.0, '1111-11-11');
savepoint test_save;
INSERT INTO weather (city, temp_lo, temp_hi, prcp, date)
VALUES ('test', 1, 1, 1.0, '11111-11-11');
ROLLBACK TO test_save;
ROLLBACK;
COMMIT;

------------
-- PHENOMENA
------------
-- DIRTY READ (2 TRANSACTIONS (READ, WRITE), READ READS UNCOMMITTED WRITE)
-- NON REPEATABLE READ (IN A READ TRANSACTION TWICE A ROW IS READ BUT IT HAS DIFFERENT DATA (READS COMMITTED UPDATE FROM A CONCURRENT TRANSACTION))
-- PHANTOM READ (IN A READ TRANSACTION TWICE A SET OF ROWS IS READ BUT THEY ARE DIFFERENT IN NUMBER (READS COMMITTED INSERT|DELETE FROM A CONCURRENT TRANSACTION))

------------
-- ISOLATION LEVELS
------------
-- READ UNCOMMITTED (PHANTOM READS, NON REPEATABLE READS AND DIRTY READS POSSIBLE) (IS READ COMMITTED IN POSTGRESQL)
-- READ COMMITTED (PHANTOM READS AND NON REPEATABLE READ POSSIBLE) (DEFAULT)
-- REPEATABLE READ (PHANTOM READS POSSIBLE)                                        (PHANTOM READS NOT POSSIBLE IN POSTGRESQL)
-- SERIALIZABLE (NO PHENOMENA)

CREATE USER qwerty WITH PASSWORD 'qwerty';
GRANT ALL ON SCHEMA public TO qwerty;
SELECT current_user;

BEGIN ISOLATION LEVEL REPEATABLE READ;
    SELECT * FROM test_isolation;
    SELECT * FROM test_isolation;
COMMIT;

BEGIN ISOLATION LEVEL READ COMMITTED ; -- (READ UNCOMMITTED IS THE SAME)
    SELECT * FROM test_isolation;
    SELECT * FROM test_isolation;
COMMIT;

BEGIN ISOLATION LEVEL SERIALIZABLE ;
    SELECT * FROM test_isolation;
    SELECT * FROM test_isolation;
COMMIT;

-----------------------------------------------------------------------------------------------------------------------------
--INHERITANCE----------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
DROP TABLE IF EXISTS capitals;
DROP TABLE IF EXISTS non_capitals;
DROP VIEW IF EXISTS new_cities;
CREATE TABLE non_capitals
(
    name       text,
    population real,
    elevation  int
);

CREATE TABLE capitals
(
    state char(2)
) INHERITS (non_capitals);

INSERT INTO capitals (name, population, elevation, state)
VALUES ('MOSCOW', 25.0, 200, '--');
INSERT INTO non_capitals (name, population, elevation)
VALUES ('SPB', 10.0, 100);
CREATE VIEW new_cities AS
SELECT name, population, elevation
FROM non_capitals
UNION
SELECT name, population, elevation
FROM capitals;
SELECT name, population, elevation
FROM new_cities
WHERE name = 'SPB';
SELECT name, population, elevation
FROM non_capitals;

SELECT *
FROM new_cities;

-----------------------------------------------------------------------------------------------------------------------------
-- CONSTRAINTS ------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
CREATE TABLE TEST_CONST
(
    name     varchar(80) primary key
);
-- NOT NULL
-- PK
-- CHECK (BEFORE INSERT)
-- UNIQUE
-- FK (REFERENCES)
-- GENERATED (IS BASED ON ANOTHER COLUMN)
-- DEFAULT
--DOLLAR SYNTAX
CREATE TABLE pk_index_test (
    id int primary key,
    val varchar(255)
);
DROP TABLE no_pk_index_test;
CREATE TABLE no_pk_index_test (
    id int,
    val varchar(255)
);

INSERT INTO pk_index_test (id, val)
SELECT g.id, 'test' FROM generate_series(1, 3000000) AS g (id);
INSERT INTO no_pk_index_test (id, val)
SELECT g.id, 'test' FROM generate_series(1, 3000000) AS g (id);
EXPLAIN ANALYZE SELECT * FROM pk_index_test WHERE id = 1000000;
EXPLAIN ANALYZE SELECT * FROM no_pk_index_test WHERE id = 1000000;
COMMIT;

CREATE TABLE CONSTRAINTS
(
    test_s varchar(80),
    test_col varchar(80) not null primary key check ( test_col > 0 ) unique references TEST_CONST (name) GENERATED ALWAYS AS (test_s) STORED default $$qwe$$
);

-----------------------------------------------------------------------------------------------------------------------------
-- SYSTEM COLUMNS (ALL TABLES HAVE THEM) ------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------

SELECT TABLEOID, XMAX, XMIN, CMAX, CMIN, CTID
from weather;

-----------------------------------------------------------------------------------------------------------------------------
-- MODIFYING TABLES ---------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
CREATE TABLE test_alter ();
ALTER TABLE test_alter ADD COLUMN id int;
INSERT INTO test_alter (id) VALUES (11);
INSERT INTO test_alter (id) VALUES (12);
SELECT * FROM test_alter;
ALTER TABLE test_alter ADD COLUMN val varchar(80);
SELECT * FROM test_alter;
ALTER TABLE test_alter DROP COLUMN val;
ALTER TABLE test_alter ADD CONSTRAINT unique_val unique (val);
ALTER TABLE test_alter ADD CONSTRAINT foreign_val foreign key (val) references cities(name);
SELECT * FROM tests;
ALTER TABLE test_alter DROP CONSTRAINT foreign_val;
ALTER TABLE test_alter ALTER COLUMN val SET DEFAULT -1;
ALTER TABLE test_alter ALTER COLUMN val DROP DEFAULT;
ALTER TABLE test_alter ALTER COLUMN val TYPE real; -- USING (for not implicit conversion)
ALTER TABLE test_alter RENAME COLUMN val TO val_new;
ALTER TABLE test_alter RENAME TO tests;


-----------------------------------------------------------------------------------------------------------------------------
--USER CREATION AND PRIVILEGES---------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
create user qwerty with password 'test';
GRANT ALL ON SCHEMA public TO qwerty;
GRANT ALL ON TABLE weather TO qwerty;
GRANT ALL ON DATABASE postgres TO qwerty;
GRANT SELECT ON weather TO qwerty;
GRANT DELETE ON weather TO qwerty;
GRANT INSERT ON weather TO qwerty;
REVOKE ALL ON TABLE weather FROM qwerty;
REVOKE ALL ON SCHEMA public FROM qwerty;
REVOKE ALL ON DATABASE test FROM qwerty;
select * from pg_roles;

-- Row security policy
ALTER TABLE weather ENABLE ROW LEVEL SECURITY;
ALTER TABLE weather DISABLE ROW LEVEL SECURITY;



-----------------------------------------------------------------------------------------------------------------------------
--DATABASE AND SCHEMA ---------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-- DATABASES (has schemas)
CREATE DATABASE test;
DROP DATABASE test;

-- SCHEMAS (has tables,functions)
CREATE SCHEMA test;
CREATE SCHEMA test AUTHORIZATION qwerty;
GRANT ALL ON TABLE weather TO qwerty;
GRANT ALL ON SCHEMA test TO qwerty;
GRANT ALL ON DATABASE postgres TO qwerty;
REVOKE ALL ON SCHEMA test FROM qwerty;
REVOKE ALL ON DATABASE postgres FROM qwerty;
REVOKE ALL ON TABLE weather FROM qwerty;
DROP SCHEMA test;
DROP SCHEMA test CASCADE;

SHOW search_path;
SET SEARCH_PATH TO public, test; -- default table search schemas

CREATE TABLE test.new ();
ALTER TABLE test.new ADD COLUMN id int primary key;

CREATE TABLE test.LOL();
REVOKE ALL ON SCHEMA test FROM qwerty;
DROP TABLE test.LOL;

-----------------------------------------------------------------------------------------------------------------------------
--FUNCTIONS AND OPERATORS---------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-- Comparison
select 3 BETWEEN 1 AND 4;
select 3 BETWEEN SYMMETRIC 1 AND 4;
select 5 = 4 + 1;
-- Math
select abs(-123);
-- String
select 'qwe' || 'qwe'; -- 'qweqwe'
select upper('qwe'); -- 'qweqwe'
select lower('qwe'); -- 'qweqwe'
select substr('qwe', 2 ,3); -- 'we'
select length('eee'); -- 3
-- Binary strings
-- Bit strings

------------------------------------------------------------------------------------------------------------------
--PATTERN MATCHING---------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
SELECT 'TTT' LIKE 'T%';
SELECT 'TTT' LIKE 'T__';
SELECT 'TTT' NOT LIKE 'S%';

SELECT 'TTT' SIMILAR TO 'T*';
SELECT 'TTT' SIMILAR TO 'T{3}';
SELECT 'TTT' NOT SIMILAR TO 'S*';

SELECT regexp_matches('asdTESTsd', '^[a-z]*TEST[a-z]*$');

-----------------------------------------------------------------------------------------------------------------------------
--INDEXES--------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
CREATE TABLE indexes_test_table (
    id int primary key not null,
    val1 varchar(80),
    val2 varchar(80),
    val3 varchar(80),
    val4 varchar(80),
    val5 varchar(80),
    val6 varchar(80),
    val7 tsvector
);

DROP TABLE indexes_test_table;

INSERT INTO indexes_test_table (id, val1, val2, val3, val4, val5, val6)
``
-- TYPE CASTING EXAMPLE
SELECT g.id, cast((g.id + g.id) as varchar), 'test', 'test', 'test', 'test', 'test' FROM generate_series(1, 3000000) AS g (id) ;

EXPLAIN DELETE FROM indexes_test_table WHERE id = 2444442;

EXPLAIN ANALYZE SELECT * FROM indexes_test_table;
EXPLAIN SELECT * FROM indexes_test_table WHERE id = 2432567;

-- INDEX TYPES

-- B-TREE (DEFAULT) (REQUIRES SORTING) (FOR COMPARISON OPERATIONS) (POSSIBLE MULTIKEY) (UNIQUE ENFORCEMENT ON TABLE)
CREATE INDEX test_btree ON indexes_test_table(id);
CREATE INDEX test_btree ON indexes_test_table(id DESC NULLS LAST);
CREATE INDEX test_btree ON indexes_test_table(id ASC NULLS FIRST);
CREATE UNIQUE INDEX test_btree ON indexes_test_table(id, val1, val2);
CREATE INDEX test_btree ON indexes_test_table(id, val1);
--PARTIAL INDEX OVER VALUES OF id,val1 WHERE id IS BIGGER THAN 1 000 000.
CREATE INDEX test_btree ON indexes_test_table(id, val1) WHERE id > 1000000;
CREATE INDEX test_btree ON indexes_test_table USING btree (id);
DROP INDEX test_btree;

-- HASH (For only =) (SINGLE KEY) (HASH MAP)
CREATE INDEX test_hash ON indexes_test_table USING hash (id) ;
DROP INDEX test_hash;

-- NEED OPERATOR CLASSES
-- GIST |GENERALIZED SEARCH TREE| (FULL TEXT SEARCH BY CONTENT for types tsvector and tsquery) (POSSIBLE MULTIKEY)
CREATE INDEX test_gist ON indexes_test_table USING gist (id);
DROP INDEX test_gist;
-- GIN |GENERALIZED INVERTED INDEX| (POSSIBLE MULTIKEY)
CREATE INDEX test_gin ON indexes_test_table USING gin (id);
DROP INDEX test_gin;



-----------------------------------------------------------------------------------------------------------------------------
--SEQUENCES--------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------

CREATE SEQUENCE test_seq START 10 INCREMENT -1 CYCLE MINVALUE 1 MAXVALUE 100;
ALTER SEQUENCE test_seq START 1;
DROP SEQUENCE test_seq CASCADE ;

CREATE TABLE test_table_for_seq (
    id int primary key default nextval('test_seq'),
    val varchar(80)
);
DROP TABLE test_table_for_seq;
CREATE TABLE test_seq_serial (
    id serial primary key,
    val varchar(80)
);
INSERT INTO test_seq_serial (val) VALUES ('test');
DROP TABLE test_seq_serial;

INSERT INTO test_table_for_seq (val) VALUES ('QWERTY');
INSERT INTO test_table_for_seq (val) VALUES ('QWERTY1');
INSERT INTO test_table_for_seq (val) VALUES ('QWERTY2');
INSERT INTO test_table_for_seq (val) VALUES ('QWERTY');
INSERT INTO test_table_for_seq (val) VALUES ('QWERTY1');
INSERT INTO test_table_for_seq (val) VALUES ('QWERTY2');
INSERT INTO test_table_for_seq (val) VALUES ('QWERTY');
INSERT INTO test_table_for_seq (val) VALUES ('QWERTY1');
INSERT INTO test_table_for_seq (val) VALUES ('QWERTY2');
INSERT INTO test_table_for_seq (val) VALUES ('QWERTY');
INSERT INTO test_table_for_seq (val) VALUES ('QWERTY1');
INSERT INTO test_table_for_seq (val) VALUES ('QWERTY2');

SELECT * FROM test_table_for_seq;

-----------------------------------------------------------------------------------------------------------------------------
--EXPLAIN ANALYZE------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-- POSTGRESQL CREATES A QUERY PLAN (NODE TREE) USING A PLANNER FOR EACH QUERY IN THE POSTGRES BACKEND PROCESS.
CREATE TABLE explain_test (
    id int primary key,
    val varchar(255)
);

CREATE TABLE analyze_test (
   id int primary key,
   val varchar(255)
);

INSERT INTO explain_test (id, val)
SELECT g.id, 'test' FROM generate_series(1, 3000000) AS g (id);
INSERT INTO analyze_test (id, val)
SELECT g.id, 'test' FROM generate_series(1, 3000000) AS g (id);
COMMIT;

-- USE EXPLAIN TO SEE THE QUERY PLAN (NODE TYPE (cost=start-up time (disk page(8k) fetches)..total time(diskspace fetches) rows=rows_operated_on_number width=row_byte_width))
EXPLAIN SELECT * FROM explain_test;
EXPLAIN SELECT * FROM explain_test, analyze_test WHERE analyze_test.id = explain_test.id;
-- USE EXPLAIN ANALYZE TO SEE ACTUAL QUERY EXECUTION INFORMATION (NODE TYPE (cost=start-up time (disk page(8k) fetches)..total time(diskspace fetches) rows=rows_operated_on_number width=row_byte_width))
EXPLAIN ANALYZE SELECT * FROM explain_test, analyze_test WHERE analyze_test.id = explain_test.id;

-- THE PLANNER USES pg_class, pg_statistics TABLE TO GET INFO ABOUT THE DATABASE FOR ITSELF AND PLAN.
SELECT * FROM pg_class; -- (info on table page number)
SELECT * FROM pg_statistic;

-----------------------------------------------------------------------------------------------------------------------------
--EXTENSIONS------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-- TO ADD FUNCTIONALITY EXTENSIONS TO POSTGRES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp"; -- uuid generation for postgres (add library of functions or routines)
DROP EXTENSION IF EXISTS "uuid-ossp";
-----------------------------------------------------------------------------------------------------------------------------
--FUNCTIONS------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------------------------------------
-- CREATING CUSTOM FUNCTIONS

CREATE OR REPLACE FUNCTION test_func(int) RETURNS int AS 'select $1' LANGUAGE sql;
CREATE OR REPLACE FUNCTION test_func_concat(text, text) RETURNS text AS 'select $1 || $2' LANGUAGE sql;
SELECT test_func(1) as result;
SELECT test_func_concat('Hello', 'World') as result;

DROP FUNCTION test_func(int);
DROP FUNCTION test_func_concat(text, text);