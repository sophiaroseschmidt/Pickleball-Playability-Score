# extract_weather_data.py
import requests
import psycopg2
from datetime import datetime,  timedelta
import json

# Database connection
conn = psycopg2.connect(
    host="your-server.postgres.database.azure.com",
    database="pickleball_db",
    user="pgadmin",
    password="your_password"
)
cur = conn.cursor()

# Cities to track
CITIES = [
    ('Phoenix', 'AZ'),
    ('San Diego', 'CA'),
    ('Miami', 'FL'),
    ('Austin', 'TX'),
    ('Denver', 'CO'),
    # ... more cities
]

# Fetch weather for each city
for city, state in CITIES:
    # Call weather API
    response = requests.get(
        f"https://api.openweathermap.org/data/2.5/forecast",
        params={
            'q': f'{city},{state},US',
            'appid': 'YOUR_API_KEY',
            'units': 'imperial'
        }
    )
    
    if response.status_code == 200:
        data = response.json()
        
        # Insert RAW data into bronze layer
        cur.execute("""
            INSERT INTO bronze.raw_weather_data (
                city, state, api_response, 
                temperature_f, humidity_pct, wind_speed_mph,
                precipitation_in, weather_condition, forecast_date,
                data_source
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (
            city,
            state,
            json.dumps(data),  # Store entire JSON response
            data['list'][0]['main']['temp'],
            data['list'][0]['main']['humidity'],
            data['list'][0]['wind']['speed'],
            data['list'][0].get('rain', {}).get('3h', 0) / 25.4,  # mm to inches
            data['list'][0]['weather'][0]['main'],
            datetime.fromtimestamp(data['list'][0]['dt']).date(),
            'openweathermap'
        ))
        
        # Log the fetch
        cur.execute("""
            INSERT INTO bronze.api_fetch_log (
                fetch_date, api_name, status, records_fetched
            ) VALUES (%s, %s, %s, %s)
        """, (datetime.now().date(), 'weather_api', 'success', 1))
    else:
        # Log failure
        cur.execute("""
            INSERT INTO bronze.api_fetch_log (
                fetch_date, api_name, status, error_message
            ) VALUES (%s, %s, %s, %s)
        """, (datetime.now().date(), 'weather_api', 'failed', response.text))

conn.commit()
cur.close()
conn.close()