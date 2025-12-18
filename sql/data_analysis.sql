-- Exploratory Data Analysis 
use world_layoffs;

SELECT * 
FROM layoffs_staging2;

-- max and min layoffs 
SELECT max(total_laid_off), max(percentage_laid_off)
FROM layoffs_staging2;

SELECT*
FROM layoffs_staging2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions desc;

-- Total layoff by a company
SELECT company, sum(total_laid_off) 
FROM layoffs_staging2
group by company
order by sum(total_laid_off) desc;

-- Start and end date of the data 
SELECT min(`date`), max(`date`)
FROM layoffs_staging2;

-- total layoff by an industry
SELECT industry, sum(total_laid_off) 
FROM layoffs_staging2
group by industry
order by sum(total_laid_off) desc;

-- layoff by year 
select year(`date`), sum(total_laid_off)
from layoffs_staging2
group by year(`date`)
order by year(`date`) desc 
;

-- layoff by year and month as well
select *
from layoffs_staging2;
select substring(`date`, 1,7) as y_m, sum(total_laid_off) as total_off
from layoffs_staging2
where substring(`date`, 1,7)  is not null
group by y_m
order by y_m asc;

-- rolling total of the layoffs 
with new_table as  
( 
select substring(`date`, 1,7) as y_m, sum(total_laid_off) as total_off
from layoffs_staging2
where substring(`date`, 1,7)  is not null
group by y_m
order by y_m asc)
select y_m, total_off, sum(total_off) over(order by y_m) as rolling_total 
from new_table
;

-- top 5 most layoffs by a commpany per year
select company, year(`date`), Sum(total_laid_off) as total_lay
from layoffs_staging2
group by company, year(`date`)
order by 3 desc
;

with company_year (company, years , total_laid_off) as 
(
select company, year(`date`), Sum(total_laid_off) as total_lay
from layoffs_staging2
group by company, year(`date`)
), company_year_rank as 
 (select * , 
 dense_rank() over(partition by years order by total_laid_off desc)as ranking
 from company_year
 where years is not null
  )
 
 select * 
 from company_year_rank
 where ranking <= 5 
 ;

-- Most affected countries 
Select country, sum(total_laid_off) as tot
from layoffs_staging2
group by country
order by tot desc;

WITH temp_table as (
Select country, sum(total_laid_off) as total
from layoffs_staging2
GROUP BY country
)
SELECT row_number() OVER(order by total DESC) as country_rank, country, total 
from temp_table
;

-- Affected at particular rank 
WITH temp_table as (
Select row_number() OVER( order by sum(total_laid_off) desc) as c_rank, country, sum(total_laid_off) as total
from layoffs_staging2
GROUP BY country
)
SELECT * from temp_table
WHERE c_rank = 9
;

-- rank by industry, in a country  
select country, industry, sum(total_laid_off) as total 
from layoffs_staging2
group by country, industry
;


WITH country_industry as (
	select country, industry, sum(total_laid_off) as total, row_number() over ( partition by country ORDER by sum(total_laid_off) DESC ) as i_rank 
	from layoffs_staging2
	group by country, industry
) 
SELECT *
FROM country_industry
WHERE i_rank < 4
;

SELECT country, industry, total_laid_off
FROM layoffs_staging2
;

SELECT country, total_laid_off
FROM layoffs_staging2
WHERE total_laid_off is not null
LIMIT 5
;


WITH temp_table as 
(
	SELECT row_number() OVER(partition by country ORDER BY sum(total_laid_off) DESC ) as rn, country, industry, sum(total_laid_off)
	FROM layoffs_staging2
	WHERE total_laid_off is not null
	GROUP BY country, industry
)
SELECT * from temp_table 
WHERE rn < 3
;

-- Funds raised by a company in particular industry 
WITH temp_table as (
	SELECT row_number() OVER(partition by industry ORDER BY funds_raised_millions DESC) as rn, industry, company, funds_raised_millions
	FROM layoffs_staging2
	WHERE industry is not null
)
SELECT * from temp_table
WHERE rn < 3
;

SELECT * from layoffs_staging2;


SELECT count(*) from layoffs_staging2;

-- avg percentage layoff at a particular stage  
select stage , avg(percentage_laid_off)
from layoffs_staging2
where stage = 'Post-IPO'
and percentage_laid_off is not null
group by stage ;



-- most affected industries 
select industry,  avg(percentage_laid_off) as total, per
from layoffs_staging2
where percentage_laid_off is not null
group by industry
order by total desc
;

-- more than 5 companies in any industry
with new_table as 
(
	select row_number() over(partition by industry order by company) as `rank`, industry, company, percentage_laid_off
	from layoffs_staging2   
)
select industry, avg(percentage_laid_off) as pr from new_table
where `rank` > 5 
group by industry
order by pr desc
LIMIT 5
;

-- Most affected industires with greater than 5 companies.
select industry, avg(percentage_laid_off) as av
from layoffs_staging2
group by industry
;

SELECT industry, company, percentage_laid_off
FROM layoffs_staging2
WHERE percentage_laid_off is not null;

WITH temp_table as (
	SELECT industry, count(company) as count_companies, avg(percentage_laid_off) as per
	FROM layoffs_staging2
	WHERE percentage_laid_off is not null
	AND company is not null
	GROUP BY industry
	ORDER BY per DESC
) 
SELECT * from temp_table 
WHERE count_companies > 5
LIMIT 5
;


with new_table as 
(
	select row_number() over(partition by industry order by company) as `rank`, industry, company, percentage_laid_off
	from layoffs_staging2   
	WHERE 
		percentage_laid_off is not null
	AND company is not null
)
select industry, count(company), avg(percentage_laid_off) as pr from new_table
where `rank` > 5 
group by industry
order by pr desc
LIMIT 5
;

with new_table as 
(
	select row_number() over(partition by industry order by company) as `rank`, industry, company, percentage_laid_off
	from layoffs_staging2   
	WHERE 
		percentage_laid_off is not null
	AND company is not null
),
 industries as (
	select distinct(industry) as ind from new_table
	where `rank` > 5 
)
SELECT industry, count(company), avg(percentage_laid_off) as pr
FROM industries JOIN layoffs_staging2 on industries.ind = layoffs_staging2.industry
GROUP by industry
ORDER by pr DESC
LIMIT 5
;

-- Most affected industry with average percentage laid offs
SELECT industry, count(company), avg(percentage_laid_off) as pr
FROM layoffs_staging2
WHERE industry in (
	with new_table as 
	(
		select row_number() over(partition by industry order by company) as `rank`, industry, company, percentage_laid_off
		from layoffs_staging2   
		WHERE 
			percentage_laid_off is not null
		AND company is not null
	)
	select distinct(industry) from new_table
	where `rank` > 5 
)
GROUP BY industry
ORDER BY pr DESC
LIMIT 5;




SELECT industry, avg(percentage_laid_off) as pr
FROM layoffs_staging2
GROUP BY industry
HAVING count(company) > 5
ORDER BY pr DESC
LIMIT 5
;

SELECT industry, count(company), avg(percentage_laid_off) as pr
FROM layoffs_staging2
WHERE industry in (
	SELECT industry
    FROM layoffs_staging2
    GROUP BY industry
    HAVING count(company) > 5
)
GROUP BY industry
ORDER BY pr DESC
LIMIT 5;
