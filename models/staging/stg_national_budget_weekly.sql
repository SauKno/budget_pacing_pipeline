/* =============================================================================
   stg_national_budget_weekly
   Layer      : staging
   Grain      : one row per event_name x week_start x channel
   Source     : raw_national_budget_weekly
   Purpose    : National weekly budget reshaped from wide (one column per
                channel) to long (one row per channel).
   Notes
     - Long format matches the grain of channel-level actual spend, so budget
       and actuals can be joined on channel instead of compared column by column.
     - UNPIVOT drops NULLs by default: a channel with no budget in a week
       produces no row rather than a zero row.
     - The source has only the event name ('E6'), not the year. The event_key is
       assigned in int_budget_weekly_dma by matching name + date window.
     - If the source table moves to long format, this becomes a plain SELECT and
       new channels flow through with no code change.
   Used by    : int_budget_weekly_dma
   ============================================================================= */

CREATE OR REPLACE VIEW `your-project.marketing_analytics.stg_national_budget_weekly` AS
SELECT
  event AS event_name,
  week_start,
  channel,
  budget
FROM `your-project.marketing_analytics.raw_national_budget_weekly`
UNPIVOT (budget FOR channel IN (
  meta     AS 'Meta',
  snapchat AS 'Snapchat',
  youtube  AS 'YouTube',
  sem      AS 'SEM',
  tiktok   AS 'TikTok'
));
