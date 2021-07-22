1) -- Numbering rows--- 

SELECT
  *,
  -- Assign numbers to each row
  ROW_NUMBER () OVER () AS Row_N
FROM summerolympics
ORDER BY Row_N ASC;

2) --Numbering Olympic games in ascending order : query the table to see in which year the 13th Summer Olympics were held? --
SELECT
  Year, ROW_NUMBER() OVER () AS Row_N
FROM (
  SELECT DISTINCT Year
  FROM summerolympics
  ORDER BY Year ASC
) AS Years
ORDER BY Year ASC;

3) -- Numbering Olympic games in descending order : reverse the row numbers so that the most recent Olympic games' rows have a lower number?--

SELECT
  Year, ROW_NUMBER() OVER (ORDER BY Year DESC) AS Row_N
FROM (
  SELECT DISTINCT Year
  FROM summerolympics
) AS Years
ORDER BY Year;

4) --Numbering Olympic athletes by medals earned: --
WITH Athlete_Medals AS (
  SELECT
    -- Count the number of medals each athlete has earned
    Athlete,
    COUNT(*) AS Medals
  FROM summerolympics
  GROUP BY Athlete)

SELECT
  -- Number each athlete by how many medals they've earned
  Athlete,
  ROW_NUMBER() OVER (ORDER BY medals DESC) AS Row_N
FROM Athlete_Medals
ORDER BY Medals DESC;

5) --Reigning weightlifting champions --
WITH Weightlifting_Gold AS (
  SELECT
    -- Return each year's champions' countries
    Year,
    Country AS champion
  FROM summerolympics
  WHERE
    Discipline = 'Weightlifting' AND
    Event = '69KG' AND
    Gender = 'Men' AND
    Medal = 'Gold')

SELECT
  Year, Champion,
  -- Fetch the previous year's champion
  LAG(Champion,1) OVER
    (ORDER BY year ASC) AS Last_Champion
FROM Weightlifting_Gold
ORDER BY Year ASC;

6) --Reigning champions by gender :fetched the previous year's champion based on multiple events, genders, or other metrics as columns---
-- split table into partitions to avoid having a champion from one event or gender appear as the previous champion of another event or gender.-- 

WITH Tennis_Gold AS (
  SELECT DISTINCT
    Gender, Year, Country
  FROM summerolympics
  WHERE
    Year >= 2000 AND
    Event = 'Javelin Throw' AND
    Medal = 'Gold')

SELECT
  Gender, Year,
  Country AS Champion,
  -- Fetch the previous year's champion by gender
  LAG(Country) OVER (PARTITION BY Gender
                         ORDER BY Year ASC) AS Last_Champion
FROM Tennis_Gold
ORDER BY Gender ASC, Year ASC;


7) --Reigning champions by gender and event--

WITH Athletics_Gold AS (
  SELECT DISTINCT
    Gender, Year, Event, Country
  FROM summerolympics
  WHERE
    Year >= 2000 AND
    Discipline = 'Athletics' AND
    Event IN ('100M', '10000M') AND
    Medal = 'Gold')

SELECT
  Gender, Year, Event,
  Country AS Champion,
  -- Fetch the previous year's champion by gender and event
  LAG(Country) OVER (PARTITION BY Gender, Event
                         ORDER BY Year ASC) AS Last_Champion
FROM Athletics_Gold
ORDER BY Event ASC, Gender ASC, Year ASC;


8) --Future gold medalists :For each year, fetch the current gold medalist and the gold medalist 3 competitions ahead of the current row.--
WITH Discus_Medalists AS (
  SELECT DISTINCT
    Year,
    Athlete
  FROM summerolympics
  WHERE Medal = 'Gold'
    AND Event = 'Discus Throw'
    AND Gender = 'Women'
    AND Year >= 2000)

SELECT
  -- For each year, fetch the current and future medalists
  Year,
  Athlete,
  LEAD(Athlete, 3) OVER (ORDER BY Year ASC) AS Future_Champion
FROM Discus_Medalists
ORDER BY Year ASC;

9) -- First athlete by name : Return all athletes and the first athlete ordered by alphabetical order -- 

