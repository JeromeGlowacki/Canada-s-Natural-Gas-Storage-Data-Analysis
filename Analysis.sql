USE NaturalGasDistribution;
GO

SELECT 
    metric,
    storage_month,
    FORMAT(value, 'N0') AS value_formatted,
    storage_date
FROM gas_storage_long
ORDER BY storage_date;

*Averages by metric*
SELECT metric, FORMAT(AVG(value), 'N0') AS avg_storage
FROM gas_storage_long
GROUP BY metric;


*Monthly trend*
SELECT storage_month, FORMAT(value, 'N0') AS opening_inventory
FROM gas_storage_long
WHERE metric = 'Opening inventory'
ORDER BY storage_month;

SELECT storage_month, FORMAT(value, 'N0') AS closing_inventory
FROM gas_storage_long
WHERE metric = 'Closing inventory'
ORDER BY storage_month;

*Monthly changes*
WITH ranked AS (
    SELECT *,
           LAG(value) OVER (PARTITION BY metric ORDER BY storage_month) AS prev_value
    FROM gas_storage_long
)
SELECT storage_month, metric, FORMAT(value, 'N0') AS inventory,
       FORMAT(value - prev_value, 'N0') AS change,
       CASE WHEN prev_value IS NOT NULL THEN FORMAT((value - prev_value)/prev_value * 100, 'N2') END AS pct_change
FROM ranked
WHERE metric IN ('Opening inventory', 'Closing inventory')
ORDER BY storage_month,
         CASE metric
             WHEN 'Opening inventory' THEN 1
             WHEN 'Closing inventory' THEN 2
         END;


*Peak and lowest month*
SELECT metric, storage_month, FORMAT(value, 'N0') AS inventory
FROM gas_storage_long
WHERE value = (SELECT MAX(value) FROM gas_storage_long WHERE metric = 'Opening inventory')
   OR value = (SELECT MIN(value) FROM gas_storage_long WHERE metric = 'Opening inventory')
ORDER BY metric;

*Monthly volatility*
WITH ranked AS (
    SELECT *,
           LAG(value) OVER (PARTITION BY metric ORDER BY storage_month) AS prev_value
    FROM gas_storage_long
    WHERE metric = 'Opening inventory'
)
SELECT storage_month,
       FORMAT(value, 'N0') AS opening_inventory,
       FORMAT(value - prev_value, 'N0') AS monthly_change,
       CASE WHEN prev_value IS NOT NULL THEN FORMAT(ABS(value - prev_value), 'N0') END AS volatility
FROM ranked
ORDER BY storage_month;


* Average inventory of natural gas stored* 
WITH yearly_avg AS (
    SELECT 
        RIGHT(storage_month, 2) AS year,  -- last 2 digits of year
        AVG(value) AS avg_opening_inventory
    FROM gas_storage_long
    WHERE metric = 'Opening inventory'
    GROUP BY RIGHT(storage_month, 2)
)
SELECT 
    year,
    FORMAT(avg_opening_inventory, 'N0') AS avg_opening_inventory,
    LAG(avg_opening_inventory) OVER (ORDER BY year) AS prev_year_avg,
    CASE 
        WHEN LAG(avg_opening_inventory) OVER (ORDER BY year) IS NOT NULL 
        THEN FORMAT((avg_opening_inventory - LAG(avg_opening_inventory) OVER (ORDER BY year)) 
                    / LAG(avg_opening_inventory) OVER (ORDER BY year) * 100, 'N2') 
    END AS pct_change
FROM yearly_avg
ORDER BY year;


*Average inventory by month to evaluate seasonality*
SELECT LEFT(storage_month, 3) AS month,
       FORMAT(AVG(CASE WHEN metric = 'Opening inventory' THEN value END), 'N0') AS avg_opening_inventory
FROM gas_storage_long
GROUP BY LEFT(storage_month, 3)
ORDER BY CASE LEFT(storage_month, 3)
           WHEN 'Jan' THEN 1
           WHEN 'Feb' THEN 2
           WHEN 'Mar' THEN 3
           WHEN 'Apr' THEN 4
           WHEN 'May' THEN 5
           WHEN 'Jun' THEN 6
           WHEN 'Jul' THEN 7
           WHEN 'Aug' THEN 8
           WHEN 'Sep' THEN 9
           WHEN 'Oct' THEN 10
           WHEN 'Nov' THEN 11
           WHEN 'Dec' THEN 12 END;


*Average monthly volatiliy*
WITH ranked AS (
    SELECT *,
           LAG(value) OVER (PARTITION BY metric ORDER BY storage_month) AS prev_value
    FROM gas_storage_long
    WHERE metric = 'Opening inventory'
)
SELECT LEFT(storage_month, 3) AS month,
       FORMAT(AVG(ABS(value - prev_value)), 'N0') AS avg_volatility
FROM ranked
GROUP BY LEFT(storage_month, 3)
ORDER BY CASE LEFT(storage_month, 3)
           WHEN 'Jan' THEN 1
           WHEN 'Feb' THEN 2
           WHEN 'Mar' THEN 3
           WHEN 'Apr' THEN 4
           WHEN 'May' THEN 5
           WHEN 'Jun' THEN 6
           WHEN 'Jul' THEN 7
           WHEN 'Aug' THEN 8
           WHEN 'Sep' THEN 9
           WHEN 'Oct' THEN 10
           WHEN 'Nov' THEN 11
           WHEN 'Dec' THEN 12 END;



*Injections vs withdrawals by year*
SELECT 
    RIGHT(storage_month, 2) AS year,
    FORMAT(SUM(CASE WHEN metric = 'Injections to storage' THEN value ELSE 0 END), 'N0') AS total_injections,
    FORMAT(SUM(CASE WHEN metric = 'Withdrawals from storage' THEN value ELSE 0 END), 'N0') AS total_withdrawals,
    FORMAT(SUM(CASE WHEN metric = 'Injections to storage' THEN value ELSE 0 END) -
           SUM(CASE WHEN metric = 'Withdrawals from storage' THEN value ELSE 0 END), 'N0') AS net_change
FROM gas_storage_long
WHERE metric IN ('Injections to storage', 'Withdrawals from storage')
GROUP BY RIGHT(storage_month, 2)
ORDER BY year;


*Average Injections vs withdrawals by year*
SELECT 
    RIGHT(storage_month, 2) AS year,
    FORMAT(AVG(CASE WHEN metric = 'Injections to storage' THEN value END), 'N0') AS avg_monthly_injections,
    FORMAT(AVG(CASE WHEN metric = 'Withdrawals from storage' THEN value END), 'N0') AS avg_monthly_withdrawals,
    FORMAT(AVG(CASE WHEN metric = 'Injections to storage' THEN value END) -
           AVG(CASE WHEN metric = 'Withdrawals from storage' THEN value END), 'N0') AS net_avg_change
FROM gas_storage_long
WHERE metric IN ('Injections to storage', 'Withdrawals from storage')
GROUP BY RIGHT(storage_month, 2)
ORDER BY year;
