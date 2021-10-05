/*
Dataset obtained from https://www.kaggle.com/rohanrao/formula-1-world-championship-1950-2020
*/

-- Let's actually pay attention to the data we have and get an average lap time for each driver (per race) by averaging the 
-- integer millisecond values and converting the type to time
-- REFERENCES: https://www.w3schools.com/sqL/func_sqlserver_dateadd.asp, 
-- https://www.sqlservercentral.com/forums/topic/converting-milliseconds
SELECT l.raceId, l.driverId, CONVERT(time, DATEADD(ms, AVG(l.milliseconds), 0)) as average_lap_time, 
AVG(l.milliseconds) as 'average_lap_time (ms)', COUNT(*) as total_laps_completed
FROM formula_one..lap_times as l
GROUP BY l.raceId, l.driverId
ORDER BY l.raceId, average_lap_time DESC;


-- Let's try to combine everything
-- REFERENCE FOR TABLEAU WOES: https://onenumber.biz/blog-1/2019/10/10/how-to-handle-milliseconds-in-tableau
SELECT races.raceId, races.name as race_name, results.driverId, 
CONCAT(drivers.forename, ' ', drivers.surname) as driver_name, results.number as driver_number, 
results.position, av.average_lap_time, av.average_lap_time_ms,
TRY_CONVERT(time, CONCAT('00:', results.fastestLapTime)) as fastest_lap_time, 
--results.fastestLapTime as fastest_lap_time, 
av.total_laps_completed, constructors.name as team_name
FROM formula_one.dbo.results as results 
	JOIN formula_one.dbo.races as races
		ON results.raceId = races.raceId JOIN formula_one..constructors as constructors
		ON results.constructorId = constructors.constructorId JOIN formula_one..drivers as drivers
		ON results.driverId = drivers.driverId JOIN (
			SELECT l.raceId, l.driverId, CONVERT(time, DATEADD(ms, AVG(l.milliseconds), 0))
			as average_lap_time, AVG(l.milliseconds) as average_lap_time_ms,COUNT(*) as total_laps_completed
			FROM formula_one..lap_times as l
			GROUP BY l.raceId, l.driverId
		) as av ON av.raceId = results.raceId AND results.driverId = av.driverId
WHERE races.year = 2021 AND races.raceId=1057
ORDER BY results.raceId, av.average_lap_time;

-- Let's try to get the average finishing position for drivers
SELECT r.driverId, AVG(CAST(r.positionOrder AS FLOAT)) as average_race_result FROM formula_one..results as r
WHERE r.raceId >=1052
GROUP BY r.driverId;

-- Azerbaijan GP 2021: The interesting thing about this one is because of the red flag after Verstappen's crash near the end.
-- This affects the lap time, which seems to include the time spent when the race was stopped into the calculation. This
-- creates outliers because Verstappen's race was ended early, so his average lap time is not affected by the stopped session
/*
SELECT * FROM formula_one..lap_times
WHERE raceId=1057 AND driverId=1;
*/

-- This one's interesting because we can try and determine whether the driver got a DNF
-- Not sure where to go with this one. Is a DNS or DQ counted as a DNF? Is there a better term to use (e.g. Leclerc Monaco 2021)?
-- Reference link: https://stackoverflow.com/questions/5435786/aggregate-function-checking-if-contains
SELECT r.driverId, MIN(CAST(r.positionOrder as INT)) as best_result, MAX(CAST(r.positionOrder as INT)) as worst_result,
MAX(
	CASE
		WHEN r.position = '\N' THEN 1
		ELSE 0
	END
) AS DNF
FROM formula_one.dbo.results as r
WHERE raceId >=1052
GROUP BY r.driverId
ORDER BY /*best_result, */r.driverId;

-- Checking for null values for race position in the results table
-- Seems to correspond to drivers not finishing the race
SELECT *
FROM formula_one.dbo.results as r
WHERE r.position = '\N'
ORDER BY r.driverId;

-- Looking at McLaren's development during the F1 Hybrid Era (2014 - Present)
SELECT * FROM formula_one.dbo.results as re WHERE constructorId = 1 AND raceId >=900 ORDER BY CAST(raceId as INT);

SELECT * FROM formula_one.dbo.constructors as c WHERE constructorRef LIKE '%mclaren%';

SELECT * FROM formula_one.dbo.constructor_results as cr WHERE constructorId = 1 AND raceId >= 900
ORDER BY raceId;

SELECT * FROM formula_one.dbo.constructor_standings as cs WHERE constructorId = 1 AND raceId >= 900
ORDER BY raceId;

SELECT * FROM formula_one.dbo.lap_times as l WHERE raceId >= 900
ORDER BY l.raceId;

SELECT * FROM formula_one.dbo.races as ra WHERE year >= 2014 ORDER BY CAST(raceId as INT);

-- McLaren average race results
SELECT ra.year, AVG(CAST(re.positionOrder AS FLOAT)) as avg_race_result, AVG(CAST(re.points AS FLOAT)) as avg_points_scored
FROM formula_one.dbo.races as ra JOIN formula_one.dbo.results as re
ON ra.raceId = re.raceId
WHERE ra.year >= 2014 AND constructorId = 1
GROUP BY ra.year
ORDER BY ra.year;

