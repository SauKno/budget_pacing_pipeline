/* Test: the mart has one row per event x date x DMA x budget_source x channel.
   Why : Duplicate rows double the budget in Tableau.
   Pass: returns 0 rows. */
SELECT
  event_key, date, dma, budget_source, channel,
  COUNT(*) AS row_count
FROM `your-project.marketing_analytics.fct_budget_daily_dma`
GROUP BY 1, 2, 3, 4, 5
HAVING COUNT(*) > 1;
