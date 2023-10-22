import boto3
import json

iot_client = boto3.client('iot-data')
iot_topic = 'strategy_auto_two/outbound'

def lambda_handler(event, context):
    message = {
        "watering_count":1,
        "delay_time":505
    }
 
    iot_client.publish(
        topic=iot_topic,
        qos=1,
        payload=json.dumps(message)
    )
    
    return {
        'statusCode': 200,
        'body': json.dumps('Nachricht erfolgreich gesendet!')
    }
