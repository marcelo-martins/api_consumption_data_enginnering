from airflow import DAG

from airflow.decorators import task
from airflow.providers.amazon.aws.transfers.local_to_s3 import LocalFilesystemToS3Operator

from datetime import datetime

from plugins.nba_api.call_api import call_tmdb_movie, call_tmdb_references
import os

default_args = {
    'owner': 'airflow',
    'start_date': datetime(2023, 1, 1),
    'retries': 1,
}
API_URL_MOVIE = 'https://api.themoviedb.org/3/trending/movie/day'
API_URL_LANGUAGE = 'https://api.themoviedb.org/3/configuration/languages'
API_URL_MOVIE_GENRES = 'https://api.themoviedb.org/3/genre/movie/list'

with DAG(
    dag_id='api_consumption',
    default_args=default_args,
    schedule=None,
    catchup=False
) as dag:
    
    @task.python(task_id='read_api_movies_en_us')
    def get_trending_movies_en_us():
        response = call_tmdb_movie(API_URL_MOVIE, language='en-US', pages=1)
        print(f'inside dag {response}')
        return response
    
    @task.python(task_id='read_api_movies_pt_br')
    def get_trending_movies_pt_br():
        response = call_tmdb_movie(API_URL_MOVIE, language='pt-BR', pages=1)
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
    
    # @task.python(task_id='extract_values')
    # def extract_values(ti=None):
    #     filebasepath, filename = ti.xcom_pull(task_ids='read_api')
    #     print(f'inside dag {filebasepath}, {filename}')
    #     miniofilepath = f's3://{os.getenv('BUCKET_NAME')}/{filename}'
    #     return {'miniofilepath': miniofilepath, 'filename': filebasepath + filename}

    # create_object = LocalFilesystemToS3Operator(
    #     task_id="create_object",
    #     filename="{{ti.xcom_pull(task_ids='extract_values')['filename']}}",
    #     dest_key="{{ti.xcom_pull(task_ids='extract_values')['miniofilepath']}}",
    #     replace=True,
    #     aws_conn_id='s3_conn'
    # )

    get_trending_movies_en_us() >> get_trending_movies_pt_br() >> get_languages() >> get_genres()
    #>> extract_values() >> create_object


if __name__ == "__main__":
    dag.test()