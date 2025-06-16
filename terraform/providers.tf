terraform {
  required_providers {
    snowflake = {
        source = "Snowflake-Labs/snowflake"
        version = "~> 1.0.5"
    }
  }
}

provider "snowflake" {
  organization_name = var.snowflake_org_name
  account_name = var.snowflake_account_name
  user = var.snowflake_user
  password = var.snowflake_password
  
  preview_features_enabled = ["snowflake_current_account_datasource", "snowflake_storage_integration_resource", "snowflake_stage_resource", "snowflake_table_resource"]

}
