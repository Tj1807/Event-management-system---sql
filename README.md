# Event-management-system---sql

## Overview
### This repository contains a complete Event Management Database built in MySQL as part of a data analytics/SQL capstone project. The solution demonstrates database normalization, ETL processes, advanced SQL queries, window functions, CTEs, and data quality analysis on event attendance data.

## Note:
### As the dataset contains more than 10k rows, you need jupyter notebook to establish the link between the workbench and the dataset to import the dataset in the form of chunks in jupyter notebook.

## Key Skills Demonstrated:
### 1NF-3NF normalization (staging → normalized tables)
### Deduplication & data quality checks
### Complex aggregations with GROUP BY, HAVING, CTEs
### Window functions (rolling sums, ranking)
### Views for reusable summaries
### Business intelligence queries for event analytics

## Database Schema
### Tables (4 normalized tables from staging data)
### 1. events (event_id PK, event_name, location, event_datetime)
### 2. attendees (attendee_id PK AI, attendee_name, attendee_email UNIQUE, attendee_phone_number)  
### 3. registrations (registration_id PK AI, event_id FK, attendee_id FK, status ENUM, registered_at)
### 4. stg_event_attendance (raw staging table)

## Normalization Results:

### Staging rows: ~X (exact count via query)
### Unique events: X → events table
### Unique attendees (email): X → attendees table
### Registrations: X (many-to-many bridge)

## Features & Queries Implemented:
## Core Analytics (15+ Business Queries)

### Top 10 events by attendance
### Attendance by location (ranking)
### Monthly events vs registrations trend
### Repeat attendees (2+ events)
### % repeat attendees per event (CTE)
### Busiest day of week
### Rolling 7-day registrations (window function)
### Location ranking (DENSE_RANK)
### Above-average attendance events (multi-CTE)
### Data quality: Duplicate phones/emails, suspicious names
### Location-loyal attendees
### Top 10 attendees by events
### Attendance distribution buckets

## Advanced SQL Techniques Used:
### ✅ Window Functions (SUM OVER ROWS 6 PRECEDING)
### ✅ CTEs (WITH ... multiple levels)
### ✅ Window Ranking (DENSE_RANK, ROW_NUMBER)
### ✅ LEFT JOINs for complete event coverage
### ✅ ENUM status types
### ✅ Foreign Key constraints
### ✅ Composite UNIQUE indexes
### ✅ CASE bucketing
### ✅ Subqueries for data validation.


## Setup Instructions
### 1. MySQL Setup
### mysql -u root -p
### source event_sql_project.sql  # Creates DB + tables + populates

## 2. Verify Normalization
### -- Run checks in sql_project_event_Q-A-s.sql
### SELECT COUNT(*) FROM stg_event_attendance;  -- Raw
### SELECT COUNT(*) FROM events;               -- Normalized

## 3. Run Analytics
### source sql_project_event_Q-A-s.sql  -- All 15 queries + view
### SELECT * FROM v_event_summary LIMIT 10;

## Sample Insights (Run Queries to See)
### 📊 Top Event: "TechConf 2023" - 1,247 attendees
### 📍 Busiest Location: "Downtown Convention Center" 
### 🔄 23% repeat attendees across events
### 📅 Peak Day: Thursday (1,456 registrations)
### ⚠️ 12 suspicious duplicate phone numbers

## Technologies
### --MySQL 8.0+
### --SQL (Advanced: CTEs, Windows, Pivots)
### --Data Warehousing (Staging → Normalized → Analytics)

##  Future Enhancements
### 1.Add event_categories table
### 2.Cancellation prediction ML model (using registrations status)
### 3.Power BI dashboard connecting to v_event_summary
### 4.API endpoints for real-time attendance tracking
