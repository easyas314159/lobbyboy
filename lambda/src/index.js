import AWS from 'aws-sdk';
import twilio from 'twilio';
import jwt from 'jsonwebtoken';
import boom from '@hapi/boom';
import {parse} from 'querystring';

import greeting from './greeting.js';
import menu from './menu.js';
import gather from './gather.js';
import dial from './dial.js';
import accept from './accept.js';

import states from './states.js';

const kms = new AWS.KMS();

let TWILIO_SECRET;

const JWT_ISSUER = process.env.JWT_ISSUER || 'lobbyboy';
const JWT_MAX_AGE = process.env.JWT_MAX_AGE || 3600000;

const STATE_HANDLERS = {
	[states.GREETING]: greeting,
	[states.MENU]: menu,
	[states.GATHER]: gather,
	[states.DIAL]: dial,
	[states.ACCEPT]: accept,
	[states.END_CALL]: null,
};

export const handle = function(event, context) {
	event.url = new URL(`https://${event.requestContext.domainName}${event.requestContext.path}`);
	if (event.queryStringParameters && event.queryStringParameters.session) {
		event.url.searchParams.set('session', event.queryStringParameters.session);
	}
	event.body = parse(event.body);

	return decrypt(process.env.TWILIO_SECRET, TWILIO_SECRET)
		.then((data) => {
			TWILIO_SECRET = data;
		})
		.then(() => validateTwilioRequest(event, context))
		.then(() => validateRequestSession(event, context))
		.then(() => getResponse(event, context))
		.catch((err) => getErrorResponse(event, context, err))
	;
};

function decrypt(encrypted, value) {
	if (value) {
		return Promise.resolve(value);
	}

	const cipherText = {CiphertextBlob: Buffer.from(encrypted, 'base64')};

	return kms.decrypt(cipherText).promise()
		.then((data) => data.Plaintext.toString('ascii'))
	;
}

function validateTwilioRequest(event, context) {
	if (!twilio.validateRequest(TWILIO_SECRET, event.headers['X-Twilio-Signature'], event.url.href, event.body)) {
		throw boom.forbidden('Invalid X-Twilio-Signature');
	}
}

function validateRequestSession(event, context) {
	if (event.queryStringParameters && event.queryStringParameters.session) {
		event.session = jwt.verify(event.queryStringParameters.session, TWILIO_SECRET, {
			issuer: JWT_ISSUER,
			maxAge: JWT_MAX_AGE,
			subject: event.body.CallSid,
		});
	} else {
		event.session = {
			state: states.GREETING,
		};
	}
}

function getResponse(event, context) {
	console.log({event, context});

	function next(state) {
		const session = jwt.sign(state, TWILIO_SECRET, {
			subject: event.body.CallSid,
			issuer: JWT_ISSUER,
			expiresIn: JWT_MAX_AGE,
		});

		const url = new URL(event.url.href);
		url.searchParams.set('session', session);

		return url.href;
	}

	const response = new twilio.twiml.VoiceResponse();
	const sessionCallback = STATE_HANDLERS[event.session.state];
	if (sessionCallback) {
		sessionCallback(response, event, context, next);
	} else {
		throw boom.badRequest('Invalid session state', event.session);
	}

	return {
		statusCode: 200,
		headers: {
			'Content-Type': 'application/xml',
		},
		body: response.toString(),
	};
}

function getErrorResponse(event, context, err) {
	if (!err.isBoom) {
		err = boom.boomify(err, {statusCode: 500});
	}
	console.error(err);

	return {
		statusCode: err.statusCode,
	};
}
