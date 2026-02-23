# EDIT THIS
import snowflake.connector

# Connect to Snowflake
conn = snowflake.connector.connect(
    user='your_username',
    password='your_password',
    account='abc12345.us-east-1',  # From Snowflake signup
    warehouse='COMPUTE_WH',
    database='finance_project',
    schema='raw_data'
)

# Load your CSV data
cursor = conn.cursor()
cursor.execute("""
    CREATE OR REPLACE TABLE raw_transactions (
        date DATE,
        merchant VARCHAR,
        amount FLOAT,
        category VARCHAR
    )
""")

# Copy data from file
cursor.execute("""
    PUT file://transactions.csv @%raw_transactions
""")

cursor.execute("""
    COPY INTO raw_transactions
    FILE_FORMAT = (TYPE = 'CSV' SKIP_HEADER = 1)
""")

print("Data loaded!")