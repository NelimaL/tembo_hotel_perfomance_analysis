set search_path to tembo_hotel;

--1 • views created - one per major business area (revenue, occupancy, guests, staff)

--Revenue analysi-Track hotel revenue and booking payments
CREATE OR REPLACE VIEW v_revenue_summary AS
SELECT booking_id,guest_name,room_no,
    check_in_date,check_out_date,nights_stayed,
    total_amount,payment_method
FROM bookings_clean;

select*  from v_revenue_summary;

--- Occupancy analysis view
CREATE OR REPLACE VIEW v_room_occupancy AS
SELECT room_no,room_type,guest_name,check_in_date,
    check_out_date,booking_status
FROM bookings_clean;

-- Guest analysis view
CREATE OR REPLACE VIEW v_guest_summary AS
SELECT
    INITCAP(guest_name) AS guest_name,
    INITCAP(guest_city) AS guest_city,
    guest_phone
from bookings_clean;

-- Staff analysis view
CREATE OR REPLACE VIEW v_staff_summary AS
SELECT
    INITCAP(staff_name) AS staff_name,
    staff_department,
    staff_salary
FROM bookings_clean;

--2.Indexes on all foreign key-equivalent columns (room_no, staff_name, guest_city, check_in_date)
-- Index for room number
CREATE INDEX idx_room_no
ON bookings_clean(room_no);

-- Index for staff name
CREATE INDEX idx_staff_name
ON bookings_clean(staff_name);

-- Index for guest city
CREATE INDEX idx_guest_city
ON bookings_clean(guest_city);

-- Index for check-in date
CREATE INDEX idx_check_in_date
ON bookings_clean(check_in_date);
