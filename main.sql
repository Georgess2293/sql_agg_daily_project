-- Let's start with grouping the KPIs chosen for the presentation into 1 single table


-- CTE_RENTALS_PER_DAY: includes Total rentals, Total amount, Total active customers, Average Rental per customer
-- average amount per customer, distinct films number, average films length, films shorter than 2 hours, film longer than 2 hours
WITH CTE_RENTALS_PER_DAY AS
(
	SELECT 
		CAST(se_rental.rental_date AS DATE) AS rental_date,
		COUNT(se_rental.rental_id) AS total_rentals,
		COALESCE(SUM(se_payment.amount),0) AS total_amount,
		COUNT(DISTINCT se_rental.customer_id) AS total_active_customers,
		ROUND(CAST(COUNT(se_rental.rental_id) AS NUMERIC)/CAST(COUNT(DISTINCT se_rental.customer_id)AS NUMERIC),2) AS avg_rental_per_customer,
		ROUND(CAST(SUM(se_payment.amount) AS NUMERIC)/CAST(COUNT(DISTINCT se_rental.customer_id)AS NUMERIC),2) AS avg_amount_per_customer,
		COUNT(DISTINCT se_film.film_id) AS films_number,
		ROUND(CAST(COUNT
			(
			se_rental.rental_id
			) AS NUMERIC)/
			CAST(COUNT(DISTINCT se_film.film_id)AS NUMERIC)
			,2) AS avg_rental_per_films,
		ROUND(AVG(se_film.length),0) AS average_length_rented,
		ROUND(COUNT(
		CASE 
			WHEN se_film.length>120
			THEN se_film.film_id
		END
		)/NULLIF
		(CAST(COUNT(se_rental.rental_id)AS NUMERIC),0)*100,2)
		AS perc_films_longer_than_2hours,
		ROUND(COUNT(
		CASE 
			WHEN se_film.length<=120
			THEN se_film.film_id
		END
		)/NULLIF
		(CAST(COUNT(se_rental.rental_id)AS NUMERIC),0)*100,2)
		AS perc_films_shorter_than_2hours

	FROM public.payment AS se_payment
    INNER JOIN public.rental AS se_rental
	ON se_payment.rental_id=se_rental.rental_id
	INNER JOIN public.inventory AS se_inventory
	ON se_rental.inventory_id=se_inventory.inventory_id
	INNER JOIN public.film AS se_film
	ON se_inventory.film_id=se_film.film_id
	GROUP BY
		CAST(se_rental.rental_date AS DATE)
	ORDER BY
		CAST(se_rental.rental_date AS DATE)
),

