{% snapshot snap_genres %}

{{
   config(
       target_database='api_db',
       target_schema='api_schema',
       unique_key='genre_id',

       strategy='check',
       check_cols=['genre_name'],
   )
}}

select
    genre_id,
    genre_name,
    current_timestamp as snapshot_ts
from {{ ref('stg_genres') }}

{% endsnapshot %}