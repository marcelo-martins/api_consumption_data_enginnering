from airflow.providers.amazon.aws.hooks.s3 import S3Hook
import os
import re

def upload_files_to_s3(bucket_name, local_folder):
    hook = S3Hook('s3_conn')
    
    for root, _, files in os.walk(local_folder):
        for file in files:
            local_path = os.path.join(root, file)
            
            relative_path = os.path.relpath(local_path, local_folder)
            
            subfolder, filename = relative_path.replace("\\", "/").split('/')

            date = re.findall('\d{8}', filename)[0]
            s3_path = f"{subfolder}/{date}/{filename}"

            hook.load_file(
                filename=local_path,
                key=s3_path,
                bucket_name=bucket_name,
                replace=True
            )