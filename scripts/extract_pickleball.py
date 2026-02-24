import requests
import pandas as pd
from datetime import datetime
import time 

cities = [
    {"name": "New York, NY",      "lat": 40.7128, "lon": -74.0060},
    {"name": "Los Angeles, CA",   "lat": 34.0522, "lon": -118.2437},
]

OVERPASS_URL = "https://overpass-api.de/api/interpreter"
SEARCH_RADIUS_METERS = 25000  # 25km radius around city center


def build_query(lat, lon, radius):
    """Build an Overpass QL query to find pickleball courts."""
    return f"""
    [out:json][timeout:60];
    (
      node["sport"="pickleball"](around:{radius},{lat},{lon});
      way["sport"="pickleball"](around:{radius},{lat},{lon});
    );
    out center tags;
    """


def parse_hours(tags):
    """Extract opening hours from OSM tags if available."""
    return tags.get("opening_hours", "Not listed")


def fetch_courts(city, retries=3):
    """Query Overpass API for pickleball courts near a city."""
    query = build_query(city["lat"], city["lon"], SEARCH_RADIUS_METERS)
    courts = []

    for attempt in range(retries):
        try:
            response = requests.post(OVERPASS_URL, data={"data": query}, timeout=60)
            response.raise_for_status()
            break  # success, exit retry loop
        except Exception as e:
            print(f"  ⚠ Attempt {attempt + 1} failed: {e}")
            if attempt < retries - 1:
                print(f"  Retrying in 10 seconds...")
                time.sleep(10)
            else:
                print(f"  ✗ Gave up after {retries} attempts")
                return courts

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

    return courts


if __name__ == "__main__":
    all_courts = []

    print("Searching for pickleball courts via OpenStreetMap...\n")

    for city in cities:
        print(f"🏓 {city['name']}...")
        courts = fetch_courts(city)
        all_courts.extend(courts)
        time.sleep(3)

    df = pd.DataFrame(all_courts)

    # Summary
    print("\n--- Results Summary ---")
    summary = df.groupby("City")["Court Name"].count().reset_index()
    summary.columns = ["City", "Courts Found"]
    print(summary.to_string(index=False))
    print(f"\nTotal courts found: {len(df)}")

"""
    # Save to CSV
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"pickleball_courts_osm_{timestamp}.csv"
    df.to_csv(filename, index=False)
    print(f"\nData saved to {filename}")
    
"""