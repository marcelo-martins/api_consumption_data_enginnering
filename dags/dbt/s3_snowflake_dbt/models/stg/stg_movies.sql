{{
  config(
    materialized = 'incremental'
    )
}}

with raw_movies_table as (
    select
        raw_movies,
        source_file,
        ingestion_ts
    from {{ source('moviesapi', 'raw_movies') }}
),

flattened as (
    select
        value as raw_movies,
        source_file,
        ingestion_ts
    from raw_movies_table,
    lateral flatten(input => raw_movies:results)
)

select
    raw_movies:id::int as movie_id,
    raw_movies:title::string as title,
    raw_movies:original_title::string as original_title,
    raw_movies:overview::string as overview,
    raw_movies:release_date::date as release_date,
    raw_movies:original_language::string as language_code,
    raw_movies:popularity::float as popularity,
    raw_movies:vote_average::float as vote_average,
    raw_movies:vote_count::int as vote_count,
    raw_movies:genre_ids as genre_ids,
    regexp_substr(source_file, 'tmdb_movie_([a-z]{2}_[a-z]{2})', 1, 1, 'e', 1)::string as file_locale,
    to_date(regexp_substr(source_file, 'movie/([0-9]{8})/', 1, 1, 'e', 1), 'YYYYMMDD') as file_ranking_date,
    ingestion_ts
from flattened

{% if is_incremental() %}
where ingestion_ts > (select max(ingestion_ts) from {{ this }})
{% endif %}