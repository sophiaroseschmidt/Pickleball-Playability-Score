import requests
import pandas as pd
from datetime import datetime
import time

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

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
SEARCH_RADIUS_METERS = 25000  # 25km radius around city center


def build_query(lat, lon, radius):
    """Build an Overpass QL query to find pickleball courts."""
    return f"""
    [out:json][timeout:30];
    (
      node["sport"="pickleball"](around:{radius},{lat},{lon});
      way["sport"="pickleball"](around:{radius},{lat},{lon});
      node["leisure"="pitch"]["sport"="pickleball"](around:{radius},{lat},{lon});
      way["leisure"="pitch"]["sport"="pickleball"](around:{radius},{lat},{lon});
    );
    out center tags;
    """


def parse_hours(tags):
    """Extract opening hours from OSM tags if available."""
    return tags.get("opening_hours", "Not listed")


def fetch_courts(city):
    """Query Overpass API for pickleball courts near a city."""
    query = build_query(city["lat"], city["lon"], SEARCH_RADIUS_METERS)
    courts = []

    try:
        response = requests.post(OVERPASS_URL, data={"data": query}, timeout=40)
        response.raise_for_status()
        elements = response.json().get("elements", [])
        print(f"  Found {len(elements)} result(s)")

        for el in elements:
            tags = el.get("tags", {})

            # Get coordinates (nodes have lat/lon directly, ways have a center)
            if el["type"] == "node":
                lat = el.get("lat")
                lon = el.get("lon")
            else:
                center = el.get("center", {})
                lat = center.get("lat")
                lon = center.get("lon")

            courts.append({
                "City":          city["name"],
                "Court Name":    tags.get("name", "Unnamed Court"),
                "Address":       ", ".join(filter(None, [
                                    tags.get("addr:housenumber", ""),
                                    tags.get("addr:street", ""),
                                    tags.get("addr:city", ""),
                                    tags.get("addr:state", ""),
                ])) or "Not listed",
                "Operator":      tags.get("operator", "Not listed"),
                "Access":        tags.get("access", "Not listed"),   # public, private, etc.
                "Fee":           tags.get("fee", "Not listed"),       # yes/no
                "Lit":           tags.get("lit", "Not listed"),       # night lighting
                "Opening Hours": parse_hours(tags),
                "Latitude":      lat,
                "Longitude":     lon,
                "OSM Type":      el["type"],
                "OSM ID":        el["id"],
            })

    except Exception as e:
        print(f"  ✗ Error: {e}")

    return courts


if __name__ == "__main__":
    all_courts = []

    print("Searching for pickleball courts via OpenStreetMap...\n")

    for city in cities:
        print(f"🏓 {city['name']}...")
        courts = fetch_courts(city)
        all_courts.extend(courts)
        time.sleep(1)  # be respectful to the free API

    df = pd.DataFrame(all_courts)

    # Summary
    print("\n--- Results Summary ---")
    summary = df.groupby("City")["Court Name"].count().reset_index()
    summary.columns = ["City", "Courts Found"]
    print(summary.to_string(index=False))
    print(f"\nTotal courts found: {len(df)}")

    # Save to CSV
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"pickleball_courts_osm_{timestamp}.csv"
    df.to_csv(filename, index=False)
    print(f"\nData saved to {filename}")