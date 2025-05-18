import paho.mqtt.client as mqtt
import ssl
import json
import time
import random

# AWS IoT Core MQTT settings
MQTT_BROKER = "a2r9e9wgf0l6x2-ats.iot.ap-south-1.amazonaws.com"  
PORT = 8883
TOPIC = "iot/topic"

CA_PATH = "certs/AmazonRootCA1.pem"
CERT_PATH = "certs/MySensorDevice-certificate.pem.crt"
KEY_PATH = "certs/MySensorDevice-private.pem.key"

client = mqtt.Client()
client.tls_set(ca_certs=CA_PATH,
               certfile=CERT_PATH,
               keyfile=KEY_PATH,
               tls_version=ssl.PROTOCOL_TLSv1_2)

client.connect(MQTT_BROKER, PORT, keepalive=60)
client.loop_start()

while True:
    payload = {
        "temperature": round(random.uniform(25, 35), 2),
        "humidity": round(random.uniform(40, 60), 2),
        "timestamp": int(time.time())
    }
    client.publish(TOPIC, json.dumps(payload))
    print("Published:", payload)
    time.sleep(5)