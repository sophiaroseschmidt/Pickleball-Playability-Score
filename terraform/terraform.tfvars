project_name     = "finance-project"
environment      = "dev"
location         = "East US"  # Or: "West US 2", "North Europe", etc.
db_admin_username = "pgadmin"
db_admin_password = "YourSecurePassword123!"  # Change this!

# Add your IP address to access database from your computer
# Find your IP: curl ifconfig.me
allowed_ip_addresses = [
  "YOUR_IP_ADDRESS/32"  # Replace with your actual IP
]


tags = {
  Project     = "Pickleball Playability Score"
  Environment = "Development"
  ManagedBy   = "Terraform"
}

# ─── Snowflake ─────────────────────────────────────────────────────────────────
# Find your account identifier in Snowflake: Admin → Accounts → hover your account
snowflake_account  = "orgname-accountname"   # e.g. "myorg-myaccount"
snowflake_username = "your_admin_user"

# Sensitive values — consider using environment variables instead:
#   export TF_VAR_snowflake_password="..."
#   export TF_VAR_snowflake_dbt_password="..."
#   export TF_VAR_snowflake_tableau_password="..."
snowflake_password          = "CHANGE_ME"
snowflake_dbt_password      = "CHANGE_ME"
snowflake_tableau_password  = "CHANGE_ME"