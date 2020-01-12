import voice from './voice.js';
import states from './states.js';

import template from './templates/greeting.handlebars';

export default function(response, event, context, next) {
	const greeting = template({});
	if (greeting) {
		response.say(voice, greeting);
	}
	response.redirect({}, next({state: states.MENU}));
}
