from airflow import DAG

from airflow.decorators import task
from airflow.providers.common.sql.operators.sql import SQLExecuteQueryOperator

from datetime import datetime

from plugins.api_utils.call_api import call_tmdb_movie, call_tmdb_references
from plugins.api_utils.upload_to_s3 import upload_files_to_s3
import os

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2023, 1, 1),
    'retries': 1,
}
API_URL_MOVIE = 'https://api.themoviedb.org/3/trending/movie/day'
API_URL_LANGUAGE = 'https://api.themoviedb.org/3/configuration/languages'
API_URL_MOVIE_GENRES = 'https://api.themoviedb.org/3/genre/movie/list'
PAGES = 5

with DAG(
    dag_id='api_consumption',
    default_args=default_args,
    schedule=None,
    catchup=False
) as dag:
    
    @task.python(task_id='read_api_movies_en_us')
    def get_trending_movies_en_us():
        response = call_tmdb_movie(API_URL_MOVIE, language='en-US', pages=PAGES)
        print(f'inside dag {response}')
        return response
    
    @task.python(task_id='read_api_movies_pt_br')
    def get_trending_movies_pt_br():
        response = call_tmdb_movie(API_URL_MOVIE, language='pt-BR', pages=PAGES)
        print(f'inside dag {response}')
        return response
    
    @task.python(task_id='read_api_languages')
    def get_languages():
        response = call_tmdb_references(API_URL_LANGUAGE, reference_name='languages')
        print(f'inside dag {response}')
        return response
    
    @task.python(task_id='read_api_genres')
    def get_genres():
        response = call_tmdb_references(API_URL_MOVIE_GENRES, reference_name='genres')
        print(f'inside dag {response}')
        return response
    
    @task.python(task_id='upload_to_s3')
    def call_upload_to_s3():
        response = upload_files_to_s3(os.getenv('BUCKET_NAME'), '/usr/local/airflow/include/api_outputs')
        print(f'inside dag {response}')
        return response

    copy_movies_to_snowflake = SQLExecuteQueryOperator(
        task_id="copy_movies_to_snowflake",
        sql="""
            COPY INTO api_db.api_schema.raw_json_movies (raw_movies, ingestion_ts, source_file)
            FROM (
                SELECT
                    $1,
                    CURRENT_TIMESTAMP(),
                    METADATA$FILENAME
                FROM @s3_stage
            )
            PATTERN = 'movie/[0-9]{8}/tmdb_movie.*\\.json'
        """,
        conn_id="snowflake_conn"
    )

    copy_genres_to_snowflake = SQLExecuteQueryOperator(
        task_id="copy_genres_to_snowflake",
        sql="""
            COPY INTO api_db.api_schema.raw_json_genres (raw_genres, ingestion_ts)
            FROM (
                SELECT
                    $1,
                    CURRENT_TIMESTAMP()
                FROM @s3_stage
            )
            PATTERN = 'movie/[0-9]{8}/tmdb_references_genres.*\\.json'
        """,
        conn_id="snowflake_conn"
    )

    copy_languages_to_snowflake = SQLExecuteQueryOperator(
        task_id="copy_languages_to_snowflake",
        sql="""
            COPY INTO api_db.api_schema.raw_json_languages (raw_languages, ingestion_ts)
            FROM (
                SELECT
                    $1,
                    CURRENT_TIMESTAMP()
                FROM @s3_stage
            )
            PATTERN = 'movie/[0-9]{8}/tmdb_references_languages.*\\.json'
        """,
        conn_id="snowflake_conn"
    )

    (get_trending_movies_en_us() >> get_trending_movies_pt_br() >> get_languages() >> get_genres()
    >> call_upload_to_s3() >> copy_movies_to_snowflake >> copy_genres_to_snowflake >> copy_languages_to_snowflake)

if __name__ == "__main__":
    dag.test()