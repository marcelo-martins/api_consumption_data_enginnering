with exploded as (
  select
    m.movie_id,
    m.title,
    m.release_date,
    m.language_code,
    m.file_locale,
    m.popularity,
    m.vote_average,
    m.vote_count,
    f.value::NUMBER as genre_id
  from {{ ref('stg_movies') }} m,
       lateral flatten(input => m.genre_ids) f
)

select
    movie_id,
    title,
    release_date,
    language_code,
    file_locale,
    popularity,
    vote_average,
    vote_count,
    genre_id
from exploded
