DROP TABLE t_katarina_petrzelova_project_sql_primary_final;

--vytvoreni primarni tabulky pro SQL projekt
CREATE TABLE t_katarina_petrzelova_project_sql_primary_final AS
SELECT 
	cp.payroll_year AS rok,
	'Mzda' AS typ,
	cpib.name,
	avg(cp.value) AS prumer
FROM czechia_payroll cp
JOIN czechia_payroll_industry_branch cpib
	ON cp.industry_branch_code = cpib.code
	AND cp.value_type_code = 5958
	AND value IS NOT NULL
GROUP BY cpib.name, cp.payroll_year
UNION ALL
SELECT
    EXTRACT(YEAR FROM cp.date_from) AS rok,
    'Cena' AS typ,
    cpc.name,
    avg(cp.value) AS prumer
FROM czechia_price AS cp
JOIN czechia_price_category AS cpc
	ON cp.category_code = cpc.code
	WHERE cp.region_code IS NULL
GROUP BY EXTRACT(YEAR FROM cp.date_from), cpc.name;

--kontrola existence a dat v tabulce:
SELECT *
FROM t_katarina_petrzelova_project_sql_primary_final
ORDER BY rok;

--otazka 1: Varianta A - procentni prirustek mezi poslednim a prvnim obdobim
WITH prvni AS (
    SELECT name, prumer
    FROM t_katarina_petrzelova_project_sql_primary_final
    WHERE rok = (SELECT MIN(rok) FROM t_katarina_petrzelova_project_sql_primary_final)
    AND typ = 'Mzda'
),
posledni AS (
    SELECT name, prumer
    FROM t_katarina_petrzelova_project_sql_primary_final
    WHERE rok = (SELECT MAX(rok) FROM t_katarina_petrzelova_project_sql_primary_final)
    AND typ = 'Mzda'
)
SELECT
    p.name,
    p.prumer AS mzda_prvni,
    l.prumer AS mzda_posledni,
    ((l.prumer - p.prumer)/p.prumer)*100 AS rozdil_procento
FROM prvni p
JOIN posledni l ON p.name = l.name
ORDER BY rozdil_procento DESC;

--otazka 1: Varianta B - prumer z prumernych rocnich prirustku dle jednotlivych oboru
WITH cte AS 
(
    SELECT 
    	t1.typ,
        t1.name,
        t1.rok AS aktualni_rok,
        t2.rok AS predchozi_rok,
        t1.prumer AS aktualni_cena,
        t2.prumer AS predchozi_cena,
        (100.0 * (t1.prumer - t2.prumer) / t2.prumer) AS procent_rust
    FROM t_katarina_petrzelova_project_sql_primary_final AS t1
            JOIN t_katarina_petrzelova_project_sql_primary_final AS t2
        	ON t1.name = t2.name
        	WHERE t1.typ = 'Mzda'
        AND t1.rok = (t2.rok + 1)
        )
SELECT 
    name,
    avg(procent_rust)
FROM 
    cte
GROUP BY name
ORDER BY avg(procent_rust) DESC;

--otazka 2: Varianta 1 - pocet litru mleka za mzdu v jednotlivych oborech
SELECT
    tp.rok,
    tp.name,
    tp.prumer AS mzda,
    cp.prumer AS cena_mleka,
    (tp.prumer / cp.prumer) AS litru_mleka
FROM
    t_katarina_petrzelova_project_sql_primary_final AS tp
JOIN
    t_katarina_petrzelova_project_sql_primary_final AS cp ON tp.rok = cp.rok
WHERE
    tp.typ = 'Mzda'
    AND cp.typ = 'Cena'
    AND cp.name = 'Mléko polotučné pasterované'
    AND cp.rok IN (2006, 2018)
ORDER BY tp.rok;

--otazka 2 - Varianta B - vyuziti CTE
 WITH cena_mleka AS (
    SELECT
        rok,
        prumer AS cena
    FROM
        t_katarina_petrzelova_project_sql_primary_final
    WHERE
        typ = 'Cena'
        AND name = 'Mléko polotučné pasterované'
)
SELECT
    tp.rok,
    tp.name AS odvetvi,
    tp.prumer AS mzda,
    c.cena AS cena_mleka,
    (tp.prumer / c.cena) AS litru_mleka
FROM
    t_katarina_petrzelova_project_sql_primary_final AS tp
JOIN
    cena_mleka AS c ON tp.rok = c.rok
    WHERE
    tp.typ = 'Mzda'
    AND tp.rok IN (2006, 2018)
ORDER BY tp.rok;

