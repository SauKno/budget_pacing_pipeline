/* Test: every budget date found a fiscal calendar match.
   Why : Missing fiscal fields mean those days drop out of any fiscal
         week / period view in Tableau.
   Pass: returns 0 rows. */
SELECT DISTINCT
  event_key,
  date
FROM `your-project.marketing_analytics.fct_budget_daily_dma`
WHERE fiscal_week IS NULL;
