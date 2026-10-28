/* Test: every event with National budget has DMA shares.
   Why : National budget is multiplied by DMA shares. An event with no shares
         (missing basis event, or basis event with no revenue yet) would lose
         its entire National budget without an error.
   Pass: returns 0 rows. */
SELECT DISTINCT
  e.event_key
FROM `your-project.marketing_analytics.stg_national_budget_weekly` n
JOIN `your-project.marketing_analytics.stg_events` e
  ON n.event_name = e.event_name
 AND n.week_start BETWEEN DATE_SUB(e.start_date, INTERVAL 6 DAY) AND e.end_date
LEFT JOIN (
  SELECT DISTINCT event_key FROM `your-project.marketing_analytics.int_event_dma_share`
) s
  ON s.event_key = e.event_key
WHERE s.event_key IS NULL;
