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

whitelist = os.environ['whitelist'].split(',')
users = os.environ['users'].split(',')
secrets = os.environ['secrets'].split(',')
accept_digit = os.environ['acceptDigit']
voice = "${var.lobbyboy_voice}"

def lambda_handler(event, context):
	log.info(event)
