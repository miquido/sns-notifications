import json
import boto3
import os

def lambda_handler(event, context):
    print(json.dumps(event))
    ssm_name = os.getenv('SSM')
    ssm = boto3.client('ssm')
    ssm.put_parameter(
        Name=ssm_name,
        Value=event['body'],
        Overwrite=True
    )


    return {
        'statusCode': 200,
        'body': 'ok'
    }

