
(
s.waitForBoot({
	// Settings
	var masterVol = 0;
	var lowVol=0.05, highVol=0.3;
	var numPlayers = 4;

	// Paths
	var mainPath = "~/sounds/";
	var folderCategories = ["BARULLOS", "CANCIONES", "NARRACIONES", "SONIDOSSCAPE"];

	// Buffers
	var categoryBuffers = Array.newClear(numPlayers);
	var garbageBuffers = List.new;
	var ampBusses = Array.fill(numPlayers, { Bus.control(s,1); });

	// Declarations
	var players;

	// Trigger functions
	var personEnters = {
		masterVol = 1;
		ampBusses.do(_.set(lowVol * masterVol)); // This will move to the trigger function
	};
	var personExits = {
		masterVol = 0;
		ampBusses.do(_.set(lowVol * masterVol)); // This will move to the trigger function
	};

	var preloadFile = { | bufferIndex, callback |
		//var categoryIndex = categoryBuffers.indexOf(buffer);
		var categoryDir = PathName.new(mainPath ++ folderCategories[bufferIndex]);

		// Add previous buffer to garbage
		if(categoryBuffers[bufferIndex].notNil, {
			garbageBuffers.add(categoryBuffers[bufferIndex]);
		});

		categoryBuffers[bufferIndex] = Buffer.read(s, categoryDir.files.choose.fullPath, action: {
			// empty garbage
			garbageBuffers.do(_.free);
			garbageBuffers = List.new;

			callback.value() ?? nil;
		});
	};

	var preloadFiles = { | doneAction |

		var numLoaded = 0;
		categoryBuffers.do({ | item, i |

			preloadFile.value(i, {
				numLoaded = numLoaded + 1;

				if(numLoaded >= categoryBuffers.size(), {
					// Call doneAction callback if it exists
					doneAction.value() ?? nil;
				});
			});
		});
	};



	var createPlayer = { |i|
		var bufferLengthSecs = categoryBuffers[i].numFrames / categoryBuffers[i].sampleRate;
		{
			var buffer = categoryBuffers[i];
			var player = PlayBuf.ar(buffer.numChannels, buffer, loop: 0, doneAction: 2);

			Out.ar(i, (player[0]+player[1]) * ampBusses[i].kr);
		}.play;

		{
			bufferLengthSecs.wait;
			createPlayer.value(i);
			preloadFile.value(i);
		}.fork;
	};


	//ARDUINO
	var serial = SerialPort("/dev/ttyUSB0", baudrate: 9600, crtscts: true);

	var readSerial = Routine({
		var byte, str, res;
		{
			if(serial.read==10, {
				str = "";
				while({byte = serial.read; byte !=13 }, {
					str= str++byte.asAscii;
				});
				res= str.asInteger;
				("read value:"+res).postln;
				if(res > 1, {
					personEnters.value();
				}, {
					personExits.value();
				});
			});
			0.01.wait;
		}.loop;
	});


	// PROGRAM
	preloadFiles.value({
		players = Array.fill(numPlayers, createPlayer);
	});

	ampBusses.do(_.set(lowVol * masterVol)); // This will move to the trigger function

	// Focus algorithm
	Tdef(\playbackSeq, {
		{
			
			var randomBusFocus = ampBusses.choose;
			{
				var env = EnvGen.kr(Env.new([lowVol, highVol, lowVol],[5, 30, 5]), doneAction:2) * masterVol;
				Out.kr(randomBusFocus, env);
			}.play;

			(10.0+5).wait;
		}.loop;
	});

	Tdef(\playbackSeq).play;
	readSerial.play;

	// Making globals for testing
	//~enter = personEnters;
	//~exit = personExits;
	//~buffers = categoryBuffers;
});

)

