s.boot;



(
	~numPlayers = 4;
	~mainPath = "~/MobileScores/Carmina/vocerera/sounds/";
	~folderCategories = ["BARULLOS", "CANCIONES", "NARRACIONES", "SONIDOSSCAPE"];

	~categoryBuffers = Array.newClear(~numPlayers);
	~garbageBuffers = List.new;
	~ampBusses = Array.fill(~numPlayers, { Bus.control(s,1); });
)

(
~preloadFiles = { | doneAction |

	var numLoaded = 0;
	~categoryBuffers.do({ | item, i |
		var categoryDir = PathName.new(~mainPath ++ ~folderCategories[i]);

		categoryDir.files.postln;
		// Add previous buffer to garbage if it exists
		if(~categoryBuffers[i].notNil, {
			~garbageBuffers.add(~categoryBuffers[i]);
		});

		~categoryBuffers[i] = Buffer.read(s, categoryDir.files.choose.fullPath, action: {

			numLoaded = numLoaded + 1;

			if(numLoaded >= ~categoryBuffers.size(), {
				// Call doneAction callback if it exists
				"done".postln;
				doneAction.value() ?? nil;
			});
		});
	});
};
)


(

	~preloadFiles.value({
		~players = Array.fill(~numPlayers, { |i|
			{
				var buffer = ~categoryBuffers[i];
				var player = PlayBuf.ar(buffer.numChannels, buffer, loop: 1);

				player * ~ampBusses[i].kr;
			}.play;
		});
	});
)


// Playback upon entry
(
	var lowVol=0.05, highVol=0.2;

	~ampBusses.do(_.set(lowVol));
	Tdef(\playbackSeq, {
		{
			
			var randomBusFocus = ~ampBusses.choose;
			{
				var env = EnvGen.kr(Env.new([lowVol, highVol, lowVol],[5, 30, 5]), doneAction:2);
				Out.kr(randomBusFocus, env);
			}.play;

			(10.0+5).wait;
		}.loop;
	});
)

Tdef(\playbackSeq).play;
Tdef(\playbackSeq).stop;
