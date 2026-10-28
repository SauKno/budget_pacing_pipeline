/* =============================================================================
   fct_budget_daily_dma
   Layer      : mart (Tableau data source)
   Grain      : one row per event_key x date x DMA x budget_source x channel
   Purpose    : Daily budget for spend pacing. Daily grain supports every pacing
                period: weekly, monthly and event to date.
   Depends on : int_budget_weekly_dma, stg_events, stg_fiscal_calendar
   Used by    : Tableau spend pacing dashboard (joined to actual spend on
                date + DMA + channel)
   Notes
     - Weekly budget is spread evenly across the in-event days of each week.
       GREATEST/LEAST clip partial first and last weeks to event dates, so no
       budget lands outside the event.
     - Dividing by the number of in-event days (not a fixed 7) keeps each
       week's total exact after the split.
     - GENERATE_DATE_ARRAY + UNNEST creates the daily rows without needing a
       separate date table.
     - event_start / event_end let Tableau compute days elapsed and days left
       from the data (FIXED LOD) instead of manually set parameters.
     - No rounding: formatting belongs in Tableau, so channels always add up
       exactly to the total.
   ============================================================================= */

CREATE OR REPLACE VIEW `your-project.marketing_analytics.fct_budget_daily_dma` AS
SELECT
  w.event_key,
  e.event_year,
  e.event_name,
  e.start_date  AS event_start,
  e.end_date    AS event_end,
  d             AS date,
  w.week_start,
  fc.fiscal_year,
  fc.fiscal_quarter,
  fc.fiscal_period,
  fc.fiscal_week,
  fc.fiscal_week_start_date,
  w.dma,
  w.budget_source,
  w.channel,
  w.weekly_budget / (
    DATE_DIFF(
      LEAST(DATE_ADD(w.week_start, INTERVAL 6 DAY), e.end_date),
      GREATEST(w.week_start, e.start_date),
      DAY
    ) + 1
  ) AS budget_daily
FROM `your-project.marketing_analytics.int_budget_weekly_dma` w
JOIN `your-project.marketing_analytics.stg_events` e
  ON e.event_key = w.event_key
CROSS JOIN UNNEST(
  GENERATE_DATE_ARRAY(
    GREATEST(w.week_start, e.start_date),
    LEAST(DATE_ADD(w.week_start, INTERVAL 6 DAY), e.end_date)
  )
) AS d
LEFT JOIN `your-project.marketing_analytics.stg_fiscal_calendar` fc
  ON fc.date = d;
