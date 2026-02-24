import requests
import pandas as pd
from datetime import datetime

# 25 major US cities with coordinates (2 for now)
cities = [
    {"name": "New York, NY",      "lat": 40.7128, "lon": -74.0060},
    {"name": "Los Angeles, CA",   "lat": 34.0522, "lon": -118.2437},
]

def fetch_weather(cities, target_hour=14):
    """Fetch today's hourly weather at target_hour (default 2 PM) for all cities.

    If target_hour is None, uses the warmest hour of the day instead.
    """

    results = []

    for city in cities:
        url = "https://api.open-meteo.com/v1/forecast"
        params = {
            "latitude": city["lat"],
            "longitude": city["lon"],
            "hourly": [
                "temperature_2m",
                "apparent_temperature",
                "relative_humidity_2m",
                "precipitation",
                "weathercode",
                "windspeed_10m",
                "cloudcover",
            ],
            "temperature_unit": "fahrenheit",
            "windspeed_unit": "mph",
            "precipitation_unit": "inch",
            "timezone": "auto",  # auto-detects timezone based on coordinates
            "forecast_days": 1,
        }

        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            data = response.json()
            hourly = data["hourly"]
            times = hourly["time"]  # list of "YYYY-MM-DDTHH:MM" strings

            if target_hour is not None:
                # Find the index for target_hour (e.g. 14 = 2 PM local time)
                idx = next(
                    (i for i, t in enumerate(times) if datetime.fromisoformat(t).hour == target_hour),
                    None,
                )
            else:
                idx = None

            # Fall back to warmest hour if target not found or target_hour is None
            if idx is None:
                idx = hourly["temperature_2m"].index(max(hourly["temperature_2m"]))

            results.append({
                "City":               city["name"],
                "Temp (°F)":          hourly["temperature_2m"][idx],
                "Feels Like (°F)":    hourly["apparent_temperature"][idx],
                "Humidity (%)":       hourly["relative_humidity_2m"][idx],
                "Precip (in)":        hourly["precipitation"][idx],
                "Wind (mph)":         hourly["windspeed_10m"][idx],
                "Cloud Cover (%)":    hourly["cloudcover"][idx],
                "Weather Code":       hourly["weathercode"][idx],
                "Local Time":         times[idx],
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
    # target_hour=14 → 2 PM local time; set to None to use warmest hour instead
    TARGET_HOUR = 14

    label = f"{TARGET_HOUR}:00 (local)" if TARGET_HOUR is not None else "warmest hour"
    print(f"Fetching today's weather at {label} for 25 US cities...\n")

    weather_data = fetch_weather(cities, target_hour=TARGET_HOUR)

    # Build DataFrame - may want to do this somewhere else
    df = pd.DataFrame(weather_data)

    # Add human-readable weather description
    df["Conditions"] = df["Weather Code"].apply(decode_weathercode)
    df.drop(columns=["Weather Code"], inplace=True)

    # Display
    pd.set_option("display.max_columns", None)
    pd.set_option("display.width", 200)
    print(f"\n--- Today's Weather at {label} Across 25 US Cities ---\n")
    print(df.to_string(index=False))

"""
    # Save to CSV
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"us_weather_{timestamp}.csv"
    df.to_csv(filename, index=False)
    print(f"\nData saved to {filename}")

"""