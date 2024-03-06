import boto3
import os

import requests

client = boto3.client('ssm')
webhooks_arns = os.getenv('WEBHOOKS', []).split(',')
webhooks = []
for webhook_arn in webhooks_arns:
    param = client.get_parameter(Name=webhook_arn, WithDecryption=True)
    webhooks.append(param['Parameter']['Value'])


def lambda_handler(event, context):
    global webhooks
    messages = list(map(lambda x: x['Sns']['Message'], event['Records']))
    for webhook in webhooks:
        for message in messages:
            requests.post(webhook, json={'text': message})


if __name__ == '__main__':
    e = {'Records': [
        {
            'Sns': {
                'Message': 'Test message'
            }
        },
        {
            'Sns': {
                'Message': 'Drugi message'
            }
        }
    ]}
    labmbda_handler(e, None)
