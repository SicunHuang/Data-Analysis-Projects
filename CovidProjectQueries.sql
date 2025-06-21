-- DATA DOWNLOADED FROM Our World in Data- Coronavirus (COVID-19) Deaths
-- DATA RANGE: 2020/02/24 to 2021/04/30


SELECT * FROM sql_profolio_project.coviddeath
WHERE continent IS NOT NULL
ORDER BY 3,4;

SELECT * FROM sql_profolio_project.covidvaccination
WHERE continent IS NOT NULL
ORDER BY 3,4;

-------------------------------------------------------------------------



-- Looking at Total Cases vs Total Deaths
-- Shows fatality rate of reported covid cases in China

SELECT 
	location, 
    date, 
    total_cases, 
    total_deaths, 
    (total_deaths/total_cases)*100 AS death_rate
FROM sql_profolio_project.coviddeath
WHERE location LIKE 'China'
ORDER BY 1,2;




-------------------------------------------------------------------------





-- Looking at Total Cases vs Population
-- Shows percentage of population got covid in China 

SELECT 
	location, 
    date, 
    total_cases, 
    total_deaths, 
    (total_cases/population)*100 AS infected_population_percentage
FROM sql_profolio_project.coviddeath
WHERE location LIKE 'China'
ORDER BY 1,2;



-------------------------------------------------------------------------






-- Looking at countries with highest infection rate compared to population

SELECT 
	location,
    population,
    MAX(total_cases) AS highest_infection_count,
    MAX((total_cases/population))*100 AS highest_infected_population_percentage
FROM sql_profolio_project.coviddeath
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY highest_infected_population_percentage DESC;


-------------------------------------------------------------------------






-- Showing countires with the highest death count (as of 2021/04/30)

SELECT 
	location,
    MAX(total_deaths) AS total_death_count
FROM sql_profolio_project.coviddeath
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC;


-------------------------------------------------------------------------





-- Showing total death count on each continent

SELECT 
	continent,
    MAX(total_deaths) AS total_death_count
FROM sql_profolio_project.coviddeath
WHERE continent IS NOT NULL 
-- Column location also includes regions such as Asia, North America that have continent as NULL
GROUP BY continent
ORDER BY total_death_count DESC;


-------------------------------------------------------------------------




-- GLOBAL NUMBERS

SELECT 
    SUM(new_cases) AS total_cases, 
    SUM(new_deaths) AS total_deaths,
    SUM(new_deaths)/SUM(new_cases)*100 AS total_death_rate
FROM sql_profolio_project.coviddeath
WHERE continent IS NOT NULL
ORDER BY 1,2;

-------------------------------------------------------------------------





-- Using WINDOW FUNCTION to calculate cumulative sum of new_vaccinations in each location

SELECT
	cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(new_vaccinations) OVER(PARTITION BY cd.location ORDER BY cd.date)
		AS cumulative_vaccination_count
FROM sql_profolio_project.coviddeath cd
JOIN sql_profolio_project.covidvaccination cv
	USING (location, date)
WHERE cd.continent IS NOT NULL;


-------------------------------------------------------------------------




-- Using CTE to show culmulative percentage of population vaccinated

WITH cte_vaccipercent AS(
SELECT
	cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(new_vaccinations) OVER(PARTITION BY cd.location ORDER BY cd.date)
		AS cumulative_vaccination_count
FROM sql_profolio_project.coviddeath cd
JOIN sql_profolio_project.covidvaccination cv
	USING (location, date)
WHERE cd.continent IS NOT NULL)
SELECT *, cumulative_vaccination_count/population*100 AS cumulative_percentage_vaccinated
FROM cte_vaccipercent;




-------------------------------------------------------------------------





-- Using TEMP TABLE to show culmulative percentage of population vaccinated

DROP TABLE IF EXISTS temp_vaccipercent;
CREATE TEMPORARY TABLE temp_vaccipercent (
continent VARCHAR(100),
location VARCHAR(100),
date datetime,
population BIGINT,
new_vaccinations INT,
cumulative_vaccination_count INT
);

INSERT INTO temp_vaccipercent
SELECT
	cd.continent,
    cd.location,
    cd.date,
    cd.population,
    cv.new_vaccinations,
    SUM(new_vaccinations) OVER(PARTITION BY cd.location ORDER BY cd.date)
		AS cumulative_vaccination_count
FROM sql_profolio_project.coviddeath cd
JOIN sql_profolio_project.covidvaccination cv
	USING (location, date)
WHERE cd.continent IS NOT NULL;

SELECT *, cumulative_vaccination_count/population*100 AS percentage_vaccinated
FROM temp_vaccipercent;



-------------------------------------------------------------------------




-- Using VIEW to show total death on each continent

DROP VIEW IF EXISTS death_each_continent;
CREATE VIEW death_each_continent AS
SELECT 
	continent,
    MAX(total_deaths) AS total_death_count
FROM sql_profolio_project.coviddeath
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_death_count DESC;

SELECT * FROM death_each_continent;

-------------------------------------------------------------------------


-- Using STORED PROCEDURE case/death/vaccination count and vacci percentage of the imputed location

DELIMITER $$

CREATE PROCEDURE location_status (
	INOUT case_count INT,
    INOUT death_count INT,
	INOUT vacci_count INT,
    INOUT vacci_percent INT,
    IN location_name VARCHAR(50)
)
BEGIN
	SELECT 
		SUM(cd.new_cases) AS total_cases,
        SUM(cd.new_deaths) AS total_deaths,
        MAX(cv.total_vaccinations) AS total_vaccinations,
        (MAX(cv.total_vaccinations)/cd.population)*100 AS vacci_percent
    FROM sql_profolio_project.coviddeath cd
    JOIN sql_profolio_project.covidvaccination cv
		USING (location,date)
	WHERE cd.continent IS NOT NULL AND location_name = cd.location
	GROUP BY cd.location,cd.population;
END $$

DELIMITER ;

CALL location_status(@total_cases,@total_deaths,@total_vaccinations,@vacci_percent,'China');
    

