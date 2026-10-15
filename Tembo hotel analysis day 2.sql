set search_path to tembo_hotel;

--1. Revenue analysis: 
--Total revenue by month, by room type, by payment method

--by month
--We grouped bookings by month using the check-in date and calculated total revenue generated each month. 
--This helped identify seasonal business trends and peak revenue periods

SELECT 
    TO_CHAR(check_in_date, 'MM') AS month,
    SUM(total_amount) AS total_revenue
FROM tembo_hotel.bookings_clean
GROUP BY month
ORDER BY month;

--by room type
SELECT room_type,
    SUM(total_amount) AS total_revenue
FROM tembo_hotel.bookings_clean
GROUP BY room_type
ORDER BY total_revenue DESC;

--by payment method
SELECT payment_method,
    SUM(total_amount) AS total_revenue
FROM tembo_hotel.v_clean_bookings
GROUP BY payment_method
ORDER BY total_revenue DESC;

--2.	Occupancy: 
--Which room types are booked most? Average nights stayed per room type
--Which room types are booked most? 
SELECT room_type,
    COUNT(*) AS total_bookings
FROM tembo_hotel.bookings_clean
GROUP BY room_type
ORDER BY total_bookings DESC;


--Average nights stayed per room type
SELECT room_type,
    ROUND(AVG(nights_stayed), 2) AS avg_nights_stayed
FROM tembo_hotel.bookings_clean
GROUP BY room_type
ORDER BY avg_nights_stayed DESC;

--3.Guest insights: 
--Top 10 cities guests come from. Average rating per room type
--Top 10 cities guests come from--Top 10
SELECT guest_city,
    COUNT(*) AS total_guests
FROM tembo_hotel.bookings_clean
GROUP BY guest_city
ORDER BY total_guests DESC
LIMIT 10;
--Nairobi being the highest

--Average rating per room type
SELECT room_type,
    ROUND(AVG(guest_rating), 2) AS avg_rating
FROM tembo_hotel.bookings_clean
GROUP BY room_type
ORDER BY avg_rating DESC;

--4.Staff performance:
--Which staff handled the most bookings? Which department generates most revenue?
--Which staff handled the most bookings?
SELECT 
    staff_name,
    SUM(total_amount) AS total_revenue
FROM tembo_hotel.bookings_clean
GROUP BY staff_name
ORDER BY total_revenue DESC
LIMIT 1;       --shows staff withmost bookings

--Which department generates most revenue?
SELECT staff_department,
    SUM(total_amount) AS total_revenue
FROM tembo_hotel.bookings_clean
GROUP BY staff_department
ORDER BY total_revenue DESC;

--5.	Trends:
--Revenue growth month over month (window function). Busiest vs quietest months
--Revenue growth month over month (window function)
WITH monthly_revenue AS (SELECT 
        TO_CHAR(check_in_date, 'MM') AS month,
        SUM(total_amount) AS revenue
    FROM tembo_hotel.bookings_clean
    GROUP BY month)
SELECT month,revenue,
    LAG(revenue) OVER (ORDER BY month) AS previous_month_revenue,
    ROUND(((revenue - LAG(revenue) OVER (ORDER BY month))
            / NULLIF(LAG(revenue) OVER (ORDER BY month), 0)) * 100,
        2) AS revenue_growth_percent
FROM monthly_revenue;

--Busiest vs quietest months
SELECT TO_CHAR(check_in_date, 'Month') AS month,
    COUNT(*) AS total_bookings
FROM tembo_hotel.bookings_clean
GROUP BY month
ORDER BY total_bookings DESC;

--6.	Cancellations: 
--Cancellation rate per room type. Revenue lost from cancellations and no-shows
--Cancellation rate per room type.
SELECT room_type,
    COUNT(*) FILTER (WHERE booking_status = 'Cancelled') AS cancelled_bookings,
    COUNT(*) AS total_bookings,
    ROUND((COUNT(*) FILTER (WHERE booking_status = 'Cancelled')::NUMERIC
            / COUNT(*)) * 100,2) AS cancellation_rate_percent
FROM tembo_hotel.bookings_clean
GROUP BY room_type
ORDER BY cancellation_rate_percent DESC;

--Revenue lost from cancellations and no-shows
SELECT booking_status,
    SUM(total_amount) AS revenue_lost
FROM tembo_hotel.bookings_clean
WHERE booking_status IN ('Cancelled', 'No Show')
GROUP BY booking_status;

--This analysis identifies seasonal performance trends and helps management understand periods of high and 
--low revenue generation



