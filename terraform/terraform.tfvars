project_name      = "pickleball-playability-score"
resource_group    = "rg-pickleball-playability-score"
environment       = "dev"
location          = "Central US"
db_admin_username = "pgadmin"
db_admin_password = "zHnwfIJgQCeFyqMd"

# Add your IP address to access database from your computer
# Find your IP: curl ifconfig.me
allowed_ip_addresses = [
  "75.162.131.118"
]

budget_alert_email = "sophiaroseschmidt@gmail.com"  

tags = {
  Project     = "Pickleball Playability Score"
  Environment = "Development"
  ManagedBy   = "Terraform"
}


snowflake_account  = "MFMJQAC-QY30204"  
snowflake_username = "SOPHIASCHMIDT"

snowflake_password          = "nsUXyti49b1OfDlG"
snowflake_dbt_password      = "UQK2agl6o9APhZd7"
snowflake_tableau_password  = "0FQoqgazNVJlC87c"