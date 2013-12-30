var SERVER_HOST = '192.168.1.8';
var SERVER_PORT = 33333;
var CLIENT_CONTROL_PORT = 33334;
var CLIENT_AHRS_PORT = 33335;

var JOYSTICK_DEADZONE = 3500;
var JOYSTICK_SENSITIVITY = 0;

var dgram = require('dgram');
var client = dgram.createSocket('udp4');

client.on( "message", function (message, remote) {
    console.log(remote.address + ':' + remote.port +' - ' + message);
});

client.bind(CLIENT_CONTROL_PORT);

var joystick = new (require('joystick'))(0, JOYSTICK_DEADZONE, JOYSTICK_SENSITIVITY);
joystick.on('button', function (stream) {
	if(stream.value=='1'){
		var messageText = stream.number + 1;
		switch (stream.number){
			case 0:
			messageText = 'FIRE';
			break;
			case 11:
			messageText = 'SELECT-UP';
			break;
			case 12:
			messageText = 'SELECT-DOWN';
			break;
			case 13:
			messageText = 'OPTIONS';
			break;
		}

		messageText = 'CONTROL BTN ' + messageText;
		var message = new Buffer(messageText);
		client.send(message, 0, message.length, SERVER_PORT, SERVER_HOST, function(err, bytes) {
			if (err) throw err;
			console.log(messageText + ' sent to ' + SERVER_HOST +':'+ SERVER_PORT);
		});
	}
});

joystick.on('axis', function (stream) {
	var messageText = stream.number;
	switch (stream.number){
		case 0:
		messageText = 'X';
		break;
		case 1:
		messageText = 'Y';
		stream.value *= -1;
		break;
		case 2:
		messageText = 'THROTTLE-LEFT';
		break;
		case 3:
		messageText = 'Z';
		break;
		case 4:
		messageText = 'THROTTLE-RIGHT';
		break;
	}

	messageText = 'CONTROL AXIS ' + messageText + ' ' + parseInt((parseInt(stream.value)*100.0/JOYSTICK_DEADZONE));
	var message = new Buffer(messageText);
	client.send(message, 0, message.length, SERVER_PORT, SERVER_HOST, function(err, bytes) {
		if (err) throw err;
		console.log(messageText + ' sent to ' + SERVER_HOST +':'+ SERVER_PORT);
	});
});
