#CREATE ROLE api_role
resource "snowflake_account_role" "api_role" {
  name = "API_ROLE"
  comment = "Role for API"
}

#CREATE DATABASE api_db
resource "snowflake_database" "api_db" {
  name = "API_DB"
  comment = "Main DB for the project"
}

#CREATE SCHEMA api_db.api_schema
resource "snowflake_schema" "api_schema" {
    name = "API_SCHEMA"
    database = snowflake_database.api_db.name
    comment = "Main schema for api_db"
}

# CREATE OR REPLACE WAREHOUSE API_WH
#   WAREHOUSE_SIZE = XSMALL
#   AUTO_SUSPEND = 60
#   AUTO_RESUME = TRUE
#   INITIALLY_SUSPENDED = TRUE;
resource "snowflake_warehouse" "api_wh" {
  name = "API_WH"
  auto_resume = true
  auto_suspend = 60
  warehouse_size = "XSMALL"
  initially_suspended = true
}

# GRANT USAGE ON DATABASE API_DB TO ROLE api_role
resource "snowflake_grant_privileges_to_account_role" "api_db_usage" {
  account_role_name = snowflake_account_role.api_role.name
  privileges = [ "USAGE" ]

  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.api_db.name
  }
  
}

#GRANT USAGE ON WAREHOUSE API_WH TO ROLE API_ROLE
resource "snowflake_grant_privileges_to_account_role" "privileges_to_wh" {
  account_role_name = snowflake_account_role.api_role.name
  privileges = [ "USAGE" ]

  on_account_object {
    object_name = snowflake_warehouse.api_wh.name
    object_type = "WAREHOUSE"
  }
}

# GRANT USAGE ON SCHEMA api_db.api_schema to ROLE api_role
# GRANT CREATE STAGE ON SCHEMA api_db.api_schema TO ROLE api_role
resource "snowflake_grant_privileges_to_account_role" "api_schema_usage" {
  account_role_name = snowflake_account_role.api_role.name
  privileges = [ "USAGE", "CREATE STAGE", "CREATE VIEW", "CREATE TABLE" ]

  # Can't be on_account_object because schemas are not visible from the whole account
  # Also, can't be on_schema_object because we want to grant the whole schema not some objects inside it
  on_schema { 
    schema_name = snowflake_schema.api_schema.fully_qualified_name
  }
  
}

# grant insert, update, delete, select on all tables in schema api_db.api_schema to role api_role
resource "snowflake_grant_privileges_to_account_role" "api_dml_schema_tables" {
  account_role_name = snowflake_account_role.api_role.name
  privileges = [ "INSERT", "UPDATE", "DELETE", "SELECT" ]

  on_schema_object {
    all {
      object_type_plural = "TABLES"
      # Fully qualified name to get api_db.schema_name instead of just schema_name
      in_schema = snowflake_schema.api_schema.fully_qualified_name
    }
  }
}

# CREATE OR REPLACE STORAGE INTEGRATION snowflake_s3
#   TYPE = EXTERNAL_STAGE
#   STORAGE_PROVIDER = 'S3'
#   ENABLED = TRUE
#   STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::051826728170:role/SnowflakeAccessRole'
#   STORAGE_ALLOWED_LOCATIONS = ('*')
resource "snowflake_storage_integration" "s3_integration" {
  name = "SNOWFLAKE_S3"
  enabled = true
  storage_provider = "S3"
  storage_aws_role_arn = "arn:aws:iam::051826728170:role/SnowflakeAccessRole"
  storage_allowed_locations = [ "*" ]
  type = "EXTERNAL_STAGE"
}

# grant usage on integration snowflake_s3 to role api_role
resource "snowflake_grant_privileges_to_account_role" "usage_integration" {
  account_role_name = snowflake_account_role.api_role.name
  privileges = [ "USAGE" ]

  on_account_object {
    object_name = snowflake_storage_integration.s3_integration.name
    object_type = "INTEGRATION"
  }
}

# grant role api_role to user marcelobmartins219
resource "snowflake_grant_account_role" "grant_role_to_user" {
  role_name = snowflake_account_role.api_role.name
  user_name = var.snowflake_user
}

# CREATE OR REPLACE STAGE s3_stage
#   STORAGE_INTEGRATION = snowflake_s3
#   URL = 's3://apibucket219/'
#   FILE_FORMAT = (TYPE = JSON);
resource "snowflake_stage" "s3_stage" {
  database = snowflake_database.api_db.name
  schema = snowflake_schema.api_schema.name
  name = "S3_STAGE"
  storage_integration = snowflake_storage_integration.s3_integration.name
  url = "s3://apibucket219/"
  file_format = "TYPE = JSON"
}

#GRANT USAGE, READ ON STAGE api_db.api_schema.s3_stage TO ROLE API_ROLE;
resource "snowflake_grant_privileges_to_account_role" "privileges_on_stage" {
  account_role_name = snowflake_account_role.api_role.name
  privileges = [ "USAGE", "READ" ]

  on_schema_object {
    object_name = snowflake_stage.s3_stage.fully_qualified_name
    object_type = "STAGE"
  }
}

#TABLES CREATION

# CREATE TABLE raw_json_movies (
#   raw VARIANT,
#   ingestion_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
# );
resource "snowflake_table" "raw_json_movies" {
  name = "RAW_JSON_MOVIES"
  database = snowflake_database.api_db.name
  schema = snowflake_schema.api_schema.name

  column {
    name = "RAW_MOVIES"
    type = "VARIANT"
  }

  column {
    name = "SOURCE_FILE"
    type = "STRING"
  }

  column {
    name = "INGESTION_TS"
    type = "TIMESTAMP_NTZ(9)"
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }
}

# CREATE TABLE raw_json_genres (
#   raw VARIANT,
#   ingestion_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
# );
resource "snowflake_table" "raw_json_genres" {
  name = "RAW_JSON_GENRES"
  database = snowflake_database.api_db.name
  schema = snowflake_schema.api_schema.name

  column {
    name = "RAW_GENRES"
    type = "VARIANT"
  }

  column {
    name = "INGESTION_TS"
    type = "TIMESTAMP_NTZ(9)"
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }
}

# CREATE TABLE raw_json_languages (
#   raw VARIANT,
#   ingestion_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
# );
resource "snowflake_table" "raw_json_languages" {
  name = "RAW_JSON_LANGUAGES"
  database = snowflake_database.api_db.name
  schema = snowflake_schema.api_schema.name

  column {
    name = "RAW_LANGUAGES"
    type = "VARIANT"
  }

  column {
    name = "INGESTION_TS"
    type = "TIMESTAMP_NTZ(9)"
    default {
      expression = "CURRENT_TIMESTAMP()"
    }
  }
}

#GRANT SELECT ON TABLE x TO ROLE role
resource "snowflake_grant_privileges_to_account_role" "access_to_tables" {
  for_each = toset([ "RAW_JSON_MOVIES", "RAW_JSON_GENRES", "RAW_JSON_LANGUAGES" ])
  account_role_name = snowflake_account_role.api_role.name
  privileges = [ "SELECT", "INSERT" ]

  on_schema_object {
    object_type = "TABLE"
    object_name = "${snowflake_database.api_db.name}.${snowflake_schema.api_schema.name}.${each.value}"
  }
}