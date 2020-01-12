import boom from '@hapi/boom';

import states from './states.js';

const DELIVERY = process.env.DELIVERY;
const PARTY_CODE = process.env.PARTY_CODE;

export default function(response, event, context, next) {
	if(DELIVERY && event.body.Digits === '0') {
		response.redirect(next({
			state: states.DIAL,
			dial: Object.keys(event.session.dial).map((key) => event.session.dial[key]),
		}));
	} else if (event.session.dial[event.body.Digits]) {
		response.redirect(next({
			state: states.DIAL,
			dial: [event.session.dial[event.body.Digits]],
		}));
	} else if(PARTY_CODE && event.body.Digits === PARTY_CODE) {
		response.redirect(next({
			state: states.ACCEPT,
		}));
	} else {
		throw boom.badRequest();
	}
}
