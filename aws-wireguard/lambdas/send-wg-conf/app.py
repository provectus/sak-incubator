import os
import boto3
import json
import logging
ses_client = boto3.client("ses")
from email.mime.application import MIMEApplication
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText


admin_email = os.getenv('WG_ADMIN_EMAIL')
project_name = os.getenv('LOCAL_NAME')

def send_email_with_attachment(user, config):
    msg = MIMEMultipart()
    msg["Subject"] = "User {} added to wireguard group".format(user)
    msg["From"] = admin_email
    msg["To"] = admin_email

    # Set message body
    body = MIMEText("Wireguard configuration file for user {} in attachment".format(user))
    msg.attach(body)

    part = MIMEApplication(config)
    part.add_header("Content-Disposition", "attachment", filename="{0}-{1}.conf".format(project_name, user))
    msg.attach(part)

    # Convert message to string and send
    response = ses_client.send_raw_email(
        Source=admin_email,
        Destinations=[admin_email],
        RawMessage={"Data": msg.as_string()}
    )
    print(response)

def handler(event, context):
    print(event)
    send_email_with_attachment(event['user'], event['client_config'])
