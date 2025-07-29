import json

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
            try:
                sns_object = json.loads(message)
                requests.post(webhook, json={'text': f'- Alarm: {sns_object["AlarmName"]}\n- Account: {sns_object["AWSAccountId"]}\n- Description: {sns_object["AlarmDescription"]}'})
            except (json.decoder.JSONDecodeError, KeyError):
                requests.post(webhook, json={'text': message})


if __name__ == '__main__':
    test_msg = '{"AlarmName":"example-dev-example-dev-test-cpu-credit-balance-low","AlarmDescription":"Average database CPU credit balance over last 10 minutes too low, expect a significant performance drop soon","AWSAccountId":"123456789","AlarmConfigurationUpdatedTimestamp":"2024-03-08T14:05:02.761+0000","NewStateValue":"ALARM","NewStateReason":"Threshold Crossed: 1 datapoint [0.0 (08/03/24 13:56:00)] was less than the threshold (20.0).","StateChangeTime":"2024-03-08T14:06:01.853+0000","Region":"US East (N. Virginia)","AlarmArn":"arn:aws:cloudwatch:us-east-1:123456789012:alarm:example-dev-example-dev-test-cpu-credit-balance-low","OldStateValue":"INSUFFICIENT_DATA","OKActions":["arn:aws:sns:us-east-1:123456789012:example-dev-example-dev-test-ok-rds-threshold-alerts20240308140459771500000003"],"AlarmActions":["arn:aws:sns:us-east-1:123456789012:example-dev-notifications"],"InsufficientDataActions":[],"Trigger":{"MetricName":"CPUCreditBalance","Namespace":"AWS/RDS","StatisticType":"Statistic","Statistic":"AVERAGE","Unit":null,"Dimensions":[{"value":"example-dev-test","name":"DBInstanceIdentifier"}],"Period":600,"EvaluationPeriods":1,"ComparisonOperator":"LessThanThreshold","Threshold":20.0,"TreatMissingData":"missing","EvaluateLowSampleCountPercentile":""}}'
    
    e = {'Records': [
        {
            'Sns': {
                'Message': test_msg
            }
        },
        {
            'Sns': {
                'Message': 'Drugi message'
            }
        }
    ]}
    lambda_handler(e, None)
