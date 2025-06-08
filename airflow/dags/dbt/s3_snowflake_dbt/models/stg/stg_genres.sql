with raw_genres_table as (
    select
        raw_genres,
        ingestion_ts
    from {{ source('moviesapi', 'raw_genres') }}
),

flattened as (
    select
        value as raw_genres,
        ingestion_ts
    from raw_genres_table,
    lateral flatten(input => raw_genres:genres)
),

treated_genres as (
    select distinct
        raw_genres:id::int as genre_id,
        raw_genres:name::string as genre_name,
        ingestion_ts
    from flattened
)

select
    genre_id,
    genre_name,
    max(ingestion_ts) as ingestion_ts
from treated_genres
group by genre_id, genre_name