CTE_COUNTRIES_RENTALS_DAILY AS  -- rentals percentage per country
(
SELECT
	CAST(se_rental.rental_date AS DATE) AS rental_date,
	COUNT(se_rental.rental_id) AS total_rentals,
	ROUND(CAST(COUNT(
		CASE 
			WHEN se_country.country_id=44 
			THEN se_rental.rental_id
		END
	)AS NUMERIC)/ NULLIF(
		CAST(COUNT(se_rental.rental_id) AS NUMERIC)
		,0) * 100,1) AS perc_rentals_India,
	ROUND(CAST(COUNT(
		CASE 
			WHEN se_country.country_id=23
			THEN se_rental.rental_id
		END
	)AS NUMERIC)/NULLIF(
		CAST(COUNT(se_rental.rental_id) AS NUMERIC)
		,0) * 100,1) AS perc_rentals_China,
	ROUND(CAST(COUNT(
		CASE 
			WHEN se_country.country_id =103 
			THEN se_rental.rental_id
		END
	)AS NUMERIC)/NULLIF(
		CAST(COUNT(se_rental.rental_id) AS NUMERIC)
		,0) * 100,1) AS perc_rentals_United_States,
	ROUND(CAST(COUNT(
		CASE 
			WHEN se_country.country_id=50 
			THEN se_rental.rental_id
		END
	)AS NUMERIC)/NULLIF(
		CAST(COUNT(se_rental.rental_id) AS NUMERIC)
		,0) * 100,1) AS perc_rentals_Japan,
	ROUND(CAST(COUNT(
		CASE 
			WHEN se_country.country_id =60
			THEN se_rental.rental_id
		END
	)AS NUMERIC)/NULLIF(
		CAST(COUNT(se_rental.rental_id) AS NUMERIC)
		,0) * 100,1) AS perc_rentals_Mexico,
	ROUND(CAST(COUNT(
		CASE 
			WHEN se_country.country_id =15 
			THEN se_rental.rental_id
		END
	)AS NUMERIC)/NULLIF(
		CAST(COUNT(se_rental.rental_id) AS NUMERIC)
		,0) * 100,1) AS perc_rentals_Brazil,
	ROUND(CAST(COUNT(
		CASE 
			WHEN se_country.country_id  =80 
			THEN se_rental.rental_id
		END
	)AS NUMERIC)/NULLIF(
		CAST(COUNT(se_rental.rental_id) AS NUMERIC)
		,0) * 100,1) AS perc_rentals_Russia,
	ROUND(CAST(COUNT(
		CASE 
			WHEN se_country.country_id =75
			THEN se_rental.rental_id
		END
	)AS NUMERIC)/NULLIF(
		CAST(COUNT(se_rental.rental_id) AS NUMERIC)
		,0) * 100,1) AS perc_rentals_Philippines,
	ROUND(CAST(COUNT(
		CASE 
			WHEN se_country.country_id =97
			THEN se_rental.rental_id
		END
	)AS NUMERIC)/NULLIF(
		CAST(COUNT(se_rental.rental_id) AS NUMERIC)
		,0) * 100,1) AS perc_rentals_Turkey,
	ROUND(CAST(COUNT(
		CASE 
			WHEN se_country.country_id =45
			THEN se_rental.rental_id
		END
	)AS NUMERIC)/NULLIF(
		CAST(COUNT(se_rental.rental_id) AS NUMERIC)
		,0) * 100,1) AS perc_rentals_Indonesia,
	ROUND(CAST(COUNT(
		CASE 
			WHEN se_country.country_id  NOT IN (44,23,103,50,60,15,80,75,97,45) 
			THEN se_rental.rental_id
		END
	)AS NUMERIC)/NULLIF(
		CAST(COUNT(se_rental.rental_id) AS NUMERIC)
		,0) * 100,1) AS rest_of_the_world
FROM 
	public.rental AS se_rental
	INNER JOIN public.customer AS se_customer
	ON se_rental.customer_id=se_customer.customer_id
	INNER JOIN public.address AS se_address
	ON se_customer.address_id=se_address.address_id
	INNER JOIN public.city AS se_city
	ON se_address.city_id=se_city.city_id
	INNER JOIN public.country AS se_country
	ON se_city.country_id=se_country.country_id
GROUP BY
	CAST(se_rental.rental_date AS DATE) 
ORDER BY 
	CAST(se_rental.rental_date AS DATE)
),

CTE_DAILY_ACTIVITY AS -- Grouping Both CTEs in 1 Daily activity CTE
(
SELECT
	CTE_RENTALS_PER_DAY.rental_date AS activity_date,
	CTE_RENTALS_PER_DAY.total_rentals,
	CTE_RENTALS_PER_DAY.total_amount,
	CTE_RENTALS_PER_DAY.total_active_customers,
	CTE_RENTALS_PER_DAY.avg_rental_per_customer,
	CTE_RENTALS_PER_DAY.avg_amount_per_customer,
	CTE_RENTALS_PER_DAY.films_number,
	CTE_RENTALS_PER_DAY.average_length_rented,
	CTE_RENTALS_PER_DAY.perc_films_longer_than_2hours,
	CTE_RENTALS_PER_DAY.perc_films_shorter_than_2hours,
	CTE_COUNTRIES_RENTALS_DAILY.perc_rentals_India,
	CTE_COUNTRIES_RENTALS_DAILY.perc_rentals_China,
	CTE_COUNTRIES_RENTALS_DAILY.perc_rentals_United_states,
	CTE_COUNTRIES_RENTALS_DAILY.perc_rentals_Japan,
	CTE_COUNTRIES_RENTALS_DAILY.perc_rentals_Mexico,
	CTE_COUNTRIES_RENTALS_DAILY.perc_rentals_Brazil,
	CTE_COUNTRIES_RENTALS_DAILY.perc_rentals_Russia,
	CTE_COUNTRIES_RENTALS_DAILY.perc_rentals_Philippines,
	CTE_COUNTRIES_RENTALS_DAILY.perc_rentals_Turkey,
	CTE_COUNTRIES_RENTALS_DAILY.perc_rentals_Indonesia,
    CTE_COUNTRIES_RENTALS_DAILY.rest_of_the_world 
FROM CTE_RENTALS_PER_DAY
INNER JOIN CTE_COUNTRIES_RENTALS_DAILY
ON CTE_RENTALS_PER_DAY.rental_date=CTE_COUNTRIES_RENTALS_DAILY.rental_date
ORDER BY CTE_RENTALS_PER_DAY.rental_date
)

