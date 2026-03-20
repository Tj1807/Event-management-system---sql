use event_management;

# For confirming Normalizations
-- How many raw rows?
SELECT COUNT(*) AS staging_rows FROM stg_event_attendance;

-- How many unique events in the raw file vs your events table?
SELECT
  (SELECT COUNT(DISTINCT event_id) FROM stg_event_attendance) AS distinct_event_ids_in_staging,
  (SELECT COUNT(*) FROM events) AS rows_in_events;

-- How many unique attendee emails in raw vs your attendees table?
SELECT
  (SELECT COUNT(DISTINCT attendee_email) FROM stg_event_attendance) AS distinct_emails_in_staging,
  (SELECT COUNT(*) FROM attendees) AS rows_in_attendees;

-- Registrations should roughly match staging rows (after dedupe rules)
SELECT COUNT(*) AS rows_in_registrations FROM registrations;


# Questions and Answers

#1. Top 10 events by attendance.
SELECT e.event_id, e.event_name, COUNT(*) AS attendees
FROM registrations r
JOIN events e ON e.event_id = r.event_id
GROUP BY e.event_id, e.event_name
ORDER BY attendees DESC
LIMIT 10;

#2. Grouping Attendance by location
SELECT
  e.location,
  COUNT(*) AS registrations
FROM registrations r
JOIN events e ON e.event_id = r.event_id
GROUP BY e.location
ORDER BY registrations DESC;

#3.  Monthly events + monthly registrations
SELECT
  YEAR(e.event_datetime) AS yr,
  MONTH(e.event_datetime) AS mon,
  COUNT(DISTINCT e.event_id) AS events_count,
  COUNT(r.registration_id) AS registrations_count
FROM events e
LEFT JOIN registrations r
  ON r.event_id = e.event_id
GROUP BY YEAR(e.event_datetime), MONTH(e.event_datetime)
ORDER BY yr, mon;


#4. Repeat attendees (2+ events).
SELECT
  a.attendee_id,
  a.attendee_name,
  a.attendee_email,
  COUNT(DISTINCT r.event_id) AS events_attended
FROM registrations r
JOIN attendees a ON a.attendee_id = r.attendee_id
GROUP BY a.attendee_id, a.attendee_name, a.attendee_email
HAVING COUNT(DISTINCT r.event_id) >= 2
ORDER BY events_attended DESC;