WITH All_Male_Medalists AS (
  SELECT DISTINCT
    Athlete
  FROM summerolympics
  WHERE Medal = 'Gold'
    AND Gender = 'Men')

SELECT
  -- Fetch all athletes and the first athlete alphabetically
  Athlete,
  FIRST_VALUE(Athlete) OVER (
    ORDER BY Athlete ASC
  ) AS First_Athlete
FROM All_Male_Medalists;

10) --Last country by name : Return the year and the city in which each Olympic games were held.
-- Fetch the last city in which the Olympic games were held --

WITH Hosts AS (
  SELECT DISTINCT Year, City
    FROM summerolympics)

SELECT
  Year,
  City,
  -- Get the last city in which the Olympic games were held
  LAST_VALUE(City) OVER (
   ORDER BY Year ASC
   RANGE BETWEEN
     UNBOUNDED PRECEDING AND
     UNBOUNDED FOLLOWING
  ) AS Last_City
FROM Hosts
ORDER BY Year ASC;


11) -- Ranking athletes by medals earned : Rank each athlete by the number of medals they've earned -- the higher the count, the higher the rank -- with identical numbers in case of identical values--.


WITH Athlete_Medals AS (
  SELECT
    Athlete,
    COUNT(*) AS Medals
  FROM summerolympics
  GROUP BY Athlete)

SELECT
  Athlete,
  Medals,
  -- Rank athletes by the medals they've won
  RANK() OVER (ORDER BY Medals DESC) AS Rank_N
FROM Athlete_Medals
ORDER BY Medals DESC;

12) --Ranking athletes from multiple countries : Rank each country's athletes by the count of medals they've earned -- 
--the higher the count, the higher the rank -- without skipping numbers in case of identical values.--


WITH Athlete_Medals AS (
  SELECT
    Country, Athlete, COUNT(*) AS Medals
  FROM summerolympics
  WHERE
    Country IN ('JPN', 'KOR')
    AND Year >= 2000
  GROUP BY Country, Athlete
  HAVING COUNT(*) > 1)

SELECT
  Country,
  -- Rank athletes in each country by the medals they've won
  Athlete,
  DENSE_RANK() OVER (PARTITION BY Country
                         ORDER BY Medals DESC) AS Rank_N
FROM Athlete_Medals
ORDER BY Country ASC, RANK_N ASC;

13) --Paging events: Split the distinct events into exactly 111 groups, ordered by event in alphabetical order.--
WITH Events AS (
  SELECT DISTINCT Event
  FROM summerolympics)
  
SELECT
  --- Split up the distinct events into 111 unique groups
  Event,
  NTILE(111) OVER (ORDER BY Event ASC) AS Page
FROM Events
ORDER BY Event ASC;

14) --Top, middle, and bottom thirds : Split the athletes into top, middle, and bottom thirds based on their count of medals and Return the average of each third.--

WITH Athlete_Medals AS (
  SELECT Athlete, COUNT(*) AS Medals
  FROM summerolympics
  GROUP BY Athlete
  HAVING COUNT(*) > 1)
  
SELECT
  Athlete,
  Medals,
  -- Split athletes into thirds by their earned medals
  NTILE (3) OVER (ORDER BY Medals DESC) AS Third
FROM Athlete_Medals
ORDER BY Medals DESC, Athlete ASC;


WITH Athlete_Medals AS (
  SELECT Athlete, COUNT(*) AS Medals
  FROM summerolympics
  GROUP BY Athlete
  HAVING COUNT(*) > 1),
  
  Thirds AS (
  SELECT
    Athlete,
    Medals,
    NTILE(3) OVER (ORDER BY Medals DESC) AS Third
  FROM Athlete_Medals)
  
SELECT
  -- Get the average medals earned in each third
  third,
  AVG(Medals) AS Avg_Medals
FROM Thirds
GROUP BY Third
ORDER BY Third ASC;


-------------------------------------------------Aggregate window functions and frames--------------------------------------

15) --Running totals of athlete medals :Return the athletes, the number of medals they earned, and the medals running total, ordered by the athletes' names in alphabetical order.-- 

WITH Athlete_Medals AS (
  SELECT
    Athlete, COUNT(*) AS Medals
  FROM summerolympics
  WHERE
    Country = 'USA' AND Medal = 'Gold'
    AND Year >= 2000
  GROUP BY Athlete)

