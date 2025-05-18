import streamlit as st
import boto3
import pandas as pd
from datetime import datetime, timedelta
from streamlit_autorefresh import st_autorefresh

# Auto-refresh every 5 seconds
st_autorefresh(interval=5000, key="data_refresh")

# UI Layout
st.title("📡 IoT Sensor Dashboard")
st.markdown("Monitor real-time temperature and humidity data from your IoT device.")

# AWS DynamoDB Setup
TABLE_NAME = "IoTData"
REGION = "ap-south-1"

# Initialize DynamoDB client
dynamodb = boto3.resource("dynamodb", region_name=REGION)
table = dynamodb.Table(TABLE_NAME)

# Helper: Scan data
def fetch_all_data():
    response = table.scan()
    data = response["Items"]
    return data

# Convert and preprocess
def clean_data(raw):
    df = pd.DataFrame(raw)
    df['timestamp'] = pd.to_datetime(pd.to_numeric(df['timestamp']), unit='s')
    df = df.sort_values("timestamp", ascending=False)
    df["temperature"] = pd.to_numeric(df["temperature"], errors="coerce")
    df["humidity"] = pd.to_numeric(df["humidity"], errors="coerce")
    return df.dropna()

# Fetch and process
raw_data = fetch_all_data()
df = clean_data(raw_data)

# Time filter
time_window = st.selectbox("📅 Select time window", ["Last 15 mins", "Last 1 hour", "Last 6 hours", "Last 24 hours", "All time"])
now = datetime.utcnow()

if time_window == "Last 15 mins":
    df = df[df["timestamp"] >= now - timedelta(minutes=15)]
elif time_window == "Last 1 hour":
    df = df[df["timestamp"] >= now - timedelta(hours=1)]
elif time_window == "Last 6 hours":
    df = df[df["timestamp"] >= now - timedelta(hours=6)]
elif time_window == "Last 24 hours":
    df = df[df["timestamp"] >= now - timedelta(hours=24)]

# Layout
col1, col2 = st.columns(2)

with col1:
    st.subheader("🌡️ Temperature")
    st.line_chart(df.set_index("timestamp")["temperature"])

with col2:
    st.subheader("💧 Humidity")
    st.line_chart(df.set_index("timestamp")["humidity"])

# Show raw data
with st.expander("📋 View Raw Data"):
    st.dataframe(df.reset_index(drop=True), use_container_width=True)