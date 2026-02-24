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
  Project     = "Personal Finance Pipeline"
  Environment = "Development"
  ManagedBy   = "Terraform"
  Owner       = "Your Name"
}