-- McLaren race results in the hybrid era (2014 - Present)
SELECT ra.year, re.raceId, re.driverId, re.positionOrder as race_result, re.points
FROM formula_one.dbo.results as re JOIN formula_one.dbo.races as ra
ON re.raceId = ra.raceId
WHERE ra.year >= 2014 AND constructorId = 1;

-- Last race with results for each year
SELECT ra.year, ra.raceId, ra.name, ra.date AS last_race_date, co.constructorId, co.position as constructor_standing
FROM formula_one.dbo.races as ra JOIN formula_one.dbo.constructor_standings as co
ON ra.raceId = co.raceId
WHERE co.constructorId = 1 AND ra.date in (
	SELECT MAX(ra2.date) 
	FROM formula_one.dbo.races as ra2 JOIN formula_one.dbo.results as re
	ON ra2.raceId = re.raceId
	WHERE ra2.year >= 2014
	GROUP BY ra2.year
)

-- Number of McLaren podium results
-- An absolute disaster of a query this is
-- Link for reference: https://www.codeproject.com/Questions/5274830/How-to-display-result-when-countequals0-for-SQL-in
SELECT listYears.year, COUNT(numPodium.raceId) as number_of_podiums
FROM
(
	SELECT DISTINCT ra1.year
	FROM formula_one.dbo.races as ra1 
	WHERE ra1.year >= 2014
) as listYears
LEFT JOIN
(
	SELECT ra2.year, re.raceId--COUNT(re.raceId)
	FROM formula_one.dbo.results as re RIGHT JOIN formula_one.dbo.races as ra2
	ON re.raceId = ra2.raceId
	WHERE ra2.year >= 2014 AND constructorId = 1 AND CAST(re.positionOrder as INT) <= 3
	--GROUP BY ra2.year
) as numPodium
ON listYears.year = numPodium.year
GROUP BY listYears.year

-- Average lap time, total
SELECT l.raceId,  CONVERT(time, DATEADD(ms, AVG(CAST(l.milliseconds as float)), 0)) as average_lap_time,
AVG(CAST(l.milliseconds as float)) as 'average_lap_time (ms)'
FROM formula_one..lap_times as l JOIN formula_one..results as r
ON l.raceId = r.raceId JOIN formula_one..races as ra
ON l.raceId = ra.raceId AND r.raceId = ra.raceId
WHERE ra.year >= 2014
GROUP BY l.raceId
ORDER BY l.raceId, average_lap_time DESC;

-- Average lap time for McLaren (2014 - 2021) for real
SELECT l.raceId, r.constructorId, CONVERT(time, DATEADD(ms, AVG(CAST(l.milliseconds as float)), 0)) as mclaren_average_lap_time,
AVG(CAST(l.milliseconds AS decimal)) as mclaren_average_lap_time_ms
FROM formula_one..lap_times as l JOIN formula_one..results as r
ON l.raceId = r.raceId AND r.driverId = l.driverId
--AND r.constructorId = 1
--WHERE l.raceId = 900 AND r.constructorId = 1
JOIN formula_one..races as ra
ON l.raceId = ra.raceId AND r.raceId = ra.raceId
--AND r.constructorId = 1
WHERE ra.year >= 2014 AND constructorId = 1
GROUP BY l.raceId, r.constructorId
ORDER BY l.raceId

-- Checking McLaren Results just in case
SELECT * FROM formula_one..lap_times as l join formula_one..results as r
ON l.raceId = r.raceId AND r.driverId = l.driverId
WHERE r.constructorId = 1 AND r.raceId = 1060;

SELECT * FROM formula_one..races as r JOIN formula_one..results as re
ON r.raceId = re.raceId
WHERE r.year >= 2014;

-- Position changes according to value for each lap - Worth looking into
SELECT raceId, driverId, COUNT(DISTINCT position) AS position_changes
FROM formula_one.dbo.results
WHERE raceId >= 900
GROUP BY raceId, driverId
ORDER BY raceId;

-- Last time McLaren won a race
SELECT TOP 1 re.raceId, ra.year, ra.name, re.driverId, re.positionOrder
FROM formula_one.dbo.results as re
JOIN formula_one.dbo.races as ra
ON re.raceId = ra.raceId
WHERE re.constructorId = 1 AND re.positionOrder = '1'
ORDER BY raceId DESC;

-- Last race each year in the hybrid era - displays year, raceId, constructor standings/points/wins, date
SELECT r.year, r.raceId, c.position, c.points, c.wins, r.date
FROM formula_one.dbo.constructor_standings as c
JOIN formula_one.dbo.races as r ON c.raceId = r.raceId
WHERE r.raceId IN (
	SELECT MAX(CAST(r2.raceId as INT)) as last_race
	FROM formula_one.dbo.races as r2 JOIN
	formula_one.dbo.results as re
	ON r2.raceId = re.raceId
	WHERE r2.year >= 2014
	GROUP BY r2.year
)
AND r.year >= 2014 AND c.constructorId = 1
ORDER BY CAST(r.raceId as INT);