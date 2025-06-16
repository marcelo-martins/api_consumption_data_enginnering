{{
  config(
    materialized = 'incremental'
    )
}}

with raw_languages_table as (
    select
        raw_languages,
        ingestion_ts
    from {{ source('moviesapi', 'raw_languages') }}
),

flattened as (
    select
        value as raw_languages,
        ingestion_ts
    from raw_languages_table,
    lateral flatten(input => raw_languages)
),

treated_languages as (
    select
        raw_languages:iso_639_1::string as language_iso_code,
        raw_languages:english_name::string as language_name,
        ingestion_ts
    from flattened
)

select
    language_iso_code,
    language_name,
    max(ingestion_ts) as ingestion_ts
from treated_languages

{% if is_incremental() %}
where ingestion_ts > (select max(ingestion_ts) from {{ this }})
{% endif %}

group by language_iso_code, language_name

