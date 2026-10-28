/* Test: DMA revenue shares sum to 1.0 for each event.
   Why : If shares don't sum to 1, allocated National budget won't add back up to
         the national total.
   Pass: returns 0 rows. */
SELECT
  event_key,
  SUM(dma_rev_pct) AS total_share
FROM `your-project.marketing_analytics.int_event_dma_share`
GROUP BY 1
HAVING ABS(SUM(dma_rev_pct) - 1) > 1e-9;
