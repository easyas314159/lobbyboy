import os
import boto3
import logging

import xml.etree.ElementTree as et

from base64 import b64decode
from urllib.parse import parse_qs

log = logging.getLogger()
log.setLevel(logging.INFO)

kms = boto3.client('kms')

ENCRYPTED_TWILIO_SID = os.environ['kmsEncryptedTwilioSid']
ENCRYPTED_TWILIO_SECRET = os.environ['kmsEncryptedTwilioSid']

TWILIO_SID = kms.decrypt(CiphertextBlob=b64decode(ENCRYPTED_TWILIO_SID))['Plaintext']
TWILIO_SECRET = kms.decrypt(CiphertextBlob=b64decode(ENCRYPTED_TWILIO_SECRET))['Plaintext']

WHITELIST = os.environ['whitelist']
GREETING = os.environ.get('greeting', None)
USERS = os.environ['users']
VOICE = os.environ['voice']

def lambda_handler(event, context):
	log.info(event)

	body = parse_qs(event['body'])

	log.info(event['headers'].get('X-Twilio-Signature', ''))

	# TODO: Make sure this request came from Twilio

	response = et.Element('Response')
	say = et.SubElement(response, 'Say')
	say.text = "Get your hands off my lobby boy!"
	say.set('voice', 'man')

	proxy = {
		'statusCode': '200',
		'headers': {
			'Content-Type': 'text/xml; charset=utf-8',
		},
		'body': et.tostring(response, encoding='unicode'),
	}

	log.info(proxy)

	return proxy
