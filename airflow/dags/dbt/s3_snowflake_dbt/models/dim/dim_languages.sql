with stg_languages as (
    select
        language_iso_code,
        language_name
    from {{ ref('stg_languages') }}
)

select
    language_iso_code,
    language_name
from stg_languages