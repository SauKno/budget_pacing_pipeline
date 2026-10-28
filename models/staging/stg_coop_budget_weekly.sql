/* =============================================================================
   stg_coop_budget_weekly
   Layer      : staging
   Grain      : one row per week_start x DMA
   Source     : raw_coop_budget_weekly
   Purpose    : Co-op weekly budget, already planned by DMA.
   Notes
     - Aggregated to week x DMA here, BEFORE any joins, so line-item detail in
       the source (vendors, line items) can't duplicate rows downstream.
     - DMA names standardized to match the revenue source.
     - Channel split and event assignment happen in int_budget_weekly_dma.
   Used by    : int_budget_weekly_dma
   ============================================================================= */

CREATE OR REPLACE VIEW `your-project.marketing_analytics.stg_coop_budget_weekly` AS
SELECT
  fiscal_week_start_date  AS week_start,
  UPPER(TRIM(dma))        AS dma,
  SUM(budget)             AS budget
FROM `your-project.marketing_analytics.raw_coop_budget_weekly`
WHERE dma IS NOT NULL
GROUP BY 1, 2;
