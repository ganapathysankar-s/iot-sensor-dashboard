# Serverless IoT Project

## Components
- **sensor_simulator.py**: Simulates IoT sensor data.
- **lambda_function.py**: AWS Lambda function to store data into DynamoDB.
- **app.py**: Flask API to retrieve stored data.
- **dashboard.py**: Streamlit dashboard to visualize the data.

## Setup Instructions
1. Start MQTT broker (Mosquitto) locally or in AWS IoT Core.
2. Run `sensor_simulator.py` to publish simulated data.
3. Deploy `lambda_function.py` as your AWS Lambda function and connect through SNS.
4. Start Flask server using `python app.py`.
5. Launch Streamlit dashboard using `streamlit run dashboard.py`.

## Notes
- Ensure correct AWS credentials and permissions.
- Update API endpoints if needed.