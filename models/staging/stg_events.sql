/* =============================================================================
   stg_events
   Layer      : staging
   Grain      : one row per event_key
   Source     : raw_events_calendar
   Purpose    : The single definition of each event's date window, shared by
                every downstream model (budget and actuals).
   Notes
     - event_key (year_event, e.g. '2026_E5') is the unique identifier. Event
       names like 'E1' repeat each year, so the name alone would merge years.
     - MIN/MAX guards against an event being split over several calendar rows
       (e.g. by region); without it, joins would multiply rows downstream.
   Used by    : int_event_dma_share, int_budget_weekly_dma, fct_budget_daily_dma
   ============================================================================= */

CREATE OR REPLACE VIEW `your-project.marketing_analytics.stg_events` AS
SELECT
  event_key,
  ANY_VALUE(event_year) AS event_year,
  ANY_VALUE(event)      AS event_name,
  MIN(start_date)       AS start_date,
  MAX(end_date)         AS end_date
FROM `your-project.marketing_analytics.raw_events_calendar`
GROUP BY event_key;
