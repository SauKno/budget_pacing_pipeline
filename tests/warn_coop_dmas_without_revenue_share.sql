/* Warning (does not fail the run): Co-op DMAs with no revenue share.
   Why : Usually a DMA name mismatch between the Co-op and revenue sources
         (e.g. 'DALLAS-FT. WORTH' vs 'DALLAS-FT WORTH'). Can be legitimate for
         a new market with no basis-period revenue. Review each row.
   Pass: returns 0 rows, or only rows you have confirmed are expected. */
SELECT DISTINCT
  w.event_key,
  w.dma
FROM `your-project.marketing_analytics.int_budget_weekly_dma` w
LEFT JOIN `your-project.marketing_analytics.int_event_dma_share` s
  ON s.event_key = w.event_key
 AND s.dma = w.dma
WHERE w.budget_source = 'Co-op'
  AND s.dma IS NULL;