SELECT
  -- Calculate the running total of athlete medals
  Athlete,
  Medals,
  SUM(Medals) OVER (ORDER BY Athlete ASC) AS Max_Medals
FROM Athlete_Medals
ORDER BY Athlete ASC;


16) --Maximum country medals by year : Return the year, country, medals, and the maximum medals earned so far for each country, ordered by year in ascending order.--

WITH Country_Medals AS (
  SELECT
    Year, Country, COUNT(*) AS Medals
  FROM summerolympics
  WHERE
    Country IN ('CHN', 'KOR', 'JPN')
    AND Medal = 'Gold' AND Year >= 2000
  GROUP BY Year, Country)

SELECT
  -- Return the max medals earned so far per country
  Country,
  Year,
  Medals,
  MAX(Medals) OVER (PARTITION BY Country
                        ORDER BY Year ASC) AS Max_Medals
FROM Country_Medals
ORDER BY Country ASC, Year ASC;

17) --Minimum country medals by year: Return the year, medals earned, and minimum medals earned so far.--

WITH France_Medals AS (
  SELECT
    Year, COUNT(*) AS Medals
  FROM summerolympics
  WHERE
    Country = 'FRA'
    AND Medal = 'Gold' AND Year >= 2000
  GROUP BY Year)

SELECT
  Year,
  Medals,
  MIN(Medals) OVER (ORDER BY Year ASC) AS Min_Medals
FROM France_Medals
ORDER BY Year ASC;


18 )--Moving maximum of Scandinavian athletes' medals: Return the year, medals earned, and the maximum medals earned, comparing only the current year and the next year.--

WITH Scandinavian_Medals AS (
  SELECT
    Year, COUNT(*) AS Medals
  FROM summerolympics
  WHERE
    Country IN ('DEN', 'NOR', 'FIN', 'SWE', 'ISL')
    AND Medal = 'Gold'
  GROUP BY Year)

SELECT
  -- Select each year's medals
  Year,
  Medals,
  -- Get the max of the current and next years'  medals
  MAX(Medals) OVER (ORDER BY Year ASC
                    ROWS BETWEEN CURRENT ROW
                    AND 1 FOLLOWING) AS Max_Medals
FROM Scandinavian_Medals
ORDER BY Year ASC;


19) --Moving maximum of Chinese athletes' medals: Return the athletes, medals earned, and the maximum medals earned, comparing only the last two and current athletes, ordering by athletes' names in alphabetical order.--

WITH Chinese_Medals AS (
  SELECT
    Athlete, COUNT(*) AS Medals
  FROM summerolympics
  WHERE
    Country = 'CHN' AND Medal = 'Gold'
    AND Year >= 2000
  GROUP BY Athlete)

SELECT
  -- Select the athletes and the medals they've earned
  Athlete,
  Medals,
  -- Get the max of the last two and current rows' medals 
  MAX(Medals) OVER (ORDER BY Athlete ASC
                    ROWS BETWEEN 2 PRECEDING
                    AND CURRENT ROW) AS Max_Medals
FROM Chinese_Medals
ORDER BY Athlete ASC;


20 ) --Moving average of Russian medals: Calculate the 3-year moving average of medals earned.--

WITH Russian_Medals AS (
  SELECT
    Year, COUNT(*) AS Medals
  FROM summerolympics
  WHERE
    Country = 'RUS'
    AND Medal = 'Gold'
    AND Year >= 1980
  GROUP BY Year)

SELECT
  Year, Medals,
  AVG(Medals) OVER
    (ORDER BY Year ASC
     ROWS BETWEEN
     2 PRECEDING AND CURRENT ROW) AS Medals_MA
FROM Russian_Medals
ORDER BY Year ASC;

21) --Moving total of countries' medals: Calculate the 3-year moving sum of medals earned per country.--

WITH Country_Medals AS (
  SELECT
    Year, Country, COUNT(*) AS Medals
  FROM summerolympics
  GROUP BY Year, Country)

