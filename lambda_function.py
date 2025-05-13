import json
import boto3
from datetime import datetime

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('IoTData')

def lambda_handler(event, context):
    try:
        message = json.loads(event['Records'][0]['sns']['Message'])

        # Generate ISO timestamp like "2025-05-07T08:10:00"
        timestamp = datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%S')

        # Write to DynamoDB
        table.put_item(Item={
            'timestamp': timestamp,
            'temperature': str(message['temperature']),
            'humidity': str(message['humidity'])
        })

        return {
            'statusCode': 200,
            'body': 'Data saved successfully'
        }

    except Exception as e:
        return {
            'statusCode': 400,
            'body': str(e)
        }

