/* =============================================================================
   snap_event_dma_share   (optional — recommended once an event goes live)
   Layer   : snapshot (table)
   Grain   : one row per event_key x DMA
   Purpose : Freezes each event's DMA shares the first time this runs for it.
             int_event_dma_share recalculates live, so if basis-period revenue
             is restated (late store data, returns), DMA budgets would shift
             mid-event and change pacing history. Freezing prevents that.
   Usage
     1. Run this file (manually or as a BigQuery scheduled query). It only
        inserts events not already saved, so re-running is safe.
     2. In int_budget_weekly_dma, change the share source from
        int_event_dma_share to snap_event_dma_share.
     3. To deliberately re-allocate an event: delete its rows here, re-run.
   ============================================================================= */

CREATE TABLE IF NOT EXISTS `your-project.marketing_analytics.snap_event_dma_share` (
  event_key       STRING,
  basis_event_key STRING,
  dma             STRING,
  dma_revenue     FLOAT64,
  dma_rev_pct     FLOAT64,
  snapshot_at     TIMESTAMP
);

INSERT INTO `your-project.marketing_analytics.snap_event_dma_share`
SELECT
  s.event_key,
  s.basis_event_key,
  s.dma,
  s.dma_revenue,
  s.dma_rev_pct,
  CURRENT_TIMESTAMP() AS snapshot_at
FROM `your-project.marketing_analytics.int_event_dma_share` s
WHERE s.event_key NOT IN (
  SELECT DISTINCT event_key
  FROM `your-project.marketing_analytics.snap_event_dma_share`
);
