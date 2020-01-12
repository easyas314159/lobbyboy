import voice from './voice.js';
import states from './states.js';

import template from './templates/menu.handlebars';

const USERS = JSON.parse(process.env.USERS);
const DELIVERY = process.env.DELIVERY;

export default function(response, event, context, next) {
	const codesDial = {};
	const codesName = [];

	let dialCode = 1;
	Object.keys(USERS).forEach((key) => {
		codesDial[dialCode] = key;
		codesName.push({
			name: USERS[key],
			code: dialCode,
		});
		dialCode += 1;
	});

	const menu = template({
		users: codesName,
		delivery: DELIVERY,
	});

	if (Object.keys(USERS).length > 0) {
		const gather = response.gather({
			action: next({state: states.GATHER, dial: codesDial}),
		});
		gather.say(voice, menu);
	} else {
		response.say(voice, menu);
		response.hangup();
	}
}
