---
trigger: always_on
---

Cursor rules — dbt artifacts (JSON) + schemas + practical handling

Project uses BigQuery Standard SQL and dbt


# BigQuery
Always favor checking table dependancies and structure using dbt artifacts over using the bq tool.
You can access bigquery using "bq" command line tool
When you use "bq query" always append --maximum_bytes_billed=100000000000
When specifying table names in queries FROM, always use `a.b.c` instead of `a`.`b`.`c` notation
When asking me if you can run a `bq query` command, show me a well formated version of this query.
Use json result format when using "bq" command line tool including when querying bigquery

# virtual environment
activate project virtual environment with "source venv/bin/activate"

# JSON
jq is installed and should be used for processing json

# DBT
Test models by using "dbt run"
You can compile models to check the jinja code by using "dbt compile"
Always generate one YML file per SQL model to make things easier to find. It must have the same name as the model file. ex: stg_this_and_that.sql stg_this_and_that.yml

## Where artifacts live
- Default output directory: target/
- Artifacts are often VERY LARGE (manifest.json and catalog.json especially). Avoid loading entire files into memory or into the editor/LLM context.

## Always prefer: interrogate artifacts with jq (streaming)
Use jq to extract only what you need (keys, specific nodes, filtered subsets) instead of opening full JSON.

## Canonical docs
- Artifact overview: https://docs.getdbt.com/reference/artifacts/dbt-artifacts
- Artifact schemas root: https://schemas.getdbt.com

## Artifacts + schema URLs (versioned)
NOTE: “vX” varies by your dbt Core version. Keep it dynamic and don’t hardcode unless required.

1) target/manifest.json
- What it is: full project graph + metadata (nodes, sources, macros, exposures, metrics, semantic_models, parent_map/child_map, docs, configs)
- Schema: https://schemas.getdbt.com/dbt/manifest/vX.json
- Use for: lineage/DAG, node metadata, refs/depends_on, owners/docs

2) target/run_results.json
- What it is: execution results for run/test/seed/snapshot (status, timing, adapter_response, failures, messages)
- Schema: https://schemas.getdbt.com/dbt/run-results/vX.json
- Use for: CI outcomes, observability, failure triage

3) target/catalog.json
- What it is: docs catalog (relations + columns + types + stats) from database introspection
- Schema: https://schemas.getdbt.com/dbt/catalog/vX.json
- Use for: column metadata, docs site, “what’s in the warehouse”

4) target/sources.json
- What it is: source freshness output (loaded_at, freshness status)
- Schema: https://schemas.getdbt.com/dbt/sources/vX.json
- Use for: freshness checks + alerts

5) target/graph_summary.json
- What it is: lightweight graph counts/summary (smallest artifact; quick health checks)
- Schema: https://schemas.getdbt.com/dbt/graph-summary/vX.json
- Use for: fast stats without parsing manifest

6) target/semantic_manifest.json (dbt Semantic Layer; present in newer dbt versions / when enabled)
- What it is: semantic-layer definitions only (semantic_models, entities, measures, dimensions)
- Schema: https://schemas.getdbt.com/dbt/semantic-manifest/vX.json
- Use for: semantic layer tooling and metrics layer inspection

## Operational guidance (important)
- Do NOT paste full artifacts into chats/tools; extract a minimal slice with jq.
- When debugging lineage, start with manifest.json, but query it with jq.
- When diagnosing failures, start with run_results.json.
- When inspecting columns/types, use catalog.json (via jq).
- When checking freshness, use sources.json.
- Use schemas.getdbt.com to validate artifacts; schema versions must match artifact versions.

## Project standards
Files specifying sources name format is src_....yml

## DBT profile for the project is:
  outputs:
    dev:
      dataset: lmg_dev
      job_creation_timeout_seconds: 30
      job_execution_timeout_seconds: 21600
      keyfile: /Users/lmg/.dbt/billets-canadiens-374eb632c67c.json
      method: service-account
      priority: interactive
      project: billets-canadiens
      retries: 2
      threads: 8
      type: bigquery
    prod:
      dataset: prod
      job_creation_timeout_seconds: 30
      job_execution_timeout_seconds: 21600
      keyfile: /Users/lmg/.dbt/billets-canadiens-374eb632c67c.json
      method: service-account
      priority: interactive
      project: billets-canadiens
      retries: 2
      threads: 8
      type: bigquery
  target: dev


## DBT info
Running with dbt=1.11.0-rc3
dbt version: 1.11.0-rc3
python version: 3.13.2
python path: /Users/lmg/code/billets-canadiens-dbt/venv/bin/python3.13
os info: macOS-15.7.1-arm64-arm-64bit-Mach-O
adapter type: bigquery
adapter version: 1.10.3
Connection:
  method: service-account
  database: billets-canadiens
  execution_project: billets-canadiens
  schema: lmg_dev
  location: None
  priority: interactive
  maximum_bytes_billed: None
  impersonate_service_account: None
  job_retry_deadline_seconds: None
  job_retries: 2
  job_creation_timeout_seconds: 30
  job_execution_timeout_seconds: 21600
  timeout_seconds: 21600
  client_id: None
  token_uri: None
  compute_region: None
  dataproc_cluster_name: None
  gcs_bucket: None
  dataproc_batch: None