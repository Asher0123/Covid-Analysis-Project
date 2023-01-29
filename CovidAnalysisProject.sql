SELECT * FROM CovidAnalysis..CovidDeaths$
WHERE continent is not NULL
ORDER BY 3,4


SELECT * FROM CovidAnalysis..CovidVaccinations$
WHERE continent is not NULL
ORDER BY 3,4

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidAnalysis..CovidDeaths$
ORDER BY 1,2


--Chances of dying from covid
SELECT location, date, total_cases, new_cases, total_deaths, (total_deaths/total_cases)*100 as  Death_Pctg
FROM CovidAnalysis..CovidDeaths$
ORDER BY 1,2

--Chances of getting infected from covid
SELECT location, date, total_cases, new_cases,  population,(total_cases/population)*100 as  Infection_Pctg
FROM CovidAnalysis..CovidDeaths$
ORDER BY 1,2


--Grouping by population and country to get better understanding of  Percentage of population infected by covid

SELECT location, population, MAX(total_cases) as MaxCases, MAX((total_cases/population))*100 as  Infection_Pctg
FROM CovidAnalysis..CovidDeaths$
WHERE continent is not NULL
GROUP BY location,population
ORDER BY Infection_Pctg DESC

--Grouping by Maximum Total Deaths of each country

SELECT continent,location, MAX(cast(total_deaths as int)) as TotalDeaths,MAX(population) as Population
FROM CovidAnalysis..CovidDeaths$
WHERE continent is not NULL --and continent='North America'
GROUP BY location,continent
ORDER BY TotalDeaths DESC

--Grouping by Maximum Total Deaths of each continent

SELECT location, MAX(cast(total_deaths as int)) as TotalDeaths
FROM CovidAnalysis..CovidDeaths$
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeaths DESC



--Total Cases and Deaths due to covid on each day from 1/1/20 till 21/1/23

SELECT date,  SUM(new_cases) as TotalCases, SUM(cast(new_deaths  as int)) as TotalDeaths,(SUM(cast(new_deaths  as int)) /SUM(new_cases))*100 as  Death_Pctg
FROM CovidAnalysis..CovidDeaths$
WHERE continent is not null 
GROUP BY date
ORDER BY 1,2 


--Total Cases and Deaths due to covid in the world and the Percentage of deaths 

SELECT SUM(new_cases) as TotalCases, SUM(cast(new_deaths  as int)) as TotalDeaths,(SUM(cast(new_deaths  as int)) /SUM(new_cases))*100 as  Death_Pctg
FROM CovidAnalysis..CovidDeaths$
WHERE continent is not null
ORDER BY 1,2 

--Joining the Covid Vaccination table and Covid deaths table based on location and date
SELECT cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations,
SUM(CONVERT(bigint,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.Date) as TotalVaccination
FROM CovidAnalysis..CovidDeaths$ cd -- cd=CovidDeaths
JOIN CovidAnalysis..CovidVaccinations$ cv --cv=CovidVaccinations
	ON cd.location=cv.location and cd.date=cv.date
WHERE cd.continent is NOT NULL
ORDER BY 2,3


--Using CTE
WITH PeopleVaccinated(Continent,location,date, population,new_vaccinations, TotalVaccination)
AS (
SELECT cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations,
SUM(CONVERT(bigint,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.Date) as TotalVaccination
FROM CovidAnalysis..CovidDeaths$ cd -- cd=CovidDeaths
JOIN CovidAnalysis..CovidVaccinations$ cv --cv=CovidVaccinations
	ON cd.location=cv.location and cd.date=cv.date
WHERE cd.continent is NOT NULL
)

SELECT *, (TotalVaccination/population)*100 as Vaccinated_Pctg FROM PeopleVaccinated


--Temp Table

DROP Table if exists #PercentagePeopleVaccinated
CREATE Table #PercentagePeopleVaccinated ( 
Continent nvarchar(255),
location nvarchar(255),
date Datetime, 
population numeric,
new_vaccinations numeric, 
TotalVaccination numeric
)

INSERT INTO #PercentagePeopleVaccinated
SELECT cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations,
SUM(CONVERT(bigint,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.Date) as TotalVaccination
FROM CovidAnalysis..CovidDeaths$ cd -- cd=CovidDeaths
JOIN CovidAnalysis..CovidVaccinations$ cv --cv=CovidVaccinations
	ON cd.location=cv.location and cd.date=cv.date
WHERE cd.continent is NOT NULL

--Percentage of Population Vaccinated 
SELECT location,MAX(population) as Population,MAX(TotalVaccination) as VaccinationTotal, (MAX(TotalVaccination)/MAX(population))*100 as Vaccinated_Pctg FROM #PercentagePeopleVaccinated
GROUP BY location
ORDER BY 1,2

--Creating View to be used for Visualization later
GO
CREATE VIEW
PercentagePeopleVaccinated as
SELECT cd.continent,cd.location,cd.date,cd.population,cv.new_vaccinations,
SUM(CONVERT(bigint,cv.new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.Date) as TotalVaccination
FROM CovidAnalysis..CovidDeaths$ cd -- cd=CovidDeaths
JOIN CovidAnalysis..CovidVaccinations$ cv --cv=CovidVaccinations
	ON cd.location=cv.location and cd.date=cv.date
WHERE cd.continent is NOT NULL	


--Creating Queries for Tableau Visualization
--1

WITH GlobalNumbers(location, new_cases,total_deaths,population)
AS (
SELECT location, SUM(new_cases) as Total_Cases,MAX(cast(total_deaths as int)) as Total_Deaths,SUM(population) OVER (PARTITION BY location) as GlobalPopulation 
FROM CovidAnalysis..CovidDeaths$
WHERE continent is NULL and location not in ('World', 'European Union', 'International','High income','Upper middle income','Lower middle income','Low income')
GROUP BY location,population
)
--ORDER BY TotalDeaths DESC

SELECT SUM(Population) as GlobalPopulation, SUM(new_Cases) as TotalCases,SUM(total_Deaths) as TotalDeaths, (SUM(Total_Deaths)/SUM(new_Cases))*100 as  Death_Pctg
FROM GlobalNumbers
--GROUP BY location,population
--ORDER BY 1,2

--2
SELECT location, SUM(cast(new_deaths as int)) as TotalDeaths, 
FROM CovidAnalysis..CovidDeaths$
WHERE continent is null and location not in ('World', 'European Union', 'International','High income','Upper middle income','Lower middle income','Low income')
GROUP BY location
ORDER BY TotalDeaths DESC

--3
SELECT location, population, MAX(total_cases) as MaxCases, MAX((total_cases/population))*100 as  Infection_Pctg
FROM CovidAnalysis..CovidDeaths$
WHERE continent is not NULL
GROUP BY location,population
ORDER BY Infection_Pctg DESC


--4
SELECT location, population, date,MAX(total_cases) as MaxCases, MAX((total_cases/population))*100 as  Infection_Pctg
FROM CovidAnalysis..CovidDeaths$
WHERE continent is not NULL
GROUP BY location,population,date
ORDER BY Infection_Pctg DESC