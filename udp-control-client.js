var SERVER_HOST = '192.168.1.10';
var SERVER_PORT = 33333;
var CLIENT_CONTROL_PORT = 33334;
var CLIENT_AHRS_PORT = 33335;

var JOYSTICK_DEADZONE = 3500;
var JOYSTICK_SENSITIVITY = 0;

var dgram = require('dgram');
var client = dgram.createSocket('udp4');

var yaw = 0.00;
var pitch = 0.00;
var roll = 0.00;

var throttle = ['AUTO', 0.00, 0.00];

var select = 1;

client.on( "message", function (message, remote) {
    console.log(remote.address + ':' + remote.port +' - ' + message);
});

client.bind(CLIENT_CONTROL_PORT);

var joystick = new (require('joystick'))(0, JOYSTICK_DEADZONE, JOYSTICK_SENSITIVITY);
joystick.on('button', function (stream) {
	if(stream.value=='1'){
		var messageText = stream.number + 1;
		//console.log(stream.number);
		switch (stream.number){
			case 0:
				messageText = 'FIRE';
			break;
			case 9:
				select = 1;
				console.log("Switched to THROTTLE " + select);
			break;
			case 10:
				select = 2;
				console.log("Switched to THROTTLE " + select);
			break;
			case 11:
			messageText = 'SELECT-UP';
				if(select >= 2)	select = 0;
				else	select++;
				console.log("Switched to THROTTLE " + select);
			break;
			case 12:
			messageText = 'SELECT-DOWN';
				if(select <= 0)	select = 2;
				else	select--;
				console.log("Switched to THROTTLE " + select);
			break;
			case 13:
			messageText = 'OPTIONS';
			break;
		}

		/*messageText = 'CONTROL BTN ' + messageText;
		var message = new Buffer(messageText);
		client.send(message, 0, message.length, SERVER_PORT, SERVER_HOST, function(err, bytes) {
			if (err) throw err;
			console.log(messageText + ' sent to ' + SERVER_HOST +':'+ SERVER_PORT);
		});*/
	}
});

joystick.on('axis', function (stream) {
	var messageText = stream.number;
	switch (stream.number){
		case 0:
		messageText = 'X';
		roll = 1*parseFloat((parseFloat(stream.value)*9.0/JOYSTICK_DEADZONE)).toFixed(2);
		break;
		case 1:
		messageText = 'Y';
		pitch = 1*parseFloat((parseFloat(stream.value)*9.0/JOYSTICK_DEADZONE)).toFixed(2);
		break;
		case 2:
		messageText = 'THROTTLE-LEFT';
		throttle[1] = ((1-(parseFloat(stream.value)+32767.0)/(2.0*32767.0))*100.0).toFixed(2);
		break;
		case 3:
		messageText = 'Z';
		yaw = parseFloat((parseFloat(stream.value)*9.0/JOYSTICK_DEADZONE)).toFixed(2);
		break;
		case 4:
		messageText = 'THROTTLE-RIGHT';
		throttle[2] = ((1-(parseFloat(stream.value)+32767.0)/(2.0*32767.0))*100.0).toFixed(2);
		break;
	}

	messageText = '$CONTROL DYNAMICS #YPRT=' + yaw + ',' + pitch + ',' + roll + '::' + throttle[select] + '\n';
	var message = new Buffer(messageText);
	client.send(message, 0, message.length, SERVER_PORT, SERVER_HOST, function(err, bytes) {
		if (err) throw err;
		console.log(messageText);// + ' sent to ' + SERVER_HOST +':'+ SERVER_PORT);
	});
});
