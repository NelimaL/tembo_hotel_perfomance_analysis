create schema tembo_hotel;

set search_path to tembo_hotel;
 
create table staging_bookings(
booking_id text,
guest_name text,
guest_phone TEXT,
guest_city TEXT,
guest_nationality TEXT,
room_no TEXT,
room_type TEXT,
room_rate_per_night TEXT,
check_in_date TEXT,
check_out_date TEXT,
nights_stayed TEXT,
staff_name TEXT,
staff_department TEXT,
staff_salary TEXT,
payment_method TEXT,
booking_status TEXT,
total_amount TEXT,
service_used TEXT,
service_price TEXT,
guest_rating TEXT
);
 
select * from staging_bookings;

select * from staging_bookings
limit 15;

--1. Create a cleaning copy
CREATE TABLE bookings_clean AS
SELECT * FROM staging_bookings;

select * from bookings_clean;

--2. limit view to 15 to identify issue
select * from staging_bookings
limit 20;

--3. identify duplicate
SELECT booking_id, COUNT(*)
FROM bookings_clean
GROUP BY booking_id
HAVING COUNT(*) > 1;

--4. deleting duplicate using booking id
DELETE FROM bookings_clean
WHERE booking_id IN (SELECT booking_id
    FROM (SELECT booking_id,
               ROW_NUMBER() OVER (PARTITION BY booking_id ORDER BY booking_id) AS rn
        FROM bookings_clean) t
    WHERE rn > 1
);

--5.trim all columns
-- Trim all text columns
UPDATE tembo_hotel.bookings_clean
SET 
    booking_id = TRIM(booking_id),
    guest_name = TRIM(guest_name),
    guest_phone = TRIM(guest_phone),
    guest_city = TRIM(guest_city),
    guest_nationality = TRIM(guest_nationality),
    room_no = TRIM(room_no),
    room_type = TRIM(room_type),
    room_rate_per_night = TRIM(room_rate_per_night),
    check_in_date = TRIM(check_in_date),
    check_out_date = TRIM(check_out_date),
    nights_stayed = TRIM(nights_stayed),
    staff_name = TRIM(staff_name),
    staff_department = TRIM(staff_department),
    staff_salary = TRIM(staff_salary),
    payment_method = TRIM(payment_method),
    booking_status = TRIM(booking_status),
    total_amount = TRIM(total_amount),
    service_used = TRIM(service_used),
    service_price = TRIM(service_price),
    guest_rating = TRIM(guest_rating);

select * from bookings_clean;

--6.correcting case
-- booking_id
UPDATE tembo_hotel.bookings_clean
SET booking_id = UPPER(booking_id);

-- guest_name
UPDATE tembo_hotel.bookings_clean
SET guest_name = INITCAP(guest_name);

-- city & nationality
UPDATE tembo_hotel.bookings_clean
SET 
    guest_city = INITCAP(guest_city),
    guest_nationality = INITCAP(guest_nationality);

-- staff_name
UPDATE tembo_hotel.bookings_clean
SET staff_name = INITCAP(staff_name);

--7. clean phone numbers
--Audit
select distinct guest_phone from bookings_clean
limit 40;
select distinct guest_phone from staging_bookings
limit 40;

--replace 254 with 0
UPDATE tembo_hotel.bookings_clean
SET guest_phone = REPLACE(REPLACE(REPLACE(guest_phone, '+254', '0'), '-', ''), ' ', '');

-- Remove invalid phones with more than 10 characters
DELETE FROM tembo_hotel.bookings_clean
WHERE LENGTH(guest_phone) != 10;

select * from bookings_clean;

--8.Standardize options for consistency
--Audit
select distinct room_type from bookings_clean;
select distinct staff_department from bookings_clean;
select distinct  payment_method from bookings_clean;

select distinct room_type from staging_bookings;
--Room type as Standard / Deluxe / Suite / Penthouse
UPDATE tembo_hotel.bookings_clean
SET room_type =
CASE
    WHEN LOWER(room_type) LIKE '%standard%' THEN 'Standard'
    WHEN LOWER(room_type) LIKE '%std%' THEN 'Standard'
    WHEN LOWER(room_type) LIKE '%deluxe%' THEN 'Deluxe'
    WHEN LOWER(room_type) LIKE '%DLX%' THEN 'Deluxe'
    WHEN LOWER(room_type) LIKE '%suite%' THEN 'Suite'
    WHEN LOWER(room_type) LIKE '%penthouse%' THEN 'Penthouse'
    ELSE 'Unknown'
END;
--Staff Department as Front Desk / Housekeeping / Restaurant / Security / Management
UPDATE tembo_hotel.bookings_clean
SET staff_department =
CASE
    WHEN LOWER(staff_department) LIKE '%front%' THEN 'Front Desk'
    WHEN LOWER(staff_department) LIKE '%house%' THEN 'Housekeeping'
    WHEN LOWER(staff_department) LIKE '%rest%' THEN 'Restaurant'
    WHEN LOWER(staff_department) LIKE '%security%' THEN 'Security'
    WHEN LOWER(staff_department) LIKE '%manage%' THEN 'Management'
    ELSE 'Other'
END;
--Payment Method as M-Pesa / Cash / Card / Bank Transfer
UPDATE tembo_hotel.bookings_clean
SET payment_method =
CASE
    WHEN LOWER(payment_method) LIKE '%mpesa%' THEN 'M-Pesa'
    WHEN LOWER(payment_method) LIKE '%cash%' THEN 'Cash'
    WHEN LOWER(payment_method) LIKE '%card%' THEN 'Card'
    WHEN LOWER(payment_method) LIKE '%bank%' THEN 'Bank Transfer'
    ELSE 'Other'
END;

