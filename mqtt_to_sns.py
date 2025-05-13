import json
import boto3
import paho.mqtt.client as mqtt

# Set up SNS
sns = boto3.client('sns', region_name='ap-south-1')  # e.g., us-east-1
SNS_TOPIC_ARN = 'arn:aws:sns:ap-south-1:886436951574:IoTTopic'

# MQTT callback
def on_message(client, userdata, msg):
    try:
        payload = msg.payload.decode()
        print("Received MQTT message:", payload)
        sns.publish(TopicArn=SNS_TOPIC_ARN, Message=payload)
    except Exception as e:
        print("Error sending to SNS:", e)

# MQTT connection
client = mqtt.Client()
client.connect("localhost", 1883, 60)
client.subscribe("iot/sensor")

client.on_message = on_message
print("Listening for MQTT messages...")
client.loop_forever()
