/* =============================================================================
   stg_fiscal_calendar
   Layer      : staging
   Grain      : one row per calendar date
   Source     : raw_fiscal_calendar
   Purpose    : Fiscal year / quarter / period / week attributes for each date.
   Notes
     - If the source's daily date column has a different name, change it HERE
       only; every downstream model uses `date`.
     - Uniqueness per date is checked in tests/assert_fiscal_calendar_one_row_per_date.sql.
       A duplicate date would double the budget for that day.
   Used by    : fct_budget_daily_dma
   ============================================================================= */

CREATE OR REPLACE VIEW `your-project.marketing_analytics.stg_fiscal_calendar` AS
SELECT
  date,                     -- adjust to the source's daily date column
  fiscal_year,
  fiscal_quarter,
  fiscal_period,
  fiscal_week,
  fiscal_week_start_date
FROM `your-project.marketing_analytics.raw_fiscal_calendar`;