--9. Remove rows with non-numeric values
DELETE FROM tembo_hotel.bookings_clean
WHERE room_rate_per_night !~ '^[0-9.]+$'
   OR staff_salary !~ '^[0-9.]+$'
   OR total_amount !~ '^[0-9.]+$';

--Audit date
select booking_id, check_in_date, check_out_date
FROM tembo_hotel.bookings_clean
LIMIT 20;
select booking_id, check_in_date, check_out_date
FROM tembo_hotel.staging_bookings;
--debug issues in date
SELECT check_in_date
FROM tembo_hotel.bookings_clean
WHERE check_in_date !~ '^\d{4}-\d{2}-\d{2}$';

--Clean/standardize the formarts you have
UPDATE tembo_hotel.bookings_clean
SET check_in_date = 
CASE
    WHEN check_in_date LIKE '__/__/____' 
        THEN TO_DATE(check_in_date, 'DD/MM/YYYY')::TEXT
    WHEN check_in_date LIKE '____-__-__' 
        THEN check_in_date
    ELSE NULL
END;

UPDATE tembo_hotel.bookings_clean
SET check_out_date = 
CASE
    WHEN check_out_date LIKE '__/__/____' 
        THEN TO_DATE(check_out_date, 'DD/MM/YYYY')::TEXT
    WHEN check_out_date LIKE '____-__-__' 
        THEN check_out_date
    ELSE NULL
END;

SELECT 
    TO_CHAR(
        TO_DATE(check_in_date, 'DD-MM-YYYY'),
        'YYYY-MM-DD'
    ) AS formatted_date
FROM bookings_clean;
SELECT 
    TO_CHAR(
        TO_DATE(check_out_date, 'DD-MM-YYYY'),
        'YYYY-MM-DD'
    ) AS formatted_date
FROM bookings_clean;


--Error -SQL Error [22P02]: ERROR: invalid input syntax for type integer: ""
--Audit
select distinct room_no from bookings_clean;
select distinct nights_stayed from bookings_clean;
select distinct  guest_rating from bookings_clean;
--Replace empty strings with NULL
SELECT room_no
FROM tembo_hotel.bookings_clean
WHERE room_no = '' OR room_no IS NULL;

SELECT nights_stayed
FROM tembo_hotel.bookings_clean
WHERE nights_stayed = '' OR nights_stayed IS NULL;

SELECT guest_rating
FROM tembo_hotel.bookings_clean
WHERE guest_rating = '' OR guest_rating IS NULL;

--correct the nulls in guest rating
ALTER TABLE tembo_hotel.bookings_clean
ALTER COLUMN guest_rating TYPE INT 
USING (
    CASE 
        WHEN guest_rating ~ '^[0-9]+$' THEN guest_rating::INT
        ELSE NULL
    END
);

--11. As a precaution Remove invalid business logic
-- Invalid dates
DELETE FROM tembo_hotel.bookings_clean
WHERE check_out_date < check_in_date;
-- Invalid pricing
DELETE FROM tembo_hotel.bookings_clean
WHERE room_rate_per_night < 0;
-- Invalid ratings
DELETE FROM tembo_hotel.bookings_clean
WHERE guest_rating < 1 OR guest_rating > 5;

select * FROM tembo_hotel.staging_bookings
WHERE check_out_date < check_in_date;

--fix nights stayed
UPDATE tembo_hotel.bookings_clean
SET nights_stayed = (check_out_date - check_in_date);
--correct data type
ALTER TABLE tembo_hotel.bookings_clean
ALTER COLUMN nights_stayed TYPE INT
USING nights_stayed::INT;

--10. Convert to correct data types
ALTER TABLE tembo_hotel.bookings_clean
ALTER COLUMN room_no TYPE INT USING room_no::INT,
ALTER COLUMN room_rate_per_night TYPE NUMERIC USING room_rate_per_night::NUMERIC,
ALTER COLUMN staff_salary TYPE NUMERIC USING staff_salary::NUMERIC,
ALTER COLUMN total_amount TYPE NUMERIC USING total_amount::NUMERIC,
ALTER COLUMN service_price TYPE NUMERIC USING NULLIF(service_price, '')::NUMERIC,
ALTER COLUMN guest_rating TYPE INT USING guest_rating::INT,
ALTER COLUMN check_in_date TYPE DATE USING check_in_date::DATE,
ALTER COLUMN check_out_date TYPE DATE USING check_out_date::DATE;

--to check data types
SELECT 
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'tembo_hotel'
AND table_name = 'bookings_clean';


CREATE OR REPLACE VIEW tembo_hotel.v_clean_bookings AS
SELECT *
FROM tembo_hotel.bookings_clean;

ALTER TABLE tembo_hotel.bookings_clean
ALTER COLUMN check_in_date TYPE DATE
USING TO_DATE(check_in_date, 'YYYY-MM-DD');

DROP VIEW tembo_hotel.v_clean_bookings;

select* from tembo_hotel.v_clean_bookings;

UPDATE tembo_hotel.bookings_clean
SET check_in_date =
CASE
    -- Format: DD-MM-YYYY
    WHEN check_in_date LIKE '__-__-____'
        THEN TO_DATE(check_in_date, 'DD-MM-YYYY')::TEXT

    -- Format: DD-MM-YY
    WHEN check_in_date LIKE '__-__-__'
        THEN TO_DATE(check_in_date, 'DD-MM-YY')::TEXT

    -- Format already correct: YYYY-MM-DD
    WHEN check_in_date LIKE '____-__-__'
        THEN check_in_date

    ELSE NULL
END
WHERE check_in_date IS NOT NULL;

ALTER TABLE tembo_hotel.bookings_clean
ALTER COLUMN check_in_date TYPE DATE
USING check_in_date::DATE;
