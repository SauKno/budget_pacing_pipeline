#!/usr/bin/env bash
# Runs every data quality test in tests/.
# Each test returns the rows that FAIL the check, so 0 rows = pass.
#   assert_*.sql : failures stop the run with a non-zero exit code
#   warn_*.sql   : reported for review, never fail the run
# Usage: ./run_tests.sh
set -euo pipefail
cd "$(dirname "$0")"

failed=0

for f in tests/*.sql; do
  name="$(basename "${f}" .sql)"
  rows="$(bq query --use_legacy_sql=false --quiet --format=csv --max_rows=1000 "$(cat "${f}")" \
          | tail -n +2 | grep -c . || true)"

  if [[ "${rows}" -eq 0 ]]; then
    echo "PASS  ${name}"
  elif [[ "${name}" == warn_* ]]; then
    echo "WARN  ${name}  (${rows} rows to review)"
  else
    echo "FAIL  ${name}  (${rows} rows)"
    failed=1
  fi
done

if [[ "${failed}" -eq 1 ]]; then
  echo "One or more tests failed. Run the failing file in BigQuery to see the rows."
  exit 1
fi
echo "All tests passed."
