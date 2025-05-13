import random
import requests
import time
from datetime import datetime

# URL of your Flask server (change if needed)
url = "http://52.66.69.23:5000/data"

# Start with base sensor values
temp = 25.0
humid = 45.0

while True:
    # Simulate small fluctuations
    temp += random.uniform(-0.5, 0.5)
    humid += random.uniform(-1, 1)

    # Clamp values to realistic range
    temp = min(max(temp, 15.0), 35.0)
    humid = min(max(humid, 20.0), 80.0)

    # Prepare data
    data = {
        "temperature": round(temp, 2),
        "humidity": round(humid, 2),
        "timestamp": datetime.utcnow().isoformat()
    }

    try:
        # Send data to Flask server
        response = requests.post(url, json=data)
        print(f"[{data['timestamp']}] ✅ Sent: Temp={data['temperature']}°C | Humidity={data['humidity']}% | Status={response.status_code}")
    except Exception as e:
        print(f"[{data['timestamp']}] ❌ Error sending data: {e}")

    # Wait 2 seconds before next data point
    time.sleep(2)
