/* =============================================================================
   stg_revenue_dma_daily
   Layer      : staging
   Grain      : one row per date x DMA
   Source     : raw_store_revenue_daily
   Purpose    : Daily store revenue by DMA, cleaned once for all downstream use.
   Notes
     - DMA names are standardized (UPPER/TRIM) here and in every other staging
       model, so DMAs match across sources. This is the main protection against
       one DMA splitting into two rows.
     - Rows with a NULL DMA are dropped: revenue that can't be tied to a DMA
       can't drive a DMA budget share.
     - Negative days (returns) are kept here; net-negative DMAs are excluded
       at the share step, where the full event window is known.
   Used by    : int_event_dma_share
   ============================================================================= */

CREATE OR REPLACE VIEW `your-project.marketing_analytics.stg_revenue_dma_daily` AS
SELECT
  date,
  UPPER(TRIM(nielsen_dma))  AS dma,
  SUM(total_store_revenue)  AS revenue
FROM `your-project.marketing_analytics.raw_store_revenue_daily`
WHERE nielsen_dma IS NOT NULL
GROUP BY 1, 2;
