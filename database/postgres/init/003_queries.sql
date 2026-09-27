-- 003_queries.sql
-- Lecture 1 workload queries for MobilityTicketing

-- Reproducible example inputs. Change these values to exercise other routes,
-- timestamps or service dates.
\set route_id 'LINE-M2'
\set after_timestamp '2026-04-29 07:30:00+00'
\set service_date '2026-04-29'

-- 1. Next 20 scheduled trips for a route after a supplied timestamp
SELECT
    t.id,
    t.route_id,
    t.service_date,
    t.scheduled_departure_utc,
    t.status
FROM trips t
WHERE t.route_id = :'route_id'
  AND t.scheduled_departure_utc > :'after_timestamp'::timestamptz
  AND t.status = 'Scheduled'
ORDER BY t.scheduled_departure_utc
LIMIT 20;


-- 2. Ordered stops for one route
SELECT
    rs.stop_sequence,
    s.id AS stop_id,
    s.name
FROM route_stops rs
JOIN stops s
    ON s.id = rs.stop_id
WHERE rs.route_id = :'route_id'
ORDER BY rs.stop_sequence;


-- 3. All routes with number of scheduled trips on a supplied service date,
--    including routes with zero trips
SELECT
    r.id,
    r.short_name,
    COUNT(t.id) AS scheduled_trip_count
FROM routes r
LEFT JOIN trips t
    ON t.route_id = r.id
    AND t.service_date = :'service_date'::date
    AND t.status = 'Scheduled'
GROUP BY
    r.id,
    r.short_name
ORDER BY
    r.short_name;
