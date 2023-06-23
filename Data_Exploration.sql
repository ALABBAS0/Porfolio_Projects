SELECT
	*
FROM
	PortfolioProject..CovidDeaths$
WHERE
	continent IS NOT NULL
ORDER BY
	3, 4

-- Total cases vs population
-- Shows percentage of population infected

SELECT
   location,
   date,
   total_cases,
   population,
   (total_cases / population) * 100 AS Infection_Percentage
FROM
   PortfolioProject..CovidDeaths$
WHERE
   continent IS NOT NULL
ORDER BY
   1, 2


-- Total cases vs total deaths
-- Shows the likelihood of death FROM Covid-19 in Jordan

SELECT
   location,
   date,
   total_cases,
   total_deaths,
   (total_deaths / total_cases) * 100 AS Death_Percentage
FROM
   PortfolioProject..CovidDeaths$
WHERE
   location = 'Jordan'
   AND continent IS NOT NULL
ORDER BY
   1, 2


-- Countries with highest infection rate
SELECT
   location,
   MAX(total_cases) HighestInfectionCount,
   population,
   MAX((total_cases / population)) * 100 AS Infection_Percentage
FROM
   PortfolioProject..CovidDeaths$
GROUP BY
   location,
   population
ORDER BY
   Infection_Percentage desc


-- Countries with highest deaths per population

SELECT
   location,
   MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM
   PortfolioProject..CovidDeaths$
WHERE
   continent IS NOT NULL
GROUP BY
   location
ORDER BY
   Total_Death_Count desc


-- Continents with highest deaths per population

SELECT
   continent,
   MAX(CAST(total_deaths AS INT)) AS Total_Death_Count
FROM
   PortfolioProject..CovidDeaths$
WHERE
   continent IS NOT NULL
GROUP BY
   continent
ORDER BY
   Total_Death_Count desc

--Global numbers

--Global total cases to global death percentage

SELECT
   SUM(new_cases) AS total_cases,
   SUM(CAST(new_deaths AS INT)) AS total_deaths,
   SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100 AS Death_Percentage
FROM
   PortfolioProject..CovidDeaths$
WHERE
   continent IS NOT NULL
ORDER BY
   1, 2


--Continent total cases to death percentage

SELECT
   location,
   SUM(CAST(new_deaths AS INT)) AS Total_Death_Count
FROM
   PortfolioProject..CovidDeaths$
WHERE
   continent IS NULL
   AND location NOT IN ('World', 'European Union', 'International')
GROUP BY
   location
ORDER BY
   Total_Death_Count desc


--Highest percentage of infected population per country

SELECT
   Location,
   Population,
   MAX(total_cases) AS HighestInfectionCount,
   MAX((total_cases / population)) * 100 AS Infection_Percentage
FROM
   PortfolioProject..CovidDeaths$
GROUP BY
   Location,
   Population
ORDER BY
   Infection_Percentage desc

--Highest percentage of infected population over date per country

SELECT
   Location,
   Population,
   date,
   MAX(total_cases) AS HighestInfectionCount,
   MAX((total_cases / population)) * 100 AS Infection_Percentage
FROM
   PortfolioProject..CovidDeaths$
GROUP BY
   Location,
   Population,
   date
ORDER BY
   Infection_Percentage desc

--Total population vs vaccinations

SELECT
   dea.continent,
   dea.location,
   dea.date,
   dea.population,
   vac.new_vaccinations,
   SUM(CAST(vac.new_vaccinations AS INT)) OVER (
      PARTITION BY dea.location
      ORDER BY
         dea.location,
         dea.date
   ) AS Cumulative_Vaccinations
FROM
   PortfolioProject..CovidDeaths$ dea
   JOIN PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location
   AND dea.date = vac.date
WHERE
   dea.continent IS NOT NULL
ORDER BY
   2, 3


-- Using CTE to perform Calculation on PARTITION BY in previous query

WITH Pop_vs_Vac (
   Continent,
   location,
   date,
   population,
   new_vaccinations,
   Cumulative_Vaccinations
) AS (
   SELECT
      dea.continent,
      dea.location,
      dea.date,
      dea.population,
      vac.new_vaccinations,
      SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
         PARTITION BY dea.location
         ORDER BY
            dea.location,
            dea.date
      ) AS Cumulative_Vaccinations
   FROM
      PortfolioProject..CovidDeaths$ dea
      JOIN PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location
      AND dea.date = vac.date
   WHERE
      dea.continent IS NOT NULL
)
SELECT
   *,
   (Cumulative_Vaccinations / population) * 100
FROM
   Pop_vs_Vac
ORDER BY
   2, 3


-- Using temp table to perform calculation on PARTITION BY in previous query

DROP TABLE if EXISTS #Pop_Vs_Vac CREATE TABLE #Pop_Vs_Vac (
   Continent nvarchar(255),
   Location nvarchar(255),
   date datetime,
   Population NUMERIC,
   New_vaccinations NUMERIC,
   Cumulative_Vaccinations NUMERIC
)

INSERT INTO
   #Pop_Vs_Vac
SELECT
   dea.continent,
   dea.location,
   dea.date,
   dea.population,
   vac.new_vaccinations,
   SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
      PARTITION BY dea.Location
      ORDER BY
         dea.location,
         dea.date
   ) AS Cumulative_Vaccinations
FROM
   PortfolioProject..CovidDeaths$ dea
   JOIN PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location
   AND dea.date = vac.date
WHERE
   dea.continent IS NOT NULL
SELECT
   *,
   (Cumulative_Vaccinations / Population) * 100
FROM
   #Pop_Vs_Vac
ORDER BY
   2, 3

-- Creating View to store data for later visualizations

USE PortfolioProject GO CREATE View Pop_Vs_Vac AS
SELECT
   dea.continent,
   dea.location,
   dea.date,
   dea.population,
   vac.new_vaccinations,
   SUM(CONVERT(INT, vac.new_vaccinations)) OVER (
      PARTITION BY dea.Location
      ORDER BY
         dea.location,
         dea.date
   ) AS Cumulative_Vaccinations --, (Cumulative_Vaccinations/population)*100
FROM
   PortfolioProject..CovidDeaths$ dea
   JOIN PortfolioProject..CovidVaccinations$ vac ON dea.location = vac.location
   AND dea.date = vac.date
WHERE
   dea.continent IS NOT NULL