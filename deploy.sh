#!/usr/bin/env bash
# Deploys config tables and views to BigQuery in dependency order.
# Each view depends on the ones above it, so order matters.
# Usage: ./deploy.sh
set -euo pipefail
cd "$(dirname "$0")"

FILES=(
  # Config tables (safe to re-run: create if missing, seed only if empty)
  config/cfg_event_basis_map.sql
  config/cfg_coop_channel_split.sql

  # Staging: one clean view per source
  models/staging/stg_events.sql
  models/staging/stg_revenue_dma_daily.sql
  models/staging/stg_national_budget_weekly.sql
  models/staging/stg_coop_budget_weekly.sql
  models/staging/stg_fiscal_calendar.sql

  # Intermediate: business logic
  models/intermediate/int_event_dma_share.sql
  models/intermediate/int_budget_weekly_dma.sql

  # Mart: Tableau data source
  models/marts/fct_budget_daily_dma.sql
)

for f in "${FILES[@]}"; do
  echo "Deploying ${f}"
  bq query --use_legacy_sql=false --quiet "$(cat "${f}")" > /dev/null
done

echo "Done. Run ./run_tests.sh to validate."
