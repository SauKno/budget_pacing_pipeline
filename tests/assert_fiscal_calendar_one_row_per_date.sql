/* Test: the fiscal calendar has exactly one row per date.
   Why : A duplicate date would duplicate every budget row on that day.
   Pass: returns 0 rows. */
SELECT
  date,
  COUNT(*) AS row_count
FROM `your-project.marketing_analytics.stg_fiscal_calendar`
GROUP BY 1
HAVING COUNT(*) > 1;
