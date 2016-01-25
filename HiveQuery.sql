-- preparing data for computing lifetime
CREATE TABLE rcoderie.lifetimeV
  (date STRING, event_type STRING, event_data STRING, country_code STRING, userId STRING, website STRING, category STRING, features STRING, os STRING, os_type STRING, os_version STRING,
  month_no INT, day INT)
  COMMENT 'Table for lifetime'
  PARTITIONED BY(month STRING);
  
  
FROM
(
SELECT *, GET_JSON_OBJECT(event_data, '$.os.type') AS os_type, GET_JSON_OBJECT(event_data, '$.os.ver') AS os_version,
  MONTH(from_unixtime(cast(unix_timestamp(date) AS BIGINT),'yyyy-MM-dd')) AS month_no,
  DAY(from_unixtime(cast(unix_timestamp(date) AS BIGINT),'yyyy-MM-dd')) AS day  
FROM rcoderie.test t
LATERAL VIEW json_tuple(event_data, 'appInstanceUid','location','vertical','features','os') json AS userId, website, category, features, os
WHERE from_unixtime(cast(unix_timestamp(date) AS BIGINT), 'yyyyMM')='201505'
)a
INSERT INTO TABLE rcoderie.lifetimeV PARTITION(month='201505')
       SELECT date, event_type, event_data, country_code, userId, website, category, features, os, os_type, os_version, month_no, day;  
       

SELECT COUNT(*), COUNT(distinct userid) as users, month, os, os_type, os_version, event_type
FROM lifetimeV
GROUP BY month, os, os_type, os_version, event_type;

-- computing lifetime value for May users
CREATE TABLE rcoderie.lifetime AS
SELECT userid, MAX(day) AS last_seen, MIN(day) as first_seen, MAX(day)-MIN(day) AS range
FROM rcoderie.lifetimeV
WHERE month='201505'
GROUP BY userid;

-- train users
CREATE TABLE rcoderie.train AS
SELECT a.userid, event_type, country_code, category, os, os_type, 
  COUNT(*) AS no_events, 
  SUM(valoare) AS active_features, 
  range
FROM
(SELECT *,
  CASE 
    WHEN features='[]' 
    THEN 0 
    ELSE size(split(features,"\,")) 
  END AS valoare
FROM lifetimeV
WHERE month='201505')a
  LEFT JOIN rcoderie.lifetime b
  ON a.userid=b.userid
GROUP BY a.userid, event_type, country_code, category, os, os_type,range;

SELECT COUNT(*) FROM rcoderie.train;

-- sample for regression in R
SELECT a.userid, b.cnt AS no_website,
  SUM(no_events) AS no_events,
  SUM(active_features) AS active_features,
  range
FROM rcoderie.train a
LEFT JOIN (SELECT userid, COUNT(DISTINCT website) AS cnt
           FROM lifetimeV
           GROUP BY userid
          )b
  ON a.userid=b.userid
GROUP BY a.userid, b.cnt, range;

-- summary
SELECT COUNT(DISTINCT userid) AS users, event_type, country_code, COUNT(DISTINCT category) AS no_categories, 
  os, os_type, SUM(no_events) AS no_events, SUM(active_features) AS no_features
FROM rcoderie.train
GROUP BY event_type, country_code, os, os_type;

-- summary avg range per countries, categories
SELECT COUNT(DISTINCT userid) AS users, event_type, country_code, category, 
  os, os_type, SUM(no_events) AS no_events, SUM(active_features) AS no_features, ROUND(AVG(range),2) AS avg_range
FROM rcoderie.train
GROUP BY event_type, country_code, category, os, os_type;
