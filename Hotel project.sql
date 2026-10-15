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