-- CREATE TABLE IF NOT EXISTS reporting_schema.georges_agg_daily
-- (
-- activity_date DATE,
-- total_rentals NUMERIC,
-- total_amount NUMERIC,
-- total_active_customers NUMERIC,
-- avg_rental_per_customer NUMERIC,
-- avg_amount_per_customer NUMERIC,
-- films_number NUMERIC,
-- average_length_rented NUMERIC,
-- perc_films_longer_than_2hours NUMERIC,
-- perc_films_shorter_than_2hours NUMERIC,
-- perc_rentals_India NUMERIC,
-- perc_rentals_China NUMERIC,
-- perc_rentals_United_states NUMERIC,
-- perc_rentals_Japan NUMERIC,
-- perc_rentals_Mexico NUMERIC,
-- perc_rentals_Brazil NUMERIC,
-- perc_rentals_Russia NUMERIC,
-- perc_rentals_Philippines NUMERIC,
-- perc_rentals_Turkey NUMERIC,
-- perc_rentals_Indonesia NUMERIC,
-- rest_of_the_world NUMERIC
-- )

-- Insert the CTE_DAILY_ACTIVITY into my agg daiy table 
INSERT INTO reporting_schema.georges_agg_daily
(
SELECT * FROM CTE_DAILY_ACTIVITY
)


-- Writing a single query for every KPI to be explained:

--1. Total Rentals (General overview on the business)

get_total_rentals="""
    SELECT
        activity_date,
        total_rentals
    FROM reporting_schema.georges_agg_daily
"""

--2. Draw both total rentals and total active customers on 1 graph and explain the correlation

get_rentals_per_customer="""
    SELECT
        activity_date,
        total_rentals,
        total_active_customers
    FROM reporting_schema.georges_agg_daily
"""

--3. Draw both total rentals and total distinc movies on 1 graph and explain the correlation: Whether same films are being rented

get_rentals_per_film="""
    SELECT
        activity_date,
        total_rentals,
        films_number
    FROM reporting_schema.georges_agg_daily
"""

--4. Draw the average amount spent by customer (Average order value analysis)

get_amount_per_customer="""
    SELECT
        activity_date,
        avg_amount_per_customer
    FROM reporting_schema.georges_agg_daily
"""

--5 Show the average length of rented movies per day: Define a range with the most length values 

get_average_length="""
    SELECT
        activity_date,
        average_length_rented
    FROM reporting_schema.georges_agg_daily
"""

--6 Show the percentage of short films (shorter than 2 hours) and long films (longer than 2 hours): Analyze the interest of customers based on length
   
   get_percentage_length="""
    SELECT
        activity_date,
        perc_films_longer_than_2hours,
        perc_films_shorter_than_2hours
    FROM reporting_schema.georges_agg_daily
"""
      
--7 Draw a pie chart with the average percentage of rentals per country: Define the countries with the most rentals

get_avg_percentage_country="""
	SELECT
		ROUND(AVG(perc_rentals_India),0) AS India,
		ROUND(AVG(perc_rentals_China),0) AS China,
		ROUND(AVG(perc_rentals_United_states),0) AS US,
		ROUND(AVG(perc_rentals_Japan),0) AS Japan,
		ROUND(AVG(perc_rentals_Mexico),0) AS Mexico,
		ROUND(AVG(perc_rentals_Brazil),0) AS Brazil,
		ROUND(AVG(perc_rentals_Russia),0) AS Russia,
		ROUND(AVG(perc_rentals_Philippines),0) AS Philippines,
		ROUND(AVG(perc_rentals_Turkey),0) AS Turkey,
		ROUND(AVG(perc_rentals_Indonesia),0) AS Indonesia,
    	ROUND(AVG(rest_of_the_world),0) AS Rest_of_the_World
	FROM  reporting_schema.georges_agg_daily
"""

--8 Choose a couple of countries, draw the percentage graph and analyze the flow 

get_percentage_India_Brazil="""
	SELECT
		activity_date,
		perc_rentals_India AS India,
	    perc_rentals_Brazil AS Brazil
	FROM  reporting_schema.georges_agg_daily
"""