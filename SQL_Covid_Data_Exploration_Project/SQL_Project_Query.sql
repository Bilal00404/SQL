SELECT * 
FROM PortfolioProjects.dbo.CovidDeaths$
order by 3,4


SELECT * 
FROM PortfolioProjects..CovidVaccinations$
order by 3,4


SELECT location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProjects..CovidDeaths$
ORDER BY 1,2


-- Total Deaths vs Total Cases
SELECT location,date,total_cases,total_deaths, 
	(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProjects..CovidDeaths$
ORDER BY 1,2


-- Total Deaths vs Total Cases in Pakistan
-- This shows the likelihood of dying if you contact Covid in Pakistan
SELECT location,date,total_cases,total_deaths, 
	(total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProjects..CovidDeaths$
WHERE location LIKE 'Pak%'
ORDER BY 2,3


-- Total cases vs Population
-- This shows that what percentage of population got covid
SELECT location,date,total_cases, population, 
	(total_cases/population)*100 AS 'PercentagePopulationInfected'
FROM PortfolioProjects..CovidDeaths$
WHERE location LIKE 'Pak%'
ORDER BY 2,3


-- The countries with highest infection rate compared to population
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, 
	MAX((total_cases/population))*100 AS 'PercentagePopulationInfected'
FROM PortfolioProjects..CovidDeaths$
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC


-- Countries with highest death count per population
SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount 
FROM PortfolioProjects..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC


-- Globaly total death percentage of people due to Covid datewise
SELECT date, SUM(new_cases) AS total_cases, SUM(cast(total_deaths AS int)) AS total_deaths, 
	ROUND((SUM(cast(total_deaths AS int))/SUM(new_cases))*100,2) AS GlobalDeathPercentage
FROM PortfolioProjects..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1


-- Globaly total death percentage of people due to Covid 
SELECT SUM(new_cases) AS total_cases, SUM(cast(total_deaths AS bigint)) AS total_deaths, 
	ROUND((SUM(cast(total_deaths AS bigint))/SUM(new_cases))*100,2) AS GlobalDeathPercentage
FROM PortfolioProjects..CovidDeaths$
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1,2


--  On which date we had the highest number of covid cases worldwide
SELECT date, SUM(new_cases) AS total_cases
FROM PortfolioProjects..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 2 DESC


--  On which date we had the highest number of covid deaths worldwide
SELECT date, SUM(CONVERT(INT,total_deaths)) AS total_deaths
FROM PortfolioProjects..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 2 DESC


--Total number of covid cases per continent
WITH country_cases (Contitnent, Country,Total_Cases_Country,Total_Population_Country)
AS
(
SELECT continent,location,MAX(CAST(total_cases AS BIGINT)) AS Total_Cases_Country,MAX(CAST(population AS BIGINT)) AS Total_Population_Country
FROM PortfolioProjects..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, continent
--ORDER BY 3 DESC
)
SELECT Contitnent,SUM(Total_Cases_Country) AS Total_Cases_Continent
FROM country_cases 
GROUP BY Contitnent
ORDER BY 2 DESC


--Total number of covid deaths per continent
DROP TABLE IF EXISTS #Country_Death
CREATE TABLE #Country_Death
(
Continent VARCHAR(255),
Country VARCHAR(255),
Deaths NUMERIC
)
INSERT INTO #Country_Death
SELECT continent,location, MAX(cast(total_deaths as int)) AS TotalDeathCount 
FROM PortfolioProjects..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, continent

	SELECT Continent, SUM(Deaths) AS Total_Deaths_Per_Continent
	FROM #Country_Death
	GROUP BY Continent
	ORDER BY 2 DESC


--which continent has the highest death ratio
DROP VIEW IF EXISTS Death_Ratio
CREATE VIEW Death_Ratio AS
SELECT continent,location,MAX(total_cases) AS Total_Cases,MAX(CONVERT(INT,total_deaths)) AS Total_Deaths, 
	(MAX(CONVERT(INT,total_deaths))/MAX(total_cases))*100 AS DeathPercentage
FROM PortfolioProjects..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, continent
--
SELECT continent AS Continent, SUM(Total_Cases) AS Cases, SUM(Total_Deaths) AS Deaths,  SUM(Total_Deaths)/SUM(Total_Cases) AS 'Death Percentage'
FROM Death_Ratio
GROUP BY continent
ORDER BY 4 DESC


-- The continent with highest infection rate compared to population
WITH Infection_Rate (Continent, Country, Population, Infection_Count, Percent_Infected)
AS
(
SELECT continent,location, population, MAX(total_cases) AS HighestInfectionCount, 
	MAX((total_cases/population))*100 AS 'PercentagePopulationInfected'
FROM PortfolioProjects..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location, population, continent
--ORDER BY PercentagePopulationInfected DESC
)
SELECT Continent, SUM(Population) AS Population, SUM(Infection_Count) AS Infection_Count, (SUM(Infection_Count)/SUM(Population))*100 AS Percent_Infected
FROM Infection_Rate
GROUP BY Continent
ORDER BY Percent_Infected DESC



-- Joining Tables

-- Total population vs vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER 
	(PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS RollingPeopleVaccinated
FROM PortfolioProjects..CovidDeaths$ AS dea
JOIN PortfolioProjects.dbo.CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2,3


-- USE CTE
WITH PopVsVac (continet, location, date, population, new_vaccination, RollingPeopleVaccinated) 
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER 
	(PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS RollingPeopleVaccinated
FROM PortfolioProjects..CovidDeaths$ AS dea
JOIN PortfolioProjects.dbo.CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100 
FROM PopVsVac


-- USE TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
RollingPeopleVaccinated NUMERIC
)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER 
	(PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS RollingPeopleVaccinated
FROM PortfolioProjects..CovidDeaths$ AS dea
JOIN PortfolioProjects.dbo.CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100 
FROM #PercentPopulationVaccinated


-- CREATE VIEW

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER 
	(PARTITION BY dea.location ORDER BY dea.location, dea.date)
	AS RollingPeopleVaccinated
FROM PortfolioProjects..CovidDeaths$ AS dea
JOIN PortfolioProjects.dbo.CovidVaccinations$ AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2,3

SELECT * 
FROM PercentPopulationVaccinated
