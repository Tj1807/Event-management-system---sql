create database event_management;

use event_management;

CREATE TABLE stg_event_attendance (
  event_id INT NOT NULL,
  event_name VARCHAR(255) NOT NULL,
  location VARCHAR(255) NOT NULL,
  date_time DATETIME NOT NULL,
  attendee_name VARCHAR(200) NOT NULL,
  attendee_email VARCHAR(255) NOT NULL,
  attendee_phone_number VARCHAR(50),
  INDEX idx_stg_event_id (event_id),
  INDEX idx_stg_attendee_email (attendee_email)
);

select * from stg_event_attendance;

#Creating 5 tables to minimize the rows and filter the rows in the dataset.

-- 1) Events (one row per event)
CREATE TABLE IF NOT EXISTS events (
  event_id INT PRIMARY KEY,
  event_name VARCHAR(255) NOT NULL,
  location VARCHAR(255) NOT NULL,
  event_datetime DATETIME NOT NULL,
  INDEX idx_event_datetime (event_datetime)
);

-- 2) Attendees (one row per unique person; email as a natural key)
CREATE TABLE IF NOT EXISTS attendees (
  attendee_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  attendee_name VARCHAR(200) NOT NULL,
  attendee_email VARCHAR(255) NOT NULL,
  attendee_phone_number VARCHAR(50),
  UNIQUE KEY uq_attendee_email (attendee_email)
);

-- 3) Registrations (bridge table: many-to-many)
CREATE TABLE IF NOT EXISTS registrations (
  registration_id BIGINT PRIMARY KEY AUTO_INCREMENT,
  event_id INT NOT NULL,
  attendee_id BIGINT NOT NULL,
  status ENUM('Registered','Cancelled','Attended','No-show') NOT NULL DEFAULT 'Attended',
  registered_at DATETIME NULL,
  UNIQUE KEY uq_event_attendee (event_id, attendee_id),
  INDEX idx_event_id (event_id),
  INDEX idx_attendee_id (attendee_id),
  CONSTRAINT fk_reg_event FOREIGN KEY (event_id) REFERENCES events(event_id),
  CONSTRAINT fk_reg_attendee FOREIGN KEY (attendee_id) REFERENCES attendees(attendee_id)
);

#2. Populating events and attendees (deduplicating with DISTINCT)

INSERT INTO events (event_id, event_name, location, event_datetime)
SELECT DISTINCT
  event_id, event_name, location, date_time
FROM stg_event_attendance;

INSERT INTO attendees (attendee_name, attendee_email, attendee_phone_number)
SELECT
  attendee_name, attendee_email, attendee_phone_number
FROM stg_event_attendance
ON DUPLICATE KEY UPDATE
  attendee_name = COALESCE(attendees.attendee_name, VALUES(attendee_name)),
  attendee_phone_number = COALESCE(attendees.attendee_phone_number, VALUES(attendee_phone_number));
  
  INSERT IGNORE INTO events (event_id, event_name, location, event_datetime)
SELECT DISTINCT event_id, event_name, location, date_time
FROM stg_event_attendance;


INSERT IGNORE INTO registrations (event_id, attendee_id, registered_at, status)
SELECT DISTINCT
  s.event_id,
  a.attendee_id,
  s.date_time,
  'Attended'
FROM stg_event_attendance s
JOIN attendees a
  ON a.attendee_email = s.attendee_email;
  
  
#1. Verifying events has rows:
SELECT COUNT(*) AS events_rows FROM events;