SELECT
  Year, Country, Medals,
  -- Calculate each country's 3-game moving total
  SUM(Medals) OVER
    (PARTITION BY Country
     ORDER BY Year ASC
     ROWS BETWEEN
     2 PRECEDING AND CURRENT ROW) AS Medals_MA
FROM Country_Medals
ORDER BY Country ASC, Year ASC;


-----------------------------------Manipulating Windows Function---------------------------

22) --pivot Table :Create the correct extension. Fill in the column names of the pivoted table.--

-- Create the correct extention to enable CROSSTAB
CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT * FROM CROSSTAB($$
  SELECT
    Gender, Year, Country
  FROM summerolympics
  WHERE
    Year IN (2008, 2012)
    AND Medal = 'Gold'
    AND Event = 'Pole Vault'
  ORDER By Gender ASC, Year ASC;
-- Fill in the correct column names for the pivoted table
$$) AS ct (Gender VARCHAR,
           "2008" VARCHAR,
           "2012" VARCHAR)

ORDER BY Gender ASC;


23) --Pivoting with ranking: Count the gold medals that France (FRA), the UK (GBR), and Germany (GER) have earned per country and year.--

--Part A : Count the gold medals that France (FRA), the UK (GBR), and Germany (GER) have earned per country and year.--

SELECT
  Country ,
  Year,
  COUNT(*) AS Awards
FROM summerolympics
WHERE
  Country IN ('FRA', 'GBR', 'GER')
  AND Year IN (2004, 2008, 2012)
  AND Medal = 'Gold'
GROUP BY country , Year
ORDER BY Country ASC, Year ASC


--Part B : Select the country and year columns, then rank the three countries by how many gold medals they earned per year.--

WITH Country_Awards AS (
  SELECT
    Country,
    Year,
    COUNT(*) AS Awards
  FROM summerolympics
  WHERE
    Country IN ('FRA', 'GBR', 'GER')
    AND Year IN (2004, 2008, 2012)
    AND Medal = 'Gold'
  GROUP BY Country, Year)

SELECT
  Country,
  Year,
  -- Rank by gold medals earned per year
  RANK() OVER
    (PARTITION BY Year
     ORDER BY Awards DESC) :: INTEGER AS rank
FROM Country_Awards
ORDER BY Country ASC, Year ASC;

--Part C : Pivot the query's results by Year by filling in the new table's correct column names..--

CREATE EXTENSION IF NOT EXISTS tablefunc;

SELECT * FROM CROSSTAB($$
  WITH Country_Awards AS (
    SELECT
      Country,
      Year,
      COUNT(*) AS Awards
    FROM summerolympics
    WHERE
      Country IN ('FRA', 'GBR', 'GER')
      AND Year IN (2004, 2008, 2012)
      AND Medal = 'Gold'
    GROUP BY Country, Year)

  SELECT
    Country,
    Year,
    RANK() OVER
      (PARTITION BY Year
       ORDER BY Awards DESC) :: INTEGER AS rank
  FROM Country_Awards
  ORDER BY Country ASC, Year ASC;
-- Fill in the correct column names for the pivoted table
$$) AS ct (Country VARCHAR,
           "2004" INTEGER,
           "2008" INTEGER,
           "2012" INTEGER)

Order by Country ASC;

24) -- Country-level subtotals: Count the gold medals awarded per country and gender. Generate Country-level gold award counts.--

-- Count the gold medals per country and gender
SELECT
  Country,
  Gender,
  COUNT(*) AS Gold_Awards
FROM summerolympics
WHERE
  Year = 2004
  AND Medal = 'Gold'
  AND Country IN ('DEN', 'NOR', 'SWE')
-- Generate Country-level subtotals
GROUP BY Country, ROLLUP(Gender)
ORDER BY Country ASC, Gender ASC;

25) --All group-level subtotals :Count the medals awarded per gender and medal type.  Generate all possible group-level counts (per gender and medal type subtotals and the grand total).--

-- Count the medals per country and medal type
SELECT
  Gender,
  Medal,
  COUNT(*) AS Awards
FROM summerolympics
WHERE
  Year = 2012
  AND Country = 'RUS'
-- Get all possible group-level subtotals
GROUP BY CUBE(Gender, Medal)
ORDER BY Gender ASC, Medal ASC;
--