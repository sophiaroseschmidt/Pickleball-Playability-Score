# dags/pickleball_pipeline.py
from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.bash import BashOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': True,
    'email_on_retry': False,
    'retries': 2,
    'retry_delay': timedelta(minutes=5),
}

dag = DAG(
    'pickleball_daily_pipeline',
    default_args=default_args,
    description='Daily pickleball playability ETL pipeline',
    schedule_interval='0 6 * * *',  # Run at 6 AM daily
    catchup=False,
)

# Task 1: Extract weather data → Load to Bronze
extract_weather = PythonOperator(
    task_id='extract_weather_data',
    python_callable=fetch_weather_to_bronze,  # Your Python function
    dag=dag,
)

# Task 2: Extract court data (weekly, not daily)
extract_courts = PythonOperator(
    task_id='extract_court_data',
    python_callable=fetch_courts_to_bronze,
    dag=dag,
)

# Task 3: Run dbt to transform Bronze → Silver → Gold
dbt_run = BashOperator(
    task_id='dbt_transform',
    bash_command='cd /path/to/dbt/project && dbt run',
    dag=dag,
)

# Task 4: Run dbt tests
dbt_test = BashOperator(
    task_id='dbt_test',
    bash_command='cd /path/to/dbt/project && dbt test',
    dag=dag,
)

# Task 5: Send email with best cities
send_email = PythonOperator(
    task_id='send_daily_email',
    python_callable=send_playability_email,  # Your email function
    dag=dag,
)

# Define dependencies
extract_weather >> dbt_run
extract_courts >> dbt_run
dbt_run >> dbt_test >> send_email

## **Visual Summary: Your ELT Flow**
"""
DAY 1 - 6:00 AM
├── Python Script: Call Weather API for 50 cities
│   └── INSERT INTO bronze.raw_weather_data (raw JSON + extracted fields)
│
├── Python Script: Call Pickleball API (weekly refresh)
│   └── INSERT INTO bronze.raw_pickleball_courts
│
└── Airflow triggers dbt run
    │
    ├── dbt builds silver.stg_weather (clean, dedupe, standardize)
    ├── dbt builds silver.stg_pickleball_courts (validate, clean)
    │
    └── dbt builds gold.daily_city_playability (calculate scores)
        ├── dbt builds gold.best_cities_today (top 10 ranking)
        └── dbt builds gold.weekly_city_trends (7-day outlook)
            │
            └── Python Script: Query gold.best_cities_today
                └── Send email: "Today's best cities for pickleball!"
"""