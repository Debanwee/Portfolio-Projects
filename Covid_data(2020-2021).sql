--select * 
--from portfolioproject_Covid..Coviddeaths
--order by 3,4;
--select * 
--from portfolioproject_Covid..Covidvaccinations
--order by 3,4;


--select location, date, total_cases, new_cases, total_deaths, population
--from portfolioproject_Covid..Coviddeaths
--order by 1, 2;

--Looking at the total cases vs total deaths

select location, date, total_cases, total_deaths,
(total_deaths / total_cases) * 100 as Death_rate
from portfolioproject_Covid..Coviddeaths
where location like '%india%'
and total_deaths is not null
order by 1, 2;
-- Death_rateshows likelihood of being saved if you get covid in india (Max percentage value was 3%)



-- looking at total cases versus population
-- shows what percentage of population got covid in India
select location, date, total_cases, population, total_deaths,
(total_deaths / population) * 100 as Death_percentage
from portfolioproject_Covid..Coviddeaths
where location like '%india%'
and total_deaths is not null
order by Death_percentage asc;
-- 2020 (March and April) was a very rough period for India (death percentage >3%) 


-- looking at India to identify a period of time with high infection rate wrt population
select location, date, total_cases, population,
(total_cases / population) * 100 as Infection_Rate
from portfolioproject_Covid..Coviddeaths
where location like '%india%'
and total_cases is not null
order by Infection_Rate asc;
--	March 2020 had the highest infection rate (1-9)% in India helping to spread the deasese in much rapid rate that expected


--looking at countries with highest infection rate compared to population
select location, population, MAX(total_cases) as High_Infection_Count,
MAX((total_cases / population)) * 100 as Max_Infection_Rate
from portfolioproject_Covid..Coviddeaths
Group by population, location
order by  Max_Infection_Rate desc, High_Infection_Count desc;
-- We need to use the MAX function in Infection rate as well because we are aggregating the data this time
-- Europe an America got infected rather badly compared to Asia and other continents


--showing at countries with highest deathcount per population
select location, population, Max(cast(total_deaths as int)) as Total_death_count 
from portfolioproject_Covid..Coviddeaths
where continent is not null 
and total_deaths is not null
group by location, population
order by Total_death_count desc ;
-- we need to change the type of data for total_deaths to integer otherwise we are getting a very peculiar number for that

-- If we can see things throgh continent wise
select continent, Max(cast(total_deaths as int)) as Total_death_count 
from portfolioproject_Covid..Coviddeaths
where continent is not null 
group by continent
order by Total_death_count desc;
-- The north america includes only USA data, someting is wrong as we did not include null data sets where some data will show us the actual numbers of countries from specific continents


-- Ater modifying it, it should look like this--
select location, Max(cast(total_deaths as int)) as Total_death_count 
from portfolioproject_Covid..Coviddeaths
where continent is null 
group by location
order by Total_death_count desc;
--Now we get actual umbers contim=nent wise


--lets look at the table at covid vaccinations along with coviddeaths
--If we can compare total population vs. new vaccinations per day 
select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations
from portfolioproject_Covid..Coviddeaths as Deaths
Join portfolioproject_Covid..Covidvaccinations as Vaccinations
     on Deaths.location = Vaccinations.location
     and Deaths.date = Vaccinations.date
where Deaths.continent is not null
order by 1,2,3
-- The output is definitely not insightful


-- Now lets see if we can sum up the vaccinations for each day just as rolling numbers with respect to locations
--total population vs. new vaccinations
select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
sum(convert(int, Vaccinations.new_vaccinations)) over (partition by Deaths.location order by Deaths.location, Deaths.date) 
as Rolling_Total_Vaccination
from portfolioproject_Covid..Coviddeaths as Deaths
Join portfolioproject_Covid..Covidvaccinations as Vaccinations
     on Deaths.location = Vaccinations.location
     and Deaths.date = Vaccinations.date
where Deaths.continent is not null and
Vaccinations.new_vaccinations is not null
order by 1,2,3;



--Using CTE
-- Lets keep in mind the number of columns in CTE should be same as number of columns in our reference table
-- order by command should be omitted as it is a subquery

with population_vs_vaccination (continent,location,date,population,new_vaccinations,Rolling_Total_Vaccination)
as
(
select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
sum(convert(int, Vaccinations.new_vaccinations)) over (partition by Deaths.location order by Deaths.location, Deaths.date) 
as Rolling_Total_Vaccination
from portfolioproject_Covid..Coviddeaths as Deaths
Join portfolioproject_Covid..Covidvaccinations as Vaccinations
     on Deaths.location = Vaccinations.location
     and Deaths.date = Vaccinations.date
where Deaths.continent is not null and
Vaccinations.new_vaccinations is not null
)


select *, (Rolling_Total_Vaccination/population)*100 as Total_percentage_vaccinated
from population_vs_vaccination;

-- Basically the above query shows us the total percentage of people vaccinated till the date for each country by using rolling percentage


--Creating a temporary table named Percent_population_vaccinated

Create Table #Percent_population_vaccinated
(
continent nvarchar(200),location nvarchar(200), Date datetime, New_vaccinations numeric, population numeric,
Rolling_Total_Vaccination numeric
)
Insert into #Percent_population_vaccinated
select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
sum(convert(int, Vaccinations.new_vaccinations)) over (partition by Deaths.location order by Deaths.location, Deaths.date) 
as Rolling_Total_Vaccination
from portfolioproject_Covid..Coviddeaths as Deaths
Join portfolioproject_Covid..Covidvaccinations as Vaccinations
     on Deaths.location = Vaccinations.location
     and Deaths.date = Vaccinations.date
where Deaths.continent is not null and
Vaccinations.new_vaccinations is not null;


select *
from #Percent_population_vaccinated;


-- creating a view for our new temporary table just to understand what pattern should come at data visualization

Create view Percent_population_vaccinated as
select Deaths.continent, Deaths.location, Deaths.date, Deaths.population, Vaccinations.new_vaccinations,
sum(convert(int, Vaccinations.new_vaccinations)) over (partition by Deaths.location order by Deaths.location, Deaths.date) 
as Rolling_Total_Vaccination
from portfolioproject_Covid..Coviddeaths as Deaths
Join portfolioproject_Covid..Covidvaccinations as Vaccinations
     on Deaths.location = Vaccinations.location
     and Deaths.date = Vaccinations.date
where Deaths.continent is not null and
Vaccinations.new_vaccinations is not null;

select*
from  Percent_population_vaccinated

