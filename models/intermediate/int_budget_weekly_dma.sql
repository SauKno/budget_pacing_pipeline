/* =============================================================================
   int_budget_weekly_dma
   Layer      : intermediate
   Grain      : one row per event_key x week_start x DMA x budget_source x channel
   Purpose    : All planned budget (National + Co-op) at the weekly grain it is
                planned at, allocated to DMA and channel.
   Depends on : stg_events, stg_national_budget_weekly, stg_coop_budget_weekly,
                int_event_dma_share, cfg_coop_channel_split
   Used by    : fct_budget_daily_dma
   Why weekly : This is the easiest grain to reconcile against the source
                budget tables (tests/assert_budget_reconciles_to_source.sql).
   ============================================================================= */

CREATE OR REPLACE VIEW `your-project.marketing_analytics.int_budget_weekly_dma` AS

/* -----------------------------------------------------------------------------
   national_weekly
   Assigns each National budget row to its event_key.
   - The source has the event name only ('E6'), so rows are matched by name
     AND by week falling within that event's window. This keeps 2026 E6 and
     2027 E6 apart without a year column in the source.
   - The -6 day offset catches a week that starts just before the event.
   ----------------------------------------------------------------------------- */
WITH national_weekly AS (
  SELECT
    e.event_key,
    n.week_start,
    n.channel,
    n.budget
  FROM `your-project.marketing_analytics.stg_national_budget_weekly` n
  JOIN `your-project.marketing_analytics.stg_events` e
    ON n.event_name = e.event_name
   AND n.week_start BETWEEN DATE_SUB(e.start_date, INTERVAL 6 DAY) AND e.end_date
),

/* -----------------------------------------------------------------------------
   national_dma
   Splits each week's national budget across DMAs by revenue share.
   - Joining on event_key applies each event's own shares.
   - Fan-out is intentional: one week x channel row becomes one row per DMA.
   ----------------------------------------------------------------------------- */
national_dma AS (
  SELECT
    n.event_key,
    n.week_start,
    s.dma,
    'National'                     AS budget_source,
    n.channel,
    n.budget * s.dma_rev_pct  AS weekly_budget
  FROM national_weekly n
  JOIN `your-project.marketing_analytics.int_event_dma_share` s
    ON s.event_key = n.event_key
),

/* -----------------------------------------------------------------------------
   coop_weekly
   Assigns each Co-op week x DMA row to an event by date overlap.
   - Co-op has no event column, so date is the only link. Events must not
     share a week (tests/assert_events_do_not_overlap.sql).
   ----------------------------------------------------------------------------- */
coop_weekly AS (
  SELECT
    e.event_key,
    c.week_start,
    c.dma,
    c.budget
  FROM `your-project.marketing_analytics.stg_coop_budget_weekly` c
  JOIN `your-project.marketing_analytics.stg_events` e
    ON c.week_start BETWEEN DATE_SUB(e.start_date, INTERVAL 6 DAY) AND e.end_date
),

/* -----------------------------------------------------------------------------
   event_coop_split
   Resolves the Co-op channel split for each event: the event's override rows
   if any exist, otherwise the default rows (event_key IS NULL).
   - The COALESCE(..., '__default__') trick turns "override or default" into
     a single equality join.
   ----------------------------------------------------------------------------- */
split_overrides AS (
  SELECT DISTINCT event_key
  FROM `your-project.marketing_analytics.cfg_coop_channel_split`
  WHERE event_key IS NOT NULL
),

event_coop_split AS (
  SELECT
    e.event_key,
    s.channel,
    s.split_pct
  FROM `your-project.marketing_analytics.stg_events` e
  LEFT JOIN split_overrides o
    ON o.event_key = e.event_key
  JOIN `your-project.marketing_analytics.cfg_coop_channel_split` s
    ON COALESCE(s.event_key, '__default__') = COALESCE(o.event_key, '__default__')
),

/* -----------------------------------------------------------------------------
   coop_dma
   Splits each DMA's weekly Co-op total across channels.
   - budget_source stays 'Co-op', so Tableau can still separate Co-op from National
     within a channel (Meta total = National Meta + Co-op Meta).
   ----------------------------------------------------------------------------- */
coop_dma AS (
  SELECT
    c.event_key,
    c.week_start,
    c.dma,
    'Co-op'                  AS budget_source,
    s.channel,
    c.budget * s.split_pct   AS weekly_budget
  FROM coop_weekly c
  JOIN event_coop_split s
    ON s.event_key = c.event_key
)

/* -----------------------------------------------------------------------------
   Final: stack National and Co-op.
   - UNION ALL (not UNION) keeps every row and skips a pointless de-dup step;
     both inputs share identical column order and types.
   ----------------------------------------------------------------------------- */
SELECT * FROM national_dma
UNION ALL
SELECT * FROM coop_dma;
