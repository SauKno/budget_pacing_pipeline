/* =============================================================================
   cfg_coop_channel_split
   Layer   : config (editable table, not a view)
   Grain   : one row per (event_key or default) x channel
   Purpose : Defines how each DMA's weekly Co-op budget is split across
             channels.
   How it works
     - Rows with event_key = NULL are the DEFAULT split for all events.
     - Rows with an event_key OVERRIDE the default for that event only.
     - This keeps history intact: changing the split for a future event is a
       new override row, not an edit that silently rewrites past events.
   Rules
     - Splits must sum to 1.0 per event_key / default
       (tests/assert_coop_split_sums_to_one.sql).
     - Channel labels must match National and actual-spend labels exactly
       ('Meta', 'YouTube', ...).
   Edit    : Example override for one event:
               INSERT INTO `your-project.marketing_analytics.cfg_coop_channel_split`
               VALUES ('2027_E2', 'Meta', 0.6), ('2027_E2', 'YouTube', 0.4);
   ============================================================================= */

CREATE TABLE IF NOT EXISTS `your-project.marketing_analytics.cfg_coop_channel_split` (
  event_key STRING,            -- NULL = default for all events
  channel   STRING  NOT NULL,
  split_pct FLOAT64 NOT NULL   -- 0.5 = 50%
);

-- Seed the current default (50% Meta / 50% YouTube) only if the table is empty,
-- so re-running this file never overwrites edits.
INSERT INTO `your-project.marketing_analytics.cfg_coop_channel_split` (event_key, channel, split_pct)
SELECT event_key, channel, split_pct
FROM UNNEST([
  STRUCT(CAST(NULL AS STRING) AS event_key, 'Meta'    AS channel, 0.5 AS split_pct),
  STRUCT(CAST(NULL AS STRING) AS event_key, 'YouTube' AS channel, 0.5 AS split_pct)
])
WHERE NOT EXISTS (
  SELECT 1 FROM `your-project.marketing_analytics.cfg_coop_channel_split`
);
