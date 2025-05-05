create database PortfolioProject1;
use PortfolioProject1;

-- Note: Some of the data here are including continents e.g, Asia, Africa etc when that
-- is not necessary when you have the countries. In order to remove that unnecessary
-- data, we have to exclude the part of the Continent column that is null because it being
-- null means that the continent is being passed as a location - not a country.
-- However. If the data is just blank (not NULL, just empty) then you can use <> ''
SELECT *
FROM portfolioproject1.coviddeathdata
WHERE continent is NOT NULL
ORDER BY 3, 4;

SELECT *
FROM portfolioproject1.covidvaccinationsdata
ORDER BY 3, 4;

-- Select the data you are using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM portfolioproject1.coviddeathdata
WHERE continent <> ''
ORDER BY 1, 2;

-- Looking at Total Cases VS Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as
DeathPercentage
FROM portfolioproject1.coviddeathdata
WHERE continent <> ''
ORDER BY 1, 2;

-- Shows the likelihood of dying if you contract Covid in your country
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as
DeathPercentage
FROM portfolioproject1.coviddeathdata
WHERE location = 'Nigeria' AND continent <> ''
ORDER BY 1, 2;

-- Looking at Total Cases VS Population
SELECT location, date, population, total_cases, (total_cases/population)*100 as
CasePercentage
FROM portfolioproject1.coviddeathdata
ORDER BY 1, 2;

-- Shows reported cases of Covid in your country per the population
SELECT location, date, population, total_cases, (total_cases/population)*100 as
PercentPopulationInfected
FROM portfolioproject1.coviddeathdata
WHERE location = 'Nigeria'
ORDER BY 1, 2;

-- Looking at countries with Highest Infection Rate compared to Population
SELECT location, population, MAX(total_cases) as TotalInfectionCount, 
MAX((total_cases/population))*100 as PercentPopulationInfected
FROM portfolioproject1.coviddeathdata
GROUP BY location, population
ORDER BY PercentPopulationInfected DESC;

-- Showing countries with the Highest Death Count per Population
-- Note: I didn't have this problem but just for knowledge sake - this is how you
-- can cast your column data to int: MAX(cast (total_deaths as int))
SELECT location, population, MAX(total_deaths) as TotalDeathCount
FROM portfolioproject1.coviddeathdata
WHERE continent <> ''
GROUP BY location, population
ORDER BY TotalDeathCount DESC;


-- LET'S BREAK THINGS DOWN BY CONTINENT

-- So, apparently, the reason why it is being queried this way and not just through selecting
-- from Continent is because it missed out some numbers. As earlier stated, when Continent
-- was blank, Location was filled with the continents. Therefore, we are going to select
-- from Location while Continent was blank to get the true numbers. So these are the correct
-- numbers but for explanation and time sake (our tutor just figured it out), we will go
-- with the former selection
SELECT location, MAX(total_deaths) as TotalDeathCount
FROM portfolioproject1.coviddeathdata
WHERE continent = ''
GROUP BY location
ORDER BY TotalDeathCount DESC;

-- Former Selection
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM portfolioproject1.coviddeathdata
WHERE continent <> ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Showing continents with the Highest Death Count per Population
SELECT continent, MAX(total_deaths) as TotalDeathCount
FROM portfolioproject1.coviddeathdata
WHERE continent <> ''
GROUP BY continent
ORDER BY TotalDeathCount DESC;


-- GLOBAL NUMBERS (per day)
SELECT date, SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths,
(SUM(new_deaths)/SUM(new_cases))*100
as DeathPercentage
FROM portfolioproject1.coviddeathdata
WHERE continent <> ''
GROUP BY date
ORDER BY 1, 2;

-- GLOBAL NUMBERS
SELECT SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths,
(SUM(new_deaths)/SUM(new_cases))*100
as DeathPercentage
FROM portfolioproject1.coviddeathdata
WHERE continent <> ''
-- GROUP BY date
ORDER BY 1, 2;


-- Looking at Total Population VS Vaccinations
SELECT *
FROM portfolioproject1.coviddeathdata as dea
JOIN portfolioproject1.covidvaccinationsdata as vac
	ON dea.location = vac.location AND
    dea.date = vac.date;

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as
RollingPeopleVaccinated
FROM portfolioproject1.coviddeathdata as dea
JOIN portfolioproject1.covidvaccinationsdata as vac
	ON dea.location = vac.location AND
    dea.date = vac.date
WHERE dea.continent <> ''
ORDER BY 2, 3;


-- Now, we want to get the ratio of people vaccinated to the population (you can't use
-- (RollingPeopleVaccinated/dea.population)* 100 as VaccinatedPopulation) and there are two ways
-- that can happen:

-- USE CTE
WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, RollingPeopleVaccinated) 
as
(SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as
RollingPeopleVaccinated
FROM portfolioproject1.coviddeathdata as dea
JOIN portfolioproject1.covidvaccinationsdata as vac
	ON dea.location = vac.location AND
    dea.date = vac.date
WHERE dea.continent is NOT NULL AND dea.continent <> ''
-- order by 2, 3
)
SELECT *, (RollingPeopleVaccinated/Population)* 100
FROM PopvsVac;


-- TEMP TABLE
drop table if exists PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated (
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
); 

INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as
RollingPeopleVaccinated
FROM portfolioproject1.coviddeathdata as dea
JOIN portfolioproject1.covidvaccinationsdata as vac
	ON dea.location = vac.location AND
    dea.date = vac.date
WHERE dea.continent is NOT NULL AND dea.continent <> '';
-- order by 2, 3

SELECT *, (RollingPeopleVaccinated/Population)* 100
FROM PercentPopulationVaccinated;


-- Creating views to store data for later visulaizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as
RollingPeopleVaccinated
FROM portfolioproject1.coviddeathdata as dea
JOIN portfolioproject1.covidvaccinationsdata as vac
	ON dea.location = vac.location AND
    dea.date = vac.date
WHERE dea.continent is NOT NULL AND dea.continent <> '';
-- order by 2, 3

SELECT * 
FROM PercentPopulationVaccinated;




