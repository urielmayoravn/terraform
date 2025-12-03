import boto3
import json
import slack_sdk
import os

REGION_NAME = os.environ["aws_region"]
PARAM_NAME = os.environ["ssm_parameter_name"]


def get_slack_webhook_url_from_ssm():
    try:
        ssm_client = boto3.client("ssm", region_name=REGION_NAME)
        response = ssm_client.get_parameter(Name=PARAM_NAME, WithDecryption=True)
        return response["Parameter"]["Value"]
    except Exception as e:
        print(f"Exception when retreiving parameter: {e}")
        return None


def lambda_handler(event, context):
    alert_message = json.loads(event["Records"][0]["Sns"]["Message"])

    alarm_name = alert_message["AlarmName"]
    timestamp = alert_message["AlarmConfigurationUpdatedTimestamp"]
    new_state_value = alert_message["NewStateValue"]
    old_state_value = alert_message["OldStateValue"]
    new_state_reason = alert_message["NewStateReason"]

    slack_webhook_url = get_slack_webhook_url_from_ssm()
    if not slack_webhook_url:
        return

    try:
        slack_client = slack_sdk.WebhookClient(slack_webhook_url)
        slack_client.send_dict(
            {
                "text": "ALARM STATUS CHANGE",
                "blocks": [
                    {
                        "type": "header",
                        "text": {
                            "type": "plain_text",
                            "text": f"{alarm_name} status changed:\n{old_state_value} -> {new_state_value}",
                        },
                    },
                    {
                        "type": "section",
                        "fields": [
                            {
                                "type": "mrkdwn",
                                "text": f"*Reason:*\n{new_state_reason}",
                            },
                            {
                                "type": "mrkdwn",
                                "text": f"*When:*\n{timestamp}",
                            },
                        ],
                    },
                    {
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": f"<https://console.aws.amazon.com/cloudwatch/home?region={REGION_NAME}|View details>",
                        },
                    },
                ],
            }
        )
    except Exception as e:
        print(f"Error sending slack message: {e}")
