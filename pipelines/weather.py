# 25 major US cities with coordinates
cities = [
    {"name": "New York, NY",      "lat": 40.7128, "lon": -74.0060},
    {"name": "Los Angeles, CA",   "lat": 34.0522, "lon": -118.2437},
    {"name": "Chicago, IL",       "lat": 41.8781, "lon": -87.6298},
    {"name": "Houston, TX",       "lat": 29.7604, "lon": -95.3698},
    {"name": "Phoenix, AZ",       "lat": 33.4484, "lon": -112.0740},
    {"name": "Philadelphia, PA",  "lat": 39.9526, "lon": -75.1652},
    {"name": "San Antonio, TX",   "lat": 29.4241, "lon": -98.4936},
    {"name": "San Diego, CA",     "lat": 32.7157, "lon": -117.1611},
    {"name": "Dallas, TX",        "lat": 32.7767, "lon": -96.7970},
    {"name": "San Jose, CA",      "lat": 37.3382, "lon": -121.8863},
    {"name": "Austin, TX",        "lat": 30.2672, "lon": -97.7431},
    {"name": "Jacksonville, FL",  "lat": 30.3322, "lon": -81.6557},
    {"name": "Des Moines, IA",    "lat": 41.5868, "lon": -93.6250},  
    {"name": "Minneapolis, MN",   "lat": 44.9778, "lon": -93.2650},  
    {"name": "Charlotte, NC",     "lat": 35.2271, "lon": -80.8431},
    {"name": "Indianapolis, IN",  "lat": 39.7684, "lon": -86.1581},
    {"name": "San Francisco, CA", "lat": 37.7749, "lon": -122.4194},
    {"name": "Seattle, WA",       "lat": 47.6062, "lon": -122.3321},
    {"name": "Denver, CO",        "lat": 39.7392, "lon": -104.9903},
    {"name": "Nashville, TN",     "lat": 36.1627, "lon": -86.7816},
    {"name": "Oklahoma City, OK", "lat": 35.4676, "lon": -97.5164},
    {"name": "Las Vegas, NV",     "lat": 36.1699, "lon": -115.1398},
    {"name": "Portland, OR",      "lat": 45.5051, "lon": -122.6750},
    {"name": "Miami, FL",         "lat": 25.7617, "lon": -80.1918},
    {"name": "Atlanta, GA",       "lat": 33.7490, "lon": -84.3880},
]

def fetch_weather(cities):
    """Fetch current weather for all cities using Open-Meteo batch-style requests."""
    
    results = []
    
    for city in cities:
        url = "https://api.open-meteo.com/v1/forecast"
        params = {
            "latitude": city["lat"],
            "longitude": city["lon"],
            "current": [
                "temperature_2m",
                "apparent_temperature",
                "relative_humidity_2m",
                "precipitation",
                "weathercode",
                "windspeed_10m",
                "winddirection_10m",
                "cloudcover",
            ],
            "temperature_unit": "fahrenheit",
            "windspeed_unit": "mph",
            "precipitation_unit": "inch",
            "timezone": "auto",  # auto-detects timezone based on coordinates
        }
        
        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            current = data["current"]
            
            results.append({
                "City":               city["name"],
                "Temp (°F)":          current["temperature_2m"],
                "Feels Like (°F)":    current["apparent_temperature"],
                "Humidity (%)":       current["relative_humidity_2m"],
                "Precip (in)":        current["precipitation"],
                "Wind (mph)":         current["windspeed_10m"],
                "Wind Dir (°)":       current["winddirection_10m"],
                "Cloud Cover (%)":    current["cloudcover"],
                "Weather Code":       current["weathercode"],
                "Local Time":         current["time"],
            })
            print(f"✓ {city['name']}")
            
        except Exception as e:
            print(f"✗ {city['name']} — Error: {e}")
    
    return results


def decode_weathercode(code):
    """Convert WMO weather code to a human-readable description."""
    codes = {
        0: "Clear sky", 1: "Mainly clear", 2: "Partly cloudy", 3: "Overcast",
        45: "Fog", 48: "Icy fog",
        51: "Light drizzle", 53: "Moderate drizzle", 55: "Dense drizzle",
        61: "Slight rain", 63: "Moderate rain", 65: "Heavy rain",
        71: "Slight snow", 73: "Moderate snow", 75: "Heavy snow",
        77: "Snow grains",
        80: "Slight showers", 81: "Moderate showers", 82: "Violent showers",
        85: "Slight snow showers", 86: "Heavy snow showers",
        95: "Thunderstorm", 96: "Thunderstorm w/ hail", 99: "Thunderstorm w/ heavy hail",
    }
    return codes.get(code, f"Unknown ({code})")


if __name__ == "__main__":
    print("Fetching weather data for 25 US cities...\n")
    
    weather_data = fetch_weather(cities)
    
    # Build DataFrame - may want to do this somewhere else
    df = pd.DataFrame(weather_data)
    
    # Add human-readable weather description
    df["Conditions"] = df["Weather Code"].apply(decode_weathercode)
    df.drop(columns=["Weather Code"], inplace=True)
    
    # Display
    pd.set_option("display.max_columns", None)
    pd.set_option("display.width", 200)
    print("\n--- Current Weather Across 25 US Cities ---\n")
    print(df.to_string(index=False))
    
    # Save to CSV
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"us_weather_{timestamp}.csv"
    df.to_csv(filename, index=False)
    print(f"\nData saved to {filename}")