-- get a overall look 
SELECT * 
FROM pas_sas

--- categories with highest 5 score rate --- 

;WITH unpiv AS
(SELECT ID, col as categories, value as score
FROM pas_sas
UNPIVOT
(
VALUE FOR col IN 
(Departure_and_Arrival_Time_Convenience, Ease_of_Online_Booking, 
Check_in_Service, Online_Boarding, Gate_Location, On_board_Service, 
Seat_Comfort, Leg_Room_Service, Cleanliness, Food_and_Drink, In_flight_Service, 
In_flight_Wifi_Service, In_flight_Entertainment, Baggage_Handling)) unpiv)
SELECT * 
INTO new_table
FROM unpiv

SELECT * 
FROM new_table

;WITH not_apply AS 
(SELECT COUNT(score) AS without0, categories
FROM new_table
WHERE score != '0'
GROUP BY categories),

five_score AS
(SELECT COUNT(score) as score5, categories
FROM new_table
WHERE score = '5'
GROUP BY categories)

SELECT ROUND(CAST(score5 as float)/CAST(without0 AS float),2) AS fiveScore_rate, five_score.categories
FROM not_apply
INNER JOIN 
five_score
ON not_apply.categories = five_score.categories
ORDER BY fiveScore_rate DESC

-- => In-flight service, Seat comfort, baggage handling are the highest ones.
-- In-flight wifi service is the lowest one. At the same time, In-flight service has the lowest one-score rates, and 
-- In-flight wifi service has the highest one-score rates. 

--- Discover which class has the highest overall satisfaction ---

SELECT DISTINCT(Class)
FROM pas_sas

-- There are three types of class: Economy, Economy Plus, and Business

SELECT COUNT(Satisfaction) as score, Class
FROM pas_sas
WHERE Class = 'Business' AND Satisfaction = 'Satisfied'
GROUP BY Class
UNION 
SELECT COUNT(Satisfaction) as econ_score, Class
FROM pas_sas
WHERE Class = 'Economy' AND Satisfaction = 'Satisfied'
GROUP BY Class
UNION 
SELECT COUNT(Satisfaction) as econ_score, Class
FROM pas_sas
WHERE Class = 'Economy Plus' AND Satisfaction = 'Satisfied'
GROUP BY Class


SELECT COUNT(Satisfaction)
FROM pas_sas
WHERE Class = 'Economy'

SELECT COUNT(Satisfaction)
FROM pas_sas
WHERE Class = 'Economy Plus'

-- however, the total number of survey responses are different from each class. As a result, 
--the one with the most "Satisfied" responses might not be the one with most satisfied customers. 
--We need to calculate the rate. 

;WITH total_response AS 
(SELECT COUNT(Satisfaction) as total, Class
FROM pas_sas
GROUP BY Class), 
business AS 
(SELECT COUNT(Satisfaction) AS business_score, Class
FROM pas_sas
WHERE Class = 'Business' AND Satisfaction = 'Satisfied'
GROUP BY Class), 
economy AS 
(SELECT COUNT(Satisfaction) AS econ_score, Class
FROM pas_sas
WHERE Class = 'Economy' AND Satisfaction = 'Satisfied'
GROUP BY Class), 
economyPlus AS 
(SELECT COUNT(Satisfaction) AS econPlus_score, Class
FROM pas_sas
WHERE Class = 'Economy Plus' AND Satisfaction = 'Satisfied'
GROUP BY Class)
SELECT ROUND(CAST(business_score as float)/ CAST(total AS float),2) AS satisfaction_rate, business.Class
FROM total_response
RIGHT JOIN 
business
ON total_response.Class = business.Class
UNION 
SELECT ROUND(CAST(econ_score as float)/ CAST(total AS float),2) AS satisfaction_rate, economy.Class
FROM total_response
RIGHT JOIN 
economy
ON total_response.Class = economy.Class
UNION 
SELECT ROUND(CAST(econPlus_score as float)/ CAST(total AS float),2) AS satisfaction_rate, economyPlus.Class
FROM total_response
RIGHT JOIN 
economyPlus
ON total_response.Class = economyPlus.Class

-- Business has the highest satisfaction rate. Economy has the lowest satisfaction rate. 

-- Discover the relationship between age and in_flight entertainment rate

SELECT * 
FROM pas_sas

SELECT MAX(Age) as max_age, MIN(Age) as min_age
FROM pas_sas

;WITH classified_age AS 
(SELECT Age, In_flight_Entertainment, Ease_of_Online_Booking, In_flight_Wifi_service,
CASE 
WHEN Age < 15 THEN 'children and young adolescents'
WHEN Age >= 15 AND Age <= 64 THEN 'the working-age'
WHEN Age >= 65 THEN 'the elderly'
END AS ageRange
FROM pas_sas
WHERE In_flight_Entertainment != 0
AND Ease_of_Online_Booking !=0 
AND 
In_flight_Wifi_service !=0) 
SELECT * 
INTO age_entertain
FROM classified_age

SELECT * 
FROM age_entertain
WHERE In_flight_Entertainment ='0'

;WITH total_rate AS 
(SELECT COUNT(In_flight_Entertainment) as totalRate, ageRange
FROM age_entertain
GROUP BY ageRange), 

fivescore AS 
(SELECT COUNT(In_flight_Entertainment) as highestRate, ageRange
FROM age_entertain
WHERE In_flight_Entertainment = '5'
GROUP BY ageRange)

SELECT ROUND(CAST(fivescore.highestRate AS float)/ CAST(total_rate.totalRate AS float),2), fivescore.ageRange
FROM total_rate
INNER JOIN 
fivescore
ON total_rate.ageRange = fivescore.ageRange

-- 25% of the working-age people rate 5-score for the entertainment service comparing to 18% in chilren and the elderly

SELECT * 
FROM age_entertain

SELECT COUNT(In_flight_Wifi_Service)
FROM age_entertain
WHERE In_flight_Wifi_Service = '1' -- 21322 people rate 1-score

SELECT ROUND(CAST(COUNT(In_flight_Wifi_Service) AS float)/21322,2) as percentage, ageRange
FROM age_entertain
WHERE In_flight_Wifi_Service = '1' 
GROUP BY ageRange

-- the majority of people who give 1 score for the WIFI service is the working-age. 

-- the relationship between distance flight and food and drink scores

SELECT * 
FROM pas_sas

UPDATE pas_sas 
SET Flight_Distance = Flight_Distance*1.60934

;WITH flight_and_food AS 
(SELECT Flight_Distance, Food_and_Drink, 
CASE 
WHEN Flight_Distance <= 800 THEN 'Short flight'
WHEN Flight_Distance > 800 AND Flight_Distance < 2200 THEN 'Medium flight'
WHEN Flight_Distance >= 2200 AND Flight_Distance <= 2600 THEN 'Long flight'
WHEN Flight_Distance > 2600 THEN 'Extra long flight'
END AS flight_classify
FROM pas_sas) 
SELECT * 
INTO flight_food
FROM flight_and_food

SELECT * 
FROM flight_food

SELECT COUNT(Food_and_Drink) as total
FROM flight_food 
WHERE Food_and_Drink = 1 -- 16051

SELECT ROUND(CAST(COUNT(Food_and_Drink) AS float)/16051,2) AS low_rate, flight_classify
FROM flight_food 
WHERE Food_and_Drink = '1'
GROUP BY flight_classify

-- the majority of people who rate the food and drink 1 score are people who have short and medium flight