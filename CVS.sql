CREATE DATABASE CVS;

USE CVS;

CREATE TABLE departments (
department_id INT PRIMARY KEY,
department_name VARCHAR(100) NOT NULL
);

SELECT * FROM departments;

CREATE TABLE locations (
location_id INT PRIMARY KEY,
location_name VARCHAR(100) NOT NULL
);

SELECT * FROM locations;

CREATE TABLE patients (
  patient_id INT AUTO_INCREMENT PRIMARY KEY,
  check_in_time TIMESTAMP NOT NULL,
  check_out_time TIMESTAMP NOT NULL,
  department_id INT NOT NULL,
  location_id INT NOT NULL,
  CONSTRAINT chk_times CHECK (check_out_time >= check_in_time),
  CONSTRAINT fk_dept FOREIGN KEY (department_id) REFERENCES departments(department_id),
  CONSTRAINT fk_loc FOREIGN KEY (location_id) REFERENCES locations(location_id)
) ENGINE=InnoDB;

/* SELECT  																			 -- SELECT converts and displays +01. ; MySQL doesn’t store the +01:00 suffix, it’s only shown at query time.
  patient_id,
  CONCAT(
    DATE_FORMAT(CONVERT_TZ(check_in_time, '+00:00', '+01:00'), '%Y-%m-%d %H:%i:%s'),
    LEFT(DATE_FORMAT(CONVERT_TZ(check_in_time, '+00:00', '+01:00'), '%z'), 3)
  ) AS check_in_time_plus01,
  CONCAT(
    DATE_FORMAT(CONVERT_TZ(check_out_time, '+00:00', '+01:00'), '%Y-%m-%d %H:%i:%s'),
    LEFT(DATE_FORMAT(CONVERT_TZ(check_out_time, '+00:00', '+01:00'), '%z'), 3)
  ) AS check_out_time_plus01
FROM patients;

*/


SELECT * FROM patients;


WITH wait_times AS (
  SELECT
    patient_id,
    location_id,
    department_id,
    ROUND(TIMESTAMPDIFF(SECOND, check_in_time, check_out_time)/60, 2) AS wait_minutes
  FROM patients
  WHERE check_in_time IS NOT NULL
    AND check_out_time IS NOT NULL
)
SELECT * FROM wait_times;

WITH wait_times AS (
  SELECT
    patient_id,
    location_id,
    department_id,
    ROUND(TIMESTAMPDIFF(SECOND, check_in_time, check_out_time)/60, 2) AS wait_minutes
  FROM patients
  WHERE check_in_time IS NOT NULL 
    AND check_out_time IS NOT NULL
),
location_avg_waits AS (
  SELECT
    l.location_name,
    ROUND(AVG(w.wait_minutes), 2) AS avg_wait_time_minutes
  FROM wait_times w
  JOIN locations l ON w.location_id = l.location_id
  GROUP BY l.location_name
)
SELECT *
FROM location_avg_waits
ORDER BY avg_wait_time_minutes DESC;

WITH wait_times AS (
  SELECT
    patient_id,
    location_id,
    TIMESTAMPDIFF(SECOND, check_in_time, check_out_time) / 60 AS wait_minutes
  FROM patients
  WHERE check_in_time IS NOT NULL 
    AND check_out_time IS NOT NULL
)
SELECT
  l.location_name,
  ROUND(AVG(w.wait_minutes), 2) AS avg_wait_time_minutes
FROM wait_times w
JOIN locations l ON w.location_id = l.location_id
GROUP BY l.location_name
HAVING AVG(w.wait_minutes) > 120
ORDER BY avg_wait_time_minutes DESC;

WITH wait_times AS (
  SELECT
    patient_id,
    department_id,
    TIMESTAMPDIFF(SECOND, check_in_time, check_out_time) / 60 AS wait_minutes
  FROM patients
  WHERE check_in_time IS NOT NULL 
    AND check_out_time IS NOT NULL
)
SELECT
  d.department_name,
  ROUND(AVG(w.wait_minutes), 2) AS avg_wait_time_minutes
FROM wait_times w
JOIN departments d ON w.department_id = d.department_id
GROUP BY d.department_name
ORDER BY avg_wait_time_minutes DESC;


-- KPI: % of Locations with High Wait Times
WITH wait_times AS (
  SELECT 
    location_id,
    TIMESTAMPDIFF(SECOND, check_in_time, check_out_time) / 60 AS wait_minutes
  FROM patients
  WHERE check_in_time IS NOT NULL 
    AND check_out_time IS NOT NULL
),
location_avg AS (
  SELECT 
    location_id,
    AVG(wait_minutes) AS avg_wait_time
  FROM wait_times
  GROUP BY location_id
)
SELECT 
  SUM(avg_wait_time > 120) AS high_wait_count,
  COUNT(*) AS total_locations,
  ROUND(SUM(avg_wait_time > 120) * 100.0 / COUNT(*), 2) AS percent_high_wait
FROM location_avg;

-- Monthly Trends of % of High-Wait Locations
WITH wait_times AS (
  SELECT
    location_id,
    DATE_FORMAT(check_in_time, '%Y-%m-01') AS month,
    TIMESTAMPDIFF(SECOND, check_in_time, check_out_time) / 60 AS wait_minutes
  FROM patients
  WHERE check_in_time IS NOT NULL 
    AND check_out_time IS NOT NULL
),
location_monthly_avg AS (
  SELECT
    location_id,
    month,
    AVG(wait_minutes) AS avg_wait_time
  FROM wait_times
  GROUP BY location_id, month
)
SELECT
  month,
  SUM(avg_wait_time > 120) AS high_wait_count,
  COUNT(*) AS total_locations,
  ROUND(SUM(avg_wait_time > 120) * 100.0 / COUNT(*), 2) AS percent_high_wait
FROM location_monthly_avg
GROUP BY month
ORDER BY month;
