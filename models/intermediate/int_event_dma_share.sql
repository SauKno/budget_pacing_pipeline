/* =============================================================================
   int_event_dma_share
   Layer      : intermediate
   Grain      : one row per event_key x DMA
   Purpose    : Each DMA's share of revenue in the event's "basis" event. These
                shares are the weights used to split national budget by DMA.
   Depends on : stg_events, stg_revenue_dma_daily, cfg_event_basis_map
   Used by    : int_budget_weekly_dma
                (or snapshots/snap_event_dma_share.sql, to freeze shares)
   ============================================================================= */

CREATE OR REPLACE VIEW `your-project.marketing_analytics.int_event_dma_share` AS

/* -----------------------------------------------------------------------------
   event_basis
   Picks the basis event for each target event.
   - A planner override in cfg_event_basis_map wins.
   - Otherwise LAG() takes the immediately preceding event by start date.
     Ordering by date (not name) carries across years: 2027_E1 -> 2026_E6.
   ----------------------------------------------------------------------------- */
WITH event_basis AS (
  SELECT
    e.event_key AS target_event_key,
    COALESCE(
      m.basis_event_key,
      LAG(e.event_key) OVER (ORDER BY e.start_date)
    ) AS basis_event_key
  FROM `your-project.marketing_analytics.stg_events` e
  LEFT JOIN `your-project.marketing_analytics.cfg_event_basis_map` m
    ON m.target_event_key = e.event_key
),

/* -----------------------------------------------------------------------------
   basis_dma_revenue
   Total revenue per DMA over the basis event's date window.
   - Range join (date BETWEEN start AND end) links daily revenue to the window.
   - HAVING > 0 drops DMAs with zero or net-negative revenue (returns), which
     would otherwise receive a zero or negative budget.
   ----------------------------------------------------------------------------- */
basis_dma_revenue AS (
  SELECT
    eb.target_event_key,
    eb.basis_event_key,
    r.dma,
    SUM(r.revenue) AS dma_revenue
  FROM event_basis eb
  JOIN `your-project.marketing_analytics.stg_events` b
    ON b.event_key = eb.basis_event_key
  JOIN `your-project.marketing_analytics.stg_revenue_dma_daily` r
    ON r.date BETWEEN b.start_date AND b.end_date
  GROUP BY 1, 2, 3
  HAVING SUM(r.revenue) > 0
)

/* -----------------------------------------------------------------------------
   Final: share of total, calculated separately for each target event.
   - SUM() OVER (PARTITION BY event) gets the event total without a second
     aggregation and self-join.
   - Shares sum to 1.0 per event, so allocated budget adds back up exactly to
     the national total (tests/assert_dma_shares_sum_to_one.sql).
   - basis_event_key is kept so anyone can see where the shares came from.
   ----------------------------------------------------------------------------- */
SELECT
  target_event_key AS event_key,
  basis_event_key,
  dma,
  dma_revenue,
  SAFE_DIVIDE(
    dma_revenue,
    SUM(dma_revenue) OVER (PARTITION BY target_event_key)
  ) AS dma_rev_pct
FROM basis_dma_revenue;
