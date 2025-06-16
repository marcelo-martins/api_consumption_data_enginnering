{% docs __overview__ %}
# dbt Model Overview

This document provides a high-level overview of the dbt models defined in the project, their structure, dependencies, and intended behavior.

---

## 🧱 Project Structure

- **Project name**: `s3_snowflake_dbt`
- **Warehouse**: Snowflake
- **Materializations used**:
  - `incremental` for staging models
  - `table` or `view` for final models
- **Target schema**: `API_SCHEMA`

---

## 📁 Model Layers

### 1. `raw/` (source data)
These are the source tables ingested via Airflow `COPY INTO` commands from S3, that comes from the TMDB API.

- `raw_json_movies`
- `raw_json_genres`
- `raw_json_languages`

They are declared using `source()` blocks in `models/sources.yml`.

---

### 2. `stg/` (staging layer)
These models clean and normalize raw JSON data into structured formats, and often include:

- Type casting
- Deduplication
- Filtering
- Flattening nested fields

#### Example models:
| Model                | Description                                       | Materialization |
|----------------------|---------------------------------------------------|-----------------|
| `stg_movies`         | Parses raw movie JSON into structured columns     | `incremental`   |
| `stg_genres`         | Normalizes genre reference data                   | `incremental`   |
| `stg_languages`      | Normalizes language metadata                      | `incremental`   |

> **Incremental logic** ensures only new data (e.g. based on `ingestion_ts`) is processed.

---

### 3. `dim/` and `fact/`:
This layer contains the dimensions and facts for the models.

#### Examples:
| Model              | Description                              | Type      |
|--------------------|------------------------------------------|-----------|
| `dim_genres`       | Genre dimension for reporting            | table     |
| `dim_languages`    | Cleaned language dimension               | table     |
| `fct_movie_views`  | Fact table for movie popularity metrics  | table     |

These models are typically materialized as `table` and joined with eachother.

---

## Incremental Strategy

Staging models are materialized as `incremental` using a filter like:

```sql
where ingestion_ts > (select max(ingestion_ts) from {{ this }})
{% enddocs %}