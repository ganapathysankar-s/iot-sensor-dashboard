import json
import boto3
import time

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('IoTData')

def lambda_handler(event, context):
    try:
        message = json.loads(event['Records'][0]['Sns']['Message'])
        table.put_item(Item={
            'timestamp': str(int(time.time())),
            'temperature': str(message['temperature']),
            'humidity': str(message['humidity'])
        })
        return {'statusCode': 200, 'body': 'Data saved successfully'}
    except Exception as e:
        return {'statusCode': 400, 'body': str(e)}