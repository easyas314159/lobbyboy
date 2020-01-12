const ACCEPT_DIGITS = process.env.ACCEPT_DIGITS;

export default function(response, event, context, next) {
	response.play({
		digits: ACCEPT_DIGITS,
	});
	response.hangup();
}
