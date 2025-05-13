import streamlit as st
import requests
import pandas as pd
import time

API_URL = "http://52.66.69.23:5000/data"  # Change if needed

st.title("🌐 Real-Time IoT Sensor Dashboard")

st.markdown("Displays live temperature and humidity data collected from IoT sensors.")

placeholder = st.empty()

while True:
    try:
        response = requests.get(API_URL)
        if response.status_code == 200:
            data = response.json()
            df = pd.DataFrame(data)
            df["timestamp"] = pd.to_datetime(pd.to_numeric(df["timestamp"]), unit='s')


            with placeholder.container():
                st.line_chart(df.set_index('timestamp')[['temperature', 'humidity']])
                st.dataframe(df)
        else:
            st.error("Failed to fetch data from API.")
    except Exception as e:
        st.error(f"Error: {e}")

    time.sleep(10)

