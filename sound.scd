s.boot;



(
~mainPath = "~/MobileScores/Carmina/birdcage/";
~folderCategories = ["BARULLOS", "CANCIONES", "NARRACIONES", "SONIDOSSCAPE"];

)

~categoryBuffers = Array.newClear(4);
(
~preloadFiles = { | doneAction |

	var numLoaded = 0;
	~categoryBuffers.do({ | item, i |
		var categoryDir = PathName.new(~mainPath ++ ~folderCategories.choose);

		~categoryBuffers[i] = Buffer.read(s, ~barullos.files.choose.fullPath, action: {

			numLoaded = numLoaded + 1;

			if(numLoaded >= ~categoryBuffers.size(), {
				// Call doneAction callback if it exists
				doneAction.value() ?? nil;
			});
		});
	});
};
)


~preloadFiles.value({"done".postln});

(
	~players = Array.fill(4, { |i|
		{ |amp=0|
			var buffer = ~categoryBuffers[i];
			var player = PlayBuf.ar(buffer.numChannels, buffer, loop: 1);

			player * amp;
		}.play;
	});
)


~players[0].set(\amp, 0.5);
~players[1].set(\amp, 0.5);
~players[2].set(\amp, 0.5);
~players[3].set(\amp, 0.5);
