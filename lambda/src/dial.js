import states from './states.js';

const CALLER_ID = process.env.CALLER_ID;

export default function(response, event, context, next) {
	// TODO: {KL} Use caller ID
	const dial = response.dial({
		action: next({state: states.END_CALL}),
		callerId: CALLER_ID,
	});

	event.session.dial.forEach((number) => {
		dial.number(number);
	});
}
