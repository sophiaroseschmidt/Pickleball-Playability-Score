project_name      = "pickleball-playability-score"
resource_group    = "rg-pickleball-playability-score"
environment       = "dev"
location          = "Central US"
budget_alert_email = "sophiaroseschmidt@gmail.com"  

tags = {
  Project     = "Pickleball Playability Score"
  Environment = "Development"
  ManagedBy   = "Terraform"
}


snowflake_organization = "MFMJQAC"
snowflake_account_name = "QY30204" 
snowflake_username = "SOPHIASCHMIDT"

snowflake_password          = "nsUXyti49b1OfDlG"
snowflake_dbt_password      = "UQK2agl6o9APhZd7"
snowflake_tableau_password  = "0FQoqgazNVJlC87c"