#5.  For each event, percent of repeat attendees.
WITH repeat_attendees AS (
  SELECT attendee_id
  FROM registrations
  GROUP BY attendee_id
  HAVING COUNT(DISTINCT event_id) >= 2
)
SELECT
  e.event_id,
  e.event_name,
  COUNT(*) AS total_attendees,
  SUM(CASE WHEN ra.attendee_id IS NOT NULL THEN 1 ELSE 0 END) AS repeat_attendees,
  ROUND(100.0 * SUM(CASE WHEN ra.attendee_id IS NOT NULL THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_repeat
FROM registrations r
JOIN events e ON e.event_id = r.event_id
LEFT JOIN repeat_attendees ra ON ra.attendee_id = r.attendee_id
GROUP BY e.event_id, e.event_name
ORDER BY pct_repeat DESC;

#6. “Busiest day” of week by registrations.
SELECT
  DAYNAME(e.event_datetime) AS day_name,
  WEEKDAY(e.event_datetime) AS day_num,  -- Monday=0 ... Sunday=6
  COUNT(*) AS registrations
FROM registrations r
JOIN events e ON e.event_id = r.event_id
GROUP BY day_name, day_num
ORDER BY registrations DESC;

#7. Rolling 7-day registrations (window function)
#First aggregate to daily totals, then compute rolling sum. (Window frames define how many rows are included around the current row.)
WITH daily_regs AS (
  SELECT
    DATE(e.event_datetime) AS day,
    COUNT(*) AS regs
  FROM registrations r
  JOIN events e ON e.event_id = r.event_id
  GROUP BY DATE(e.event_datetime)
)
SELECT
  day,
  regs,
  SUM(regs) OVER (
    ORDER BY day
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS rolling_7day_regs
FROM daily_regs
ORDER BY day;

#8. Rank locations by total attendance (DENSE_RANK)
#DENSE_RANK() ranks without gaps when ties occur.
WITH loc AS (
  SELECT
    e.location,
    COUNT(*) AS total_regs
  FROM registrations r
  JOIN events e ON e.event_id = r.event_id
  GROUP BY e.location
)
SELECT
  location,
  total_regs,
  DENSE_RANK() OVER (ORDER BY total_regs DESC) AS location_rank
FROM loc
ORDER BY location_rank, location;

#9. Events with attendance above overall average (CTE).
WITH per_event AS (
  SELECT
    e.event_id,
    e.event_name,
    COUNT(r.registration_id) AS attendance
  FROM events e
  LEFT JOIN registrations r ON r.event_id = e.event_id
  GROUP BY e.event_id, e.event_name
),
avg_att AS (
  SELECT AVG(attendance) AS avg_attendance
  FROM per_event
)
SELECT
  p.event_id, p.event_name, p.attendance
FROM per_event p
CROSS JOIN avg_att a
WHERE p.attendance > a.avg_attendance
ORDER BY p.attendance DESC;

#10.  Duplicate identities: same phone used by multiple emails.
SELECT
  attendee_phone_number,
  COUNT(DISTINCT attendee_email) AS emails_on_same_phone
FROM attendees
WHERE attendee_phone_number IS NOT NULL AND attendee_phone_number <> ''
GROUP BY attendee_phone_number
HAVING COUNT(DISTINCT attendee_email) >= 2
ORDER BY emails_on_same_phone DESC;

#11.  Suspicious emails: same name with different emails.
SELECT
  attendee_name,
  COUNT(DISTINCT attendee_email) AS distinct_emails
FROM attendees
GROUP BY attendee_name
HAVING COUNT(DISTINCT attendee_email) >= 2
ORDER BY distinct_emails DESC, attendee_name;

#12. Attendees who only attended events in one location.
SELECT
  a.attendee_id,
  a.attendee_name,
  a.attendee_email,
  COUNT(DISTINCT e.location) AS locations_count
FROM registrations r
JOIN attendees a ON a.attendee_id = r.attendee_id
JOIN events e ON e.event_id = r.event_id
GROUP BY a.attendee_id, a.attendee_name, a.attendee_email
HAVING COUNT(DISTINCT e.location) = 1
ORDER BY a.attendee_id;

#13. Top 10 attendees by number of events attended.
SELECT
  a.attendee_id,
  a.attendee_name,
  a.attendee_email,
  COUNT(DISTINCT r.event_id) AS events_attended
FROM registrations r
JOIN attendees a ON a.attendee_id = r.attendee_id
GROUP BY a.attendee_id, a.attendee_name, a.attendee_email
ORDER BY events_attended DESC
LIMIT 10;

#14. Attendance distribution (bucketing events by attendance)
WITH per_event AS (
  SELECT
    e.event_id,
    COUNT(r.registration_id) AS attendance
  FROM events e
  LEFT JOIN registrations r ON r.event_id = e.event_id
  GROUP BY e.event_id
),
buckets AS (
  SELECT
    CASE
      WHEN attendance BETWEEN 1 AND 10 THEN '01-10'
      WHEN attendance BETWEEN 11 AND 50 THEN '11-50'
      WHEN attendance BETWEEN 51 AND 100 THEN '51-100'
      WHEN attendance BETWEEN 101 AND 200 THEN '101-200'
      ELSE '200+'
    END AS bucket
  FROM per_event
)
SELECT bucket, COUNT(*) AS events_in_bucket
FROM buckets
GROUP BY bucket
ORDER BY bucket;

#15. Create a view v_event_summary.
CREATE OR REPLACE VIEW v_event_summary AS
SELECT
  e.event_id,
  e.event_name,
  e.event_datetime,
  e.location,
  COUNT(r.registration_id) AS attendance
FROM events e
LEFT JOIN registrations r ON r.event_id = e.event_id
GROUP BY e.event_id, e.event_name, e.event_datetime, e.location;















