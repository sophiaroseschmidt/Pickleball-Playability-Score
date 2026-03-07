resource "snowflake_database" "pickleball" {
  name    = "PICKLEBALL_DB"
  comment = "Pickleball Playability Score data warehouse"
}

resource "snowflake_schema" "bronze" {
  database = snowflake_database.pickleball.name
  name     = "BRONZE"
  comment  = "Raw ingested data"
}

resource "snowflake_schema" "silver" {
  database = snowflake_database.pickleball.name
  name     = "SILVER"
  comment  = "Cleaned and data"
}

resource "snowflake_schema" "gold" {
  database = snowflake_database.pickleball.name
  name     = "GOLD"
  comment  = "Ready, aggregated data"
}

resource "snowflake_warehouse" "main" {
  name           = "PICKLEBALL_WH"
  warehouse_size = "XSMALL"
  auto_suspend   = 60   # suspend after 60 seconds of inactivity
  auto_resume    = true
  comment        = "Primary compute warehouse"
}

# SNOWFLAKE ROLES ---------------------------

resource "snowflake_role" "dbt" {
  name    = "DBT_ROLE"
  comment = "Role for dbt transformations — write access to all schemas"
}

resource "snowflake_role" "tableau" {
  name    = "TABLEAU_ROLE"
  comment = "Role for Tableau — read-only access to the gold schema"
}

# SNOWFLAKE USERS ---------------------------

resource "snowflake_user" "dbt" {
  name                 = "DBT_USER"
  password             = var.snowflake_dbt_password
  default_role         = snowflake_role.dbt.name
  default_warehouse    = snowflake_warehouse.main.name
  default_namespace    = "${snowflake_database.pickleball.name}.${snowflake_schema.silver.name}"
  must_change_password = false
  comment              = "Service account for dbt"
}

resource "snowflake_user" "tableau" {
  name                 = "TABLEAU_USER"
  password             = var.snowflake_tableau_password
  default_role         = snowflake_role.tableau.name
  default_warehouse    = snowflake_warehouse.main.name
  default_namespace    = "${snowflake_database.pickleball.name}.${snowflake_schema.gold.name}"
  must_change_password = false
  comment              = "Service account for Tableau"
}

resource "snowflake_grant_role" "dbt_user" {
  role_name = snowflake_role.dbt.name
  user_name = snowflake_user.dbt.name
}

resource "snowflake_grant_role" "tableau_user" {
  role_name = snowflake_role.tableau.name
  user_name = snowflake_user.tableau.name
}

resource "snowflake_grant_privileges_to_role" "dbt_warehouse" {
  role_name  = snowflake_role.dbt.name
  privileges = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.main.name
  }
}

resource "snowflake_grant_privileges_to_role" "tableau_warehouse" {
  role_name  = snowflake_role.tableau.name
  privileges = ["USAGE"]
  on_account_object {
    object_type = "WAREHOUSE"
    object_name = snowflake_warehouse.main.name
  }
}

resource "snowflake_grant_privileges_to_role" "dbt_database" {
  role_name  = snowflake_role.dbt.name
  privileges = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.pickleball.name
  }
}

resource "snowflake_grant_privileges_to_role" "tableau_database" {
  role_name  = snowflake_role.tableau.name
  privileges = ["USAGE"]
  on_account_object {
    object_type = "DATABASE"
    object_name = snowflake_database.pickleball.name
  }
}
# DBT PRIVILEDGES ---------------------------

resource "snowflake_grant_privileges_to_role" "dbt_schema_bronze" {
  role_name  = snowflake_role.dbt.name
  privileges = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE", "MODIFY"]
  on_schema {
    schema_name = "${snowflake_database.pickleball.name}.${snowflake_schema.bronze.name}"
  }
}

resource "snowflake_grant_privileges_to_role" "dbt_schema_silver" {
  role_name  = snowflake_role.dbt.name
  privileges = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE", "MODIFY"]
  on_schema {
    schema_name = "${snowflake_database.pickleball.name}.${snowflake_schema.silver.name}"
  }
}

resource "snowflake_grant_privileges_to_role" "dbt_schema_gold" {
  role_name  = snowflake_role.dbt.name
  privileges = ["USAGE", "CREATE TABLE", "CREATE VIEW", "CREATE STAGE", "MODIFY"]
  on_schema {
    schema_name = "${snowflake_database.pickleball.name}.${snowflake_schema.gold.name}"
  }
}

# TABLEAU PERMISSIONS ---------------------------

resource "snowflake_grant_privileges_to_role" "tableau_schema_gold" {
  role_name  = snowflake_role.tableau.name
  privileges = ["USAGE"]
  on_schema {
    schema_name = "${snowflake_database.pickleball.name}.${snowflake_schema.gold.name}"
  }
}

# Future grants so Tableau can read tables/views created by dbt in gold
resource "snowflake_grant_privileges_to_role" "tableau_future_tables" {
  role_name  = snowflake_role.tableau.name
  privileges = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "TABLES"
      in_schema          = "${snowflake_database.pickleball.name}.${snowflake_schema.gold.name}"
    }
  }
}

resource "snowflake_grant_privileges_to_role" "tableau_future_views" {
  role_name  = snowflake_role.tableau.name
  privileges = ["SELECT"]
  on_schema_object {
    future {
      object_type_plural = "VIEWS"
      in_schema          = "${snowflake_database.pickleball.name}.${snowflake_schema.gold.name}"
    }
  }
}

