var HOST = '127.0.0.1';
var SERVER_PORT = 33333;
var CLIENT_PORT = 33334;

var dgram = require('dgram');
var client = dgram.createSocket('udp4');

client.on( "message", function (message, remote) {
    console.log(remote.address + ':' + remote.port +' - ' + message);
});

client.bind(CLIENT_PORT, HOST);

var message = new Buffer('Hello World!');
client.send(message, 0, message.length, SERVER_PORT, HOST, function(err, bytes) {
	if (err) throw err;
	console.log('UDP message sent to ' + HOST +':'+ SERVER_PORT);
});
