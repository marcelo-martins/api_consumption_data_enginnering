import os
import requests
import json
from datetime import datetime

RESULT_FILEPATH = '/usr/local/airflow/include/api_outputs/'

def call_api(url, params=None, **kwargs):
    key = os.getenv('API_READ_TOKEN')

    response = requests.get(url=url, headers={'Authorization': f'Bearer {key}'}, params=params)
    try:
        response.raise_for_status()
        data = response.json()
    except requests.exceptions.RequestException as e:
        print(f"API call failed! Status: {response.status_code}, Error: {e}, Response: {response.text}")
        raise
    
    return data

def write_api_data_locally(data, endpoint, page=None, language=None, reference_name=None):

    if language:
        language = language.replace('-', '_').lower()

    if endpoint == 'movie':
        filename = f"tmdb_{endpoint}_{language}_{datetime.now().strftime('%Y%m%d')}_{page}.json"
    elif endpoint == 'references':
        filename = f"tmdb_{endpoint}_{reference_name}_{datetime.now().strftime('%Y%m%d')}.json"

    basepath = os.path.join(RESULT_FILEPATH, endpoint)
    os.makedirs(basepath, exist_ok=True)

    fullpath = os.path.join(basepath, filename)

    with open(fullpath, 'w') as f:
        json.dump(data, f)

def call_tmdb_movie(url, language='en-US', pages=5):
    endpoint = 'movie'

    for page in range(1, pages+1):
        params = {
            'language': language, 
            'page': page
        }
        data = call_api(url, params=params)
        write_api_data_locally(data, endpoint=endpoint, page=page, language=language)

def call_tmdb_references(url, reference_name):
    endpoint = 'references'

    data = call_api(url)
    write_api_data_locally(data, endpoint=endpoint, page=None, language=None, reference_name=reference_name)