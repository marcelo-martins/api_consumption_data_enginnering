from airflow import DAG
from datetime import datetime
from cosmos import DbtDag, ProjectConfig, ProfileConfig
from cosmos.profiles import SnowflakeUserPasswordProfileMapping

# Path to your dbt project and profiles
DBT_PROJECT_PATH = "/usr/local/airflow/dags/dbt/s3_snowflake_dbt"
CONN_ID = "snowflake_conn"  # Your Airflow Snowflake connection ID
DBT_SCHEMA = "API_SCHEMA"  # e.g., analytics
DBT_DATABASE = "API_DB"  # e.g., analytics_db

# Cosmos profile config for Snowflake
profile_config = ProfileConfig(
    profile_name="default",
    target_name="dev",
    profile_mapping=SnowflakeUserPasswordProfileMapping(
        conn_id=CONN_ID,
        profile_args={
            "schema": DBT_SCHEMA,
            "database": DBT_DATABASE,
            "warehouse": "API_WH"
        },
    ),
)

# Create the full DAG from the dbt project
dbt_dag = DbtDag(
    dag_id="dbt_snowflake_cosmos_dag",
    project_config=ProjectConfig(DBT_PROJECT_PATH),
    profile_config=profile_config,
    schedule_interval=None,
    start_date=datetime(2023, 1, 1),
    catchup=False,
    default_args={"retries": 1},
    operator_args={"install_deps": True},
)
