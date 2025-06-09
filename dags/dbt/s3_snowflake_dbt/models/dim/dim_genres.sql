with snap_genres as (
    select
        genre_id,
        genre_name,
        dbt_valid_to
    from {{ ref('snap_genres') }}
)

select
    genre_id,
    genre_name
from snap_genres
where dbt_valid_to is null