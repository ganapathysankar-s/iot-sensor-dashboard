from flask import Flask, jsonify
import boto3

app = Flask(__name__)
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('IoTData')

@app.route('/data', methods=['GET'])
def get_data():
    items = []
    response = table.scan()
    items.extend(response['Items'])

    while 'LastEvaluatedKey' in response:
        response = table.scan(ExclusiveStartKey=response['LastEvaluatedKey'])
        items.extend(response['Items'])

    return jsonify(items)
