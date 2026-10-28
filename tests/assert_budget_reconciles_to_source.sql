/* Test: total budget in the mart equals the source totals, per event and
         budget source.
   Why : The most important check. Catches budget lost or duplicated anywhere
         in the pipeline: missing shares, bad splits, join fan-out, or days
         dropped by the daily spread.
   Pass: returns 0 rows (tolerance: 1 cent). */
WITH source_totals AS (
  SELECT e.event_key, 'National' AS budget_source, SUM(n.budget) AS source_budget
  FROM `your-project.marketing_analytics.stg_national_budget_weekly` n
  JOIN `your-project.marketing_analytics.stg_events` e
    ON n.event_name = e.event_name
   AND n.week_start BETWEEN DATE_SUB(e.start_date, INTERVAL 6 DAY) AND e.end_date
  GROUP BY 1, 2

  UNION ALL

  SELECT e.event_key, 'Co-op' AS budget_source, SUM(c.budget) AS source_budget
  FROM `your-project.marketing_analytics.stg_coop_budget_weekly` c
  JOIN `your-project.marketing_analytics.stg_events` e
    ON c.week_start BETWEEN DATE_SUB(e.start_date, INTERVAL 6 DAY) AND e.end_date
  GROUP BY 1, 2
),

mart_totals AS (
  SELECT event_key, budget_source, SUM(budget_daily) AS mart_budget
  FROM `your-project.marketing_analytics.fct_budget_daily_dma`
  GROUP BY 1, 2
)

SELECT
  COALESCE(s.event_key, m.event_key)          AS event_key,
  COALESCE(s.budget_source, m.budget_source)  AS budget_source,
  s.source_budget,
  m.mart_budget,
  IFNULL(m.mart_budget, 0) - IFNULL(s.source_budget, 0) AS difference
FROM source_totals s
FULL OUTER JOIN mart_totals m
  ON s.event_key = m.event_key
 AND s.budget_source = m.budget_source
WHERE ABS(IFNULL(m.mart_budget, 0) - IFNULL(s.source_budget, 0)) > 0.01;
