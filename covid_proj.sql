USE PortfolioProject;
 


SELECT location, 
	   date_2, 
       total_cases, 
       new_cases, 
       total_deaths, 
       population
FROM cd
WHERE location IS NOT NULL
ORDER BY location, date_2;





-- Looking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT location, 
	   date, 
       total_cases,  
       total_deaths,
       (total_deaths/total_cases)*100 AS DeathPercentage
FROM cd
WHERE location IS NOT NULL 
	AND total_deaths IS NOT NULL 
    AND location LIKE '%states%'
ORDER BY location, total_cases, date;



-- find out how to change date format
-- use date_2 going forward

ALTER TABLE cd
ADD test_d varchar(255);


UPDATE cd
SET test_d = date;

UPDATE cd
SET test_d = DATE_FORMAT(STR_TO_DATE(test_d,'%m/%d/%Y'), '%Y-%m-%d');

ALTER TABLE cd
MODIFY COLUMN test_d TEXT;

ALTER TABLE cd
RENAME COLUMN test_d TO date_2;

/*
ALTER TABLE cd
DROP COLUMN test_d;
*/


-- Looking at Total cases vs Population
-- Shows what percentage of population got covid

SELECT location, 
	   date,
       population,
       total_cases,  
       (total_cases/population)*100 AS Percent_Population_Infected
FROM cd
WHERE location IS NOT NULL 
      -- AND location LIKE '%states%'
ORDER BY location, total_cases, date;


-- Looking at countries with Highest Infection Rate compared to Population
SELECT location, 
       population,
       MAX(total_cases) AS Highest_Infection_Count,  
       MAX((total_cases/population))*100 AS Percent_Population_Infected
FROM cd
WHERE location IS NOT NULL 
      -- AND location LIKE '%states%'
GROUP BY location, population
ORDER BY Percent_Population_Infected DESC;



-- Showing Countries with Highest Death Count per Population

SELECT location, MAX(total_deaths) AS Total_Death_Count
FROM cd
WHERE location IS NOT NULL
      AND continent IS NOT NULL
GROUP BY location
ORDER BY Total_Death_Count DESC;





-- break things down by continent

/*
SELECT continent, MAX(total_deaths) AS Total_Death_Count
FROM cd
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY Total_Death_Count DESC;
*/

SELECT location, MAX(total_deaths) AS Total_Death_Count
FROM cd
WHERE continent IS NULL
GROUP BY location
ORDER BY Total_Death_Count DESC;



-- GLOBAL NUMBERS

SELECT date_2, 
       SUM(new_cases) AS total_cases,
       SUM(new_deaths) AS total_deaths,
       SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM cd
WHERE continent IS NOT NULL 
GROUP BY date_2
ORDER BY date_2;

SELECT SUM(new_cases) AS total_cases,
       SUM(new_deaths) AS total_deaths,
       SUM(new_deaths)/SUM(new_cases)*100 AS DeathPercentage
FROM cd
WHERE continent IS NOT NULL;



-- Join covid deaths and vaccinations
-- Looking at Total Population vs Vaccinations

SELECT cd.continent, 
       cd.location, 
       cd.date_2, 
       cd.population,
       cv.new_vaccinations,
       SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date_2) AS Rolling_People_Vaccinated
FROM cd
INNER JOIN cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
ORDER BY cd.location, cd.date_2;


-- USE CTE (Common Table Expression)

WITH Pop_vs_Vac (Continent, Location, Date, Population, New_Vaccinations, Rolling_People_Vaccinated)
AS 
(
SELECT cd.continent, 
       cd.location, 
       cd.date_2, 
       cd.population,
       cv.new_vaccinations,
       SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date_2) AS Rolling_People_Vaccinated
FROM cd
INNER JOIN cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL
-- ORDER BY cd.location, cd.date_2
)
SELECT *, (Rolling_People_Vaccinated/Population)*100 AS Percent_Vaccinated
FROM Pop_vs_Vac;


-- Temp Table

DROP TABLE IF EXISTS Percent_Population_Vaccinated;

CREATE TEMPORARY TABLE Percent_Population_Vaccinated 
(
Continent TEXT,
Location TEXT,
Date_2 TEXT,
Population BIGINT,
New_vaccinations BIGINT,
Rolling_People_Vaccinated BIGINT
);

INSERT INTO Percent_Population_Vaccinated 
SELECT cd.continent, 
       cd.location, 
       cd.date_2, 
       cd.population,
       cv.new_vaccinations,
       SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date_2) AS Rolling_People_Vaccinated
FROM cd
INNER JOIN cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;
-- ORDER BY cd.location, cd.date_2

SELECT *, (Rolling_People_Vaccinated/Population)*100 AS Percent_Vaccinated
FROM Percent_Population_Vaccinated;




-- Creating View to store date for later visualizations

CREATE VIEW Percent_Population_Vaccinated AS
SELECT cd.continent, 
       cd.location, 
       cd.date_2, 
       cd.population,
       cv.new_vaccinations,
       SUM(cv.new_vaccinations) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date_2) AS Rolling_People_Vaccinated
FROM cd
INNER JOIN cv
	ON cd.location = cv.location
	AND cd.date = cv.date
WHERE cd.continent IS NOT NULL;
-- ORDER BY cd.location, cd.date_2;

SELECT *
FROM Percent_Population_Vaccinated;