CREATE DATABASE NaturalGasDistribution;
GO

USE NaturalGasDistribution;
GO

CREATE TABLE gas_storage_long (
    metric VARCHAR(100),
    storage_month VARCHAR(10),
    value FLOAT
);

DECLARE @cols NVARCHAR(MAX);

SELECT @cols = STRING_AGG(QUOTENAME(name), ',')
FROM sys.columns
WHERE object_id = OBJECT_ID('[Canadian Natural Gas Storage Dataset]')
  AND name <> 'Storage';

SELECT @cols;  -- sanity check

DECLARE @sql NVARCHAR(MAX);

SET @sql = '
INSERT INTO gas_storage_long (metric, storage_month, value)
SELECT Storage, storage_month, value
FROM [Canadian Natural Gas Storage Dataset]
UNPIVOT (
    value FOR storage_month IN (' + @cols + ')
) u;
';

EXEC sp_executesql @sql;

SELECT COUNT(*) AS total_rows
FROM gas_storage_long;

SELECT TOP 10 *
FROM gas_storage_long
ORDER BY [value]desc;

SELECT DISTINCT metric
FROM gas_storage_long;

UPDATE gas_storage_long
SET storage_date = DATEFROMPARTS(
    2000 + CAST(RIGHT(storage_month, 2) AS INT),
    CASE LEFT(storage_month, 3)
        WHEN 'Jan' THEN 1 WHEN 'Feb' THEN 2 WHEN 'Mar' THEN 3
        WHEN 'Apr' THEN 4 WHEN 'May' THEN 5 WHEN 'Jun' THEN 6
        WHEN 'Jul' THEN 7 WHEN 'Aug' THEN 8 WHEN 'Sep' THEN 9
        WHEN 'Oct' THEN 10 WHEN 'Nov' THEN 11 WHEN 'Dec' THEN 12
    END,
    1
);

SELECT
    MIN(storage_date) AS start_date,
    MAX(storage_date) AS end_date
FROM gas_storage_long;

