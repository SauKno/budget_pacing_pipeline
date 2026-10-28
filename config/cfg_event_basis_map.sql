/* =============================================================================
   cfg_event_basis_map
   Layer   : config (editable table, not a view)
   Grain   : one row per target event
   Purpose : Lets planners choose which past event's revenue sets each event's
             DMA budget shares (e.g. "same event last year" when seasonality
             matters). Events with no row here fall back to the previous event
             by date (see int_event_dma_share).
   Edit    : INSERT / UPDATE rows directly; no SQL model changes needed.
             Example:
               INSERT INTO `your-project.marketing_analytics.cfg_event_basis_map`
               VALUES ('2027_E1', '2026_E1', 'Same event last year');
   ============================================================================= */

CREATE TABLE IF NOT EXISTS `your-project.marketing_analytics.cfg_event_basis_map` (
  target_event_key STRING NOT NULL,  -- event being budgeted, e.g. '2027_E1'
  basis_event_key  STRING NOT NULL,  -- event whose revenue sets the shares, e.g. '2026_E1'
  note             STRING            -- why this basis was chosen
);
