/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Converting Data Types

*/

SELECT *
FROM Project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3, 4


-- Select Data that we are going to be starting with

SELECT
    Location,
    Date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM
    Project..CovidDeaths
WHERE
    continent IS NOT NULL
ORDER BY
    Location, Date;



-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

SELECT
    Location,
    Date,
    Total_Cases,
    Total_Deaths,
    (Total_Deaths / NULLIF(Total_Cases, 0)) * 100 AS DeathPercentage
FROM
    Project..CovidDeaths
WHERE
    Location LIKE '%states%'
    AND Continent IS NOT NULL
ORDER BY
    1, 2;



-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

SELECT
    Location,
    Date,
    Population,
    Total_Cases,
    (Total_Cases / NULLIF(Population, 0)) * 100 AS PercentPopulationInfected
FROM
    Project..CovidDeaths
--WHERE
--    Location LIKE '%states%'
ORDER BY
    1, 2;



-- Countries with Highest Infection Rate compared to Population

SELECT
    Location,
    Population,
    MAX(total_cases) AS HighestInfectionCount,
    MAX((total_cases * 100.0) / Population) AS PercentPopulationInfected
FROM
    Project..CovidDeaths
-- WHERE Location LIKE '%states%'  
GROUP BY
    Location, Population
ORDER BY
    PercentPopulationInfected DESC;



-- Countries with Highest Death Count per Population

WITH FilteredCovidDeaths AS (
    SELECT
        Location,
        CAST(Total_deaths AS INT) AS TotalDeathCount
    FROM
        Project..CovidDeaths
    WHERE
        continent IS NOT NULL
        -- AND Location LIKE '%states%'
)
SELECT
    Location,
    MAX(TotalDeathCount) AS TotalDeathCount
FROM
    FilteredCovidDeaths
GROUP BY
    Location
ORDER BY
    TotalDeathCount DESC;




-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

SELECT
    continent,
    MAX(CAST(Total_deaths AS INT)) AS TotalDeathCount
FROM
    Project..CovidDeaths
WHERE
    continent IS NOT NULL
--    AND location LIKE '%states%' 
GROUP BY
    continent
ORDER BY
    TotalDeathCount DESC;



-- GLOBAL NUMBERS

SELECT
    SUM(new_cases) as total_cases,
    SUM(CAST(new_deaths AS INT)) as total_deaths,
    SUM(CAST(new_deaths AS INT)) / NULLIF(SUM(new_cases), 0) * 100 AS DeathPercentage
FROM
    Project..CovidDeaths
WHERE
    continent IS NOT NULL
GROUP BY
    date
ORDER BY
    total_cases, total_deaths;



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated,
    (SUM(CONVERT(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) / dea.population) * 100 as PercentageVaccinated
FROM
    Project..CovidDeaths dea
JOIN
    Project..CovidVaccinations vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE
    dea.continent IS NOT NULL
ORDER BY
    2, 3;


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From Project..CovidDeaths dea
Join Project..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


