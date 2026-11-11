#!/bin/bash
# Signalpost: download data + run 100-company smoke test (no model calls)
set -e
cd "$(dirname "$0")/.."
command -v uv >/dev/null || pip install --user -q uv
export PATH=$HOME/.local/bin:$PATH
uv sync -q
[ -s brreg-enheter.csv ] || curl -sL 'https://data.brreg.no/enhetsregisteret/api/enheter/lastned/csv' -o brreg-enheter.csv
[ -s signalpost-universe.jsonl.gz ] || curl -sL 'https://builderr.ai/signalpost-company-universe-2025.jsonl.gz' -o signalpost-universe.jsonl.gz
uv run python select_entry_batch.py --universe signalpost-universe.jsonl.gz --count 100 --output entry-companies.jsonl
cp entry-companies.jsonl smoke-companies.jsonl
mkdir -p out
uv run python scripts/run_competition_batch.py --organisations smoke-companies.jsonl --bulk brreg-enheter.csv \
  --profiles-output out/smoke-profiles.jsonl --output out/smoke-envelopes.jsonl --report out/smoke-report.json \
  --run-id smoke-001 --expected-count 100
echo SMOKE_DONE; python3 -c "import json;r=json.load(open('out/smoke-report.json'));print({k:v for k,v in r.items() if not isinstance(v,(list,dict))})"