-- otazka 3 
WITH cte AS 
(
    SELECT 
    	t1.typ,
        t1.name,
        t1.rok AS aktualni_rok,
        t2.rok AS predchozi_rok,
        t1.prumer AS aktualni_cena,
        t2.prumer AS predchozi_cena,
        (100.0 * (t1.prumer - t2.prumer) / t2.prumer) AS procent_rust
    FROM t_katarina_petrzelova_project_sql_primary_final AS t1
            JOIN t_katarina_petrzelova_project_sql_primary_final AS t2
        	ON t1.name = t2.name
        	WHERE t1.typ = 'Cena'
        AND t1.rok = (t2.rok + 1)
        )
SELECT 
    name,
    avg(procent_rust) AS prumerny_prirustek
FROM 
    cte
GROUP BY name
ORDER BY avg(procent_rust);

--otazka c 4. rust mezd vs rust cen
WITH prumery AS (
    SELECT
        Rok,
        Typ,
        AVG(prumer) AS prumer
    FROM
        t_katarina_petrzelova_project_sql_primary_final
    GROUP BY
        Rok, Typ
),
prumery_ceny AS (
    SELECT * FROM prumery WHERE Typ = 'Cena'
),
prumery_mzdy AS (
    SELECT * FROM prumery WHERE Typ = 'Mzda'
),
prirustek AS (
    SELECT
        c1.Rok AS Rok,
        c1.prumer AS prumer_ceny,
        c0.prumer AS prumer_ceny_min,
        m1.prumer AS prumer_mzdy,
        m0.prumer AS prumer_mzdy_min,
        ((c1.prumer - c0.prumer) / c0.prumer) * 100 AS rust_cen_pct,
        ((m1.prumer - m0.prumer) / m0.prumer) * 100 AS rust_mzd_pct
    FROM
        prumery_ceny c1
    JOIN prumery_ceny c0 ON c0.Rok = c1.Rok - 1
    JOIN prumery_mzdy m1 ON m1.Rok = c1.Rok
    JOIN prumery_mzdy m0 ON m0.Rok = c1.Rok - 1
)
SELECT
    Rok,
    rust_cen_pct,
    rust_mzd_pct,
    rust_cen_pct - rust_mzd_pct AS rozdil
FROM
    prirustek
ORDER BY rozdil desc;

--vytvořeni sekundarni tabulky - evropske zeme
CREATE TABLE t_katarina_petrzelova_project_sql_secondary_final AS
SELECT 
 	year,
 	country,
 	gdp,
 	population,
 	gini
FROM economies
WHERE YEAR BETWEEN 2006 AND 2018 
AND country IN (
    SELECT country
    FROM countries
    WHERE continent = 'Europe'
);

--kontrola existence tabulky sekundarni
SELECT *
FROM t_katarina_petrzelova_project_sql_secondary_final
LIMIT 50;

--otazka c 5 - korelace HDP, mezd a cen ve stejnem roce
WITH mzdy_prirustky AS (
SELECT
    Rok,
    avg(Prumer) AS mzda,
    LAG(avg(Prumer)) OVER (ORDER BY Rok) AS predchozi_mzda,
    (avg(Prumer) - LAG(avg(Prumer)) OVER (ORDER BY Rok)) / LAG(avg(Prumer)) OVER (ORDER BY Rok) * 100 AS rust_mezd_procent
  FROM t_katarina_petrzelova_project_sql_primary_final
  WHERE Typ = 'Mzda'
  AND rok BETWEEN 2006 AND 2018
  GROUP BY rok
)
, ceny_prirustky AS (
SELECT
    Rok,
    avg(Prumer) AS cena,
    LAG(avg(Prumer)) OVER (ORDER BY Rok) AS predchozi_cena,
    (avg(Prumer) - LAG(avg(Prumer)) OVER (ORDER BY Rok)) / LAG(avg(Prumer)) OVER (ORDER BY Rok) * 100 AS rust_cen_procent
  FROM t_katarina_petrzelova_project_sql_primary_final
  WHERE Typ = 'Cena'
  GROUP BY rok
)
, hdp_prirustky AS (
SELECT
    year,
    gdp / population AS HDP_na_obyv,
    LAG(gdp / population) OVER (ORDER BY year) AS predchozi_hdp,
    ((gdp / population) - LAG(gdp / population) OVER (ORDER BY year)) / LAG(gdp / population) OVER (ORDER BY year) * 100 AS rust_hdp_procent
  FROM t_katarina_petrzelova_project_sql_secondary_final
  WHERE country = 'Czech Republic'
  AND YEAR BETWEEN 2006 AND 2018
)
SELECT 
  mp.rok,
  mp.rust_mezd_procent,
  c.rust_cen_procent,
  h.rust_hdp_procent
FROM mzdy_prirustky AS mp
JOIN ceny_prirustky AS c ON mp.rok = c.rok
JOIN hdp_prirustky AS h ON mp.rok = h.YEAR
ORDER BY mp.rok;

